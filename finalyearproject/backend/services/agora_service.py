import time
from agora_token_builder import RtcTokenBuilder
from config.settings import settings

class AgoraService:
    @staticmethod
    def generate_rtc_token(channel_name: str, uid: int = 0, role: int = 1, expiration_time_in_seconds: int = 3600):
        """
        Generate an RTC token for joining a specific channel.
        :param channel_name: The name of the channel (e.g., booking_id).
        :param uid: User ID (0 means Agora will assign one).
        :param role: 1 for publisher (default), 2 for subscriber.
        :param expiration_time_in_seconds: Token validity duration.
        :return: Generated token string.
        """
        app_id = settings.AGORA_APP_ID
        app_certificate = settings.AGORA_APP_CERTIFICATE
        
        if not app_id or not app_certificate or "YOUR_AGORA" in app_certificate or app_certificate == "":
            return None

        current_timestamp = int(time.time())
        privilege_expired_ts = current_timestamp + expiration_time_in_seconds

        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, 
            app_certificate, 
            channel_name, 
            uid, 
            role, 
            privilege_expired_ts
        )
        return token

agora_service = AgoraService()
