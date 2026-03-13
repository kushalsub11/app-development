from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from config.database import engine, Base, SessionLocal
from config.settings import settings
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from models.user import Booking, BookingStatus
from routers import (
    auth_router,
    user_router,
    advisor_router,
    booking_router,
    review_router,
    report_router,
    payment_router,
    admin_router,
    chat_router,
    call_router,
    horoscope_router,
    astro_router,
    payout_router,
    notification_router,
)


# Create database tables
Base.metadata.create_all(bind=engine)

async def auto_cancel_stale_bookings():
    while True:
        await asyncio.sleep(60) # check every minute
        db = SessionLocal()
        try:
            five_mins_ago = datetime.utcnow() - timedelta(minutes=5)
            # 1. Find requested bookings older than 5 mins
            stale_requests = db.query(Booking).filter(
                Booking.status == BookingStatus.requested,
                Booking.created_at <= five_mins_ago
            ).all()
            
            # 2. Find accepted bookings (awaiting payment) older than 5 mins
            stale_payments = db.query(Booking).filter(
                Booking.status == BookingStatus.accepted,
                Booking.accepted_at <= five_mins_ago
            ).all()

            all_stale = stale_requests + stale_payments
            
            if all_stale:
                for b in all_stale:
                    b.status = BookingStatus.cancelled
                db.commit()
        except Exception as e:
            print(f"Error in auto-cancel task: {e}")
        finally:
            db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start background task
    task = asyncio.create_task(auto_cancel_stale_bookings())
    yield
    # Stop background task
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass

app = FastAPI(
    title="Sajelo Guru API",
    description="Astrology Advisory System Backend API",
    version="1.0.0",
    lifespan=lifespan
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router.router)
app.include_router(user_router.router)
app.include_router(advisor_router.router)
app.include_router(booking_router.router)
app.include_router(review_router.router)
app.include_router(report_router.router)
app.include_router(payment_router.router)
app.include_router(admin_router.router)
app.include_router(chat_router.router)
app.include_router(call_router.router)
app.include_router(astro_router.router)
app.include_router(horoscope_router.router)
app.include_router(payout_router.router)
app.include_router(notification_router.router)





@app.get("/")
async def root():
    return {
        "message": "Welcome to Sajelo Guru API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.SERVER_HOST, port=settings.SERVER_PORT, reload=True)
