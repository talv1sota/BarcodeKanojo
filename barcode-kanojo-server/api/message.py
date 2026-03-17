from fastapi import APIRouter, Depends

from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response

router = APIRouter()


@router.get("/dialog.json")
async def dialog(
    a: int = 0,  # action
    pod: int = 0,  # part of day
    user: User = Depends(get_current_user),
):
    """Return kanojo dialog messages based on action and time of day."""
    # TODO: implement proper dialog system with database
    messages = {
        0: ["Hello!", "Nice to meet you!"],
        1: ["Good morning!", "Did you sleep well?"],
        2: ["Good afternoon!", "Having a nice day?"],
        3: ["Good evening!", "How was your day?"],
        4: ["Good night!", "Sweet dreams!"],
    }
    return api_response(
        code=200, message="OK",
        kanojo_message={"messages": messages.get(pod, ["Hello!"])},
    )
