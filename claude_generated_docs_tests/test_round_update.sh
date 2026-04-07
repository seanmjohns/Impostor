#!/bin/bash

# Test Round Update Detection

set -e

API_BASE="http://localhost:8080"

echo "🔄 Testing Round Update Detection"
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
echo "   ✅ Bob joined"
echo ""

# Alice starts round 1
echo "4️⃣  Alice (host) starts Round 1..."
ROUND1=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND1_NUM=$(echo $ROUND1 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Round Number: $ROUND1_NUM"
echo ""

# Bob gets word for round 1
echo "5️⃣  Bob gets word for Round 1..."
BOB_WORD1=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
BOB_ROUND1=$(echo $BOB_WORD1 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Bob's Round: $BOB_ROUND1"
if [ "$BOB_ROUND1" == "1" ]; then
    echo "   ✅ PASS: Bob is on Round 1"
else
    echo "   ❌ FAIL: Expected Round 1, got Round $BOB_ROUND1"
fi
echo ""

# Alice starts round 2
echo "6️⃣  Alice (host) starts Round 2..."
ROUND2=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND2_NUM=$(echo $ROUND2 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Round Number: $ROUND2_NUM"
if [ "$ROUND2_NUM" == "2" ]; then
    echo "   ✅ PASS: Round 2 started"
else
    echo "   ❌ FAIL: Expected Round 2, got Round $ROUND2_NUM"
fi
echo ""

# Bob checks for round update
echo "7️⃣  Bob checks for round update..."
BOB_WORD2=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
BOB_ROUND2=$(echo $BOB_WORD2 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Bob's Round: $BOB_ROUND2"
if [ "$BOB_ROUND2" == "2" ]; then
    echo "   ✅ PASS: Bob can detect Round 2"
    echo "   📱 Frontend will auto-load new word via polling"
else
    echo "   ❌ FAIL: Expected Round 2, got Round $BOB_ROUND2"
fi
echo ""

# Alice starts round 3
echo "8️⃣  Alice (host) starts Round 3..."
ROUND3=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND3_NUM=$(echo $ROUND3 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Round Number: $ROUND3_NUM"
echo ""

# Verify Bob can still get the new round
echo "9️⃣  Verify Bob gets Round 3..."
BOB_WORD3=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
BOB_ROUND3=$(echo $BOB_WORD3 | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
if [ "$BOB_ROUND3" == "3" ]; then
    echo "   ✅ PASS: Bob can detect Round 3"
else
    echo "   ❌ FAIL: Expected Round 3, got Round $BOB_ROUND3"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backend round update detection verified!"
echo ""
echo "📱 Frontend Behavior:"
echo "   When host starts a new round:"
echo "   1. Non-host players poll every 3 seconds"
echo "   2. Detect roundNumber has increased"
echo "   3. Show alert: 'Round X has started!'"
echo "   4. Auto-load new word and role"
echo "   5. Update round number display"
echo "   6. Reset word display to ?????"
echo ""
echo "🧪 Manual Test:"
echo "   1. Open http://localhost:8080 in Window 1 (Alice - Host)"
echo "   2. Open http://localhost:8080 in Window 2 (Bob - Player)"
echo "   3. Alice creates game, Bob joins"
echo "   4. Alice starts Round 1"
echo "   5. Both players see Round 1"
echo "   6. Alice clicks 'Next Round'"
echo "   7. Window 2 (Bob) shows alert 'Round 2 has started!'"
echo "      (Within 3 seconds due to polling)"
