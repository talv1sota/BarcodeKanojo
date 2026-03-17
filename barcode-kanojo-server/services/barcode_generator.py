"""Deterministic kanojo attribute generation from barcode strings.

The original server algorithm is unknown. This implementation uses a hash-based
approach that deterministically maps a barcode string to kanojo appearance
attributes within their valid ranges.
"""
import hashlib
import struct


# Valid ranges for each attribute (inclusive).
# Ranges are calibrated to match the actual avatar_data asset folders
# to avoid falling back to _001 for missing variants.
PART_RANGES = {
    "eye_type": (1, 15),
    "nose_type": (1, 6),
    "mouth_type": (1, 12),
    "face_type": (1, 6),
    "brow_type": (1, 12),
    "fringe_type": (1, 22),
    "hair_type": (1, 26),
    "accessory_type": (0, 5),
    "spot_type": (0, 7),
    "glasses_type": (0, 2),
    "body_type": (1, 1),  # body_002 includes a held flask prop — avoid for random generation
    "ear_type": (0, 2),
    "skin_color": (1, 12),
    "hair_color": (1, 24),
    "eye_color": (1, 12),
}

# Clothes have non-contiguous valid folders, so use explicit list
# Available: 001-005, 011, 022 (regular outfits)
VALID_CLOTHES = [1, 2, 3, 4, 5, 11, 22]

STAT_RANGE = (10, 100)
POSITION_RANGE = (-1.0, 1.0)


def _hash_barcode(barcode: str, domain: str) -> int:
    """Hash barcode with a domain-specific salt to get a deterministic integer."""
    data = f"{barcode}:{domain}".encode("utf-8")
    digest = hashlib.sha256(data).digest()
    return struct.unpack(">Q", digest[:8])[0]


def _map_to_range(value: int, min_val: int, max_val: int) -> int:
    return min_val + (value % (max_val - min_val + 1))


def _map_to_float_range(value: int, min_val: float, max_val: float, steps: int = 100) -> float:
    step = (value % steps) / (steps - 1)
    return round(min_val + step * (max_val - min_val), 2)


def generate_kanojo_attributes(barcode: str) -> dict:
    """Generate deterministic kanojo attributes from a barcode string."""
    attrs = {}

    # Generate part types and colors
    for attr_name, (min_val, max_val) in PART_RANGES.items():
        h = _hash_barcode(barcode, attr_name)
        attrs[attr_name] = _map_to_range(h, min_val, max_val)

    # Clothes: pick from explicit list of available outfits
    h = _hash_barcode(barcode, "clothes_type")
    attrs["clothes_type"] = VALID_CLOTHES[h % len(VALID_CLOTHES)]

    # Generate stats
    for stat in ["flirtable", "consumption", "possession", "recognition", "sexual"]:
        h = _hash_barcode(barcode, stat)
        attrs[stat] = _map_to_range(h, STAT_RANGE[0], STAT_RANGE[1])

    # Generate positions
    for pos in ["eye_position", "brow_position", "mouth_position"]:
        h = _hash_barcode(barcode, pos)
        attrs[pos] = _map_to_float_range(h, POSITION_RANGE[0], POSITION_RANGE[1])

    # Race type (always 1 for now)
    attrs["race_type"] = 1

    # Generate birthday
    h_month = _hash_barcode(barcode, "birth_month")
    h_day = _hash_barcode(barcode, "birth_day")
    attrs["birth_month"] = _map_to_range(h_month, 1, 12)
    attrs["birth_day"] = _map_to_range(h_day, 1, 28)
    attrs["birth_year"] = 2000 + _map_to_range(_hash_barcode(barcode, "birth_year"), 0, 10)

    return attrs
