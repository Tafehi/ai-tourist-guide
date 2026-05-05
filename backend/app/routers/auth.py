from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/v1", tags=["auth"])


class AppleAuthRequest(BaseModel):
    identity_token: str


@router.post("/auth/apple")
async def sign_in_with_apple(request: AppleAuthRequest):
    raise NotImplementedError
