from fastapi import FastAPI

from app.routers import auth, chat, cities, identify

app = FastAPI(title="LocalLore API", version="0.1.0")

app.include_router(identify.router)
app.include_router(chat.router)
app.include_router(cities.router)
app.include_router(auth.router)


@app.get("/health")
async def health():
    return {"ok": True}
