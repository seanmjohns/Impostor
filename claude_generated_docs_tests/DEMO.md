# Impostor - Live Demo Guide

Step-by-step guide to demonstrate the game.

## 🎬 Setup (5 seconds)

```bash
./run.sh
```

Server starts at http://localhost:8080

## 🎮 Demo Flow

### Part 1: Creating a Game (Host)

**Browser Window 1** - Alice (Host)
```
1. Open http://localhost:8080
2. Click "Create New Game"
3. Enter name: "Alice"
4. You see:
   ┌─────────────────────────┐
   │   🎭 Game Lobby         │
   │   Player: Alice [HOST]  │
   │                         │
   │   Game Code: ABC123     │
   │   [Copy Link]           │
   │                         │
   │   [Start Round 1]       │
   └─────────────────────────┘
```

### Part 2: Joining the Game (Players)

**Browser Window 2** - Bob
```
1. Open http://localhost:8080
2. Click "Join Game"
3. Enter code: "ABC123"
4. Enter name: "Bob"
5. Wait in lobby...
```

**Browser Window 3** - Charlie
```
1. Open http://localhost:8080
2. Click "Join Game"  
3. Enter code: "ABC123"
4. Enter name: "Charlie"
5. Wait in lobby...
```

### Part 3: Starting the Round (Host)

**Alice's Window**
```
1. Click "Start Round 1"
2. Screen changes to:
   ┌─────────────────────────┐
   │   🎭 Round 1            │
   │   Player: Alice         │
   │   Game Code: ABC123     │
   │                         │
   │   Don't show others!    │
   │   ┌─────────────────┐   │
   │   │     ?????       │   │
   │   └─────────────────┘   │
   │   👆 Click and hold     │
   │                         │
   │   [Skip Word]           │
   │   [Next Round] (Host)   │
   │   [End Game]            │
   └─────────────────────────┘
```

### Part 4: Revealing Words

**Alice** - Click and hold the `?????` box:
```
┌─────────────────┐
│    BANANA       │  ← Innocent (sees word)
└─────────────────┘
```

**Bob** - Click and hold:
```
┌─────────────────┐
│    BANANA       │  ← Innocent (same word)
└─────────────────┘
```

**Charlie** - Click and hold:
```
┌─────────────────┐
│   IMPOSTOR      │  ← Impostor! (no word)
└─────────────────┘
```

### Part 5: Discussion Phase

**In-Person or Voice Chat:**
- Alice: "Mine is yellow and curved..."
- Bob: "Yeah, mine is a fruit you peel..."
- Charlie (impostor): "Umm... yeah, sweet and... long?"
- Alice & Bob: "Charlie is sus! 🤔"

### Part 6: Word Skipping (Optional)

If the word is too hard:

**Bob clicks "Skip Word"**
```
Votes: 1
(Need 50% of innocent players)
```

**Alice clicks "Skip Word"**  
```
✅ Word skipped! Loading new word...
(Roles are reassigned)
```

### Part 7: Next Round

**Alice** (host) clicks "Next Round":
```
Round 2 starts
New word assigned
New roles assigned
All players reveal again...
```

## 🎯 What Makes It Fun

**Innocent Players:**
- Try to describe the word without saying it
- Watch for players who seem confused
- Vote out the impostor

**Impostors:**
- Listen carefully to others
- Try to blend in with vague descriptions
- Don't get caught!

## 📊 Expected Behavior

**Role Distribution (3 players):**
- ~95% of rounds: 1 impostor, 2 innocent
- ~5% of rounds: 0 impostors, 3 innocent (edge case)

**Word Skipping:**
- Only innocent players can vote
- Requires 50% of innocent votes (e.g., 1 out of 2)
- Roles are reassigned to prevent meta-gaming

## 🧪 Quick Test Commands

```bash
# Test 1: Health check
curl http://localhost:8080/health

# Test 2: Create game
curl -X POST http://localhost:8080/create_game

# Test 3: Full flow
./test_api.sh
```

## 💻 Multi-Device Setup

For the best experience:

**Option 1: Multiple Devices**
```
Device 1 (Phone): Alice (host)
Device 2 (Tablet): Bob
Device 3 (Laptop): Charlie
All connect to: http://YOUR_IP:8080
```

**Option 2: Same Computer**
```
Window 1: Normal browser (Alice)
Window 2: Incognito/Private (Bob)
Window 3: Different browser (Charlie)
```

## 🎭 Demo Tips

1. **Keep screens hidden** when revealing words
2. **Use voice chat** or play in-person for discussion
3. **Start with 4-6 players** for best experience
4. **Explain rules first**: Innocent see word, impostor doesn't
5. **Have fun!** It's a social game - laugh, accuse, deceive!

---

**Ready to demo? Run `./run.sh` and share your screen! 🎬**
