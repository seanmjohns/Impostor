#!/bin/bash

# API Testing Script for Impostor Game
# This script demonstrates the full game flow

set -e

API_BASE="http://localhost:8080"

echo "🎭 Impostor Game - API Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check server health
echo "1️⃣  Checking server health..."
HEALTH=$(curl -s $API_BASE/health)
echo "   Response: $HEALTH"
echo ""

# Create a game
echo "2️⃣  Creating a new game..."
CREATE_RESPONSE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE_RESPONSE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)
echo "   Game Code: $GAME_CODE"
echo ""

# Player 1 joins (host)
echo "3️⃣  Player 1 (Alice) joining as host..."
JOIN1_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Alice")
TOKEN1=$(echo $JOIN1_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
IS_HOST1=$(echo $JOIN1_RESPONSE | grep -o '"isHost":[^,}]*' | cut -d':' -f2)
echo "   Session Token: ${TOKEN1:0:20}..."
echo "   Is Host: $IS_HOST1"
echo ""

# Player 2 joins
echo "4️⃣  Player 2 (Bob) joining..."
JOIN2_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Bob")
TOKEN2=$(echo $JOIN2_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
IS_HOST2=$(echo $JOIN2_RESPONSE | grep -o '"isHost":[^,}]*' | cut -d':' -f2)
echo "   Session Token: ${TOKEN2:0:20}..."
echo "   Is Host: $IS_HOST2"
echo ""

# Player 3 joins
echo "5️⃣  Player 3 (Charlie) joining..."
JOIN3_RESPONSE=$(curl -s -X POST "$API_BASE/join_game?gameCode=$GAME_CODE&name=Charlie")
TOKEN3=$(echo $JOIN3_RESPONSE | grep -o '"sessionToken":"[^"]*"' | cut -d'"' -f4)
echo "   Session Token: ${TOKEN3:0:20}..."
echo ""

# Host starts round 1
echo "6️⃣  Host starting Round 1..."
ROUND_RESPONSE=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND_NUM=$(echo $ROUND_RESPONSE | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Round Number: $ROUND_NUM"
echo ""

# All players get their words
echo "7️⃣  Players getting their words/roles..."

echo "   Alice:"
WORD1=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN1")
echo "   $WORD1"

echo "   Bob:"
WORD2=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN2")
echo "   $WORD2"

echo "   Charlie:"
WORD3=$(curl -s -X GET $API_BASE/get_word -H "Authorization: $TOKEN3")
echo "   $WORD3"
echo ""

# Test word skip (assuming Bob is innocent)
echo "8️⃣  Testing word skip..."
echo "   Bob votes to skip..."
SKIP_RESPONSE=$(curl -s -X POST $API_BASE/vote_word_skip -H "Authorization: $TOKEN2" || echo '{"error":"Bob might be impostor"}')
echo "   Response: $SKIP_RESPONSE"
echo ""

# Host starts round 2
echo "9️⃣  Host starting Round 2..."
ROUND2_RESPONSE=$(curl -s -X POST $API_BASE/next_round -H "Authorization: $TOKEN1")
ROUND2_NUM=$(echo $ROUND2_RESPONSE | grep -o '"roundNumber":[0-9]*' | cut -d':' -f2)
echo "   Round Number: $ROUND2_NUM"
echo ""

echo "✅ Test complete!"
echo ""
echo "🎮 To play the game, open http://localhost:8080 in your browser"
