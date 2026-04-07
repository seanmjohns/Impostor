# Kick Player Feature

## Overview

The kick player feature allows the game host to remove disruptive or inactive players from the game session.

## Why This Feature?

**Common Scenarios:**
- Player went AFK (away from keyboard)
- Wrong person joined the game
- Disruptive behavior
- Testing with dummy accounts
- Player asked to be removed

## How It Works

### API Endpoint

**POST /kick_player?playerId=<id>**

**Authentication:** Host session token required

**Parameters:**
- `playerId` - The ID of the player to remove

**Response:**
```json
{
  "success": true,
  "kickedPlayer": "player-id-123"
}
```

**Status Codes:**
- `200` - Player successfully kicked
- `400` - Invalid request (missing player, self-kick, or invalid session)
- `403` - Non-host attempted to kick (permission denied)
- `500` - Internal server error

## Frontend Implementation

### Visual Design

**Host View:**
```
Players
┌─────────────────────────────┐
│ Alice (You)        HOST     │  ← No kick button (yourself)
│ Bob                [Kick]   │  ← Red kick button
│ Charlie            [Kick]   │  ← Red kick button
└─────────────────────────────┘
3 players
```

**Non-Host View:**
```
Players
┌─────────────────────────────┐
│ Alice              HOST     │  ← No kick button
│ Bob (You)                   │  ← No kick button
│ Charlie                     │  ← No kick button
└─────────────────────────────┘
3 players
```

### Button Styling

```css
.kick-btn {
    background: #dc3545;    /* Red */
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.8em;
}

.kick-btn:hover {
    background: #c82333;    /* Darker red */
}
```

### User Flow

**Host Side:**
1. **Host clicks "Kick" button**
2. **Confirmation dialog appears**: "Kick [PlayerName] from the game?"
3. **Host confirms**: Player is removed
4. **Player list updates**: Kicked player disappears immediately

**Kicked Player Side:**
1. **Polling detects absence** from player list (~3 seconds)
2. **Alert notification**: "You have been removed from the game by the host."
3. **Auto-redirect**: Returns to home screen
4. **Session cleared**: All game state reset
5. **Can rejoin**: Use new name to rejoin if desired

## Security & Validation

### Permission Checks

✅ **Host verification**: Only host can kick  
✅ **Self-protection**: Cannot kick yourself  
✅ **Session validation**: Valid session token required  
✅ **Player existence**: Player must be in game  

### Backend Validation

```go
// 1. Verify requester is host
host, exists := game.GetPlayerByToken(hostToken)
if host.ID != game.HostID {
    return fmt.Errorf("only the host can kick players")
}

// 2. Prevent self-kick
if playerIDToKick == host.ID {
    return fmt.Errorf("cannot kick yourself")
}

// 3. Verify player exists
if _, exists := game.GetPlayer(playerIDToKick); !exists {
    return fmt.Errorf("player not found")
}

// 4. Remove player
delete(game.Players, playerIDToKick)
```

## Testing

### Run Tests

```bash
./test_kick.sh
```

### Test Scenarios

| Test | Expected Result | Status |
|------|----------------|--------|
| Host kicks player | Player removed | ✅ Pass |
| Non-host tries to kick | 403 Forbidden | ✅ Pass |
| Host tries to kick self | 400 Bad Request | ✅ Pass |
| Kick non-existent player | 400 Bad Request | ✅ Pass |
| Kicked player's token | 400 Invalid | ✅ Pass |
| Player count updates | Decrements by 1 | ✅ Pass |

### Manual Testing

1. **Setup:**
   - Start server: `./run.sh`
   - Open browser: Window 1 (Host)
   - Open browser: Window 2 (Player)

2. **Test Kick:**
   - Window 1: Create game as "Alice"
   - Window 2: Join game as "Bob"
   - Window 1: See "Kick" button next to Bob
   - Window 1: Click "Kick"
   - Window 1: Confirm dialog
   - Window 1: Bob disappears from list
   - Window 2: Disconnected (optional: redirect to home)

## Edge Cases

### What happens when...

**Host is kicked?**
- Cannot happen - host cannot kick themselves

**Last player is kicked?**
- Host remains alone in game
- Can continue or end game

