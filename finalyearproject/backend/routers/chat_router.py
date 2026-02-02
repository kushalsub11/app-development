from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
import json

from sqlalchemy.orm import Session
from sqlalchemy.orm import joinedload
from typing import List, Dict
from config.database import get_db
from models.user import User, ChatRoom, ChatMessage, Booking
from schemas.user_schema import ChatRoomResponse, ChatMessageResponse
from middleware.auth_middleware import get_current_user
from services.auth_service import decode_access_token

router = APIRouter(prefix="/chat", tags=["Chat"])

# Simple in-memory connection manager for WebSockets
class ConnectionManager:
    def __init__(self):
        # Maps room_id -> list of active WebSockets
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: int):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)

    def disconnect(self, websocket: WebSocket, room_id: int):
        if room_id in self.active_connections:
            self.active_connections[room_id].remove(websocket)
            if not self.active_connections[room_id]:  # clean up empty rooms
                del self.active_connections[room_id]

    async def broadcast(self, message: dict, room_id: int):
        if room_id in self.active_connections:
            print(f"--- Signaling --- Broadcasting to {len(self.active_connections[room_id])} listeners in Room {room_id}")
            for connection in self.active_connections[room_id]:
                await connection.send_json(message)
        else:
            print(f"--- Signaling --- ERROR: No active listeners in Room {room_id}")

manager = ConnectionManager()

async def get_user_from_token(token: str, db: Session) -> User:
    payload = decode_access_token(token)
    if not payload:
        return None
    
    user_id: int = payload.get("user_id")
    if user_id is None:
        return None
        
    user = db.query(User).filter(User.id == user_id).first()
    return user


@router.get("/room/booking/{booking_id}", response_model=ChatRoomResponse)
async def get_or_create_room(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get the chat room for a specific booking. Create it if it doesn't exist."""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    # Check authorization (only user or advisor attached to booking can access)
    is_user = booking.user_id == current_user.id
    is_advisor = booking.advisor.user_id == current_user.id
    if not (is_user or is_advisor):
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")

    # Check consultation type
    if booking.consultation_type.value != "chat":
        raise HTTPException(status_code=403, detail="This booking is not for a chat consultation.")

    room = db.query(ChatRoom).options(
        joinedload(ChatRoom.messages)
    ).filter(ChatRoom.booking_id == booking_id).first()
    
    if room:
        # Sort messages by timestamp so history is correct on the phone
        room.messages.sort(key=lambda x: x.timestamp)
    
    if not room:
        room = ChatRoom(
            booking_id=booking_id,
            user_id=booking.user_id,
            advisor_id=booking.advisor.user_id
        )
        db.add(room)
        db.commit()
        db.refresh(room)
        
    return room


@router.websocket("/ws/{room_id}")
async def websocket_endpoint(
    websocket: WebSocket, 
    room_id: int, 
    token: str = Query(...), 
    db: Session = Depends(get_db)
):
    user = await get_user_from_token(token, db)
    if not user:
        print(f"WS Auth Failed for token: {token[:10]}...")
        await websocket.close(code=1008)  # Policy Violation (invalid auth)
        return

    # Verify room exists and user is participant
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        print(f"WS Error: Room {room_id} not found")
        await websocket.close(code=1008)
        return
        
    if user.id != room.user_id and user.id != room.advisor_id:
        print(f"WS Error: User {user.id} not participant in room {room_id}")
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, room_id)
    print(f"--- WebSocket --- User {user.id} (Role: {user.role}) connected to Room {room_id}")
    try:
        while True:
            # Receive data as JSON (standardized with the frontend)
            try:
                msg_data = await websocket.receive_json()
            except WebSocketDisconnect:
                break
            except Exception as e:
                print(f"WS Incoming Error: {e}")
                break
            
            msg_type = msg_data.get("type", "chat")
            
            if msg_type == "chat":
                # Save message to DB
                new_msg = ChatMessage(
                    room_id=room_id,
                    sender_id=user.id,
                    content=msg_data.get("content", "")
                )
                db.add(new_msg)
                db.commit()
                db.refresh(new_msg)

                # Broadcast to everyone in the room
                broadcast_msg = {
                    "type": "chat",
                    "id": new_msg.id,
                    "room_id": new_msg.room_id,
                    "sender_id": new_msg.sender_id,
                    "content": new_msg.content,
                    "timestamp": new_msg.timestamp.isoformat(),
                    "is_read": new_msg.is_read
                }
                await manager.broadcast(broadcast_msg, room_id)
            
            elif msg_type in ["call_invite", "call_accept", "call_reject", "call_end"]:
                # For call signaling, just broadcast the entire payload
                msg_data["sender_id"] = user.id
                print(f"--- Signaling --- Broadcasting {msg_type} from {user.id} to Room {room_id}")
                await manager.broadcast(msg_data, room_id)

            
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)
