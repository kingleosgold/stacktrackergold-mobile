# Stack Tracker Gold — Intelligence Generator

Daily cron script that generates precious metals intelligence briefs and COMEX vault inventory data using Gemini 2.5 Flash with Google Search grounding.

Runs on the Mac Mini alongside the Bezal Prospector, using the same architecture.

## What It Does

1. **Intelligence Briefs** — Searches 6 topics (gold/silver news, Fed policy, COMEX supply, central bank buying, silver industrial demand, platinum/palladium) and writes the top 8 briefs to `intelligence_briefs` table
2. **Vault Data** — Searches for latest COMEX warehouse inventory (registered/eligible/combined for all 4 metals) and writes to `vault_data` table

## Setup

### 1. Copy to Mac Mini

```bash
# From this repo
scp -r backend/intelligence/ macmini:~/clawd/intelligence/
```

Or if already on the Mac Mini:
```bash
mkdir -p ~/clawd/intelligence
cp backend/intelligence/*.py ~/clawd/intelligence/
```

### 2. Verify Environment Variables

These should already be set in `~/.clawdbot/.env` (shared with Prospector):

```
GEMINI_API_KEY=your-gemini-key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. Test

```bash
python3 ~/clawd/intelligence/test-intelligence.py
```

Expected output: Gemini search OK, Supabase insert OK, cleanup OK.

### 4. Create Log Directory

```bash
mkdir -p ~/clawd/logs
```

### 5. Add Cron Job

```bash
crontab -e
```

Add this line (runs daily at 6:30 AM EST):

```
30 6 * * * cd ~/clawd/intelligence && /usr/bin/python3 generate-intelligence.py >> ~/clawd/logs/intelligence.log 2>&1
```

### 6. Verify Cron

```bash
# Check cron is set
crontab -l

# Check logs after first run
tail -50 ~/clawd/logs/intelligence.log
```

## Dependencies

Already installed for Prospector:
- `google-genai` — Gemini API client
- `supabase` — Supabase Python client

## Cost

~$0.07-0.10 per daily run (7-8 grounded Gemini Flash calls at ~$0.01 each).

## Troubleshooting

- **Empty briefs**: Check Gemini API key, may be rate limited
- **Supabase errors**: Verify service role key has insert permissions
- **No vault data**: COMEX reports publish around 4-5 PM ET the previous day; morning runs should find yesterday's data
- **All searches fail**: Check internet connectivity on Mac Mini
