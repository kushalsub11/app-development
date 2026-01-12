import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv
import os

load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "sajelo_guru")

try:
    # Connect to default postgres database to create the new database
    connection = psycopg2.connect(
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
        dbname="postgres"
    )
    
    # Needs to be autocommit since CREATE DATABASE cannot run in a transaction block
    connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cursor = connection.cursor()
    
    # Check if database exists
    cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
    exists = cursor.fetchone()
    
    if not exists:
        cursor.execute(f"CREATE DATABASE {DB_NAME};")
        print(f"Database `{DB_NAME}` created successfully.")
    else:
        print(f"Database `{DB_NAME}` already exists.")
        
    cursor.close()
    connection.close()

except Exception as e:
    print(f"Error creating PostgreSQL database: {e}")
