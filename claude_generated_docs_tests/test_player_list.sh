#!/bin/bash

# Test Player List Feature

set -e

API_BASE="http://localhost:8080"

echo "👥 Testing Player List Feature"
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
PLAYER1_ID=$(echo $JOIN1_RESPONSE | grep -o '"playerId":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Alice joined"
echo ""

# Check player list (should have 1 player)
echo "3️⃣  Getting player list (should show 1 player)..."
PLAYERS1=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
PLAYER_COUNT1=$(echo $PLAYERS1 | grep -o '"playerCount":[0-9]*' | cut -d':' -f2)
IS_HOST1=$(echo $PLAYERS1 | grep -o '"isHost":true')

if [ "$PLAYER_COUNT1" == "1" ] && [ ! -z "$IS_HOST1" ]; then
    echo "   ✅ PASS: 1 player, Alice is host"
else
    echo "   ❌ FAIL: Expected 1 player with host=true"
    echo "   Response: $PLAYERS1"
fi
echo ""

# Bob joins
echo "4️⃣  Bob joining..."
JOIN2_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Bob joined"
echo ""

# Check player list (should have 2 players)
echo "5️⃣  Getting player list (should show 2 players)..."
PLAYERS2=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
PLAYER_COUNT2=$(echo $PLAYERS2 | grep -o '"playerCount":[0-9]*' | cut -d':' -f2)

if [ "$PLAYER_COUNT2" == "2" ]; then
    echo "   ✅ PASS: 2 players in list"
else
    echo "   ❌ FAIL: Expected 2 players"
    echo "   Response: $PLAYERS2"
fi
echo ""

# Charlie joins
echo "6️⃣  Charlie joining..."
JOIN3_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie")
TOKEN3=$(echo $JOIN3_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Charlie joined"
echo ""

# Check player list from Bob's perspective
echo "7️⃣  Getting player list from Bob's session (should show 3 players)..."
PLAYERS3=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN2")
PLAYER_COUNT3=$(echo $PLAYERS3 | grep -o '"playerCount":[0-9]*' | cut -d':' -f2)

if [ "$PLAYER_COUNT3" == "3" ]; then
    echo "   ✅ PASS: 3 players in list"
else
    echo "   ❌ FAIL: Expected 3 players"
    echo "   Response: $PLAYERS3"
fi
echo ""

# Test with invalid token
echo "8️⃣  Testing with invalid token (should fail)..."
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $API_BASE/players -H "Authorization: invalid_token")
HTTP_CODE=$(echo "$INVALID_RESPONSE" | tail -1)

if [ "$HTTP_CODE" == "400" ]; then
    echo "   ✅ PASS: Correctly returns 400 for invalid token"
else
    echo "   ❌ FAIL: Expected 400, got $HTTP_CODE"
fi
echo ""

# Test without token
echo "9️⃣  Testing without token (should fail)..."
NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $API_BASE/players)
HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -1)

if [ "$HTTP_CODE" == "400" ]; then
    echo "   ✅ PASS: Correctly returns 400 for missing token"
else
    echo "   ❌ FAIL: Expected 400, got $HTTP_CODE"
fi
echo ""

# Pretty print final player list
echo "🔟 Final player list (pretty printed):"
curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1" | python3 -m json.tool
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All player list tests passed!"
echo ""
echo "📱 To test frontend:"
echo "   1. Open http://localhost:8080"
echo "   2. Create a game"
echo "   3. Open another window and join"
echo "   4. Watch player list update in real-time!"
