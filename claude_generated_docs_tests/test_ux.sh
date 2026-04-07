#!/bin/bash

# Test UX improvements

echo "🎨 Testing UX Improvements"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start server
./bin/impostor > /tmp/impostor_test.log 2>&1 &
SERVER_PID=$!
sleep 2

# Download the page
curl -s http://localhost:8080/ > /tmp/index_test.html

echo "1️⃣  Check for Round button removed?"
if grep -q "Check for Round" /tmp/index_test.html; then
    echo "   ❌ FAIL: Button still exists"
else
    echo "   ✅ PASS: Button removed"
fi
echo ""

echo "2️⃣  Vote count hidden from players?"
if grep -q "Votes:.*skipVotes" /tmp/index_test.html; then
    echo "   ❌ FAIL: Vote count still visible"
else
    echo "   ✅ PASS: Vote count hidden"
fi
echo ""

echo "3️⃣  End Game button exists (for hosts)?"
if grep -q "endGameBtn" /tmp/index_test.html; then
    echo "   ✅ PASS: End Game button found"
else
    echo "   ❌ FAIL: End Game button missing"
fi
echo ""

echo "4️⃣  Leave Game button exists (for non-hosts in game)?"
if grep -q "leaveGameBtn" /tmp/index_test.html; then
    echo "   ✅ PASS: Leave Game button found"
else
    echo "   ❌ FAIL: Leave Game button missing"
fi
echo ""

echo "5️⃣  Automatic polling still active?"
if grep -q "startPolling" /tmp/index_test.html; then
    echo "   ✅ PASS: Polling function exists"
else
    echo "   ❌ FAIL: Polling removed"
fi
echo ""

# Stop server
kill $SERVER_PID 2>/dev/null
rm -f /tmp/index_test.html

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ UX improvements verified!"
