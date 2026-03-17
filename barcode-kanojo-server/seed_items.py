"""Seed the items table with date and gift items."""

import asyncio
from sqlalchemy import select, text
from models.database import engine, async_session, init_db, Base
from models.item import Item


GIFT_ITEMS = [
    # Category 1: Flowers
    {"item_class": 1, "item_category_id": 1, "title": "Rose Bouquet",
     "description": "A beautiful bouquet of red roses.", "price": "10",
     "confirm_use_message": "Give this rose bouquet?"},
    {"item_class": 1, "item_category_id": 1, "title": "Sunflowers",
     "description": "Bright and cheerful sunflowers.", "price": "5",
     "confirm_use_message": "Give these sunflowers?"},
    {"item_class": 1, "item_category_id": 1, "title": "Tulip Bundle",
     "description": "A colorful bundle of tulips.", "price": "8",
     "confirm_use_message": "Give this tulip bundle?"},
    # Category 2: Sweets
    {"item_class": 1, "item_category_id": 2, "title": "Chocolate Box",
     "description": "A luxurious box of assorted chocolates.", "price": "15",
     "confirm_use_message": "Give this chocolate box?"},
    {"item_class": 1, "item_category_id": 2, "title": "Macaron Set",
     "description": "Delicate French macarons in pastel colors.", "price": "12",
     "confirm_use_message": "Give this macaron set?"},
    {"item_class": 1, "item_category_id": 2, "title": "Cake Slice",
     "description": "A slice of strawberry shortcake.", "price": "8",
     "confirm_use_message": "Give this cake?"},
    # Category 3: Accessories
    {"item_class": 1, "item_category_id": 3, "title": "Hair Ribbon",
     "description": "A cute ribbon for her hair.", "price": "20",
     "confirm_use_message": "Give this hair ribbon?"},
    {"item_class": 1, "item_category_id": 3, "title": "Bracelet",
     "description": "A sparkling charm bracelet.", "price": "25",
     "confirm_use_message": "Give this bracelet?"},
    {"item_class": 1, "item_category_id": 3, "title": "Plush Bear",
     "description": "An adorable stuffed teddy bear.", "price": "18",
     "confirm_use_message": "Give this plush bear?"},
]

DATE_ITEMS = [
    # Category 4: Casual
    {"item_class": 2, "item_category_id": 4, "title": "Walk in the Park",
     "description": "A relaxing stroll through the park.", "price": "Free",
     "confirm_use_message": "Go for a walk?"},
    {"item_class": 2, "item_category_id": 4, "title": "Coffee Date",
     "description": "Enjoy coffee and conversation at a cozy cafe.", "price": "5",
     "confirm_use_message": "Go for coffee?"},
    {"item_class": 2, "item_category_id": 4, "title": "Window Shopping",
     "description": "Browse the shops together downtown.", "price": "Free",
     "confirm_use_message": "Go window shopping?"},
    # Category 5: Entertainment
    {"item_class": 2, "item_category_id": 5, "title": "Movie Date",
     "description": "Watch the latest hit movie together.", "price": "15",
     "confirm_use_message": "Go to the movies?"},
    {"item_class": 2, "item_category_id": 5, "title": "Karaoke Night",
     "description": "Sing your hearts out at karaoke.", "price": "12",
     "confirm_use_message": "Go to karaoke?"},
    {"item_class": 2, "item_category_id": 5, "title": "Arcade Fun",
     "description": "Play games at the arcade together.", "price": "10",
     "confirm_use_message": "Go to the arcade?"},
    # Category 6: Dining
    {"item_class": 2, "item_category_id": 6, "title": "Ramen Shop",
     "description": "Enjoy a warm bowl of ramen.", "price": "10",
     "confirm_use_message": "Go eat ramen?"},
    {"item_class": 2, "item_category_id": 6, "title": "Fancy Dinner",
     "description": "A romantic evening at a fine restaurant.", "price": "30",
     "confirm_use_message": "Go to dinner?"},
    {"item_class": 2, "item_category_id": 6, "title": "Picnic Lunch",
     "description": "A homemade picnic in a scenic spot.", "price": "8",
     "confirm_use_message": "Go on a picnic?"},
]

CATEGORY_TITLES = {
    1: "Flowers",
    2: "Sweets",
    3: "Accessories",
    4: "Casual",
    5: "Entertainment",
    6: "Dining",
}


async def seed():
    await init_db()
    async with async_session() as db:
        # Check if items already exist
        result = await db.execute(select(Item).limit(1))
        if result.scalar_one_or_none():
            print("Items already seeded, skipping.")
            return

        all_items = GIFT_ITEMS + DATE_ITEMS
        for item_data in all_items:
            item = Item(**item_data)
            db.add(item)
            print(f"  Added: {item_data['title']} (class={item_data['item_class']})")

        await db.commit()
        print(f"\nSeeded {len(all_items)} items ({len(GIFT_ITEMS)} gifts, {len(DATE_ITEMS)} dates)")


if __name__ == "__main__":
    asyncio.run(seed())
