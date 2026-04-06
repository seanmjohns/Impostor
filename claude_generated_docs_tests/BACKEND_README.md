# Impostor Backend

A Go-based backend service for the Impostor social deduction word game.

## Features

- **Session/Room Management**: Players can create and join games using unique game codes
- **Role Assignment**: Intelligent role assignment ensuring at least 1 impostor 95% of the time
- **Word Skipping**: Voting-based word skipping system for innocent players
- **Real-time Sessions**: Games are held in memory for fast, real-time gameplay

## API Endpoints

### POST /create_game
Creates a new game session and returns a unique game code.

**Response:**
```json
{
  "gameCode": "ABC123"
}
```

### POST /join_game?gameCode=<code>&name=<name>
Joins a game session with the specified game code and player name.

**Response:**
```json
{
  "sessionToken": "...",
  "playerId": "...",
  "playerName": "...",
  "gameCode": "ABC123",
  "isHost": true
}
```

### POST /next_round
Advances to the next round (host only). Requires `Authorization` header with session token.

**Response:**
```json
{
  "success": true,
  "roundNumber": 1
}
```

### GET /get_word
Retrieves the word for the current round. Requires `Authorization` header with session token.

**Response (Innocent):**
```json
{
  "isImpostor": false,
  "word": "apple",
  "roundNumber": 1
}
```

**Response (Impostor):**
```json
{
  "isImpostor": true,
  "roundNumber": 1
}
```

### POST /vote_word_skip
Votes to skip the current word (innocent players only). Requires `Authorization` header with session token.

**Response:**
```json
{
  "success": true,
  "skipped": false,
  "skipVotes": 1
}
```

### POST /kick_player?playerId=<id>
Kicks a player from the game (host only). Requires `Authorization` header with session token.

**Parameters:**
- `playerId` - ID of the player to kick

**Response:**
```json
{
  "success": true,
  "kickedPlayer": "player-id-123"
}
```

**Errors:**
- `403` - Only the host can kick players
- `400` - Cannot kick yourself, player not found, or session not found

### GET /players
Retrieves all players in the current session. Requires `Authorization` header with session token.

**Response:**
```json
{
  "gameCode": "ABC123",
  "playerCount": 3,
  "players": [
    {
      "id": "...",
      "name": "Alice",
      "isHost": true
    },
    {
      "id": "...",
      "name": "Bob",
      "isHost": false
    },
    {
      "id": "...",
      "name": "Charlie",
      "isHost": false
    }
  ]
}
```

## Running the Server

### Build
```bash
go build -o bin/impostor ./cmd/server
```

### Run
```bash
./bin/impostor
```

### Environment Variables
- `PORT`: Server port (default: 8080)
- `WORDLIST_DIR`: Directory containing word list files (default: ./wordlists)
- `STATIC_DIR`: Directory containing static files (default: .)

### Example
```bash
PORT=3000 WORDLIST_DIR=./wordlists ./bin/impostor
```

## Development

### Project Structure
```
.
├── cmd/
│   └── server/          # Main server entry point
├── internal/
│   ├── models/          # Data models
│   ├── game/            # Game logic and management
│   ├── handlers/        # HTTP handlers
│   └── wordlist/        # Wordlist loading
├── wordlists/           # Word list files
└── index.html           # Frontend (optional)
```

### Role Assignment Algorithm

The role assignment algorithm ensures:
- At least 1 impostor in 95%+ of games
- On average, 1 impostor per game
- Starting probability adjusted based on player count
- Probability reduced by 50% after each impostor assignment

### Testing
```bash
go test ./...
```

## Architecture

The backend uses an in-memory data store for game sessions, making it:
- Fast and responsive
- Simple to deploy
- Suitable for moderate traffic

Note: Game state is lost on server restart. For production use with persistent state, consider adding a database layer.
