# Player List Feature

## Overview

The player list feature shows all players in a game session, updating in real-time as players join or leave.

## API Endpoint

### GET /players

**Authentication:** Requires `Authorization` header with session token

**Response:**
```json
{
  "gameCode": "ABC123",
  "playerCount": 3,
  "players": [
    {
      "id": "player-id-1",
      "name": "Alice",
      "isHost": true
    },
    {
      "id": "player-id-2",
      "name": "Bob",
      "isHost": false
    },
    {
      "id": "player-id-3",
      "name": "Charlie",
      "isHost": false
    }
  ]
}
```

**Status Codes:**
- `200` - Successfully retrieved players
- `400` - Session not found or missing token
- `500` - Internal server error

## Frontend Implementation

### Display Locations

Player list appears in two places:

1. **Lobby Screen** - Shows who's waiting to start
2. **Game Screen** - Shows who's playing

### Visual Design

```
Players
┌────────────────────────┐
│ Alice (You)      HOST  │  ← Green border (you) + HOST badge
│ Bob                    │  ← Default border
│ Charlie                │  ← Default border
└────────────────────────┘
3 players
```

**Visual Indicators:**
- **Green border**: Current player (you)
- **Yellow border**: Host player
- **HOST badge**: Displayed next to host's name
- **Player count**: Shows total at bottom

### Auto-Update Mechanism

**Polling Schedule:**
- Polls `/players` endpoint every **3 seconds**
- Starts when entering lobby or game screen
- Stops when leaving game or returning home

**Functions:**
```javascript
startPlayerPolling()  // Begins polling
stopPlayerPolling()   // Stops polling
updatePlayerList()    // Fetches and updates UI
displayPlayers()      // Renders player list
```

## User Experience

### Joining a Game

1. **Player creates game** → Shows 1 player (themselves)
2. **Others join** → Player count increments automatically
3. **Real-time updates** → See players appear within 3 seconds

### During a Round

- Player list stays visible during gameplay
- Shows who's still in the game
- Host indicator helps identify who controls rounds

### Benefits

✅ **Social awareness** - Know who you're playing with  
✅ **Connection verification** - Confirm you're in the right game  
✅ **Host identification** - Know who can start rounds  
✅ **Player tracking** - See if someone left  
✅ **Real-time sync** - No manual refresh needed  

## Technical Details

### Backend (Go)

**File:** `internal/handlers/handlers.go`

```go
func (h *Handler) GetPlayers(w http.ResponseWriter, r *http.Request) {
    // Get game from session token
    game, _, err := h.gameManager.GetGameByToken(sessionToken)
    
    // Build player list (no role information)
    players := make([]PlayerInfo, 0, len(game.Players))
    for _, player := range game.Players {
        players = append(players, PlayerInfo{
            ID:     player.ID,
            Name:   player.Name,
            IsHost: player.ID == game.HostID,
        })
    }
    
    // Return response
    json.NewEncoder(w).Encode(response)
}
```

**Security:**
- ✅ Requires authentication (session token)
- ✅ Only returns player names and host status
- ✅ Never exposes roles (impostor/innocent)
- ✅ Validates session before returning data

### Frontend (JavaScript)

**Polling Implementation:**

```javascript
// Start polling when entering lobby/game
function startPlayerPolling() {
    stopPlayerPolling();
    updatePlayerList(); // Immediate update
    playerPollInterval = setInterval(async () => {
        await updatePlayerList();
    }, 3000); // Every 3 seconds
}

// Fetch and update
async function updatePlayerList() {
    const response = await fetch('/players', {
        headers: { 'Authorization': sessionToken }
    });
    const data = await response.json();
    displayPlayers(data.players, data.playerCount);
}
```

**CSS Styling:**

```css
.players-section { /* Container */ }
.player-list { /* List wrapper */ }
.player-item { /* Individual player */ }
.player-item.is-you { /* Green border */ }
.player-item.is-host { /* Yellow border */ }
.player-count { /* Count display */ }
```

## Testing

### Run Tests

```bash
./test_player_list.sh
```

**Test Coverage:**
- ✅ Single player (host)
- ✅ Multiple players joining
- ✅ Player count accuracy
- ✅ Host identification
- ✅ Invalid token handling
- ✅ Missing token handling
- ✅ Cross-session queries

### Manual Testing

1. Start server: `./run.sh`
2. Open browser: `http://localhost:8080`
3. Create game in window 1
4. Join game in window 2
5. Watch player list update in window 1 (~3 seconds)
6. Join from window 3
7. All windows show updated player list

## Performance

**Network Impact:**
- Request size: ~100 bytes (headers)
- Response size: ~50-200 bytes (depending on player count)
- Frequency: Every 3 seconds per player
- Total: Minimal overhead for 2-10 players

**Client Impact:**
- CPU: Negligible (simple DOM updates)
- Memory: <1KB per player
- UI: No visible lag or flicker

## Future Enhancements

Possible additions:
- [ ] Player avatars/icons
- [ ] Activity indicators (idle/active)
- [ ] Kick player (host only)
- [ ] Player join/leave notifications
- [ ] Custom player colors
- [ ] WebSocket for instant updates

## Conclusion

The player list feature provides essential social awareness for the game while maintaining security (no role leaks) and performance (efficient polling). It enhances the user experience by showing who's in the game at all times.

**Try it now:**
```bash
./run.sh  # Start server
# Open http://localhost:8080
```
