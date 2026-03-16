from sqlalchemy.orm import Session
from models.user import Notification

def create_notification(
    db: Session, 
    user_id: int, 
    title: str, 
    message: str, 
    notification_type: str = None, 
    reference_id: str = None
):
    """
    Central helper to create and save a notification for a user.
    """
    new_notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
        reference_id=reference_id
    )
    db.add(new_notification)
    try:
        db.commit()
        db.refresh(new_notification)
        return new_notification
    except Exception as e:
        db.rollback()
        print(f"Error creating notification: {e}")
        return None
