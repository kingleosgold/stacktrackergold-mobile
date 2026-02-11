#!/usr/bin/env python3
"""
Stack Tracker Gold — Intelligence Test Script
Quick test to verify Gemini + Supabase connectivity.
Runs 1 search and inserts 1 test brief.
"""

import os
import sys
import json
import re
from datetime import datetime
from pathlib import Path

# ============================================
# ENVIRONMENT
# ============================================

ENV_PATH = Path.home() / ".clawdbot" / ".env"

def load_env(env_path):
    if not env_path.exists():
        print(f"ERROR: {env_path} not found")
        return False
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                os.environ[key.strip()] = value.strip().strip("'").strip('"')
    return True

print("\n=== Stack Tracker Gold — Intelligence Test ===\n")

if not load_env(ENV_PATH):
    sys.exit(1)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

missing = [k for k in ["GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"] if not os.environ.get(k)]
if missing:
    print(f"ERROR: Missing env vars: {', '.join(missing)}")
    sys.exit(1)

print("Environment loaded OK")

# ============================================
# CLIENTS
# ============================================

from google import genai
from google.genai import types
from supabase import create_client

print("Initializing Gemini (gemini-2.5-flash)...")
gemini_client = genai.Client(api_key=GEMINI_API_KEY)

print("Initializing Supabase...")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ============================================
# TEST SEARCH
# ============================================

TODAY = datetime.now().strftime("%Y-%m-%d")

print(f"\nSearching: 'gold precious metals news today {TODAY}'...")

try:
    response = gemini_client.models.generate_content(
        model="gemini-2.5-flash",
        contents=f"gold precious metals market news today {TODAY}",
        config=types.GenerateContentConfig(
            tools=[types.Tool(google_search=types.GoogleSearch())],
            temperature=0.3,
            system_instruction=(
                "You are a precious metals market analyst. Search for the most important "
                "gold news from today. Return a JSON array with exactly 1 item. The item must "
                "have: title (string), summary (2-3 sentences), category (one of: market_brief, "
                "breaking_news, policy, supply_demand, analysis), source (publication name), "
                "source_url (if findable), relevance_score (1-100). Return ONLY JSON, no markdown."
            ),
        ),
    )

    text = response.text.strip()
    text = re.sub(r"^```(?:json)?\s*\n?", "", text)
    text = re.sub(r"\n?```\s*$", "", text)
    result = json.loads(text.strip())

    print(f"\nGemini response parsed OK:")
    print(json.dumps(result, indent=2))

except Exception as e:
    print(f"\nGemini search FAILED: {e}")
    sys.exit(1)

# ============================================
# TEST INSERT
# ============================================

if isinstance(result, list) and len(result) > 0:
    brief = result[0]
    row = {
        "date": TODAY,
        "category": brief.get("category", "market_brief"),
        "title": f"[TEST] {brief.get('title', 'Test Brief')}",
        "summary": brief.get("summary", "Test summary"),
        "source": brief.get("source", "test"),
        "source_url": brief.get("source_url"),
        "relevance_score": brief.get("relevance_score", 50),
    }

    print(f"\nInserting test brief into intelligence_briefs...")
    try:
        res = supabase.table("intelligence_briefs").insert(row).execute()
        print(f"Supabase insert OK: {res.data[0]['id']}")
        print(f"\nTitle: {row['title']}")
        print(f"Category: {row['category']}")
        print(f"Source: {row['source']}")

        # Clean up test data
        print(f"\nCleaning up test brief...")
        supabase.table("intelligence_briefs").delete().eq("id", res.data[0]["id"]).execute()
        print("Cleaned up OK")

    except Exception as e:
        print(f"Supabase insert FAILED: {e}")
        sys.exit(1)

print(f"\n{'='*40}")
print(f"  ALL TESTS PASSED")
print(f"  Gemini: OK")
print(f"  Supabase: OK")
print(f"  Ready for cron setup!")
print(f"{'='*40}\n")
