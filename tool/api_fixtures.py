"""Write backend-shaped API fixtures for the app's contract tests.

Every response fixture is built by validating sample data through the backend's own Pydantic
response model and dumping it the way FastAPI does (`mode="json"`, `by_alias=True`). The output
carries every field, default and alias the backend really sends. Every DTO the app parses has a
fixture here. Request fixtures are the flattened JSON schemas of the bodies the app sends.
Operation fixtures (the query keys each route declares) come from the backend `docs/openapi.json`.
Push data and deep links are built by the backend's own functions.

Run from the app root with the backend environment:

    uv run --project ../../360ghar/360ghar-backend python tool/api_fixtures.py

(or give the absolute path of the backend). It imports schemas only: no app start-up, no
database, no network. The files go to `test/fixtures/api/*.json`. `test/contract/*_test.dart`
parses them with the app's models. `tool/gen_enums.py` writes the wire enums the app reads.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

APP = Path(__file__).resolve().parents[1]
# scripts/contract_sync.sh passes the selected checkout in BACKEND_DIR.
BACKEND = Path(
    os.environ.get("BACKEND_DIR") or APP.parents[1] / "360ghar" / "360ghar-backend"
).resolve()
OUT = APP / "test" / "fixtures" / "api"
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import gen_enums  # noqa: E402  (the list of wire enums the app uses)
from app.api.api_v1.endpoints.auth import (  # noqa: E402
    IdentifierStatusRequest,
    IdentifierStatusResponse,
    LastMethodRequest,
)
from app.api.api_v1.endpoints.notifications import (  # noqa: E402
    DeviceRegisterIn,
    DeviceRegistration,
    DeviceUnregisterIn,
)
from app.infrastructure.errors import (  # noqa: E402
    ErrorEnvelope,
    ValidationErrorEnvelope,
    error_body,
    validation_details,
)
from app.models.enums import AppKey  # noqa: E402
from app.schemas.common import (  # noqa: E402
    NotificationSettings,
    NotificationSettingsWrite,
    PrivacySettings,
    PrivacySettingsPatch,
)
from app.schemas.core import (  # noqa: E402
    AppVersionCheckRequest,
    AppVersionCheckResponse,
    BugReportCreate,
)
from app.schemas.flatmates import (  # noqa: E402
    BlockCreate,
    BlockedUserOut,
    BlockOut,
    CompatibilityBreakdown,
    ConversationCreate,
    ConversationQnAState,
    ConversationSummary,
    FlatmatesBootstrap,
    FlatmatesNotificationBulkUpdate,
    FlatmatesNotificationOut,
    FlatmatesNotificationUpdate,
    FlatmatesPeer,
    FlatmatesProfile,
    FlatmatesProfileUpdate,
    FlatmateVisitUpdate,
    IncomingLikeSummary,
    MatchContactOut,
    MatchStatusOut,
    MatchSummary,
    MessageCreate,
    MessageOut,
    NotificationsMarkedRead,
    NotificationUnreadCount,
    OutgoingLikeSummary,
    ProfileViewEventCreate,
    ProfileViewEventOut,
    QnAAnswers,
    ReportCreate,
    ReportOut,
    SocietyTagVoteCreate,
    SocietyTagVoteOut,
    SwipeRequest,
    SwipeResult,
    UnmatchPairRequest,
)
from app.schemas.pagination import CursorPage  # noqa: E402
from app.schemas.property import (  # noqa: E402
    Property,
    PropertyCreate,
    PropertyDetail,
    PropertyUpdate,
)
from app.schemas.storage import UploadResult  # noqa: E402
from app.schemas.user import AuthGateState, SelfUser, UserUpdate  # noqa: E402
from app.schemas.visit import (  # noqa: E402
    Visit,
    VisitCancel,
    VisitCreate,
    VisitReschedule,
    VisitUpdate,
)
from app.services.deeplinks.registry import get_app  # noqa: E402
from app.services.flatmates.realtime import flatmates_realtime_config  # noqa: E402
from app.services.notifications.fcm import build_message  # noqa: E402
from app.services.notifications.helpers import _augment_data_with_meta  # noqa: E402
from app.services.notification_config import NotificationChannel  # noqa: E402

NOW = "2026-09-30T10:15:02Z"
COMPANY_NUMBER = "+911800000360"
ME = 7  # the signed-in user of every fixture


def dump(model_cls, data):
    return model_cls.model_validate(data).model_dump(mode="json", by_alias=True)


def page(model_cls, items, *, next_cursor=None, limit=20, total=None):
    return dump(
        CursorPage[model_cls],
        {
            "items": items,
            "next_cursor": next_cursor,
            "has_more": next_cursor is not None,
            "limit": limit,
            "total": total,
        },
    )


# --------------------------------------------------------------------------- samples


def public_user(uid: int, name: str, avatar: str | None = None):
    return {"id": uid, "display_name": name, "avatar_url": avatar}


def listing_summary(pid: int = 42, **extra):
    base = {
        "property_id": pid,
        "title": "Sunny room in Koramangala",
        "main_image_url": f"https://cdn.example.com/p{pid}/main.jpg",
        "image_urls": [
            f"https://cdn.example.com/p{pid}/main.jpg",
            f"https://cdn.example.com/p{pid}/bed.jpg",
        ],
        "monthly_rent": 24_000,
        "security_deposit": 48_000,
        "maintenance_charges": 1_500.5,
        "available_from": "2026-11-01",
        "room_type": "private_room",
        "bedrooms": 2,
        "bathrooms": None,
        "balconies": 1,
        "area_sqft": 1200,
        "floor_number": 3,
        "total_floors": 8,
        "city": "Bengaluru",
        "locality": "Koramangala",
        "sub_locality": "5th Block",
        "landmark": "Forum Mall",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "features": ["furnished", "wifi"],
        "amenities": ["Gym", "Lift"],
        "video_tour_url": None,
        "virtual_tour_url": None,
    }
    base.update(extra)
    return base


def peer(uid: int, name: str, **extra):
    base = {
        "id": uid,
        "full_name": name,
        "profile_image_url": f"https://cdn.example.com/u/{uid}.jpg",
        "mode": "co_hunter",
        "city": "Bengaluru",
        "locality": "HSR Layout",
        "age_bucket": "25-30",
        "profession": "Designer",
        "bio": "Early riser, tidy, cooks on weekends.",
        "budget_min": 12_000,
        "budget_max": 25_000.5,
        "move_in_timeline": "within_1_month",
        "sleep_schedule": "early_bird",
        "cleanliness": "tidy",
        "food_habits": "vegetarian",
        "smoking": "never",
        "drinking": "occasionally",
        "native_place": "Pune",
        "linkedin_url": None,
        "guests_policy": "occasional_ok",
        "work_style": "hybrid",
        "gender": "female",
        "gender_preference": "any",
        "non_negotiables": ["no_smoking", "no_parties"],
        "has_pets": False,
        "party_habit": "occasional_weekends",
        "match_percentage": 85.0,
        "top_matches": ["Same sleep schedule", "Both vegetarian"],
        "listing": None,
    }
    base.update(extra)
    return base


def context_property(pid: int = 42):
    return {
        "id": pid,
        "title": "Sunny room in Koramangala",
        "locality": "Koramangala",
        "city": "Bengaluru",
        "monthly_rent": 24_000,
        "main_image_url": f"https://cdn.example.com/p{pid}/main.jpg",
        "owner_name": "Rahul S",
        "owner_image_url": None,
    }


def profile(**extra):
    base = {
        "id": ME,
        "full_name": "Asha Verma",
        "email": "asha@example.com",
        "phone": "+919800000000",
        "profile_image_url": "https://cdn.example.com/u/7.jpg",
        "mode": "room_poster",
        "profile_status": "active",
        "onboarding_completed": True,
        "bio": "Product designer.",
        "age": 29,
        "profession": "Designer",
        "budget_min": 15_000,
        "budget_max": 30_000,
        "move_in_timeline": "immediate",
        "city": "Bengaluru",
        "locality": "Indiranagar",
        "sleep_schedule": "flexible",
        "cleanliness": "spotless",
        "food_habits": "no_preference",
        "smoking": "never",
        "drinking": "never",
        "native_place": "Delhi",
        "linkedin_url": None,
        "age_bucket": "25-30",
        "guests_policy": "occasional_ok",
        "work_style": "wfh",
        "gender": "female",
        "gender_preference": "female",
        "preferences": {"non_negotiables": ["no_smoking"], "pets": "no"},
        "last_active_at": NOW,
    }
    base.update(extra)
    return base


def image(pid: int, slot: int, category: str, *, main: bool = False):
    return {
        "id": pid * 10 + slot,
        "property_id": pid,
        "image_url": f"https://cdn.example.com/p{pid}/{category}-{slot}.jpg",
        "image_category": category,
        "display_order": slot,
        "is_main_image": main,
    }


def prop(pid: int, **extra):
    """A flatmate listing as the list routes send it: the owner number is already masked."""
    base = {
        "id": pid,
        "owner_id": 9,
        "title": "Sunny room in Koramangala",
        "description": "Corner room, attached balcony.",
        "property_type": "flatmate",
        "purpose": "rent",
        "base_price": 24_000,
        "monthly_rent": 24_000,
        "security_deposit": 48_000,
        "maintenance_charges": 1_500,
        "area_sqft": 1200,
        "status": "available",
        "is_available": True,
        "available_from": "2026-11-01",
        "view_count": 120,
        "like_count": 14,
        "interest_count": 3,
        "created_at": NOW,
        "updated_at": NOW,
        "city": "Bengaluru",
        "locality": "Koramangala",
        "sub_locality": "5th Block",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "bedrooms": 2,
        "bathrooms": None,
        "main_image_url": f"https://cdn.example.com/p{pid}/main.jpg",
        "owner_name": "Rahul S",
        # Masked for a viewer who is not the owner: the agent number, else the company number.
        "owner_contact": COMPANY_NUMBER,
        "features": ["furnished", "wifi"],
        "furnishing_level": "furnished",
        "kitchen_type": "vegetarian",
        "ventilation_type": "good",
        "windows_count": 3,
        "images": [
            image(pid, 1, "room", main=True),
            image(pid, 2, "kitchen"),
            image(pid, 3, "floor_plan"),
        ],
        "amenities": [
            {"id": 11, "title": "Gym", "icon": "dumbbell", "category": "recreation"},
            {"id": 12, "title": "Lift", "icon": "lift", "category": "utilities"},
        ],
        "listing_preferences": {
            "gender_preference": "any",
            "sharing_type": "private_room",
            "moderation_status": "live",
            "pets": "no",
            "parties_at_home": "occasional_weekends",
            "society_type": "gated",
            "society_amenities": ["Gym"],
            "society_vibe_tags": ["quiet", "family"],
            "rooms": [{"furnishing_level": "furnished"}],
        },
    }
    base.update(extra)
    return base


def visit(vid: int, **extra):
    base = {
        "id": vid,
        "property_id": 42,
        "user_id": ME,
        "counterparty_user_id": 2,
        "conversation_id": 10,
        "match_id": 4,
        "visit_context": "flatmate_meet",
        "scheduled_date": "2026-10-04T05:30:00Z",
        "time_slot_label": "Morning (9 to 12)",
        "status": "requested",
        "created_at": NOW,
        "updated_at": NOW,
        "property": prop(42),
        "user": public_user(ME, "Asha Verma", "https://cdn.example.com/u/7.jpg"),
        "counterparty_user": public_user(2, "Priya P", "https://cdn.example.com/u/2.jpg"),
    }
    base.update(extra)
    return base


def message(mid: int, **extra):
    base = {
        "id": mid,
        "conversation_id": 10,
        "sender_id": 2,
        "body": "Hey! Is the room still available?",
        "attachment_url": None,
        "message_type": "text",
        "message_metadata": None,
        "read_at": None,
        "created_at": NOW,
    }
    base.update(extra)
    return base


def conversation(cid: int, **extra):
    base = {
        "id": cid,
        "source": "profile_match",
        "status": "active",
        "peer": peer(2, "Priya P"),
        "context_property": context_property(),
        "last_message_preview": "Hey! Is the room still available?",
        "last_message_at": NOW,
        "unread_count": 2,
        "matched_at": NOW,
        "qna": {
            "current_user": {"user_id": ME, "q1": "A calm place", "q2": "Balanced", "q3": None},
            "peer": {"user_id": 2, "q1": "Tidy", "q2": "Social", "q3": "Clean"},
            "both_answered": False,
        },
    }
    base.update(extra)
    return base


# --------------------------------------------------------------------------- requests


def flatten_request(model_cls) -> dict[str, Any]:
    """The request body contract the app must satisfy: required keys, strictness, key limits."""
    schema = model_cls.model_json_schema(mode="validation")
    defs = schema.get("$defs", {})

    def resolve(node: dict[str, Any]) -> tuple[dict[str, Any], bool]:
        nullable = False
        while True:
            if "$ref" in node:
                node = defs[node["$ref"].split("/")[-1]]
            elif "anyOf" in node:
                members = [m for m in node["anyOf"] if m.get("type") != "null"]
                nullable = nullable or len(members) != len(node["anyOf"])
                node = members[0]
            else:
                return node, nullable

    properties: dict[str, Any] = {}
    for name, raw in schema.get("properties", {}).items():
        node, nullable = resolve(raw)
        info = {
            key: node[key]
            for key in (
                "enum",
                "maxLength",
                "minLength",
                "maximum",
                "minimum",
                "exclusiveMinimum",
                "type",
            )
            if key in node
        }
        info["nullable"] = nullable
        if "properties" in node:
            info["properties"] = sorted(node["properties"])
        properties[name] = info
    return {
        "required": sorted(schema.get("required", [])),
        "extra_forbidden": schema.get("additionalProperties") is False,
        "properties": properties,
    }


def operations() -> dict[str, Any]:
    """Every operation in the OpenAPI document: query keys, body schema and response codes."""
    spec = json.loads((BACKEND / "docs" / "openapi.json").read_text())
    out: dict[str, Any] = {}
    for path, item in spec["paths"].items():
        for method, op in item.items():
            if method not in ("get", "post", "put", "patch", "delete"):
                continue
            query = {}
            for param in op.get("parameters", []):
                if param["in"] == "query":
                    schema = param.get("schema", {})
                    members = [m for m in schema.get("anyOf", [schema]) if m.get("type") != "null"]
                    base = members[0] if members else {}
                    query[param["name"]] = {
                        key: base[key] for key in ("maximum", "minimum") if key in base
                    }
            body = (
                op.get("requestBody", {})
                .get("content", {})
                .get("application/json", {})
                .get("schema")
            )
            out[f"{method.upper()} {path}"] = {
                "query": query,
                "body": body.get("$ref", "").split("/")[-1] if body else None,
                "responses": sorted(code for code in op["responses"] if code.isdigit()),
            }
    return dict(sorted(out.items()))


def push_data(*, route: str | None, type_key: str, data: dict[str, Any] | None = None):
    """The FCM message of one flatmates push, built by the backend's own functions."""
    payload = _augment_data_with_meta(
        data, type_key=type_key, channel=NotificationChannel.PUSH, priority="high"
    )
    message_ = build_message(
        token="fcm-token",
        title="Title",
        body="Body",
        data=payload,
        route=route,
        type_key=type_key,
        app_key=AppKey.flatmates,
    )["message"]
    return {
        "data": message_["data"],
        "android_channel_id": message_["android"]["notification"]["channel_id"],
    }


