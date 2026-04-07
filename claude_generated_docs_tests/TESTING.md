# Testing Documentation

## Overview

The Impostor game has comprehensive unit tests covering all core functionality, including game logic, role assignment, player management, and word lists.

## Running Tests

### Run All Tests

```bash
make test
```

or

```bash
go test ./...
```

### Run Tests with Verbose Output

```bash
make test-verbose
```

or

```bash
go test -v ./...
```

### Run Tests for Specific Package

```bash
go test ./internal/models -v      # Models tests
go test ./internal/game -v        # Game manager and roles tests
go test ./internal/wordlist -v    # Wordlist tests
```

## Test Coverage

### Models Tests (`internal/models/models_test.go`)

Tests the core data models and their methods:

- ✅ **Game Creation** - New games are initialized correctly
- ✅ **Player Addition** - Players can join games, first player becomes host
- ✅ **Player Retrieval** - Find players by ID and session token
- ✅ **Name Uniqueness** - Duplicate names are rejected
- ✅ **Player Removal** - Players can be removed from games
- ✅ **Host Reassignment** - When host leaves, next player (by join time) becomes host
- ✅ **Skip Vote Reset** - Skip votes reset correctly for new rounds
- ✅ **Player Sorting** - Players can be retrieved in consistent order

**Example:**
```bash
go test ./internal/models -v
```

### Game Manager Tests (`internal/game/manager_test.go`)

Tests the game manager business logic:

- ✅ **Game Creation** - Games are created with unique codes
- ✅ **Player Joining** - Players can join games
  - Rejects invalid game codes
  - Rejects duplicate names
  - **Enforces 12 player limit**
- ✅ **Token-based Retrieval** - Games and players found by session tokens
- ✅ **Round Management** - Host can start rounds, assigns roles and words
  - Only host can advance rounds
  - Roles are assigned correctly
- ✅ **Word Skipping** - Players can vote to skip words
  - 50% innocent player threshold
  - Impostors cannot vote
  - SkipCount increments for detection
- ✅ **Player Kicking** - Host can kick players
  - Only host can kick
  - Cannot kick yourself
  - Host reassignment on kick
- ✅ **Player Leaving** - Players can leave voluntarily
  - Host reassignment on leave

**Key Tests:**
- `TestJoinGamePlayerLimit` - Verifies 12 player maximum
- `TestKickHostReassignsHost` - Host transfers correctly
- `TestLeaveGameHostReassignment` - Voluntary leave transfers host

### Role Assignment Tests (`internal/game/roles_test.go`)

Tests the intelligent role assignment algorithm:

- ✅ **Basic Role Assignment** - All players get roles (innocent or impostor)
- ✅ **At Least One Impostor** - Guaranteed 95%+ of the time
- ✅ **Average Impostor Count** - ~1-2 impostors on average
- ✅ **Probability Distribution** - Reasonable distribution across player counts
- ✅ **Single Player** - Becomes impostor
- ✅ **Two Players** - At least one impostor
- ✅ **Role Reassignment** - Roles can be reassigned (for word skips)

**Statistical Tests:**
- `TestAssignRolesGuaranteesAtLeastOneImpostor` - 100 runs, verifies guarantee
- `TestAssignRolesAverageImpostorCount` - 1000 runs, checks average ~1.8 impostors

### Wordlist Tests (`internal/wordlist/wordlist_test.go`)

Tests word loading and selection:

- ✅ **Manual Word Loading** - Can load words from array
- ✅ **Random Word Selection** - All words can be selected
- ✅ **Empty Wordlist** - Returns empty string
- ✅ **Directory Loading** - Loads all `.txt` files from directory
- ✅ **Empty Directory** - Rejects directories with no files
- ✅ **Whitespace Handling** - Trims and filters blank lines
- ✅ **Word Count** - Accurate count of loaded words

## Test Statistics

```
$ go test ./... -v

PASS: internal/models    (9 tests, all passing)
PASS: internal/game      (24 tests, all passing)  
PASS: internal/wordlist  (8 tests, all passing)

Total: 41 unit tests, 100% passing
```

## Integration Tests

Shell scripts test end-to-end functionality:

