#!/bin/bash

# Test Player List Order Consistency

set -e

API_BASE="http://localhost:8080"

echo "📋 Testing Player List Order Consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create game
echo "1️⃣  Creating game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

# Players join in order: Alice, Bob, Charlie
echo "2️⃣  Players joining in order..."
echo "   Alice (host) joining..."
JOIN1=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
sleep 0.1  # Small delay to ensure different JoinedAt timestamps

echo "   Bob joining..."
curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob" > /dev/null
sleep 0.1

echo "   Charlie joining..."
curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie" > /dev/null
sleep 0.1

echo "   Dave joining..."
curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Dave" > /dev/null
echo ""

# Get player list multiple times and check order is consistent
echo "3️⃣  Fetching player list 5 times to verify order consistency..."
echo ""

for i in {1..5}; do
    PLAYERS=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN1")
    # Extract player names in order
    NAMES=$(echo $PLAYERS | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | tr '\n' ',' | sed 's/,$//')
    echo "   Attempt $i: $NAMES"

    # Store first result to compare
    if [ $i -eq 1 ]; then
        FIRST_ORDER=$NAMES
    fi

    # Check if order matches first result
    if [ "$NAMES" != "$FIRST_ORDER" ]; then
        echo ""
        echo "   ❌ FAIL: Order changed!"
        echo "   Expected: $FIRST_ORDER"
        echo "   Got:      $NAMES"
        exit 1
    fi

    # Small delay between requests
    sleep 0.2
done

echo ""
echo "   ✅ PASS: Player order is consistent across all requests"
echo ""

# Verify order is by join time (should be Alice, Bob, Charlie, Dave)
echo "4️⃣  Verifying order is by join time..."
if [[ $FIRST_ORDER == "Alice,Bob,Charlie,Dave" ]]; then
    echo "   ✅ PASS: Players ordered by join time"
    echo "   Order: Alice → Bob → Charlie → Dave"
else
    echo "   ❌ FAIL: Unexpected order"
    echo "   Expected: Alice,Bob,Charlie,Dave"
    echo "   Got:      $FIRST_ORDER"
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Player list order is stable!"
echo ""
echo "📱 Frontend Behavior:"
echo "   - Player list will not shift/reorder on each poll"
echo "   - Players appear in join order (oldest first)"
echo "   - Host is always first (joined first)"
echo "   - New players appear at bottom"
echo "   - Kicked players disappear without reordering others"
