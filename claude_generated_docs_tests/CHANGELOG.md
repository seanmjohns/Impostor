# Changelog

All notable changes to the Impostor game will be documented in this file.

## [1.2.1] - 2026-04-05

### Added

#### Round Update Notifications
- **Auto-detection for non-host players**: When the host starts a new round, all other players are automatically notified
- **Polling mechanism**: Every 3 seconds, non-host players check for round number changes
- **Automatic word reload**: New word and role automatically loaded when round changes
- **Visual notification**: Alert shows "Round X has started!" to inform players
- **UI updates**: Round number and word display automatically reset

### Technical Details

**Frontend:**
```javascript
async function checkForRoundUpdate()  // Polls for round changes
async function handleNewRound(num)    // Handles new round notification
```

**Flow:**
1. Host clicks "Next Round"
2. Round number increments on backend
3. Non-host players poll `/get_word` every 3 seconds
4. Detect `roundNumber` has increased
5. Show notification and reload word
6. Update UI with new round number

**User Experience:**
- Non-host players see: "Round 2 has started!"
- Word display resets to `?????`
- New word/role loaded automatically
- Round number updates in header
- Seamless transition (1-3 second delay)

## [1.2.0] - 2026-04-05

### Added

#### Kick Player Feature
- **New API Endpoint**: `POST /kick_player?playerId=<id>`
  - Allows host to remove players from the game
  - Requires session token authentication
  - Validates host permissions
  - Prevents self-kicking

- **Frontend Kick Controls**
  - "Kick" button appears next to each player (host view only)
  - Red button styling for clear action indication
  - Confirmation dialog before kicking
  - Immediate player list refresh after kick
  - Kicked player's session becomes invalid

- **Kick Notifications**
  - Kicked players receive immediate notification
  - Alert message: "You have been removed from the game by the host."
  - Auto-detection via polling (within ~3 seconds)
  - Automatic redirect to home screen
  - Session cleared to prevent errors
  - Can rejoin with new name if desired

- **Security & Validation**
  - Only host can kick players
  - Cannot kick yourself
  - Validates player exists before kicking
  - Returns appropriate HTTP status codes

### Technical Details

**Backend:**
```go
// New method in game/manager.go
func (m *Manager) KickPlayer(game *Game, hostToken, playerIDToKick string)

// New handler in handlers.go
func (h *Handler) KickPlayer(w http.ResponseWriter, r *http.Request)
```

**Frontend:**
```javascript
async function kickPlayer(playerIdToKick)  // Kicks player with confirmation
```

**Visual Design:**
```
Players (Host View)
┌─────────────────────────┐
│ Alice (You)      HOST   │
│ Bob              [Kick] │ ← Red kick button
│ Charlie          [Kick] │
└─────────────────────────┘
```

### Validation Rules

1. **Authorization**: Must be authenticated (session token)
2. **Permission**: Only host can kick
3. **Self-protection**: Cannot kick yourself
4. **Existence**: Player must exist in game
5. **Confirmation**: Frontend confirms before kicking

### Error Handling

- `403 Forbidden` - Non-host attempts to kick
- `400 Bad Request` - Invalid player ID, missing parameter, or self-kick attempt
- `500 Internal Server Error` - Server error

### User Experience

**Host Actions:**
1. See "Kick" button next to all other players
2. Click "Kick" on a player
3. Confirm the kick action
4. Player is immediately removed
5. Player list updates automatically

**Kicked Player:**
1. Removed from game
2. Session token becomes invalid
3. Cannot rejoin with same session
4. Can rejoin with new name if desired

### Testing

Run the kick player test suite:
```bash
./test_kick.sh
```

**Test Coverage:**
- ✅ Host successfully kicks player
- ✅ Non-host blocked from kicking (403)
- ✅ Cannot kick yourself (400)
- ✅ Player count updates correctly
- ✅ Kicked player's token invalidated
- ✅ Player list refreshes after kick

## [1.1.0] - 2026-04-05

### Added

#### Player List Feature
- **New API Endpoint**: `GET /players`
  - Returns all players in the current session
  - Includes player ID, name, and host status
  - Requires session token authentication
  - Returns player count for convenience

