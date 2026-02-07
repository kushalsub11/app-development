from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config.settings import settings
from config.database import Base
from models.user import User
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

admin_email = "admin@sajeloguru.com"
admin = db.query(User).filter(User.email == admin_email).first()

if not admin:
    admin = User(
        email=admin_email,
        full_name="Super Admin",
        password_hash=pwd_context.hash("admin123"),
        role="admin",
        is_email_verified=True,
        is_active=True
    )
    db.add(admin)
    db.commit()
    print("Admin Created successfully!")
else:
    admin.password_hash = pwd_context.hash("admin123")
    admin.is_email_verified = True
    db.commit()
    print("Admin Reset successfully!")

db.close()
