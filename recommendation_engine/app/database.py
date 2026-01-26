from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import get_settings

settings = get_settings()

# Convert postgresql:// to postgresql+asyncpg:// for async
async_database_url = settings.database_url.replace(
    "postgresql://", "postgresql+asyncpg://"
)

# Async engine for FastAPI
async_engine = create_async_engine(async_database_url, echo=settings.debug)

AsyncSessionLocal = sessionmaker(
    async_engine, class_=AsyncSession, expire_on_commit=False
)

Base = declarative_base()


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
