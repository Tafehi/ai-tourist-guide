from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/v1", tags=["chat"])


class ChatRequest(BaseModel):
    poi_id: str
    history: list[dict]
    message: str


@router.post("/chat")
async def chat(request: ChatRequest):
    raise NotImplementedError
