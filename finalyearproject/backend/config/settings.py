from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    # Database
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "kushal"
    DB_NAME: str = "sajelo_guru"

    # JWT
    JWT_SECRET_KEY: str = "sajelo-guru-super-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # Server
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000

    # SMTP Server
    SMTP_SERVER: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = ""
    
    # Agora
    AGORA_APP_ID: str = ""
    AGORA_APP_CERTIFICATE: str = ""

    # Khalti
    KHALTI_SECRET_KEY: str = "Key live_secret_key_68791341fdd94846a146f0457ff7b455"  # Sandbox Key
    KHALTI_INITIATE_URL: str = "https://dev.khalti.com/api/v2/epayment/initiate/"
    KHALTI_LOOKUP_URL: str = "https://dev.khalti.com/api/v2/epayment/lookup/"


    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+psycopg2://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    class Config:
        env_file = ".env"


settings = Settings()
