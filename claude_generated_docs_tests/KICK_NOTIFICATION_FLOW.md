# Kick Notification Flow

## Visual Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     HOST KICKS PLAYER                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Host clicks "Kick" next to Bob's name                      │
│  Confirmation: "Kick Bob from the game?"                    │
│  Host clicks "OK"                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  POST /kick_player?playerId=bob-id                         │
│  Authorization: alice-session-token                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend validates:                                         │
│  ✓ Alice is host                                           │
│  ✓ Not kicking herself                                     │
│  ✓ Bob exists in game                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  delete(game.Players, "bob-id")                            │
│  Returns: {"success": true, "kickedPlayer": "bob-id"}      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Host's player list refreshes immediately                   │
│  Bob disappears from host's screen                         │
└─────────────────────────────────────────────────────────────┘

                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   BOB'S SIDE (Within ~3 seconds)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob's browser polls: GET /players                          │
│  Authorization: bob-session-token                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend checks: Is bob-id still in game?                   │
│  Result: NO (Bob was deleted)                               │
│  Returns: 400 Bad Request "Session not found"              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob's frontend detects:                                    │
│  - response.ok = false (400 error)                         │
│  - Calls handleKicked()                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  handleKicked() executes:                                   │
│  1. stopPolling() - Stop all polling                       │
│  2. alert("You have been removed...")                      │
│  3. Clear session: sessionToken = ''                       │
│  4. Clear game state: playerId = '', gameCode = '', etc.   │
│  5. showHome() - Navigate to home screen                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob sees:                                                  │
│  [!] Alert: "You have been removed from the game           │
│              by the host."                                  │
│  [OK]                                                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob clicks "OK"                                            │
│  Browser shows home screen:                                 │
│    🎭 Impostor                                              │
│    [Create New Game]                                        │
│    [Join Game]                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Bob can now:                                               │
│  - Create a new game                                        │
│  - Join a different game                                    │
│  - Rejoin same game with different name (if allowed)       │
└─────────────────────────────────────────────────────────────┘
```

## Timeline

```
T=0s    Host clicks "Kick" on Bob
        ↓
T=0.1s  Backend removes Bob from game.Players
        ↓
T=0.2s  Host's screen refreshes (Bob gone)
        ↓
T=1-3s  Bob's polling interval triggers
        ↓
T=1-3s  Bob's GET /players returns 400
        ↓
T=1-3s  Bob sees alert notification
        ↓
T=1-3s  Bob clicks OK, returns to home
```

**Average notification time:** ~1.5 seconds (middle of 0-3s polling window)

## Detection Methods

Bob's kick is detected via **two possible paths**:

### Path 1: Session Invalid (Primary)
```javascript
const response = await fetch('/players', {
    headers: { 'Authorization': sessionToken }
});

if (!response.ok) {  // 400 - session invalid
    handleKicked();
}
```

### Path 2: Not in Player List (Secondary)
```javascript
const data = await response.json();
const stillInGame = data.players.some(p => p.id === playerId);

if (!stillInGame && playerId) {  // Not in list
    handleKicked();
}
```

**Why two methods?**
- **Path 1** catches kicks immediately (session invalidated)
- **Path 2** is a safety net in case session somehow remains valid

## State Cleanup

When kicked, all state is cleared:

```javascript
sessionToken = '';      // Invalidate session
playerId = '';          // Clear identity
playerName = '';        // Clear name
gameCode = '';          // Leave game
isHost = false;         // Reset permissions
currentRound = 0;       // Clear round
isImpostor = false;     // Clear role
hasSkipped = false;     // Reset vote
```

This ensures:
- No orphaned sessions
- Clean state for rejoining
- No errors from stale data

## User Experience

**For the Kicked Player:**
```
1. Playing game normally
   ↓
2. Screen shows: "You have been removed from the game by the host."
   ↓
3. Click OK
   ↓
4. Back at home screen
   ↓
5. Can rejoin or find different game
```

**Timing:**
- Fast enough to feel immediate (1-3 seconds)
- Not so instant that it's jarring
- Gives user time to finish current action

## Alternative Approaches Considered

### ❌ WebSocket Real-Time Notification
**Pros:** Instant notification  
**Cons:** More complex, requires WebSocket infrastructure  
**Decision:** Polling is sufficient (1-3s delay acceptable)

### ❌ Long Polling
**Pros:** Faster than regular polling  
**Cons:** More server resources, minimal benefit  
**Decision:** 3-second polling is adequate

### ❌ No Notification
**Pros:** Simpler implementation  
**Cons:** Player confused by errors  
**Decision:** Notification is essential UX

### ✅ Polling Detection (Chosen)
**Pros:** Simple, reuses existing infrastructure  
**Cons:** 1-3 second delay  
**Decision:** Best balance of simplicity and UX

## Testing

### Automated Test
```bash
./test_kick_notification.sh
```

Verifies:
- ✅ Kicked player's session becomes invalid
- ✅ Kicked player not in player list
- ✅ Backend returns 400 for kicked player

### Manual Test
1. Open two browser windows
2. Window 1: Host creates game
3. Window 2: Player joins
4. Window 1: Kick player
5. Window 2: See notification within 3 seconds

## Conclusion

The kick notification system provides:
- **Immediate feedback** to kicked players
- **Clean state management** preventing errors
- **Simple implementation** using existing polling
- **Good UX** with clear messaging

Players always know their status and can quickly recover from being kicked.
