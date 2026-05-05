from fastapi import APIRouter, UploadFile, File

router = APIRouter(prefix="/v1", tags=["identify"])


@router.post("/identify")
async def identify_image(image: UploadFile = File(...)):
    raise NotImplementedError
