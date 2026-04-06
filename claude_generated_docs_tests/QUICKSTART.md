# Impostor - Quick Start Guide

Get up and running in 30 seconds!

## 🚀 Start the Server

```bash
./run.sh
```

That's it! Server runs on http://localhost:8080

## 🎮 Play the Game

### As Host

1. Open http://localhost:8080
2. Click **"Create New Game"**
3. Enter your name → You get a game code
4. Share the code with friends
5. Click **"Start Round 1"** when everyone joins
6. Click and hold the `?????` to see if you're an impostor
7. Click **"Next Round"** to continue playing

### As Player

1. Open http://localhost:8080
2. Click **"Join Game"**
3. Enter the game code + your name
4. Wait for host to start
5. Click and hold the `?????` to see your word or impostor status
6. If you don't like the word, click **"Skip Word"**

## 🎯 Game Rules

**Innocent Players**:
- You see a **word** (e.g., "banana")
- Describe the word without saying it
- Try to identify the impostors

**Impostors**:
- You see **"IMPOSTOR"** instead of a word
- Listen and blend in
- Try not to get caught!

## 💡 Tips

- **Hide your screen** when revealing
- Use **voice chat** (Discord/Zoom) for discussion
- Play with **4-8 players** for best experience
- Each player needs their **own device**

## 🧪 Test It

```bash
./test_api.sh  # Run automated API tests
```

## 📚 More Info

- [FRONTEND_README.md](FRONTEND_README.md) - Detailed frontend guide
- [BACKEND_README.md](BACKEND_README.md) - API documentation

## 🐛 Troubleshooting

**Can't connect?**
- Make sure the server is running (`./run.sh`)
- Check http://localhost:8080/health shows `{"status":"ok"}`

**Game not starting?**
- Only the host can start rounds
- Make sure at least one player has joined

**Word skip not working?**
- Impostors cannot skip
- Need 50% of innocent players to vote

---

**Have fun playing! 🎭**
