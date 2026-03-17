from fastapi import APIRouter, Depends, Form

from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response, error_response

router = APIRouter()


@router.post("/compare_price.json")
async def compare_price(
    price: int = Form(...),
    store_item_id: int = Form(...),
    user: User = Depends(get_current_user),
):
    return api_response(code=200, message="OK")


@router.post("/verify_tickets.json")
async def verify_tickets(
    store_item_id: int = Form(...),
    use_tickets: int = Form(...),
    user: User = Depends(get_current_user),
):
    if user.tickets < use_tickets:
        return error_response(400, "Not enough tickets")
    return api_response(code=200, message="OK")
