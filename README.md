# Impostor
The classic Impostor social-deduction word game.

> **Quick Start**: See [QUICKSTART.md](QUICKSTART.md) for a 30-second setup guide!

## Features

- **Session-based gameplay**: Create and join games with unique game codes
- **Real-time player list**: See all players in the game, updates automatically
- **Host controls**: Kick players, start rounds, and manage the game
- **Intelligent role assignment**: Ensures at least 1 impostor 95% of the time
- **Voting-based word skipping**: Players can vote to skip difficult words
- **Real-time backend**: Go-based backend for fast, responsive gameplay
- **Mobile-friendly**: Clean, responsive UI that works on all devices

## Quick Start

### 1. Start the Backend

**Easiest way** (using the run script):

```bash
./run.sh        # Starts on port 8080
./run.sh 3000   # Custom port
```

**Or using Make**:

```bash
make run                  # Starts on port 8080
PORT=3000 make run-port   # Custom port
```

**Or directly**:

```bash
make build            # Build once
./bin/impostor        # Run on default port 8080
./bin/impostor -port 3000  # Run on custom port
```

### 2. Play the Game

1. Open `http://localhost:8080` in your browser
2. Click **"Create New Game"** and enter your name
3. Share the game code or link with friends
4. When everyone joins, click **"Start Round 1"**
5. Click and hold to reveal your word or impostor status
6. Discuss and try to identify the impostors!

### 3. Test with Multiple Players

Open multiple browser windows or use private/incognito mode to simulate multiple players:

```bash
# In different browser windows/tabs
http://localhost:8080  # Player 1 creates game
http://localhost:8080  # Player 2 joins with code
http://localhost:8080  # Player 3 joins with code
```

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - 30-second setup guide ⚡
- **[BACKEND_README.md](BACKEND_README.md)** - Backend API documentation and architecture
- **[FRONTEND_README.md](FRONTEND_README.md)** - Frontend features and game instructions
- **[PLAYER_LIST_FEATURE.md](PLAYER_LIST_FEATURE.md)** - Real-time player list documentation
- **[KICK_PLAYER_FEATURE.md](KICK_PLAYER_FEATURE.md)** - Host kick controls documentation
- **[KICK_NOTIFICATION_FLOW.md](KICK_NOTIFICATION_FLOW.md)** - How kick notifications work
- **[ROUND_UPDATE_NOTIFICATIONS.md](ROUND_UPDATE_NOTIFICATIONS.md)** - Auto-sync round changes
- **[DEMO.md](DEMO.md)** - Live demo walkthrough
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and bug fixes

## How It Works

**Backend (Go)**:
- RESTful API with in-memory session storage
- Intelligent role assignment (≥1 impostor, ~1 average)
- Word selection from 40+ curated word lists
- Voting-based word skipping with role reassignment

**Frontend (HTML/JS)**:
- Clean, mobile-friendly interface
- Click-and-hold word reveal for privacy
- Real-time game state synchronization
- Shareable game links

## Project Structure

```
.
├── cmd/server/          # Server entry point
├── internal/
│   ├── models/          # Data models
│   ├── game/            # Game logic
│   ├── handlers/        # HTTP handlers
│   └── wordlist/        # Word list management
├── wordlists/           # Word list files
├── index.html           # Web interface
└── Makefile            # Build commands
```

## Development

```bash
# Build
make build

# Run
make run

# Run tests
make test              # Run all unit tests
make test-verbose      # Run with verbose output

# Format code
make fmt
```

### Testing

The project has comprehensive unit tests covering:
- Game creation and player management (12 player limit)
- Host reassignment when host leaves
- Role assignment algorithm
- Word skipping with notifications
- Session management and security

See **[TESTING.md](TESTING.md)** for detailed testing documentation.

```bash
# Run all tests
make test

# Run specific package tests
go test ./internal/models -v
go test ./internal/game -v
go test ./internal/wordlist -v

# Integration tests
./test_host_reassignment.sh
./test_word_skip_notification.sh
./test_player_order.sh
```
