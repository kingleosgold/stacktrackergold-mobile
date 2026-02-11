#!/usr/bin/env python3
"""
Stack Tracker Gold — Daily Intelligence Generator
Runs daily at 6:30 AM EST via cron on the Mac Mini.

Jobs:
  1. Search for precious metals news → write intelligence_briefs to Supabase
  2. Search for COMEX vault inventory → write vault_data to Supabase

Architecture: Gemini 2.5 Flash + Google Search grounding → Supabase
Same pattern as Bezal Prospector.
"""

import os
import sys
import json
import time
import re
from datetime import datetime, timezone
from pathlib import Path
from difflib import SequenceMatcher

# ============================================
# ENVIRONMENT
# ============================================

ENV_PATH = Path.home() / ".clawdbot" / ".env"

def load_env(env_path):
    """Load environment variables from .env file."""
    if not env_path.exists():
        print(f"  {env_path} not found")
        return False
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip().strip("'").strip('"')
                os.environ[key] = value
    return True

def ts():
    """Timestamp for logging."""
    return datetime.now().strftime("%H:%M:%S")

print(f"\n{'='*60}")
print(f"  Stack Tracker Gold — Intelligence Generator")
print(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}")
print(f"{'='*60}\n")

# Load env
print(f"[{ts()}] Loading environment from {ENV_PATH}")
if not load_env(ENV_PATH):
    print(f"[{ts()}] FATAL: Could not load environment")
    sys.exit(1)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not all([GEMINI_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY]):
    missing = [k for k in ["GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"] if not os.environ.get(k)]
    print(f"[{ts()}] FATAL: Missing env vars: {', '.join(missing)}")
    sys.exit(1)

print(f"[{ts()}] Environment loaded successfully")

# ============================================
# CLIENTS
# ============================================

from google import genai
from google.genai import types
from supabase import create_client

print(f"[{ts()}] Initializing Gemini client (gemini-2.5-flash)...")
gemini_client = genai.Client(api_key=GEMINI_API_KEY)
MODEL = "gemini-2.5-flash"

print(f"[{ts()}] Initializing Supabase client...")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ============================================
# CONFIG
# ============================================

TODAY = datetime.now().strftime("%Y-%m-%d")
MAX_API_CALLS = 30
MAX_BRIEFS_PER_DAY = 8
api_call_count = 0
start_time = time.time()

# ============================================
# HELPERS
# ============================================

def parse_json_response(text):
    """Parse JSON from Gemini response, cleaning markdown backticks."""
    if not text:
        return None
    # Strip markdown code fences
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*\n?", "", text)
    text = re.sub(r"\n?```\s*$", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        print(f"     JSON parse error: {e}")
        print(f"     Raw text (first 200 chars): {text[:200]}")
        return None


def gemini_search(prompt, system_prompt=None, max_retries=3):
    """Call Gemini with Google Search grounding. Returns parsed JSON or None."""
    global api_call_count

    if api_call_count >= MAX_API_CALLS:
        print(f"     Budget cap reached ({MAX_API_CALLS} calls). Skipping.")
        return None

    for attempt in range(1, max_retries + 1):
        try:
            api_call_count += 1

            config = types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                temperature=0.3,
            )
            if system_prompt:
                config.system_instruction = system_prompt

            response = gemini_client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=config,
            )

            if response and response.text:
                return parse_json_response(response.text)
            else:
                print(f"     Attempt {attempt}: Empty response")

        except Exception as e:
            print(f"     Attempt {attempt} failed: {e}")
            if attempt < max_retries:
                wait = 2 ** attempt
                print(f"     Retrying in {wait}s...")
                time.sleep(wait)

    return None


def title_similarity(a, b):
    """Check title similarity ratio (0-1)."""
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()


# ============================================
# STEP 1: INTELLIGENCE BRIEFS
# ============================================

print(f"\n[{ts()}] ===== STEP 1: INTELLIGENCE BRIEFS =====\n")

