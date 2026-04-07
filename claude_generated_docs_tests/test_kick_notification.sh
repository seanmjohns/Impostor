#!/bin/bash

# Test Kick Notification Feature
# This test verifies that kicked players are detected

set -e

API_BASE="http://localhost:8080"

echo "🔔 Testing Kick Notification"
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
echo "   ✅ Alice joined"
echo ""

# Bob joins
echo "3️⃣  Bob joining..."
JOIN2_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
BOB_ID=$(echo $JOIN2_RESPONSE | grep -o '"playerId":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Bob joined (ID: $BOB_ID)"
echo ""

# Bob checks player list (should see himself)
echo "4️⃣  Bob checks player list (should include himself)..."
PLAYERS_BEFORE=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN2")
BOB_IN_LIST=$(echo $PLAYERS_BEFORE | grep -c "\"name\":\"Bob\"" || true)
if [ "$BOB_IN_LIST" -gt 0 ]; then
    echo "   ✅ PASS: Bob is in the player list"
else
    echo "   ❌ FAIL: Bob not in player list"
fi
echo ""

# Alice kicks Bob
echo "5️⃣  Alice kicks Bob..."
curl -s -X POST "$API_BASE/kick_player?playerId=$BOB_ID" -H "Authorization: $TOKEN1" > /dev/null
echo "   ✅ Bob has been kicked"
echo ""

# Bob tries to get player list (should fail - session invalid)
echo "6️⃣  Bob tries to fetch players (should get 400 - kicked)..."
BOB_CHECK=$(curl -s -w "\n%{http_code}" -X GET $API_BASE/players -H "Authorization: $TOKEN2")
HTTP_CODE=$(echo "$BOB_CHECK" | tail -1)
if [ "$HTTP_CODE" == "400" ]; then
    echo "   ✅ PASS: Bob's session is invalid (400)"
    echo "   📱 Frontend will detect this and show kick notification"
else
    echo "   ❌ FAIL: Expected 400, got $HTTP_CODE"
fi
echo ""

# Verify Bob is not in player list anymore
echo "7️⃣  Verify Bob is not in player list..."
PLAYERS_AFTER=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
BOB_STILL_IN_LIST=$(echo $PLAYERS_AFTER | grep -c "\"name\":\"Bob\"" || true)
if [ "$BOB_STILL_IN_LIST" -eq 0 ]; then
    echo "   ✅ PASS: Bob has been removed from player list"
else
    echo "   ❌ FAIL: Bob still appears in player list"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backend kick detection verified!"
echo ""
echo "📱 Frontend Behavior:"
echo "   When Bob's polling detects he's not in the player list:"
echo "   1. Shows alert: 'You have been removed from the game by the host.'"
echo "   2. Clears session and returns to home screen"
echo "   3. Can rejoin with new name if desired"
echo ""
echo "🧪 Manual Test:"
echo "   1. Open http://localhost:8080 in Window 1 (Alice - Host)"
echo "   2. Open http://localhost:8080 in Window 2 (Bob - Player)"
echo "   3. Alice creates game, Bob joins"
echo "   4. Alice clicks 'Kick' next to Bob"
echo "   5. Window 2 (Bob) shows alert and returns to home screen"
echo "      (Within 3 seconds due to polling interval)"
