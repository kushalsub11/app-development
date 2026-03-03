from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

# Load from the backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "kushal")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "sajelo_guru")

SQLALCHEMY_DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def migrate():
    print(f"Connecting to {SQLALCHEMY_DATABASE_URL}...")
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    
    with engine.connect() as conn:
        print("Checking for existing columns...")
        try:
            conn.execute(text("SELECT advisor_reply FROM reviews LIMIT 1"))
            print("Columns already exist. Skipping.")
            return
        except Exception:
            # We must rollback or start a new transaction because the previous one failed due to column check
            print("Column not found, proceeding with ALTER TABLE...")
            pass

    # Start a clean transaction
    with engine.begin() as conn:
        try:
            conn.execute(text("ALTER TABLE reviews ADD COLUMN advisor_reply TEXT"))
            print("Added advisor_reply column.")
        except Exception as e:
            if "already exists" in str(e):
                print("advisor_reply column already exists.")
            else:
                raise e

        try:
            conn.execute(text("ALTER TABLE reviews ADD COLUMN replied_at TIMESTAMP"))
            print("Added replied_at column.")
        except Exception as e:
            if "already exists" in str(e):
                print("replied_at column already exists.")
            else:
                raise e
                
    print("Migration completed.")

if __name__ == "__main__":
    migrate()
