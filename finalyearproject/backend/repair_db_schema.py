import sys
import os

# Add the current directory to sys.path to import local modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from config.database import engine, Base
from models.user import User, AdvisorProfile, Booking, ChatMessage, MessageType

def repair_db():
    print("--- Starting Database Repair (Adding New Columns) ---")
    
    # Each operation in its own transaction block to avoid "InFailedSqlTransaction"
    operations = [
        ("CREATE TYPE messagetype AS ENUM ('text', 'image')", "Created MessageType ENUM"),
        ("ALTER TABLE advisor_profiles ADD COLUMN is_physical_available BOOLEAN DEFAULT FALSE", "Added is_physical_available to advisor_profiles"),
        ("ALTER TABLE advisor_profiles ADD COLUMN is_virtual_available BOOLEAN DEFAULT TRUE", "Added is_virtual_available to advisor_profiles"),
        ("ALTER TABLE advisor_profiles ADD COLUMN is_online BOOLEAN DEFAULT TRUE", "Added is_online to advisor_profiles"),
        ("ALTER TABLE advisor_profiles ADD COLUMN office_address VARCHAR(500)", "Added office_address to advisor_profiles"),
        ("ALTER TABLE bookings ADD COLUMN meeting_location VARCHAR(500)", "Added meeting_location to bookings"),
        ("ALTER TABLE chat_messages ADD COLUMN message_type messagetype DEFAULT 'text'", "Added message_type to chat_messages"),
        ("ALTER TABLE advisor_profiles ADD COLUMN religion VARCHAR(50)", "Added religion to advisor_profiles"),
        ("ALTER TABLE notifications ADD COLUMN notification_type VARCHAR(50)", "Added notification_type to notifications"),
        ("ALTER TABLE notifications ADD COLUMN reference_id VARCHAR(50)", "Added reference_id to notifications"),
    ]

    for sql, success_msg in operations:
        try:
            with engine.begin() as conn:
                conn.execute(text(sql))
            print(f"[+] {success_msg}")
        except Exception as e:
            # Check if it's already exists
            if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                print(f"[-] Column/Type already exists, skipping.")
            else:
                print(f"[-] Operation failed: {e}")

    print("--- Database Repair Finished ---")

if __name__ == "__main__":
    repair_db()
