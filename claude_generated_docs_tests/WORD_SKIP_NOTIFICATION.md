# Word Skip Notification

## Overview

When a word is skipped via voting, all players are automatically notified and their game state updates to reflect the new word - even if they didn't vote or weren't the player who triggered the skip.

## Problem

**Before this feature:**
- Player A votes to skip
- Player B votes to skip (triggers the 50% threshold)
- Only Player B's frontend reloads the word
- Player A and other players stuck with old word
- Roles reassigned but players don't know
- Game state becomes desynced

**After this feature:**
- Player A votes to skip
- Player B votes to skip (triggers skip)
- Within ~3 seconds, ALL players notified
- Everyone's word automatically reloads
- Seamless synchronization across all clients

## How It Works

### Backend Changes

**1. Added SkipCount to Round Model** (`internal/models/models.go`):
```go
type Round struct {
    Number      int       `json:"number"`
    Word        string    `json:"word"`
    StartedAt   time.Time `json:"startedAt"`
    SkipVotes   int       `json:"skipVotes"`
    SkipCount   int       `json:"skipCount"`  // NEW: Increments on each word skip
    IsCompleted bool      `json:"isCompleted"`
}
```

**2. Increment SkipCount on Skip** (`internal/game/manager.go`):
```go
func (m *Manager) SkipWord(game *models.Game) error {
    // ... reassign roles, get new word ...
    game.CurrentRound.SkipCount++  // Increment so players can detect changes
    return nil
}
```

**3. Return SkipCount in API** (`internal/handlers/handlers.go`):
```go
// GET /get_word now returns:
{
    "isImpostor": false,
    "word": "banana",
    "roundNumber": 1,
    "skipCount": 2  // NEW: Allows detection of word skips
}
```

### Frontend Changes

**1. Track Current SkipCount** (`index.html`):
```javascript
let currentSkipCount = 0;  // NEW: Track skip count
```

**2. Detect SkipCount Changes** (polling):
```javascript
async function checkForRoundUpdate() {
    const response = await fetch(`${API_BASE}/get_word`, {
        headers: { 'Authorization': sessionToken }
    });
    const data = await response.json();
    
    // Check for round number change (non-host only)
    if (!isHost && data.roundNumber > currentRound) {
        await handleNewRound(data.roundNumber);
        return;
    }
    
    // Check for word skip (ALL players)
    if (data.skipCount > currentSkipCount) {
        await handleWordSkip(data.skipCount);
    }
}
```

**3. Handle Word Skip**:
```javascript
async function handleWordSkip(newSkipCount) {
    currentSkipCount = newSkipCount;
    
    // Show notification
    alert('Word was skipped! Loading new word...');
    
    // Reload word and update UI
    await loadWord();
    
    // Reset word display
    const wordDisplay = document.getElementById('wordDisplay');
    wordDisplay.textContent = '?????';
    wordDisplay.className = 'word-display' + (isImpostor ? ' impostor' : ' player');
}
```

**4. Update loadWord to Track SkipCount**:
```javascript
async function loadWord() {
    const data = await response.json();
    isImpostor = data.isImpostor;
    currentRound = data.roundNumber;
    currentSkipCount = data.skipCount || 0;  // NEW: Track skipCount
    hasSkipped = false;
    // ... rest of function ...
}
```

## Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│              PLAYER A VOTES TO SKIP (Vote 1/2)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  POST /vote_word_skip (Player A)                            │
│  - Player A marked as hasSkipped                            │
│  - SkipVotes = 1                                            │
│  - Not enough votes yet (need 2/3 = 67%)                   │
│  - Response: {"skipped": false}                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              PLAYER B VOTES TO SKIP (Vote 2/2)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  POST /vote_word_skip (Player B)                            │
│  - Player B marked as hasSkipped                            │
│  - SkipVotes = 2                                            │
│  - Threshold reached! (2/3 = 67%)                          │
│  - SkipWord() called:                                       │
│    • Reassign roles                                         │
│    • Pick new random word                                   │
│    • Reset skip votes                                       │
│    • SkipCount++  (0 → 1)                                  │
│  - Response: {"skipped": true}                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               PLAYER B'S FRONTEND (Immediate)                │
│  - Receives {"skipped": true}                               │
│  - Shows alert: "Word skipped! Loading new word..."        │
│  - Calls loadWord() → gets new word + skipCount=1          │
│  - Updates UI                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            OTHER PLAYERS (Within ~1-3 seconds)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Polling interval triggers (every 3 seconds)                │
│  GET /get_word                                              │
│  Response: {"skipCount": 1, ...}                           │
│                                                             │
│  checkForRoundUpdate() detects:                             │
│  - Current skipCount: 0                                     │
│  - New skipCount: 1                                         │
│  - Difference detected! (1 > 0)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  handleWordSkip(1) executes:                                │
│  1. Updates currentSkipCount = 1                            │
│  2. Shows alert: "Word was skipped! Loading new word..."   │
│  3. Calls loadWord() to get new word/role                  │
│  4. Resets word display to ?????                           │
│  5. Updates skip button state                               │
└─────────────────────────────────────────────────────────────┘
```

## Key Differences from Round Updates

| Feature | Round Update | Word Skip |
|---------|--------------|-----------|
| **Trigger** | Host clicks "Next Round" | Any innocent player's vote reaches threshold |
| **What Changes** | Round number increments | Word changes, round number stays same |
| **Who Detects** | Non-host players only | ALL players (including host) |
| **Backend Field** | `roundNumber` | `skipCount` |
| **How Often** | Once per round | Multiple times per round possible |

## Timeline

```
T=0s    Player B votes (triggers skip)
        ↓