- **Frontend Player Display**
  - Player list shown in both lobby and game screens
  - Auto-updates every 3 seconds via polling
  - Visual indicators:
    - Green border for "You" (current player)
    - Yellow border for host
    - Host badge displayed next to host's name
  - Shows real-time player count

- **Automatic Polling**
  - `startPlayerPolling()`: Polls `/players` every 3 seconds
  - `stopPlayerPolling()`: Stops polling when leaving game
  - Integrated with existing polling cleanup

### Technical Details

**Backend (Go):**
```go
// New handler in handlers.go
func (h *Handler) GetPlayers(w http.ResponseWriter, r *http.Request)
```

**Frontend (JavaScript):**
```javascript
async function updatePlayerList()      // Fetches from /players
function displayPlayers(players, count) // Updates UI
function startPlayerPolling()          // Starts polling
function stopPlayerPolling()           // Stops polling
```

**CSS Additions:**
- `.players-section` - Container styling
- `.player-list` - List styling
- `.player-item` - Individual player styling
- `.player-item.is-you` - Current player highlight (green)
- `.player-item.is-host` - Host indicator (yellow)
- `.player-count` - Player count display

### User Experience

**Lobby Screen:**
```
Players
┌──────────────────┐
│ Alice (You) HOST │ ← Green border, you are host
│ Bob              │
│ Charlie          │
└──────────────────┘
3 players
```

**Game Screen:**
```
Players
┌──────────────────┐
│ Alice      HOST  │ ← Yellow border, host
│ Bob (You)        │ ← Green border, you
│ Charlie          │
└──────────────────┘
3 players
```

### Benefits

- ✅ **Social awareness**: See who's in the game
- ✅ **Real-time updates**: Players auto-appear as they join
- ✅ **Clear host identification**: Know who controls the game
- ✅ **Connection verification**: Confirm you're in the right game
- ✅ **Player tracking**: See if someone left

## [1.0.2] - 2026-04-05

### Changed

#### UX Improvements
1. **Removed "Check for Round" button**
   - **Rationale**: Horrible UX - players shouldn't need a manual button
   - **Solution**: Automatic polling now handles round detection seamlessly
   - **Impact**: Non-host players automatically join rounds within ~2 seconds
   - Players see "Waiting for host to start the round..." message in lobby

2. **Separated End Game and Leave Game controls**
   - **Host players**: See "End Game" button (terminates game for everyone)
   - **Non-host players**: See "Leave Game" button (only they leave, game continues)
   - **Rationale**: Non-hosts shouldn't be able to end the game for everyone
   - **Impact**: Better control separation and prevents accidental game termination

3. **Hidden skip vote counts**
   - **Removed**: Vote count display (e.g., "Votes: 2/3")
   - **Rationale**: Showing vote counts can leak information about player roles
   - **Impact**: Players still get "Vote Recorded" feedback, but can't use vote math to deduce roles
   - Vote threshold logic still works server-side

### Technical Details

**Removed Elements:**
- `checkRoundBtn` button from lobby screen
- `skipVotes` display from skip section
- Vote count update logic in `voteSkip()` and `loadWord()`

**Updated Elements:**
- `showLobby()`: Simplified to only show start button for hosts
- `showGame()`: Conditional buttons based on `isHost` flag
  - Host: "Next Round" + "End Game"
  - Non-host: "Leave Game"

**Preserved Functionality:**
- Automatic polling (`startPolling()`) still active for non-hosts
- `checkForRound()` function kept for internal use
- All backend skip vote logic unchanged

## [1.0.1] - 2026-04-05

### Fixed

#### Issue #1: Click-and-Hold Word Reveal Not Working
- **Problem**: Word reveal on click-and-hold was not functioning
- **Root Cause**: Event handlers referenced stale DOM element after cloning
- **Solution**: 
  - Pass word as parameter to `setupRevealOnHold(word)` instead of reading from dataset
  - Ensure reveal/hide functions reference the fresh DOM element after cloning
  - Event listeners now correctly attached to the new element
- **Impact**: Word reveal now works correctly on both desktop (mouse) and mobile (touch)

