#!/bin/bash

# Test Word Skip Notification
# Verifies that when a word is skipped, the skipCount increments
# and other players can detect the change via polling

set -e

API_BASE="http://localhost:8080"

echo "🔄 Testing Word Skip Notification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create game
echo "1️⃣  Creating game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

# Alice joins (host, innocent)
echo "2️⃣  Alice joining..."
JOIN1=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   Alice's token: ${TOKEN1:0:10}..."
echo ""

# Bob joins (will be innocent)
echo "3️⃣  Bob joining..."
JOIN2=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   Bob's token: ${TOKEN2:0:10}..."
echo ""

# Charlie joins
echo "4️⃣  Charlie joining..."
JOIN3=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie")
TOKEN3=$(echo $JOIN3 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   Charlie's token: ${TOKEN3:0:10}..."
echo ""

# Dave joins
echo "5️⃣  Dave joining..."
JOIN4=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Dave")
TOKEN4=$(echo $JOIN4 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   Dave's token: ${TOKEN4:0:10}..."
echo ""

# Alice starts round 1
echo "6️⃣  Alice starting Round 1..."
curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1" > /dev/null
echo "   Round started!"
echo ""

# Check initial skipCount for all players
echo "7️⃣  Checking initial skipCount..."
WORD1=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN1")
SKIP1=$(echo $WORD1 | grep -o '"skipCount":[0-9]*' | cut -d':' -f2)
echo "   All players' skipCount: $SKIP1"

if [ "$SKIP1" != "0" ]; then
    echo ""
    echo "   ❌ FAIL: Initial skipCount should be 0"
    exit 1
fi
echo "   ✅ Initial skipCount: 0"
echo ""

# Try to get 2 innocent players to vote (with 4 players, we have 3 innocents)
# We'll vote until we trigger a skip
echo "8️⃣  Voting to skip word..."
echo "   Trying Bob..."
VOTE1=$(curl -s -X POST $API_BASE/vote_word_skip -H "Authorization: $TOKEN2")
if echo $VOTE1 | grep -q '"success":true'; then
    echo "   ✅ Bob voted (innocent player)"
    BOB_SKIPPED=$(echo $VOTE1 | grep -o '"skipped":true')
else
    echo "   ⚠️  Bob is impostor, trying Charlie..."
fi

if [ -z "$BOB_SKIPPED" ]; then
    echo "   Trying Charlie..."
    VOTE2=$(curl -s -X POST $API_BASE/vote_word_skip -H "Authorization: $TOKEN3")
    if echo $VOTE2 | grep -q '"success":true'; then
        echo "   ✅ Charlie voted"
        CHARLIE_SKIPPED=$(echo $VOTE2 | grep -o '"skipped":true')
    else
        echo "   ⚠️  Charlie is impostor, trying Dave..."
    fi
fi

# Check if skip was triggered
if [ -n "$BOB_SKIPPED" ] || [ -n "$CHARLIE_SKIPPED" ]; then
    echo "   ✅ Word skipped successfully!"
else
    # Need one more vote
    echo "   Trying Dave..."
    VOTE3=$(curl -s -X POST $API_BASE/vote_word_skip -H "Authorization: $TOKEN4")
    DAVE_SKIPPED=$(echo $VOTE3 | grep -o '"skipped":true')
    if [ -n "$DAVE_SKIPPED" ]; then
        echo "   ✅ Word skipped successfully!"
    else
        echo "   ❌ FAIL: Unable to trigger word skip"
        exit 1
    fi
fi
echo ""

# Check skipCount incremented for all players
echo "9️⃣  Checking skipCount after skip..."
WORD_AFTER=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN1")
SKIP_AFTER=$(echo $WORD_AFTER | grep -o '"skipCount":[0-9]*' | cut -d':' -f2)
echo "   All players' skipCount: $SKIP_AFTER"

if [ "$SKIP_AFTER" != "1" ]; then
    echo ""
    echo "   ❌ FAIL: skipCount should be 1 after skip"
    echo "   Got: $SKIP_AFTER"
    exit 1
fi
echo "   ✅ skipCount incremented to 1"
echo ""

# Verify round number stayed the same
echo "🔟 Verifying round number didn't change..."
ROUND_AFTER=$(echo $WORD_AFTER | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)

if [ "$ROUND_AFTER" != "1" ]; then
    echo "   ❌ FAIL: Round number should still be 1"
    exit 1
fi
echo "   ✅ Round number stayed at 1"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Word skip notification test passed!"
echo ""
echo "📱 Frontend Behavior:"
echo "   - When word is skipped, skipCount increments"
echo "   - All players can detect skipCount change via polling"
echo "   - Frontend shows alert and reloads word"
echo "   - Round number stays the same"
echo ""
