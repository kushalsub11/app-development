import smtplib
from email.message import EmailMessage
from config.settings import settings
import random
import string

def generate_otp(length=6) -> str:
    """Generate a random numeric OTP."""
    return ''.join(random.choices(string.digits, k=length))

def send_email_sync(to_email: str, subject: str, html_content: str):
    """Sync function to send an email using SMTP."""
    
    # If SMTP is not properly configured, just print to console (useful in development)
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        print(f"--- MOCK EMAIL ---")
        print(f"To: {to_email}")
        print(f"Subject: {subject}")
        print(f"Content: {html_content}")
        print(f"------------------")
        return

    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = settings.SMTP_FROM_EMAIL
    msg['To'] = to_email
    msg.set_content(html_content, subtype='html')

    try:
        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.send_message(msg)
    except Exception as e:
        print(f"Error sending email: {e}")

def send_otp_email(to_email: str, otp: str):
    """Send an OTP email."""
    subject = "Sajelo Guru - Verify your Email"
    content = f"""
    <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f4;">
        <div style="background-color: #ffffff; padding: 30px; border-radius: 10px; max-width: 500px; margin: 0 auto;">
            <h2 style="color: #7B4FD4; text-align: center;">Namaste! 🙏</h2>
            <p style="color: #333; font-size: 16px;">Here is your One-Time Password (OTP) for Sajelo Guru. Please do not share this with anyone.</p>
            <div style="background-color: #FFF9E6; border: 2px dashed #FFD700; padding: 15px; text-align: center; border-radius: 8px; margin: 25px 0;">
                <h1 style="color: #7B4FD4; margin: 0; letter-spacing: 5px;">{otp}</h1>
            </div>
            <p style="color: #777; font-size: 14px; text-align: center;">This code will expire in 10 minutes.</p>
        </div>
    </div>
    """
    send_email_sync(to_email, subject, content)