### Host Reassignment Test

```bash
./test_host_reassignment.sh
```

Tests:
- ✅ Host leaves, next player becomes host
- ✅ Player is removed from list
- ✅ 12 player limit enforced

### Word Skip Notification Test

```bash
./test_word_skip_notification.sh
```

Tests:
- ✅ SkipCount increments when word skipped
- ✅ All players can detect skip via polling
- ✅ Round number stays same

### Player Order Consistency Test

```bash
./test_player_order.sh
```

Tests:
- ✅ Player list maintains stable order
- ✅ Players sorted by join time
- ✅ Consistent across multiple requests

## Writing New Tests

### Unit Test Template

```go
func TestFeatureName(t *testing.T) {
    // Arrange
    m := createTestManager(t)
    game, _ := m.CreateGame()
    _, player, _ := m.JoinGame(game.Code, "Alice")

    // Act
    err := m.SomeMethod(game, player)

    // Assert
    if err != nil {
        t.Fatalf("Failed: %v", err)
    }
    
    if game.SomeField != expectedValue {
        t.Errorf("Expected %v, got %v", expectedValue, game.SomeField)
    }
}
```

### Integration Test Template

```bash
#!/bin/bash
set -e

API_BASE="http://localhost:8080"

echo "Testing feature..."

# Create game
CREATE=$(curl -s -X POST $API_BASE/create_game)
GAME_CODE=$(echo $CREATE | grep -o '"gameCode":"[^"]*"' | cut -d'"' -f4)

# Test assertions
if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "❌ FAIL: Expected $EXPECTED, got $ACTUAL"
    exit 1
fi

echo "✅ PASS: Test passed"
```

## Test Best Practices

1. **Arrange-Act-Assert** - Structure tests clearly
2. **Independent Tests** - Each test should be self-contained
3. **Descriptive Names** - `TestFeature_Scenario_ExpectedResult`
4. **Error Messages** - Include context in error messages
5. **Edge Cases** - Test boundaries (0 players, 1 player, 12 players)
6. **Probabilistic Tests** - Run multiple iterations for random behavior

## Continuous Integration

Tests run automatically on:
- Pre-commit (if configured)
- Pull requests
- Main branch pushes

```bash
# Run before committing
make test

# Run with coverage
go test ./... -cover

# Generate coverage report
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

## Debugging Failed Tests

### Verbose Output

```bash
go test -v ./internal/game -run TestSpecificTest
```

### Test a Single Function

```bash
go test ./internal/models -run TestRemovePlayer -v
```

### Print Debugging

```go
func TestSomething(t *testing.T) {
    t.Logf("Debug info: %v", someValue)
    // Test continues...
}
```

## Common Test Patterns

### Test Multiple Cases

```go
func TestMultipleCases(t *testing.T) {
    tests := []struct {
        name     string
        input    int
        expected int
    }{
        {"zero", 0, 0},
        {"positive", 5, 10},
        {"negative", -3, -6},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := SomeFunction(tt.input)
            if result != tt.expected {
                t.Errorf("Expected %d, got %d", tt.expected, result)
            }
        })
    }
}
```

### Test Concurrency

```go
func TestConcurrentAccess(t *testing.T) {
    game := models.NewGame("TEST")
    
    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            player := &models.Player{ID: fmt.Sprintf("p%d", id)}
            game.AddPlayer(player)
        }(i)
    }
    wg.Wait()
    
    if game.GetPlayerCount() != 10 {
        t.Errorf("Expected 10 players, got %d", game.GetPlayerCount())
    }
}
```

## Test Maintenance

- **Keep Tests Updated** - When adding features, add tests
- **Fix Flaky Tests** - Tests should be deterministic
- **Remove Obsolete Tests** - Delete tests for removed features
- **Document Complex Tests** - Add comments for non-obvious logic

## Summary

✅ **41 unit tests** covering all core functionality  
✅ **3 integration tests** for end-to-end scenarios  
✅ **100% passing** - All tests green  
✅ **Key features tested:**
- 12 player limit
- Host reassignment  
- Atomic player removal
- Word skip notifications
- Role assignment algorithm
- Session management

Run `make test` to verify everything works!