SEARCHES = [
    f"gold silver precious metals market news today {TODAY}",
    f"federal reserve interest rate policy gold impact {TODAY}",
    f"COMEX silver gold delivery supply shortage {TODAY}",
    f"central bank gold buying reserves {TODAY}",
    f"silver industrial demand solar panels EV {TODAY}",
    f"platinum palladium automotive catalyst supply {TODAY}",
]

SYSTEM_PROMPT = (
    "You are a precious metals market analyst. Search for the most important news "
    "from the last 24 hours about the given topic. Return a JSON array of 1-3 news items. "
    "Each item must have: title (string), summary (2-3 sentences), category (one of: "
    "market_brief, breaking_news, policy, supply_demand, analysis), source (publication name), "
    "source_url (if findable), relevance_score (1-100, how important this is for physical "
    "precious metals stackers). Only include genuinely newsworthy items. If nothing significant "
    "happened, return an empty array. Return ONLY the JSON array, no markdown."
)

all_briefs = []

for i, query in enumerate(SEARCHES, 1):
    print(f"[{ts()}] Search {i}/{len(SEARCHES)}: {query[:60]}...")
    result = gemini_search(query, system_prompt=SYSTEM_PROMPT)

    if result and isinstance(result, list):
        print(f"     Found {len(result)} briefs")
        all_briefs.extend(result)
    else:
        print(f"     No results or bad response")

    # Small delay between searches
    if i < len(SEARCHES):
        time.sleep(1)

print(f"\n[{ts()}] Raw briefs collected: {len(all_briefs)}")

# Deduplicate by title similarity
deduped = []
for brief in all_briefs:
    title = brief.get("title", "")
    if not title:
        continue
    is_dupe = False
    for existing in deduped:
        if title_similarity(title, existing.get("title", "")) > 0.8:
            is_dupe = True
            break
    if not is_dupe:
        deduped.append(brief)

print(f"[{ts()}] After dedup: {len(deduped)} briefs")

# Sort by relevance and cap
deduped.sort(key=lambda b: b.get("relevance_score", 0), reverse=True)
final_briefs = deduped[:MAX_BRIEFS_PER_DAY]
print(f"[{ts()}] Final briefs (capped at {MAX_BRIEFS_PER_DAY}): {len(final_briefs)}")

# Delete existing briefs for today (idempotent reruns)
print(f"[{ts()}] Clearing existing briefs for {TODAY}...")
try:
    supabase.table("intelligence_briefs").delete().eq("date", TODAY).execute()
    print(f"     Cleared")
except Exception as e:
    print(f"     Clear failed (may not exist yet): {e}")

# Insert briefs
briefs_inserted = 0
for brief in final_briefs:
    try:
        row = {
            "date": TODAY,
            "category": brief.get("category", "market_brief"),
            "title": brief.get("title", "Untitled"),
            "summary": brief.get("summary", ""),
            "source": brief.get("source"),
            "source_url": brief.get("source_url"),
            "relevance_score": min(max(int(brief.get("relevance_score", 50)), 1), 100),
        }
        supabase.table("intelligence_briefs").insert(row).execute()
        briefs_inserted += 1
        print(f"     Inserted: {row['title'][:60]}...")
    except Exception as e:
        print(f"     Insert failed: {e}")

print(f"\n[{ts()}] Briefs inserted: {briefs_inserted}/{len(final_briefs)}")

# ============================================
# STEP 2: VAULT DATA (COMEX)
# ============================================

print(f"\n[{ts()}] ===== STEP 2: VAULT DATA (COMEX) =====\n")

VAULT_PROMPT = (
    f"Search for today's ({TODAY}) COMEX precious metals warehouse inventory report. "
    "Find the latest registered and eligible inventory numbers for gold, silver, platinum, "
    "and palladium. Also find the current open interest for the active month contract for "
    "each metal. Return a JSON object with keys: gold, silver, platinum, palladium. "
    "Each must have: registered_oz (number), eligible_oz (number), registered_change_oz "
    "(number, daily change), eligible_change_oz (number, daily change), open_interest_oz "
    "(number, active month). Use the most recent data available. Return ONLY JSON, no markdown."
)

