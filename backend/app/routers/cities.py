from fastapi import APIRouter

router = APIRouter(prefix="/v1", tags=["cities"])


@router.get("/cities")
async def list_cities():
    raise NotImplementedError


@router.get("/cities/{city}/pack")
async def get_pack_url(city: str):
    raise NotImplementedError
