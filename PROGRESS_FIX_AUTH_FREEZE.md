# Fix Auth Freeze Issue

## User Report
**From Jon's dad via Dave Zellner:**
"When he went into your app and it got to the point where it says sign in and then some other wording, it froze on him. And this happened a few times."

## Root Cause Analysis

The app was freezing on the sign-in screen due to **unprotected async operations** in the authentication flow. Specifically:

### Issue #1: OAuth Flows Without Timeouts
**Google & Apple Sign-In:**
- Opens a browser/modal for OAuth authentication
- Waits indefinitely for user to complete flow
- If user closes browser incorrectly, network times out, or OAuth provider has issues → Promise never resolves
- App stuck in loading state forever ⛔

**Example scenario:**
1. User taps "Continue with Google"
2. Browser opens for Google sign-in
3. User hits back button or network drops
4. WebBrowser.openAuthSessionAsync() never returns
5. Loading spinner stays forever
6. App frozen

### Issue #2: Network Requests Without Timeouts
**Email/Password Sign-In:**
- Calls Supabase API to authenticate
- No timeout protection
- If network is slow or API is down → hangs indefinitely
- App stuck in loading state ⛔

### Issue #3: No User Escape Hatch
Even if user realizes something is wrong, there's no way to cancel or retry without force-closing the app.

## The Fix

### 1. Added Timeout Protection to All Auth Methods

**Google OAuth (60-second timeout):**
```typescript
const browserPromise = WebBrowser.openAuthSessionAsync(data.url, redirectUrl);
const timeoutPromise = new Promise((_, reject) => 
  setTimeout(() => reject(new Error('Sign in timed out after 60 seconds. Please try again.')), 60000)
);
const result = await Promise.race([browserPromise, timeoutPromise]);
```

**Apple OAuth (60-second timeout):**
```typescript
const credentialPromise = AppleAuthentication.signInAsync({ ... });
const timeoutPromise = new Promise((_, reject) => 
  setTimeout(() => reject(new Error('Sign in timed out after 60 seconds. Please try again.')), 60000)
);
const credential = await Promise.race([credentialPromise, timeoutPromise]);
```

**Email Sign-In (30-second timeout):**
```typescript
const signInPromise = supabase.auth.signInWithPassword({ email, password });
const timeoutPromise = new Promise((_, reject) => 
  setTimeout(() => reject(new Error('Sign in timed out. Please check your internet connection and try again.')), 30000)
);
const result = await Promise.race([signInPromise, timeoutPromise]);
```

**Email Sign-Up (30-second timeout):**
Same pattern as sign-in.

### 2. Added User Escape Hatch (30-Second Alert)

**Problem:** Even with timeouts, user might think app is frozen before timeout expires.

**Solution:** Show a "Taking longer than expected" alert after 30 seconds with "Cancel and Try Again" button.

**How it works:**
- Timer starts when loading begins
- After 30 seconds, shows helpful message:
  - "Sign in is taking longer than usual"
  - "This could be due to a slow internet connection"
  - **"Cancel and Try Again" button** ← User can escape!
- Clicking button stops loading and shows error message
- User can try different method or retry

### 3. Better Error Handling

**Added dismiss detection:**
- Google/Apple OAuth now detects `dismiss` result type (when user closes browser)
- Returns "Sign in cancelled" error instead of hanging
- Loading state properly reset

## What This Fixes

### Before ❌
1. User taps "Continue with Google"
2. Network issue or user closes browser incorrectly
3. **App stuck loading forever**
4. User has to force-close app
5. Frustration + bad experience

### After ✅
1. User taps "Continue with Google"
2. Network issue or user closes browser incorrectly
3. **After 30 seconds:** Alert shows "Taking longer than expected"
4. **After 60 seconds:** Timeout error "Sign in timed out. Please try again."
5. User can retry or try different method
6. No force-close needed

## Technical Details

### Timeout Values
- **OAuth flows (Google/Apple):** 60 seconds
  - Why 60s? OAuth involves opening browser, loading provider page, user interaction
  - Long enough for normal flow, short enough to detect stuck state
- **Email sign-in:** 30 seconds
  - Why 30s? Simple API call, should be fast
  - If taking >30s, network or API issue
- **User alert:** 30 seconds
  - Shows user something is happening, gives option to bail early

### Promise.race() Pattern
```typescript
const result = await Promise.race([actualOperation, timeoutOperation]);
```
- Returns whichever Promise resolves/rejects first
- If timeout wins → throws timeout error
- If actual operation wins → returns result
- Ensures operation can never hang indefinitely

### Finally Block Protection
All auth methods already had `finally { setLoading(false); }` blocks, so loading state ALWAYS resets even if timeout throws error. This is critical for preventing stuck states.

## Files Changed
- ✅ `src/contexts/AuthContext.tsx` - Added timeouts to all auth methods
- ✅ `src/screens/AuthScreen.tsx` - Added 30-second "stuck" alert with escape button

## Testing Recommendations

**Scenario 1: Normal Sign-In (Should work as before)**
1. Tap "Continue with Google" or "Sign In with Apple"
2. Complete auth flow normally
3. Should sign in successfully ✓

**Scenario 2: User Cancels OAuth**
1. Tap "Continue with Google"
2. Close the browser immediately
3. Should show "Sign in cancelled" error ✓
4. Loading should stop ✓

**Scenario 3: Slow Network**
1. Enable airplane mode AFTER tapping sign-in
2. Should show "Taking longer than expected" after 30s ✓
3. Should show timeout error after 60s (OAuth) or 30s (email) ✓
4. Can retry after turning network back on ✓

**Scenario 4: OAuth Hangs**
1. Start OAuth flow
2. Simulate hang (e.g., browser process stuck)
3. After 30s: "Taking longer" alert appears ✓
4. User can click "Cancel and Try Again" ✓
5. After 60s: Timeout error shows ✓

## Status
✅ **COMPLETE** - All auth methods protected with timeouts, user escape hatch added, better error handling.

Dave (and all users) should no longer experience frozen sign-in screens! 🎉