VAULT_SYSTEM = (
    "You are a COMEX warehouse data analyst. Search for the most recent CME Group / COMEX "
    "precious metals warehouse stock reports. Return precise numbers in troy ounces. "
    "If exact daily data is not available for a metal, use the most recent report numbers. "
    "Return ONLY valid JSON."
)

print(f"[{ts()}] Searching for COMEX vault inventory data...")
vault_result = gemini_search(VAULT_PROMPT, system_prompt=VAULT_SYSTEM)

vault_inserted = 0
vault_metals_status = {}

if vault_result and isinstance(vault_result, dict):
    # Delete existing vault data for today (idempotent)
    print(f"[{ts()}] Clearing existing vault data for {TODAY}...")
    try:
        supabase.table("vault_data").delete().eq("date", TODAY).eq("source", "comex").execute()
        print(f"     Cleared")
    except Exception as e:
        print(f"     Clear failed: {e}")

    for metal in ["gold", "silver", "platinum", "palladium"]:
        metal_data = vault_result.get(metal)
        if not metal_data:
            print(f"     {metal}: No data found")
            vault_metals_status[metal] = "no data"
            continue

        try:
            registered = float(metal_data.get("registered_oz", 0))
            eligible = float(metal_data.get("eligible_oz", 0))
            reg_change = float(metal_data.get("registered_change_oz", 0))
            elig_change = float(metal_data.get("eligible_change_oz", 0))
            open_interest = float(metal_data.get("open_interest_oz", 0))

            combined = registered + eligible
            combined_change = reg_change + elig_change
            oversubscribed = round(open_interest / registered, 2) if registered > 0 else 0

            row = {
                "date": TODAY,
                "source": "comex",
                "metal": metal,
                "registered_oz": registered,
                "eligible_oz": eligible,
                "combined_oz": combined,
                "registered_change_oz": reg_change,
                "eligible_change_oz": elig_change,
                "combined_change_oz": combined_change,
                "open_interest_oz": open_interest,
                "oversubscribed_ratio": oversubscribed,
            }

            supabase.table("vault_data").insert(row).execute()
            vault_inserted += 1
            vault_metals_status[metal] = f"registered={registered:,.0f} oz, ratio={oversubscribed:.2f}x"
            print(f"     {metal}: {vault_metals_status[metal]}")

        except Exception as e:
            print(f"     {metal}: Insert failed — {e}")
            vault_metals_status[metal] = f"error: {e}"
else:
    print(f"[{ts()}] Vault search returned no usable data")
    vault_metals_status = {m: "search failed" for m in ["gold", "silver", "platinum", "palladium"]}

print(f"\n[{ts()}] Vault rows inserted: {vault_inserted}/4")

# ============================================
# STEP 3: SUMMARY
# ============================================

elapsed = time.time() - start_time
est_cost = api_call_count * 0.01  # ~$0.01 per grounded search call

print(f"\n{'='*60}")
print(f"  SUMMARY")
print(f"{'='*60}")
print(f"  Intelligence briefs: {briefs_inserted} inserted")
print(f"  Vault data:")
for metal, status in vault_metals_status.items():
    print(f"    {metal:>10}: {status}")
print(f"  API calls used:  {api_call_count}/{MAX_API_CALLS}")
print(f"  Est. cost:       ~${est_cost:.2f}")
print(f"  Runtime:         {elapsed:.1f}s")
print(f"{'='*60}\n")

# Exit with error if nothing worked at all
if briefs_inserted == 0 and vault_inserted == 0:
    print(f"[{ts()}] ERROR: No data generated at all. Check API keys and connectivity.")
    sys.exit(1)

print(f"[{ts()}] Done.")
