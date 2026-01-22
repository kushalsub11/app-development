from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config.database import engine, Base
from config.settings import settings
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
)


# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Sajelo Guru API",
    description="Astrology Advisory System Backend API",
    version="1.0.0",
)

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
