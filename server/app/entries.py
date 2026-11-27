# Entries: the WatchList entity — a title in the user's library, scoped per
# user. A copy of notes.py with other nouns: list with pagination/search,
# create with validation (400), get/put/delete with 404.

from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, Request, Response

from .auth import require_auth
from .db import conn, now_iso
from .errors import json_response, not_found, read_json_body, string_field, validation_error

router = APIRouter()

TYPES = ("movie", "series", "anime")
STATUSES = ("planned", "watching", "completed", "onHold", "dropped")


def _to_json(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "type": row["type"],
        "year": row["year"],
        "genres": row["genres"],
        "description": row["description"],
        "episodes": row["episodes"],
        "status": row["status"],
        "myRating": row["my_rating"],
        "watchedEpisodes": row["watched_episodes"],
        "note": row["note"],
        "isFavorite": bool(row["is_favorite"]),
        "createdAt": row["created_at"],
    }


def _find(user_id: int, id_param: str):
    """Finds an entry by id, but only among the current user's entries.

    Someone else's entry is indistinguishable from a missing one (404).
    """
    try:
        entry_id = int(id_param)
    except (TypeError, ValueError):
        return None
    return conn.execute(
        "SELECT * FROM entries WHERE id = ? AND user_id = ?", (entry_id, user_id)
    ).fetchone()


def _int_or(value: Optional[str], default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _int_field(body: Dict[str, Any], key: str, default: Optional[int]) -> Optional[int]:
    """body[key] as an int (bool is not an int here); default when missing."""
    value = body.get(key)
    if value is None:
        return default
    if isinstance(value, bool) or not isinstance(value, int):
        raise validation_error(key + " must be an integer")
    return value


def _text(body: Dict[str, Any], key: str) -> str:
    return body[key] if isinstance(body.get(key), str) else ""


def _parse(body: Optional[Dict[str, Any]]) -> tuple:
    """Validates a create/update body; returns the column values in order."""
    if body is None:
        raise validation_error("Body must be a JSON object")
    name = string_field(body, "name")
    if name is None:
        raise validation_error("name is required")
    if body.get("type") not in TYPES:
        raise validation_error("type must be one of: " + ", ".join(TYPES))
    if body.get("status") not in STATUSES:
        raise validation_error("status must be one of: " + ", ".join(STATUSES))
    year = _int_field(body, "year", None)
    if year is None:
        raise validation_error("year is required")
    episodes = _int_field(body, "episodes", 1)
    if episodes < 1:
        raise validation_error("episodes must be at least 1")
    rating = _int_field(body, "myRating", None)
    if rating is not None and not 1 <= rating <= 10:
        raise validation_error("myRating must be between 1 and 10")
    watched = _int_field(body, "watchedEpisodes", 0)
    if not 0 <= watched <= episodes:
        raise validation_error("watchedEpisodes must be between 0 and episodes")
    favorite = body.get("isFavorite", False)
    if not isinstance(favorite, bool):
        raise validation_error("isFavorite must be a boolean")

    return (
        name, body["type"], year, _text(body, "genres"),
        _text(body, "description"), episodes, body["status"], rating,
        watched, _text(body, "note"), int(favorite),
    )


_COLUMNS = (
    "name, type, year, genres, description, episodes, status, my_rating, "
    "watched_episodes, note, is_favorite"
)


@router.get("/entries")
async def list_entries(request: Request, user_id: int = Depends(require_auth)):
    """GET /entries?page=1&limit=20&search=  -> {items, page, limit, total}"""
    query = request.query_params
    page = max(_int_or(query.get("page"), 1), 1)
    limit = min(max(_int_or(query.get("limit"), 20), 1), 100)
    search = query.get("search", "")

    # SQLite's LIKE ignores case only for ASCII, so Cyrillic is compared
    # through lower() on both sides (Python's str.lower knows Unicode)
    where = "user_id = ? AND (pylower(name) LIKE ? OR pylower(genres) LIKE ?)"
    pattern = "%" + search.lower() + "%"
    args = (user_id, pattern, pattern)

    total = conn.execute(
        "SELECT COUNT(*) AS n FROM entries WHERE " + where, args
    ).fetchone()["n"]
    rows = conn.execute(
        "SELECT * FROM entries WHERE " + where + " ORDER BY id DESC LIMIT ? OFFSET ?",
        args + (limit, (page - 1) * limit),
    ).fetchall()

    return json_response(
        {
            "items": [_to_json(row) for row in rows],
            "page": page,
            "limit": limit,
            "total": total,
        }
    )


@router.post("/entries")
async def create_entry(request: Request, user_id: int = Depends(require_auth)):
    """POST /entries  {name, type, year, status, ...} -> 201 entry"""
    values = _parse(await read_json_body(request))
    cursor = conn.execute(
        "INSERT INTO entries (user_id, " + _COLUMNS + ", created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (user_id,) + values + (now_iso(),),
    )
    row = _find(user_id, str(cursor.lastrowid))
    return json_response(_to_json(row), status=201)


@router.get("/entries/{entry_id}")
async def get_entry(entry_id: str, user_id: int = Depends(require_auth)):
    """GET /entries/{id} -> 200 entry | 404"""
    row = _find(user_id, entry_id)
    if row is None:
        raise not_found("Entry not found")
    return json_response(_to_json(row))


@router.put("/entries/{entry_id}")
async def update_entry(
    entry_id: str, request: Request, user_id: int = Depends(require_auth)
):
    """PUT /entries/{id}  {name, type, year, status, ...} -> 200 | 404"""
    row = _find(user_id, entry_id)
    if row is None:
        raise not_found("Entry not found")

    values = _parse(await read_json_body(request))
    conn.execute(
        "UPDATE entries SET name = ?, type = ?, year = ?, genres = ?, "
        "description = ?, episodes = ?, status = ?, my_rating = ?, "
        "watched_episodes = ?, note = ?, is_favorite = ? WHERE id = ?",
        values + (row["id"],),
    )
    updated = _find(user_id, str(row["id"]))
    return json_response(_to_json(updated))


@router.delete("/entries/{entry_id}")
async def delete_entry(entry_id: str, user_id: int = Depends(require_auth)):
    """DELETE /entries/{id} -> 204 | 404"""
    row = _find(user_id, entry_id)
    if row is None:
        raise not_found("Entry not found")
    conn.execute("DELETE FROM entries WHERE id = ?", (row["id"],))
    return Response(status_code=204)  # 204 = success with no body
