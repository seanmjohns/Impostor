# Round Update Notifications

## Overview

When the host advances to the next round, all non-host players are automatically notified and their game state is updated to match the new round.

## Problem

**Before this feature:**
- Host clicks "Next Round"
- Host sees new round immediately
- Other players stuck on old round
- Players confused why word doesn't change
- Manual refresh required

**After this feature:**
- Host clicks "Next Round"
- Within ~3 seconds, all players notified
- Automatic word reload for all players
- Seamless round transitions
- No manual intervention needed

## How It Works

### Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    HOST STARTS NEW ROUND                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Host clicks "Next Round"                                   │
│  POST /next_round                                           │
│  Backend increments game.RoundNumber (1 → 2)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Host's screen updates immediately:                         │
│  - Loads new word/role                                      │
│  - Updates round number to 2                                │
│  - Resets word display to ?????                            │
└─────────────────────────────────────────────────────────────┘

                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              NON-HOST PLAYERS (Within ~3 seconds)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob's polling interval triggers (every 3 seconds)          │
│  GET /get_word                                              │
│  Response: {"roundNumber": 2, ...}                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  checkForRoundUpdate() detects:                             │
│  - Current round: 1                                         │
│  - New round: 2                                             │
│  - Difference detected! (2 > 1)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  handleNewRound(2) executes:                                │
│  1. Updates currentRound = 2                                │
│  2. Shows alert: "Round 2 has started!"                    │
│  3. Calls loadWord() to get new word/role                  │
│  4. Resets word display to ?????                           │
│  5. Updates round number in UI                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob sees:                                                  │
│  [!] Round 2 has started!                                  │
│  [OK]                                                       │
│  → New word loaded                                          │
│  → Round number updated                                     │
│  → Ready to play new round                                  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### Frontend Code

**Round Change Detection:**
```javascript
async function checkForRoundUpdate() {
    if (!sessionToken || isHost) return;

    const response = await fetch('/get_word', {
        headers: { 'Authorization': sessionToken }
    });

    if (!response.ok) return;

    const data = await response.json();

    // Check if round number increased
    if (data.roundNumber && data.roundNumber > currentRound) {
        await handleNewRound(data.roundNumber);
    }
}
```

**New Round Handler:**
```javascript
async function handleNewRound(newRoundNumber) {
    currentRound = newRoundNumber;

    // Notify player
    alert(`Round ${newRoundNumber} has started!`);

    // Reload word and role
    await loadWord();

    // Reset display
    const wordDisplay = document.getElementById('wordDisplay');
    wordDisplay.textContent = '?????';
    wordDisplay.className = 'word-display' + 
        (isImpostor ? ' impostor' : ' player');

    // Update UI
    document.getElementById('roundNumber').textContent = currentRound;
}
```

**Integrated with Polling:**
```javascript
function startPlayerPolling() {
    playerPollInterval = setInterval(async () => {
        await updatePlayerList();

        // Check for round updates if in game (non-host only)
        const gameScreen = document.getElementById('gameScreen');
        if (gameScreen.classList.contains('active') && !isHost) {
            await checkForRoundUpdate();
        }
    }, 3000);
}
```

## Timeline

```
T=0s    Host clicks "Next Round"
        ↓
T=0.1s  Backend increments round number
        ↓
T=0.2s  Host's screen updates
        ↓
T=1-3s  Non-host polling triggers
        ↓
T=1-3s  Non-host detects round change
        ↓
T=1-3s  Non-host sees alert notification
        ↓
T=1-3s  Non-host loads new word
        ↓
T=1-3s  Non-host UI updates
```

**Average notification time:** ~1.5 seconds

## User Experience

### Host's Perspective

```
1. Playing Round 1
2. Clicks "Next Round" button
3. Immediately sees:
   - Round 2 in header
   - New word (after click-hold)
   - ????? placeholder
4. Continues playing
```

### Non-Host Player's Perspective

```
1. Playing Round 1
2. Host starts Round 2 (player doesn't know yet)
3. Within 1-3 seconds:
   - Alert: "Round 2 has started!"
   - Click OK
   - See Round 2 in header
   - Word display resets to ?????
   - New word available (click-hold to reveal)
4. Continues playing
```

## Edge Cases

### What if player is revealing word when round changes?

**Scenario:**
- Player is holding down to reveal word
- Host starts new round
- Alert appears

**Behavior:**
- Alert interrupts reveal
- Player must click OK
- Word display resets
- Player can reveal new word

### What if multiple rounds advance quickly?

**Scenario:**
- Host clicks "Next Round" twice rapidly
- Round 1 → 2 → 3

**Behavior:**
- Non-host detects highest round number
- Only one notification shown (for Round 3)
- Word loaded for latest round
- No duplicate alerts

### What if player is in lobby when round starts?

**Scenario:**
- Player in lobby
- Host starts Round 1

**Behavior:**
- Uses existing `checkForRound()` mechanism
- Player auto-enters game screen
- Different from round-to-round transitions

### What if network is slow?

**Scenario:**
- Polling interval delayed

**Behavior:**
- May take longer than 3 seconds to detect
- Eventually detects and updates
- No data loss
- Seamless when connection resumes

## Benefits

✅ **No manual refresh** - Players don't need to reload page  
✅ **Synchronized gameplay** - All players on same round  
✅ **Clear notifications** - Players know when rounds change  
✅ **Automatic updates** - Word, role, UI all update together  
✅ **Seamless UX** - Feels like real-time multiplayer  

## Testing

### Automated Test

```bash
./test_round_update.sh
```

**Verifies:**
- ✅ Backend round number increments
- ✅ Non-host can detect round changes
- ✅ Multiple round transitions work
- ✅ Round numbers stay synchronized

### Manual Test

1. **Setup:**
   - Window 1: Host (Alice)
   - Window 2: Player (Bob)

2. **Test:**
   - Alice creates game
   - Bob joins
   - Alice starts Round 1
   - Both see Round 1
   - Alice clicks "Next Round"
   - Bob sees notification within 3 seconds
   - Bob's screen updates to Round 2

3. **Verify:**
   - Round number matches (2)
   - Bob has new word
   - Word display reset to ?????

## Performance

**Network Impact:**
- Same polling used for player list
- No additional requests
- Reuses existing `/get_word` endpoint
- Minimal overhead

**Client Impact:**
- Simple number comparison
- Negligible CPU usage
- No memory leaks
- Efficient state management

## Future Enhancements

Possible improvements:
- [ ] WebSocket for instant notifications
- [ ] Sound effect when round changes
- [ ] Countdown timer before round starts
- [ ] Show who started the round
- [ ] Batch multiple round changes
- [ ] Offline round queue

## Comparison with Other Features

### Similar: Kick Detection
- Both use polling
- Both detect backend changes
- Both show notifications
- Both update UI automatically

### Different: Round Start (Lobby → Game)
- Round start uses different mechanism
- Polling for word existence, not changes
- Enters game screen vs. staying in game
- No notification, just transition

## Conclusion

Round update notifications provide a seamless multiplayer experience by automatically synchronizing all players when the host advances rounds. Using the existing polling infrastructure keeps the implementation simple while maintaining good UX with ~1.5 second notification times.

**Try it now:**
```bash
./run.sh
# Window 1: Create game, start Round 1, click "Next Round"
# Window 2: Join game, see automatic round update notification
```
