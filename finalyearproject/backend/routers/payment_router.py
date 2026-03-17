from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
import requests
import json
import logging
from config.database import get_db
from config.settings import settings
from models.user import User, Payment, Booking, BookingStatus, PaymentStatus
from schemas.user_schema import PaymentCreate, PaymentResponse
from middleware.auth_middleware import get_current_user, require_role

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/khalti/initiate/{booking_id}")
async def initiate_khalti_payment(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Initiate Khalti payment for a booking."""
    # Verify booking exists and belongs to the user
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")
    
    if booking.status != BookingStatus.accepted:
        raise HTTPException(
            status_code=400, 
            detail=f"Cannot pay for booking in {booking.status} status. Please wait for advisor acceptance."
        )
    
    # Amount in Paisa
    amount_paisa = int(booking.amount * 100)

    # Khalti Initiate URL
    url = settings.KHALTI_INITIATE_URL
    headers = {
        "Authorization": settings.KHALTI_SECRET_KEY,
        "Content-Type": "application/json",
    }
    
    # Use the server's network IP for the return URL so physical devices can reach it
    base_url = f"http://192.168.18.28:{getattr(settings, 'SERVER_PORT', 8000)}"
    
    payload = {
        "return_url": f"{base_url}/payments/khalti/callback?booking_id={booking.id}", 
        "website_url": "https://sajeloguru.com",

        "amount": amount_paisa,
        "purchase_order_id": str(booking.id),
        "purchase_order_name": f"Consultation Booking #{booking.id}",
        "customer_info": {
            "name": current_user.full_name,
            "email": current_user.email,
            "phone": current_user.phone or "9800000000",
        }
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response_data = response.json()
        
        if response.status_code == 200:
            return response_data
        else:
            error_detail = response_data.get("detail", response_data.get("message", "Khalti initiation failed"))
            logger.error(f"Khalti API error for booking {booking_id}: Status {response.status_code}, Response: {response_data}")
            raise HTTPException(status_code=400, detail=error_detail)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Khalti payment initiation error for booking {booking_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


from fastapi.responses import HTMLResponse

@router.get("/khalti/callback", response_class=HTMLResponse)
async def khalti_callback(
    request: Request,
    booking_id: int,
    pidx: str = None,
    transaction_id: str = None,
    tidx: str = None,
    amount: int = None,
    total_amount: int = None,
    mobile: str = None,
    status: str = None,
    purchase_order_id: str = None,
    purchase_order_name: str = None,
    db: Session = Depends(get_db),
):
    """Callback from Khalti after payment redirection."""
    # If redirection comes with status=Completed or we simply have a pidx
    if pidx:
        # We can verify it right here
        url = settings.KHALTI_LOOKUP_URL
        headers = {
            "Authorization": settings.KHALTI_SECRET_KEY,
            "Content-Type": "application/json",
        }
        payload = {"pidx": pidx}
        
        try:
            response = requests.post(url, headers=headers, json=payload)
            res_data = response.json()
            
            if response.status_code == 200 and res_data.get("status") == "Completed":
                # Update DB
                booking = db.query(Booking).filter(Booking.id == booking_id).first()
                if booking:
                    # Update Payment or Create if not exists
                    payment = db.query(Payment).filter(Payment.booking_id == booking_id).first()
                    if not payment:
                        payment = Payment(
                            booking_id=booking.id,
                            user_id=booking.user_id,
                            amount=booking.amount,
                            transaction_id=pidx,
                            payment_method="khalti",
                            status=PaymentStatus.completed,
                            paid_at=datetime.utcnow()
                        )
                        db.add(payment)
                    else:
                        payment.status = PaymentStatus.completed
                        payment.transaction_id = pidx
                        payment.paid_at = datetime.utcnow()
                    
                    booking.status = BookingStatus.confirmed
                    db.commit()

                return """
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Payment Successful | Sajelo Guru</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f6f7f9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                        .card { background: white; padding: 40px; border-radius: 24px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); text-align: center; max-width: 400px; width: 90%; }
                        .icon { width: 80px; height: 80px; background: #28a745; color: white; border-radius: 50%; display: flex; justify-content: center; align-items: center; font-size: 40px; margin: 0 auto 24px; }
                        h1 { color: #1a0949; margin: 0 0 12px; font-size: 24px; }
                        p { color: #666; font-size: 16px; line-height: 1.5; margin: 0 0 32px; }
                        .btn { background: linear-gradient(135deg, #1a0949 0%, #381b85 100%); color: white; padding: 14px 28px; border: none; border-radius: 12px; font-size: 16px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-block; box-shadow: 0 4px 15px rgba(56, 27, 133, 0.3); }
                    </style>
                </head>
                <body>
                    <div class="card">
                        <div class="icon">✓</div>
                        <h1>Payment Success!</h1>
                        <p>Your consultation booking has been confirmed. You can now return to the app to start your session.</p>
                        <a href="javascript:window.close()" class="btn">Return to App</a>
                    </div>
                </body>
                </html>
                """
        except Exception as e:
            print(f"Callback verification error: {e}")

    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Payment Failed | Sajelo Guru</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f6f7f9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .card { background: white; padding: 40px; border-radius: 24px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); text-align: center; max-width: 400px; width: 90%; }
            .icon { width: 80px; height: 80px; background: #dc3545; color: white; border-radius: 50%; display: flex; justify-content: center; align-items: center; font-size: 40px; margin: 0 auto 24px; }
            h1 { color: #1a0949; margin: 0 0 12px; font-size: 24px; }
            p { color: #666; font-size: 16px; line-height: 1.5; margin: 0 0 32px; }
            .btn { background: #5d3fd3; color: white; padding: 14px 28px; border: none; border-radius: 12px; font-size: 16px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-block; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="icon">✕</div>
            <h1>Verification Failed</h1>
            <p>We couldn't verify your payment. Please check your transaction history in the app or contact support.</p>
            <a href="javascript:window.close()" class="btn">Go Back</a>
        </div>
    </body>
    </html>
    """



@router.get("/khalti/verify")
async def verify_khalti_payment(
    pidx: str,
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Verify Khalti payment status and update database."""
    # Khalti Lookup URL
    url = settings.KHALTI_LOOKUP_URL
    headers = {
        "Authorization": settings.KHALTI_SECRET_KEY,
        "Content-Type": "application/json",
    }
    
    payload = {"pidx": pidx}

    try:
        response = requests.post(url, headers=headers, json=payload)
        response_data = response.json()
        
        if response.status_code == 200 and response_data.get("status") == "Completed":
            # Update Payment/Booking table
            booking = db.query(Booking).filter(Booking.id == booking_id).first()
            if not booking:
                raise HTTPException(status_code=404, detail="Booking not found")
            
            # Check if payment already exists
            payment = db.query(Payment).filter(Payment.booking_id == booking_id).first()
            if not payment:
                payment = Payment(
                    booking_id=booking.id,
                    user_id=current_user.id,
                    amount=booking.amount,
                    transaction_id=pidx,
                    payment_method="khalti",
                    status=PaymentStatus.completed,
                    paid_at=datetime.utcnow()
                )
                db.add(payment)
            else:
                payment.status = PaymentStatus.completed
                payment.transaction_id = pidx
                payment.paid_at = datetime.utcnow()
            
            booking.status = BookingStatus.confirmed
            db.commit()
            return {"success": True, "message": "Payment verified successfully", "booking_id": booking.id}
        else:
            logger.warning(f"Payment verification failed for booking {booking_id}: {response_data}")
            return {"success": False, "message": "Payment not completed or verification failed", "data": response_data}
            
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Payment verification error for booking {booking_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Process a payment for a booking."""
    # Verify booking exists
    booking = db.query(Booking).filter(Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")

    # Check if payment already exists
    existing = db.query(Payment).filter(Payment.booking_id == payment_data.booking_id).first()
    if existing and existing.status == PaymentStatus.completed:
        raise HTTPException(status_code=400, detail="Payment already completed")

    new_payment = Payment(
        booking_id=payment_data.booking_id,
        user_id=current_user.id,
        amount=payment_data.amount,
        transaction_id=payment_data.transaction_id,
        payment_method=payment_data.payment_method,
        status=PaymentStatus.completed,
        paid_at=datetime.utcnow(),
    )
    db.add(new_payment)

    # Update booking status to confirmed
    booking.status = BookingStatus.confirmed
    db.commit()
    db.refresh(new_payment)
    return PaymentResponse.model_validate(new_payment)


@router.get("/my-payments", response_model=List[PaymentResponse])
async def get_my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get payments for the current user."""
    payments = db.query(Payment).filter(Payment.user_id == current_user.id).all()
    return [PaymentResponse.model_validate(p) for p in payments]


@router.get("", response_model=List[PaymentResponse])
async def get_all_payments(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all payments (Admin only)."""
    payments = db.query(Payment).all()
    return [PaymentResponse.model_validate(p) for p in payments]
