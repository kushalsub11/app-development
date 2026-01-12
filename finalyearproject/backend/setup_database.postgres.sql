-- Sajelo Guru Database Setup Script for PostgreSQL
-- Run this in pgAdmin or via psql if you don't use the create_db.py script

-- Create Database
-- CREATE DATABASE sajelo_guru;
-- \c sajelo_guru

-- Enum Types (PostgreSQL requires explicit Enum type creation)
CREATE TYPE user_role AS ENUM ('user', 'advisor', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
CREATE TYPE consultation_type AS ENUM ('chat', 'voice', 'video');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved', 'dismissed');
CREATE TYPE call_status AS ENUM ('initiated', 'ongoing', 'completed', 'missed');

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_image VARCHAR(255),
    role user_role DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Insert default admin (Password: admin123 hashed with bcrypt)
INSERT INTO users (full_name, email, password_hash, role, is_active) 
VALUES ('Admin', 'admin@sajeloguru.com', '$2b$12$LXFhJ8G0h1gJ3T3Z1qJ3ZOqdGkPv2S8TN8J3p3j5d5GfZ3v3j3b3.', 'admin', TRUE)
ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name;

-- Advisor Profiles Table
CREATE TABLE IF NOT EXISTS advisor_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    specialization VARCHAR(200),
    experience_years INTEGER DEFAULT 0,
    hourly_rate FLOAT DEFAULT 0.0,
    rating FLOAT DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_doc VARCHAR(255),
    available_slots JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    advisor_id INTEGER NOT NULL REFERENCES advisor_profiles(id) ON DELETE CASCADE,
    booking_date TIMESTAMP NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status booking_status DEFAULT 'pending',
    consultation_type consultation_type DEFAULT 'chat',
    amount FLOAT DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount FLOAT NOT NULL,
    transaction_id VARCHAR(255),
    status payment_status DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'khalti',
    paid_at TIMESTAMP
);

-- Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    advisor_id INTEGER NOT NULL REFERENCES advisor_profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reports Table
CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    reporter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_advisor_id INTEGER NOT NULL REFERENCES advisor_profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    description TEXT,
    status report_status DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Chat Rooms Table
CREATE TABLE IF NOT EXISTS chat_rooms (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    advisor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Call Logs Table
CREATE TABLE IF NOT EXISTS call_logs (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    caller_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    call_type consultation_type NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    status call_status DEFAULT 'initiated',
    started_at TIMESTAMP,
    ended_at TIMESTAMP
);
