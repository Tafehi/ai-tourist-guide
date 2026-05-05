import ssl

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.config import settings


def _build_connect_args() -> dict:
    if not settings.database_ssl:
        return {}
    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = True
    ssl_ctx.verify_mode = ssl.CERT_REQUIRED
    return {"ssl": ssl_ctx}


engine = create_async_engine(
    settings.database_url,
    pool_size=settings.database_pool_size,
    max_overflow=settings.database_max_overflow,
    pool_recycle=settings.database_pool_recycle,
    pool_pre_ping=True,
    connect_args=_build_connect_args(),
)

async_session = async_sessionmaker(engine, expire_on_commit=False)