#### Issue #2: Non-Host Players Stuck in Lobby
- **Problem**: When host started a round, other players remained in lobby with no notification
- **Root Cause**: No mechanism for non-host players to detect when a round started
- **Solution**:
  - Added **"Check for Round"** button for manual checking
  - Implemented **automatic polling** every 2 seconds for non-host players
  - Players auto-transition to game screen when round is detected
  - Added visual pulse animation to "Check for Round" button
  - Polling automatically starts when entering lobby and stops when leaving
- **Impact**: All players now seamlessly join rounds without manual coordination

### Technical Details

**setupRevealOnHold Fix:**
```javascript
// Before
function setupRevealOnHold() {
    const wordDisplay = document.getElementById('wordDisplay');
    const word = wordDisplay.dataset.word;
    function reveal() { wordDisplay.textContent = word; } // References old element
    // Clone happens here, breaking the reference
}

// After
function setupRevealOnHold(word) {
    // Clone first
    const display = document.getElementById('wordDisplay'); // Get new element
    function reveal() { display.textContent = word; } // References new element
}
```

**Round Detection Implementation:**
```javascript
// Auto-polling for non-host players
function startPolling() {
    pollInterval = setInterval(async () => {
        await checkForRound(true); // Silent check every 2 seconds
    }, 2000);
}

async function checkForRound(silent = false) {
    const response = await fetch('/get_word', ...);
    if (response.ok) {
        // Round found! Auto-enter game
        await loadWord();
        showGame();
    }
}
```

### Testing

All fixes verified with automated test suite:
```bash
./test_fixes.sh
```

**Test Coverage:**
- ✅ Server health check
- ✅ Game creation
- ✅ Multi-player joining
- ✅ Non-host blocked before round starts (returns 400)
- ✅ Host successfully starts round
- ✅ Non-host can retrieve word after round starts
- ✅ Word/role data correctly provided by backend

## [1.0.0] - 2026-04-05

### Added

#### Backend (Go)
- RESTful API with 6 endpoints
- In-memory session management
- Intelligent role assignment algorithm
  - Guarantees ≥1 impostor in 95%+ of rounds
  - Averages ~1 impostor per round
  - Adaptive probability based on player count
- Word list management (40+ files, 8000+ words)
- Voting-based word skipping system
- Session token authentication
- CORS support for frontend integration

#### Frontend (HTML/JavaScript)
- Single-page application with multiple screens
  - Home screen
  - Create/join game screens
  - Lobby with shareable links
  - Game screen with word reveal
- Click-and-hold word reveal for privacy
- Mobile-responsive design
- Touch event support for mobile devices
- Game code and URL sharing
- Host-only controls
- Word skip voting interface

#### Documentation
- README.md - Main project documentation
- BACKEND_README.md - API documentation
- FRONTEND_README.md - Frontend features guide
- QUICKSTART.md - 30-second setup guide
- DEMO.md - Live demo walkthrough
- PROJECT_SUMMARY.md - Complete project summary

#### Tools & Scripts
- Makefile - Build commands
- run.sh - Easy server launcher
- test_api.sh - Automated API testing
- .gitignore - Git ignore rules

### Features

**Game Flow:**
1. Create/join game with unique codes
2. Host starts rounds
3. Intelligent role assignment
4. Private word reveal
5. Word skip voting (50% threshold)
6. Next round progression

**Role Assignment:**
- Random player shuffling each round
- Starting probability: 30-50% (based on player count)
- Probability halves after each impostor assigned
- Fallback ensures ≥1 impostor if none assigned

**Word Skipping:**
- Only innocent players can vote
- Requires 50% of innocent players
- Roles reassigned on skip to prevent meta-gaming
- Real-time vote counter

### Architecture

**Backend:** Go HTTP server with in-memory storage
**Frontend:** Vanilla HTML/CSS/JavaScript
**API:** RESTful JSON API
**Auth:** Session token-based
**Storage:** In-memory (games lost on restart)

---

## Version Format

This project uses Semantic Versioning (SemVer): MAJOR.MINOR.PATCH

- **MAJOR**: Incompatible API changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)
