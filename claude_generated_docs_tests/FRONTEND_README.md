# Impostor Frontend

A web-based frontend for the Impostor social deduction game, fully integrated with the Go backend.

## Features

- **Create & Join Games**: Simple interface for creating new games or joining existing ones with a game code
- **Player Management**: Enter your name and see your role (host or player)
- **Game Lobby**: Share game codes and links with friends
- **Round System**: Host can start rounds, all players get their words or impostor status
- **Word Reveal**: Click and hold to reveal your word/status privately
- **Word Skipping**: Innocent players can vote to skip difficult words (50% threshold)
- **Mobile Friendly**: Responsive design works on phones, tablets, and desktops

## How to Play

### Creating a Game

1. Click **"Create New Game"**
2. Enter your name
3. Share the game code or link with friends
4. When everyone has joined, click **"Start Round 1"** (host only)

### Joining a Game

1. Click **"Join Game"**
2. Enter the game code (6 characters) provided by the host
3. Enter your name
4. Wait in the lobby for the host to start the round

### Playing a Round

1. **Reveal Your Role**: Click and hold the `?????` box to see your word or impostor status
   - **Innocent Players**: You'll see a word - discuss it with others without saying the word
   - **Impostors**: You'll see "IMPOSTOR" - try to blend in without knowing the word

2. **Skip a Word** (Innocent players only):
   - If you don't like the word, click **"Skip Word"**
   - When 50% of innocent players vote to skip, a new word is assigned
   - Roles are reassigned to prevent vote counting from revealing impostor info

3. **Next Round** (Host only):
   - After discussion and voting, the host can start the next round
   - New word and roles are assigned

## Game Flow

```
Create/Join Game
      ↓
   Lobby (waiting for host)
      ↓
Start Round (host only)
      ↓
Players reveal words/impostor status
      ↓
Discussion and deduction
      ↓
Optional: Vote to skip word
      ↓
Next Round (host only) or End Game
```

## Features Explained

### Session Management

- Each player gets a unique session token when joining
- Session token is stored in memory (lost on page refresh - rejoin if needed)
- Only the host can start/advance rounds

### Role Assignment

The backend uses an intelligent algorithm:
- At least 1 impostor in 95%+ of rounds
- On average, 1 impostor per round
- Probability adjusted based on player count
- Roles are reassigned each round (or when word is skipped)

### Word Skipping

- Only innocent players can vote to skip
- Requires 50% of innocent players to agree
- Impostors cannot vote (would be too easy!)
- When skipped, roles are reassigned to prevent meta-gaming
- Vote count is displayed for transparency

### Privacy

- Click-and-hold reveal prevents accidental word exposure
- Works with both mouse and touch on mobile
- Players should physically hide their screens during reveal

## URL Sharing

Game URLs are shareable:
- `?gameCode=ABC123` - Join game ABC123 in lobby
- Share via the "Copy Link" button in the lobby

## Browser Compatibility

- Modern browsers (Chrome, Firefox, Safari, Edge)
- JavaScript required
- No cookies, uses sessionStorage for state

## Running Locally

1. Start the backend server:
   ```bash
   ./bin/impostor
   ```

2. Open in browser:
   ```
   http://localhost:8080
   ```

3. For testing multiple players, use:
   - Multiple browser windows
   - Incognito/private windows
   - Different devices on the same network

## Tips for Best Experience

- **Use different devices**: Each player should use their own phone/tablet/computer
- **Private screens**: Make sure others can't see your screen when revealing
- **Good internet**: Local network or fast internet for best experience
- **Communication**: Use voice chat (Discord, Zoom) or play in-person
- **Group size**: 4-8 players is ideal

## Customization

The frontend can be customized by editing `index.html`:
- **Colors**: Modify the CSS variables in the `<style>` section
- **API endpoint**: Change `API_BASE` if backend is on a different server
- **Text/labels**: Update the HTML content directly

## API Integration

The frontend uses these backend endpoints:
- `POST /create_game` - Create new game
- `POST /join_game?gameCode=X&name=Y` - Join game
- `POST /next_round` - Start/advance round (requires session token)
- `GET /get_word` - Get word or impostor status (requires session token)
- `POST /vote_word_skip` - Vote to skip (requires session token)

Session tokens are sent via the `Authorization` header.