**Player in middle of round is kicked?**
- Removed immediately
- Round continues without them
- May affect game balance

**Kicked player tries to rejoin?**
- Receives notification and returns to home
- Can rejoin with new name
- Gets new session token
- Treated as new player

**How long until kicked player is notified?**
- Up to 3 seconds (polling interval)
- Faster if they interact with game (triggers API call)
- Immediate if they're on a screen that polls players

**All non-host players are kicked?**
- Host remains alone
- Game is still valid
- Host can end game or wait for new players

## Best Practices

### When to Kick

✅ **Good reasons:**
- Player is AFK/unresponsive
- Wrong person joined
- Player requested to leave
- Testing/debugging
- Player being disruptive

❌ **Bad reasons:**
- Player is winning/losing
- Personal grudges
- Suspecting impostor (that's the game!)

### Communication

Before kicking:
1. Try to communicate with player
2. Ask if they're having issues
3. Give warning if behavior is problematic
4. Only kick as last resort

## Kick Notification System

### How It Works

Kicked players are notified through the existing polling mechanism:

1. **Player list polling** runs every 3 seconds
2. **Detection**: When `/players` endpoint is called:
   - Returns `400` if session is invalid
   - Player checks if their ID is in the player list
3. **Notification**: If player not found or session invalid:
   - Shows alert: "You have been removed from the game by the host."
   - Calls `handleKicked()` function
4. **Cleanup**: Resets all game state and returns to home

### Implementation

```javascript
async function updatePlayerList() {
    const response = await fetch('/players', {
        headers: { 'Authorization': sessionToken }
    });

    if (!response.ok) {
        // Session invalid - likely kicked
        handleKicked();
        return;
    }

    const data = await response.json();
    const stillInGame = data.players.some(p => p.id === playerId);
    
    if (!stillInGame && playerId) {
        // Not in player list - definitely kicked
        handleKicked();
        return;
    }
}

function handleKicked() {
    stopPolling();
    alert('You have been removed from the game by the host.');
    // Reset state and return home
    sessionToken = '';
    // ... clear other state
    showHome();
}
```

## Implementation Details

### Backend Flow

```
HTTP POST /kick_player?playerId=X
    ↓
Validate session token
    ↓
Verify host permissions
    ↓
Check not self-kick
    ↓
Verify player exists
    ↓
Delete player from game.Players map
    ↓
Return success response
    ↓
Kicked player's next polling request fails
    ↓
Frontend detects kick and notifies user
```

### Frontend Flow

```
Click "Kick" button
    ↓
Fetch player name for confirmation
    ↓
Show confirmation dialog
    ↓
User confirms
    ↓
POST to /kick_player
    ↓
Refresh player list
    ↓
Player removed from UI
```

### Data Changes

**Before Kick:**
```json
{
  "players": [
    {"id": "1", "name": "Alice", "isHost": true},
    {"id": "2", "name": "Bob", "isHost": false},
    {"id": "3", "name": "Charlie", "isHost": false}
  ],
  "playerCount": 3
}
```

**After Kicking Bob:**
```json
{
  "players": [
    {"id": "1", "name": "Alice", "isHost": true},
    {"id": "3", "name": "Charlie", "isHost": false}
  ],
  "playerCount": 2
}
```

## Future Enhancements

Possible improvements:
- [ ] Ban/block feature (prevent rejoin)
- [ ] Kick history/audit log
- [ ] Vote-kick (democratic removal)
- [ ] Temporary mute instead of kick
- [ ] Transfer host before self-kick
- [ ] Reason for kick (optional note)
- [ ] Notify kicked player with reason

## Troubleshooting

**"Only the host can kick players"**
- You are not the host
- Check if host badge appears next to your name

**"Cannot kick yourself"**
- Attempting to kick your own player ID
- End game instead if you want to leave

**"Player not found"**
- Player already left
- Player ID is invalid
- Refresh player list

**Kick button not appearing**
- You are not the host
- Looking at your own player entry
- UI not refreshed

## Conclusion

The kick player feature provides essential moderation tools for game hosts while maintaining security through proper permission checks and validation. It balances power (host control) with safety (cannot self-kick) for a smooth gaming experience.

**Try it now:**
```bash
./run.sh
# Create game as host
# Join with another browser
# Click "Kick" next to player
```
