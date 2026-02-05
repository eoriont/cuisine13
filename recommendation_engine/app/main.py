from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routers import ingredients, facts, recommend, steal, generate

settings = get_settings()

app = FastAPI(
    title="Cuisine13 Recommendation Engine",
    description="AI-powered recipe recommendations, steal mode, and ingredient processing",
    version="1.0.0",
)

# CORS - only allow Phoenix app (internal Docker network)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4000", "http://web:4000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(ingredients.router, prefix="/api/ingredients", tags=["Ingredients"])
app.include_router(facts.router, prefix="/api/facts", tags=["Recipe Facts"])
app.include_router(recommend.router, prefix="/api/recommend", tags=["Recommendations"])
app.include_router(steal.router, prefix="/api/steal", tags=["Steal Mode"])
app.include_router(generate.router, prefix="/api/generate", tags=["AI Generation"])


@app.get("/")
async def root():
    return {"status": "ok", "service": "recommendation-engine"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
