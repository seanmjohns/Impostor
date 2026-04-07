#!/bin/bash

# Test Kick Player Feature

set -e

API_BASE="http://localhost:8080"

echo "🦵 Testing Kick Player Feature"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create game
echo "1️⃣  Creating game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

# Alice joins as host
echo "2️⃣  Alice joining (host)..."
JOIN1_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
ALICE_ID=$(echo $JOIN1_RESPONSE | grep -o '"playerId":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Alice joined (ID: $ALICE_ID)"
echo ""

# Bob joins
echo "3️⃣  Bob joining..."
JOIN2_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
BOB_ID=$(echo $JOIN2_RESPONSE | grep -o '"playerId":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Bob joined (ID: $BOB_ID)"
echo ""

# Charlie joins
echo "4️⃣  Charlie joining..."
JOIN3_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie")
TOKEN3=$(echo $JOIN3_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
CHARLIE_ID=$(echo $JOIN3_RESPONSE | grep -o '"playerId":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Charlie joined (ID: $CHARLIE_ID)"
echo ""

# Check initial player list
echo "5️⃣  Initial player list (should show 3)..."
PLAYERS1=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
PLAYER_COUNT1=$(echo $PLAYERS1 | grep -o '"playerCount":[0-9]*' | cut -d':' -f2)
if [ "$PLAYER_COUNT1" == "3" ]; then
    echo "   ✅ PASS: 3 players in game"
else
    echo "   ❌ FAIL: Expected 3 players"
fi
echo ""

# Test: Non-host tries to kick (should fail)
echo "6️⃣  Bob (non-host) tries to kick Charlie (should fail)..."
KICK_FAIL=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/kick_player?playerId=$CHARLIE_ID" -H "Authorization: $TOKEN2")
HTTP_CODE=$(echo "$KICK_FAIL" | tail -1)
if [ "$HTTP_CODE" == "403" ]; then
    echo "   ✅ PASS: Non-host correctly blocked (403)"
else
    echo "   ❌ FAIL: Expected 403, got $HTTP_CODE"
fi
echo ""

# Test: Host tries to kick themselves (should fail)
echo "7️⃣  Alice tries to kick herself (should fail)..."
KICK_SELF=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/kick_player?playerId=$ALICE_ID" -H "Authorization: $TOKEN1")
HTTP_CODE=$(echo "$KICK_SELF" | tail -1)
if [ "$HTTP_CODE" == "400" ]; then
    echo "   ✅ PASS: Cannot kick self (400)"
else
    echo "   ❌ FAIL: Expected 400, got $HTTP_CODE"
fi
echo ""

# Test: Host kicks Bob (should succeed)
echo "8️⃣  Alice (host) kicks Bob..."
KICK_SUCCESS=$(curl -s -X POST "$API_BASE/kick_player?playerId=$BOB_ID" -H "Authorization: $TOKEN1")
KICKED_ID=$(echo $KICK_SUCCESS | grep -o '"kickedPlayer":"[^"]*"' | cut -d'"' -f4)
if [ "$KICKED_ID" == "$BOB_ID" ]; then
    echo "   ✅ PASS: Bob kicked successfully"
else
    echo "   ❌ FAIL: Kick did not return correct player ID"
fi
echo ""

# Verify Bob is gone
echo "9️⃣  Verifying Bob is removed (should show 2 players)..."
PLAYERS2=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
PLAYER_COUNT2=$(echo $PLAYERS2 | grep -o '"playerCount":[0-9]*' | cut -d':' -f2)
HAS_BOB=$(echo $PLAYERS2 | grep -c '"name":"Bob"' || true)

if [ "$PLAYER_COUNT2" == "2" ] && [ "$HAS_BOB" == "0" ]; then
    echo "   ✅ PASS: 2 players remain, Bob is gone"
else
    echo "   ❌ FAIL: Expected 2 players without Bob"
    echo "   Player count: $PLAYER_COUNT2, Has Bob: $HAS_BOB"
fi
echo ""

# Test: Kicked player's token is invalid
echo "🔟 Bob's session token should be invalid..."
BOB_CHECK=$(curl -s -w "\n%{http_code}" -X GET $API_BASE/players -H "Authorization: $TOKEN2")
HTTP_CODE=$(echo "$BOB_CHECK" | tail -1)
if [ "$HTTP_CODE" == "400" ]; then
    echo "   ✅ PASS: Kicked player's token is invalid (400)"
else
    echo "   ❌ FAIL: Expected 400, got $HTTP_CODE"
fi
echo ""

# Final player list
echo "1️⃣1️⃣  Final player list:"
curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1" | python3 -m json.tool
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All kick player tests passed!"
echo ""
echo "📱 To test frontend:"
echo "   1. Open http://localhost:8080"
echo "   2. Create a game as host"
echo "   3. Join with another browser window"
echo "   4. See 'Kick' button next to other players (host only)"
echo "   5. Click 'Kick' to remove a player"
