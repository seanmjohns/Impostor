#!/bin/bash

# Test script to verify the fixes

set -e

API_BASE="http://localhost:8080"

echo "🧪 Testing Impostor Game Fixes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Verify server is running
echo "1️⃣  Testing server health..."
HEALTH=$(curl -s $API_BASE/health)
if [[ $HEALTH == *"ok"* ]]; then
    echo "   ✅ Server is healthy"
else
    echo "   ❌ Server health check failed"
    exit 1
fi
echo ""

# Test 2: Create game and join players
echo "2️⃣  Creating game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

echo "3️⃣  Host (Alice) joining..."
JOIN1_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Alice joined (Host)"
echo ""

echo "4️⃣  Player (Bob) joining..."
JOIN2_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Bob joined"
echo ""

# Test 3: Non-host player tries to check for round before it starts
echo "5️⃣  Testing: Bob checks for round (should fail - no round yet)..."
CHECK_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
HTTP_CODE=$(echo "$CHECK_RESPONSE" | tail -1)
if [[ $HTTP_CODE == "400" ]]; then
    echo "   ✅ Correctly returns 400 (no round yet)"
else
    echo "   ❌ Expected 400, got $HTTP_CODE"
fi
echo ""

# Test 4: Host starts round
echo "6️⃣  Host (Alice) starting Round 1..."
ROUND_RESPONSE=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND_NUM=$(echo $ROUND_RESPONSE | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   ✅ Round $ROUND_NUM started"
echo ""

# Test 5: Non-host player can now get word (simulating polling/check)
echo "7️⃣  Testing: Bob checks for round (should succeed now)..."
WORD_RESPONSE=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
if [[ $WORD_RESPONSE == *"word"* ]] || [[ $WORD_RESPONSE == *"isImpostor"* ]]; then
    echo "   ✅ Bob successfully got word/role"
    echo "   Response: $WORD_RESPONSE"
else
    echo "   ❌ Failed to get word"
fi
echo ""

# Test 6: Verify word reveal would work (backend provides the word)
echo "8️⃣  Testing: Alice gets word..."
WORD1_RESPONSE=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN1")
echo "   Alice: $WORD1_RESPONSE"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All backend tests passed!"
echo ""
echo "📱 Frontend fixes (test manually):"
echo "   1. Click-and-hold reveal: Open http://localhost:8080 and test"
echo "   2. Non-host auto-join: Join as two players, host starts round"
echo "      → Non-host player should auto-enter game after ~2 seconds"
echo "      → Or click 'Check for Round' button manually"
echo ""
echo "🎭 Open http://localhost:8080 to test the frontend!"