def deeplinks() -> dict[str, Any]:
    app = get_app("flatmates")
    assert app is not None
    return {
        "custom_scheme": app.custom_scheme,
        "chat": {
            "https_path": app.https_path("chat", "42"),
            "scheme_url": app.scheme_url("chat", "42"),
        },
        "listing": {
            "https_path": app.https_path("listing", "17"),
            "scheme_url": app.scheme_url("listing", "17"),
        },
    }


def enums() -> dict[str, list[str]]:
    """The wire enums the app uses, with the values the backend serves."""
    known = gen_enums.load(BACKEND / "docs" / "openapi.json")
    return {name: known[name] for name in gen_enums.ENUMS}


# --------------------------------------------------------------------------- fixtures


def fixtures() -> dict[str, Any]:
    listing_peer = peer(
        3,
        "Rahul S",
        mode="room_poster",
        listing=listing_summary(42),
        top_matches=[],
        match_percentage=None,
    )
    catalogs = [
        {
            "key": "flatmates_modes",
            "version": 3,
            "payload": {
                "items": [
                    {"id": "room_poster", "label": "List my room", "description": "I have a room"},
                    {"id": "co_hunter", "label": "Find a flat", "description": "I need a place"},
                    {"id": "seeker", "label": "Find a flatmate", "description": "I have a flat"},
                    {"id": "open_to_both", "label": "Open to both", "description": ""},
                ]
            },
        },
        {
            "key": "flatmates_report_reasons",
            "version": 1,
            "payload": {
                "items": [
                    {"id": "spam", "label": "Spam"},
                    {"id": "fake_profile", "label": "Fake Profile"},
                    {"id": "abuse", "label": "Abuse"},
                    {"id": "inappropriate", "label": "Inappropriate Content"},
                    {"id": "other", "label": "Other"},
                ]
            },
        },
    ]
    return {
        "bootstrap": {
            "bootstrap": dump(
                FlatmatesBootstrap,
                {
                    "profile": profile(),
                    "catalogs": catalogs,
                    "active_listing_count": 2,
                    "conversation_count": 5,
                    "unread_message_count": 3,
                    "realtime": flatmates_realtime_config(ME),
                },
            ),
            "bootstrap_new_user": dump(
                FlatmatesBootstrap,
                {
                    "profile": {"id": ME},
                    "catalogs": [],
                    "active_listing_count": 0,
                    "conversation_count": 0,
                    "unread_message_count": 0,
                    "realtime": flatmates_realtime_config(ME),
                },
            ),
            "profile": dump(FlatmatesProfile, profile()),
            "profile_paused": dump(FlatmatesProfile, profile(profile_status="paused")),
            # GET and PUT /users/me. The profile completion reads full_name and date_of_birth.
            "self_user": dump(
                SelfUser,
                {
                    "id": ME,
                    "email": None,
                    "full_name": "Asha Verma",
                    "phone": "+919876543210",
                    "date_of_birth": "1996-04-12",
                    "is_active": True,
                    "is_verified": True,
                    "phone_verified": True,
                    "supabase_user_id": "0b9e6d6e-6f5a-4a38-9d57-2f4b0a1c7e11",
                    "created_at": NOW,
                    "updated_at": NOW,
                },
            ),
            "auth_state": dump(
                AuthGateState,
                {"stage": "active", "next_action": "grant_access", "missing_fields": []},
            ),
            "auth_state_profile_completion": dump(
                AuthGateState,
                {
                    "stage": "profile_completion",
                    "next_action": "complete_profile",
                    "missing_fields": ["date_of_birth"],
                },
            ),
        },
        "peers": {
            "page": page(
                FlatmatesPeer,
                [peer(2, "Priya P"), listing_peer],
                next_cursor="eyJrIjpbMTc2MCwyXSwiZiI6ImFiYzEyMyJ9",
                limit=20,
            ),
            "detail": dump(FlatmatesPeer, listing_peer),
            "detail_no_listing": dump(FlatmatesPeer, peer(2, "Priya P")),
            "compatibility": dump(
                CompatibilityBreakdown,
                {
                    "user_id": ME,
                    "peer_id": 2,
                    "overall_percentage": 82.5,
                    "color": "green",
                    "dimensions": [
                        {
                            "name": "sleep_schedule",
                            "weight": 0.2,
                            "user_value": "flexible",
                            "peer_value": "early_bird",
                            "score": 70.0,
                            "match": False,
                            "summary": "Close sleep schedules",
                        },
                        {
                            "name": "cleanliness",
                            "weight": 0.3,
                            "user_value": "tidy",
                            "peer_value": "tidy",
                            "score": 100.0,
                            "match": True,
                            "summary": "Both tidy",
                        },
                    ],
                    "summary": ["Both tidy"],
                },
            ),
        },
        "conversations": {
            "list_page": page(
                ConversationSummary,
                [
                    conversation(10),
                    conversation(
                        11,
                        source="listing_interest",
                        peer=listing_peer,
                        qna=None,
                        matched_at=None,
                        unread_count=0,
                        last_message_preview=None,
                        last_message_at=None,
                    ),
                ],
                next_cursor="eyJrIjpbIjIwMjYtMDktMzAiLDEwXSwiZiI6ImFiYyJ9",
            ),
            "detail": dump(ConversationSummary, conversation(10)),
            "created": dump(
                ConversationSummary, conversation(12, source="listing_interest", qna=None)
            ),
            "messages_page": page(
                MessageOut,
                [
                    message(100),
                    message(101, sender_id=ME, body="Yes, come over on Saturday."),
                    message(
                        102,
                        sender_id=ME,
                        body="Visit requested for Morning (9 to 12)",
                        message_type="text",
                        message_metadata={
                            "visit_id": 5,
                            "status": "requested",
                            "scheduled_date": "2026-10-04T05:30:00Z",
                            "time_slot_label": "Morning (9 to 12)",
                        },
                    ),
                    message(
                        103,
                        sender_id=None,
                        body="Priya left the conversation.",
                        message_type="system",
                    ),
                    message(
                        104,
                        body=None,
                        attachment_url="https://cdn.example.com/c/10/photo.jpg",
                        message_type="image",
                    ),
                ],
                next_cursor="eyJrIjpbMTAwLDEwMF0sImYiOiJhYmMifQ",
                limit=50,
            ),
            "messages_last_page": page(MessageOut, [message(1)], limit=50),
            "message_created": dump(MessageOut, message(105, sender_id=ME, body="On my way")),
            "qna_state": dump(
                ConversationQnAState,
                {
                    "current_user": {"user_id": ME, "q1": "A calm place", "q2": "Balanced", "q3": "Tidy"},
                    "peer": {"user_id": 2, "q1": "Quiet", "q2": "Social", "q3": "Clean"},
                    "both_answered": True,
                },
            ),
        },
        "matches": {
            "page": page(
                MatchSummary,
                [
                    {
                        "id": 4,
                        "status": "active",
                        "peer": peer(2, "Priya P"),
                        "context_property": context_property(),
                        "created_at": NOW,
                    },
                    {
                        "id": 5,
                        "status": "blocked",
                        "peer": peer(3, "Rahul S"),
                        "context_property": None,
                        "created_at": NOW,
                    },
                ],
                limit=100,
            ),
            "contact": dump(
                MatchContactOut, {"match_id": 4, "peer_user_id": 2, "phone": "+919800000002"}
            ),
            "contact_no_phone": dump(MatchContactOut, {"match_id": 4, "peer_user_id": 2}),
            "unmatched": dump(MatchStatusOut, {"id": 4, "status": "unmatched"}),
        },
        "likes": {
            "incoming_page": page(
                IncomingLikeSummary,
                [
                    {
                        "id": 1,
                        "peer": peer(2, "Priya P"),
                        "context_property": context_property(),
                        "created_at": NOW,
                    }
                ],
                next_cursor="eyJrIjpbMSwxXSwiZiI6ImFiYyJ9",
            ),
            "outgoing_page": page(
                OutgoingLikeSummary,
                [
                    {
                        "id": 8,
                        "target_type": "user",
                        "peer": peer(3, "Rahul S"),
                        "property": None,
                        "context_property": None,
                        "created_at": NOW,
                    },
                    {
                        "id": 9,
                        "target_type": "property",
                        "peer": None,
                        "property": prop(42, liked=True),
                        "context_property": context_property(),
                        "created_at": NOW,
                    },
                ],
            ),
        },
        "swipes": {
            "match": dump(
                SwipeResult,
                {
                    "stored": True,
                    "action": "like",
                    "target_type": "user",
                    "conversation_id": 10,
                    "match_id": 4,
                    "did_match": True,
                },
            ),
            "pass": dump(
                SwipeResult, {"stored": True, "action": "pass", "target_type": "user"}
            ),
            "property_like": dump(
                SwipeResult,
                {
                    "stored": True,
                    "action": "like",
                    "target_type": "property",
                    "conversation_id": 11,
                },
            ),
            "profile_view": dump(
                ProfileViewEventOut,
                {
                    "id": 31,
                    "viewer_user_id": ME,
                    "viewed_user_id": 2,
                    "context_property_id": None,
                    "source": "swipe_deck",
                    "duration_seconds": 3600,
                    "scroll_depth_percent": 80,
                    "created_at": NOW,
                },
            ),
            "society_vote": dump(
                SocietyTagVoteOut,
                {
                    "property_id": 42,
                    "tag": "quiet",
                    "current_vote": "up",
                    "upvotes": 4,
                    "downvotes": 1,
                    "disputed": False,
                },
            ),
        },
        "blocks": {
            "page": page(
                BlockedUserOut,
                [
                    {
                        "id": 51,
                        "blocked_user_id": 3,
                        "blocked_user": public_user(3, "Rahul S", "https://cdn.example.com/u/3.jpg"),
                        "created_at": NOW,
                    },
                    {
                        "id": 52,
                        "blocked_user_id": 9,
                        "blocked_user": public_user(9, None, None),
                        "created_at": None,
                    },
                ],
                next_cursor="eyJrIjpbIjIwMjYtMDktMzAiLDUyXSwiZiI6ImFiYyJ9",
            ),
            "created": dump(
                BlockOut,
                {"id": 53, "blocker_user_id": ME, "blocked_user_id": 4, "created_at": NOW},
            ),
            "report": dump(
                ReportOut,
                {
                    "id": 6,
                    "reporter_user_id": ME,
                    "reported_user_id": 3,
                    "reason": "abuse",
                    "status": "open",
                    "notes": None,
                    "created_at": NOW,
                },
            ),
        },
        "visits": {
            "list_page": page(
                Visit,
                [
                    visit(5),
                    visit(
                        6,
                        status="confirmed",
                        time_slot_label=None,
                        visit_context="property_tour",
                        counterparty_user_id=None,
                        conversation_id=None,
                        match_id=None,
                        counterparty_user=None,
                    ),
                    visit(7, status="completed", scheduled_date="2026-09-01T09:00:00Z"),
                ],
                next_cursor="eyJrIjpbIjIwMjYtMDktMzAiLDVdLCJmIjoiYWJjIn0",
                limit=100,
            ),
            "created": dump(Visit, visit(8)),
            "confirmed": dump(Visit, visit(5, status="confirmed")),
            "rescheduled": dump(
                Visit,
                visit(
                    5,
                    status="reschedule_suggested",
                    scheduled_date="2026-10-06T09:00:00Z",
                    rescheduled_from="2026-10-04T05:30:00Z",
                    cancellation_reason="Traffic",
                ),
            ),
            "cancelled": dump(
                Visit, visit(5, status="cancelled", cancellation_reason="Plans changed")
            ),
        },
        "properties": {
            "list_page": page(
                Property,
                [prop(42), prop(43, title="Master bedroom, Indiranagar", liked=True)],
                next_cursor="eyJrIjpbIjIwMjYtMDktMzAiLDQzXSwiZiI6ImFiYyJ9",
            ),
            "detail": dump(
                PropertyDetail,
                prop(
                    42,
                    agent={
                        "id": 4,
                        "name": "Ravi Kumar",
                        "contact_number": "+919811111111",
                        "avatar_url": None,
                    },
                    owner_contact="+919811111111",
                    user_has_scheduled_visit=True,
                    user_scheduled_visit_count=1,
                    user_next_visit_date="2026-10-04T05:30:00Z",
                ),
            ),
            # The owner's own listings: one in each moderation state.
            "mine_page": page(
                Property,
                [
                    prop(
                        60,
                        owner_contact=None,
                        listing_preferences={
                            "gender_preference": "any",
                            "sharing_type": "private_room",
                            "moderation_status": "pending_review",
                        },
                    ),
                    prop(
                        61,
                        listing_preferences={
                            "gender_preference": "any",
                            "sharing_type": "private_room",
                            "moderation_status": "paused",
                        },
                    ),
                    prop(
                        62,
                        listing_preferences={
                            "gender_preference": "female",
                            "sharing_type": "shared_room",
                            "moderation_status": "rejected",
                        },
                    ),
                    prop(63),
                ],
                limit=100,
            ),
            "owner_updated_in_review": dump(
                Property,
                prop(
                    60,
                    listing_preferences={
                        "gender_preference": "any",
                        "sharing_type": "private_room",
                        "moderation_status": "pending_review",
                    },
                ),
            ),
        },
        "settings": {
            "notification_settings": dump(
                NotificationSettings,
                {"push_notifications": False, "promotional_emails": True},
            ),
            "privacy_settings": dump(
                PrivacySettings, {"profile_visibility": "private", "hide_last_name": True}
            ),
            "version_check": dump(
                AppVersionCheckResponse,
                {
                    "update_available": True,
                    "is_mandatory": False,
                    "latest_version": "1.1.0",
                    "download_url": "https://example.com/app",
                    "release_notes": "Fixes",
                    "min_supported_version": "1.0.0",
                },
            ),
            "upload": dump(
                UploadResult,
                {
                    "file_path": "generic/abc123",
                    "public_url": "https://res.cloudinary.com/demo/image/upload/generic/abc123.jpg",
                    "file_type": "image",
                    "file_size": 20480,
                    "content_type": "image/jpeg",
                    "original_filename": "photo.jpg",
                },
            ),
            "identifier_status": dump(
                IdentifierStatusResponse,
                {
                    "exists": True,
                    "verified": True,
                    "has_password": False,
                    "channel": "phone",
                    "next_step": "otp",
                },
            ),
            "identifier_status_email": dump(
                IdentifierStatusResponse,
                {
                    "exists": True,
                    "verified": True,
                    "has_password": True,
                    "channel": "email",
                    "next_step": "password",
                },
            ),
        },
        "notifications": {
            "page": page(
                FlatmatesNotificationOut,
                [
                    {
                        "id": "n-1",
                        "type": "flatmate_new_message",
                        "title": "New message",
                        "body": "Priya sent you a message",
                        "is_read": False,
                        "reference_id": 10,
                        "route": "/flatmates/chat/10",
                        "created_at": NOW,
                    },
                    {
                        "id": "n-2",
                        "type": "general",
                        "title": "Welcome",
                        "body": "Welcome to 360 FlatMates",
                        "is_read": True,
                        "reference_id": None,
                        "route": None,
                        "created_at": NOW,
                    },
                ],
                next_cursor="eyJrIjpbIjIwMjYtMDktMzAiLCJuLTIiXSwiZiI6ImFiYyJ9",
            ),
            "one": dump(
                FlatmatesNotificationOut,
                {
                    "id": "n-1",
                    "type": "flatmate_new_message",
                    "title": "New message",
                    "body": "Priya sent you a message",
                    "is_read": True,
                    "reference_id": 10,
                    "route": "/flatmates/chat/10",
                    "created_at": NOW,
                },
            ),
            "marked_read": dump(NotificationsMarkedRead, {"updated": 3}),
            "unread_count": dump(NotificationUnreadCount, {"unread_count": 2}),
            "registration": dump(
                DeviceRegistration,
                {
                    "platform": "ios",
                    "app_key": "flatmates",
                    "app_version": "1.0.9",
                    "locale": "en_IN",
                    "last_seen": NOW,
                },
            ),
            "push_message": push_data(
                route="/flatmates/chat/10", type_key="flatmate_new_message", data={"conversation_id": 10}
            ),
            "push_promotion": push_data(route=None, type_key="promotion_generic"),
            "push_type_only": push_data(route=None, type_key="flatmate_visit_scheduled"),
        },
        "deeplinks": deeplinks(),
        "errors": {
            "unauthorized": dump(
                ErrorEnvelope, error_body("TOKEN_INVALID", "The token is not valid.")
            ),
            "inactive": dump(
                ErrorEnvelope, error_body("USER_INACTIVE", "This account is deactivated.")
            ),
            "forbidden": dump(ErrorEnvelope, error_body("FORBIDDEN", "You cannot do that.")),
            "not_found": dump(
                ErrorEnvelope, error_body("MATCH_NOT_FOUND", "There is no active match.")
            ),
            "profile_not_found": dump(
                ErrorEnvelope, error_body("PROFILE_NOT_FOUND", "Profile not found.")
            ),
            "conflict": dump(
                ErrorEnvelope, error_body("VISIT_CONFLICT", "You already have a visit then.")
            ),
            "listing_status_conflict": dump(
                ErrorEnvelope,
                error_body(
                    "LISTING_STATUS_CONFLICT", "The listing cannot be resumed in this state."
                ),
            ),
            "profile_status_locked": dump(
                ErrorEnvelope,
                error_body("PROFILE_STATUS_LOCKED", "The profile status is set by moderation."),
            ),
            "rate_limited": dump(
                ErrorEnvelope, error_body("RATE_LIMIT_EXCEEDED", "Too many requests.")
            ),
            "server": dump(
                ErrorEnvelope, error_body("INTERNAL_ERROR", "An unexpected error occurred")
            ),
            "unavailable": dump(
                ErrorEnvelope,
                error_body("SERVICE_UNAVAILABLE", "The service is busy. Try again soon."),
            ),
            "bad_request": dump(
                ErrorEnvelope, error_body("BAD_REQUEST", "Conversation is not active")
            ),
            "validation": dump(
                ValidationErrorEnvelope,
                error_body(
                    "VALIDATION_ERROR",
                    "Request validation failed",
                    validation_details(
                        [
                            {
                                "loc": ("body", "reason"),
                                "msg": "String should have at least 1 character",
                                "type": "string_too_short",
                            },
                            {"loc": ("body", "full_name"), "msg": "Field required", "type": "missing"},
                            {
                                "loc": ("query", "limit"),
                                "msg": "Input should be less than or equal to 100",
                                "type": "less_than_equal",
                            },
                        ]
                    ),
                ),
            ),
            "validation_no_fields": dump(
                ValidationErrorEnvelope,
                error_body("INVALID_CURSOR", "Cursor does not match", {"fields": []}),
            ),
        },
        "requests": {
            name: flatten_request(model)
            for name, model in {
                "BlockCreate": BlockCreate,
                "BugReportCreate": BugReportCreate,
                "ConversationCreate": ConversationCreate,
                "DeviceRegisterIn": DeviceRegisterIn,
                "DeviceUnregisterIn": DeviceUnregisterIn,
                "FlatmatesNotificationBulkUpdate": FlatmatesNotificationBulkUpdate,
                "FlatmatesNotificationUpdate": FlatmatesNotificationUpdate,
                "FlatmatesProfileUpdate": FlatmatesProfileUpdate,
                "FlatmateVisitUpdate": FlatmateVisitUpdate,
                "IdentifierStatusRequest": IdentifierStatusRequest,
                "LastMethodRequest": LastMethodRequest,
                "MessageCreate": MessageCreate,
                "NotificationSettingsWrite": NotificationSettingsWrite,
                "PrivacySettingsPatch": PrivacySettingsPatch,
                "ProfileViewEventCreate": ProfileViewEventCreate,
                "PropertyCreate": PropertyCreate,
                "PropertyUpdate": PropertyUpdate,
                "QnAAnswers": QnAAnswers,
                "ReportCreate": ReportCreate,
                "SocietyTagVoteCreate": SocietyTagVoteCreate,
                "SwipeRequest": SwipeRequest,
                "UnmatchPairRequest": UnmatchPairRequest,
                "UserUpdate": UserUpdate,
                "AppVersionCheckRequest": AppVersionCheckRequest,
                "VisitCancel": VisitCancel,
                "VisitCreate": VisitCreate,
                "VisitReschedule": VisitReschedule,
                "VisitUpdate": VisitUpdate,
            }.items()
        },
        "operations": operations(),
        "enums": enums(),
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for group, data in fixtures().items():
        path = OUT / f"{group}.json"
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        print(f"wrote {path.relative_to(APP)}")


if __name__ == "__main__":
    main()