T=0.1s  Backend increments skipCount
        ↓
T=0.2s  Player B's screen updates immediately
        ↓
T=1-3s  Other players' polling triggers
        ↓
T=1-3s  Other players detect skipCount change
        ↓
T=1-3s  Other players see alert notification
        ↓
T=1-3s  Other players load new word
        ↓
T=1-3s  All players synced
```

**Average notification time for non-triggering players:** ~1.5 seconds

## Edge Cases

### What if host votes and triggers skip?

**Scenario:**
- Host is innocent player
- Host votes and triggers skip
- Host's frontend immediately reloads word

**Behavior:**
- Host's voteSkip() calls loadWord() → sets currentSkipCount = 1
- Host's polling also runs checkForRoundUpdate()
- checkForRoundUpdate sees skipCount=1 vs currentSkipCount=1 (no change)
- No duplicate notification for host ✅

### What if impostor tries to vote?

**Scenario:**
- Impostor clicks "Skip Word" button
- Frontend sends POST /vote_word_skip

**Behavior:**
- Backend returns 400: "impostors cannot skip words"
- Frontend shows error alert
- No skipCount increment
- Other players unaffected ✅

### What if word skipped multiple times in same round?

**Scenario:**
- Skip 1: skipCount goes from 0 → 1
- Skip 2: skipCount goes from 1 → 2
- Skip 3: skipCount goes from 2 → 3

**Behavior:**
- Each skip increments skipCount
- Polling detects each increment
- Players get notification for each skip
- Works correctly ✅

### What if player is offline when skip happens?

**Scenario:**
- Player loses network connection
- Word gets skipped while offline
- Player reconnects

**Behavior:**
- When player reconnects, polling resumes
- GET /get_word returns current skipCount
- Player detects skipCount > their cached value
- Player gets notification and loads new word
- Catches up automatically ✅

## Testing

### Automated Test

```bash
./test_word_skip_notification.sh
```

**Verifies:**
- ✅ Initial skipCount is 0
- ✅ SkipCount increments when word skipped
- ✅ All players see same skipCount
- ✅ Round number stays the same
- ✅ Handles impostor players correctly

### Manual Test

1. **Setup:**
   - Window 1: Alice (host)
   - Window 2: Bob
   - Window 3: Charlie

2. **Test:**
   - Alice creates game
   - Bob and Charlie join
   - Alice starts Round 1
   - All see Round 1 with initial word
   - Bob votes to skip
   - Charlie votes to skip (triggers skip)
   - Charlie sees immediate update
   - Within 3 seconds: Alice and Bob see notification
   - All players have new word

3. **Verify:**
   - All skipCounts match
   - All have same new word (or impostor status)
   - Skip button reset for all
   - Round number still 1

## Performance

**Network Impact:**
- Same polling used for player list and round updates
- No additional requests
- Reuses existing `/get_word` endpoint
- SkipCount field adds ~15 bytes to response
- Minimal overhead

**Client Impact:**
- Simple number comparison (O(1))
- Negligible CPU usage
- No memory leaks
- Efficient state management

## Benefits

✅ **Synchronized gameplay** - All players get new word simultaneously  
✅ **No manual refresh** - Automatic detection and reload  
✅ **Clear notifications** - Players know when word changes  
✅ **Works for all players** - Including host, non-voters, late joiners  
✅ **Resilient** - Handles network issues, offline players  
✅ **Efficient** - Uses existing polling infrastructure  

## Future Enhancements

Possible improvements:
- [ ] WebSocket for instant notifications (<100ms latency)
- [ ] Show which player triggered the skip
- [ ] Countdown timer before word changes
- [ ] Skip animation instead of alert
- [ ] Track skip history per round
- [ ] Configurable skip threshold (currently 50%)

## Conclusion

Word skip notifications ensure all players stay synchronized when words are skipped via voting. By tracking a `skipCount` field and using the existing polling mechanism, players detect word changes within ~1.5 seconds and automatically reload their game state.

**Try it now:**
```bash
./run.sh
# Window 1: Create game, start round
# Window 2: Join game, vote to skip
# Window 3: Join game, vote to skip (triggers threshold)
# Observe: All windows get notification within 3 seconds
```
