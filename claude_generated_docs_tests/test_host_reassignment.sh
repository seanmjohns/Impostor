#!/bin/bash

# Test Host Reassignment and Player Limit
# Verifies that when host leaves, next player becomes host
# And that games are limited to 12 players

set -e

API_BASE="http://localhost:8080"

echo "🔄 Testing Host Reassignment and Player Limit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create game
echo "1️⃣  Creating game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

# Alice joins (will be host)
echo "2️⃣  Alice joining as host..."
JOIN1=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
IS_HOST1=$(echo $JOIN1 | grep -o '"isHost":true')
if [ -z "$IS_HOST1" ]; then
    echo "   ❌ FAIL: Alice should be host"
    exit 1
fi
echo "   ✅ Alice is host"
echo ""

# Bob joins
echo "3️⃣  Bob joining..."
JOIN2=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
IS_HOST2=$(echo $JOIN2 | grep -o '"isHost":false')
if [ -z "$IS_HOST2" ]; then
    echo "   ❌ FAIL: Bob should not be host"
    exit 1
fi
echo "   ✅ Bob is not host"
echo ""

# Charlie joins
echo "4️⃣  Charlie joining..."
JOIN3=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie")
TOKEN3=$(echo $JOIN3 | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Charlie joined"
echo ""

# Check initial player list
echo "5️⃣  Checking initial player list..."
PLAYERS=$(curl -s -X GET $API_BASE/players -H "Authorization: $TOKEN2")
ALICE_HOST=$(echo $PLAYERS | grep -o '"name":"Alice"[^}]*"isHost":true')
if [ -z "$ALICE_HOST" ]; then
    echo "   ❌ FAIL: Alice should be host in player list"
    echo "   Response: $PLAYERS"
    exit 1
fi
echo "   ✅ Alice is shown as host"
echo ""

# Alice leaves the game
echo "6️⃣  Alice (host) leaving game..."
LEAVE=$(curl -s -X POST $API_BASE/leave_game -H "Authorization: $TOKEN1")
echo "   ✅ Alice left"
echo ""

# Check player list after host leaves
echo "7️⃣  Checking player list after host leaves..."
PLAYERS_AFTER=$(curl -s -w "\n" -X GET $API_BASE/players -H "Authorization: $TOKEN2")

# Alice should not be in list
ALICE_PRESENT=$(echo $PLAYERS_AFTER | grep -o '"name":"Alice"')
if [ -n "$ALICE_PRESENT" ]; then
    echo "   ❌ FAIL: Alice should not be in player list"
    exit 1
fi
echo "   ✅ Alice removed from player list"

# Bob should now be host (next by join time)
BOB_HOST=$(echo $PLAYERS_AFTER | grep -o '"name":"Bob"[^}]*"isHost":true')
if [ -z "$BOB_HOST" ]; then
    echo "   ❌ FAIL: Bob should be host after Alice leaves"
    echo "   Response: $PLAYERS_AFTER"
    exit 1
fi
echo "   ✅ Bob is now host"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Host reassignment test passed!"
echo ""

# Test player limit
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔢 Testing 12 Player Limit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create new game
echo "1️⃣  Creating new game..."
CREATE2=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE2=$(echo $CREATE2 | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE2"
echo ""

# Add 12 players
echo "2️⃣  Adding 12 players..."
for i in {1..12}; do
    curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE2&name=Player$i" > /dev/null
    echo "   Player $i joined"
done
echo "   ✅ All 12 players joined"
echo ""

# Try to add 13th player
echo "3️⃣  Trying to add 13th player..."
JOIN13=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE2&name=Player13")
FULL_ERROR=$(echo $JOIN13 | grep -o "game is full")
if [ -z "$FULL_ERROR" ]; then
    echo "   ❌ FAIL: Should reject 13th player"
    echo "   Response: $JOIN13"
    exit 1
fi
echo "   ✅ 13th player rejected with 'game is full'"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed!"
echo ""
echo "📋 Summary:"
echo "   ✅ Host reassignment works when host leaves"
echo "   ✅ Next player (by join time) becomes host"
echo "   ✅ Games limited to 12 players maximum"
echo ""
