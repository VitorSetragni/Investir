from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', extra='ignore')
    database_url: str = 'sqlite:///./local.db'
    supabase_url: str = ''
    supabase_anon_key: str = ''
    uploader_emails: str = ''
    allowed_origins: str = ''
    market_cache_seconds: int = 900
    max_upload_bytes: int = 12 * 1024 * 1024
    demo_mode: bool = False
    app_env: str = 'development'

    @property
    def uploaders(self):
        return {x.strip().lower() for x in self.uploader_emails.split(',') if x.strip()}


@lru_cache
def settings():
    return Settings()
