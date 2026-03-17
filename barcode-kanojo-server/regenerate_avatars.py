#!/usr/bin/env python3
"""Regenerate avatar images for all kanojos in the database.

Usage:
    .venv/bin/python regenerate_avatars.py [--fix-clothes]

Options:
    --fix-clothes   Also update clothes_type in DB to a valid asset folder
                    for kanojos whose current clothes_type has no folder.
"""
import sqlite3
import sys
from pathlib import Path

# Add project root to path so we can import services
sys.path.insert(0, str(Path(__file__).parent))

from config import settings
from services.avatar_composer import generate_and_save
from services.barcode_generator import VALID_CLOTHES

DB_PATH = Path(__file__).parent / "barcode_kanojo.db"

# All clothes folders that actually exist as regular outfits
VALID_CLOTHES_SET = set(VALID_CLOTHES)


def main():
    fix_clothes = "--fix-clothes" in sys.argv

    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    rows = cur.execute("""
        SELECT id, name, body_type, face_type, eye_type, eye_color,
               brow_type, brow_position, mouth_type, mouth_position,
               nose_type, ear_type, fringe_type, hair_type, hair_color,
               skin_color, clothes_type, glasses_type, accessory_type,
               spot_type, eye_position, barcode
        FROM kanojos
        ORDER BY id
    """).fetchall()

    print(f"Found {len(rows)} kanojos to regenerate")

    for row in rows:
        kanojo_id = row["id"]
        name = row["name"]
        clothes_type = row["clothes_type"]

        # Fix clothes_type if it doesn't have an actual asset folder
        if fix_clothes and clothes_type not in VALID_CLOTHES_SET:
            # Pick a new clothes type based on barcode hash for consistency
            barcode = row["barcode"] or str(kanojo_id)
            import hashlib, struct
            h = struct.unpack(">Q", hashlib.sha256(
                f"{barcode}:clothes_type".encode()).digest()[:8])[0]
            new_clothes = VALID_CLOTHES[h % len(VALID_CLOTHES)]
            print(f"  Kanojo {kanojo_id} ({name}): clothes_type {clothes_type} → {new_clothes}")
            cur.execute("UPDATE kanojos SET clothes_type = ? WHERE id = ?",
                        (new_clothes, kanojo_id))
            clothes_type = new_clothes

        attrs = {
            "body_type": row["body_type"],
            "face_type": row["face_type"],
            "eye_type": row["eye_type"],
            "eye_color": row["eye_color"],
            "brow_type": row["brow_type"],
            "brow_position": row["brow_position"],
            "mouth_type": row["mouth_type"],
            "mouth_position": row["mouth_position"],
            "nose_type": row["nose_type"],
            "ear_type": row["ear_type"],
            "fringe_type": row["fringe_type"],
            "hair_type": row["hair_type"],
            "hair_color": row["hair_color"],
            "skin_color": row["skin_color"],
            "clothes_type": clothes_type,
            "glasses_type": row["glasses_type"],
            "accessory_type": row["accessory_type"],
            "spot_type": row["spot_type"],
            "eye_position": row["eye_position"],
        }

        output_dir = settings.UPLOAD_DIR / "profile_images" / "kanojo" / str(kanojo_id)
        print(f"  Generating kanojo {kanojo_id} ({name})... ", end="", flush=True)
        try:
            generate_and_save(kanojo_id, attrs, output_dir)
            print("OK")
        except Exception as e:
            print(f"FAILED: {e}")

    if fix_clothes:
        conn.commit()
        print("\nDatabase updated with fixed clothes_type values.")

    conn.close()
    print(f"\nDone! Regenerated {len(rows)} kanojos.")


if __name__ == "__main__":
    main()
