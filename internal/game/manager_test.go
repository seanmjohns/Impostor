package game

import (
	"testing"

	"github.com/sjohnson-confluent/impostor/internal/models"
	"github.com/sjohnson-confluent/impostor/internal/wordlist"
)

func createTestManager(t *testing.T) *Manager {
	// Create a simple in-memory wordlist for testing
	wl := &wordlist.WordList{}
	wl.LoadWords([]string{"apple", "banana", "cherry", "date", "elderberry"})
	return NewManager(wl)
}

func TestCreateGame(t *testing.T) {
	m := createTestManager(t)

	game, err := m.CreateGame()
	if err != nil {
		t.Fatalf("Failed to create game: %v", err)
	}

	if game.Code == "" {
		t.Error("Game code should not be empty")
	}

	if len(game.Code) != 6 {
		t.Errorf("Expected game code length 6, got %d", len(game.Code))
	}

	// Game should be stored in manager
	retrieved, err := m.GetGame(game.Code)
	if err != nil {
		t.Errorf("Failed to retrieve created game: %v", err)
	}

	if retrieved.Code != game.Code {
		t.Errorf("Expected code %s, got %s", game.Code, retrieved.Code)
	}
}

func TestJoinGame(t *testing.T) {
	m := createTestManager(t)

	// Create a game
	game, _ := m.CreateGame()

	// First player joins
	g, player, err := m.JoinGame(game.Code, "Alice")
	if err != nil {
		t.Fatalf("Failed to join game: %v", err)
	}

	if player.Name != "Alice" {
		t.Errorf("Expected player name Alice, got %s", player.Name)
	}

	if player.SessionToken == "" {
		t.Error("Session token should not be empty")
	}

	// First player should be host
	if g.HostID != player.ID {
		t.Error("First player should be host")
	}

	// Second player joins
	_, player2, err := m.JoinGame(game.Code, "Bob")
	if err != nil {
		t.Fatalf("Failed to join game: %v", err)
	}

	// Second player should not be host
	if g.HostID == player2.ID {
		t.Error("Second player should not be host")
	}

	// Game should have 2 players
	if g.GetPlayerCount() != 2 {
		t.Errorf("Expected 2 players, got %d", g.GetPlayerCount())
	}
}

func TestJoinGameInvalidCode(t *testing.T) {
	m := createTestManager(t)

	_, _, err := m.JoinGame("INVALID", "Alice")
	if err == nil {
		t.Error("Should fail to join game with invalid code")
	}

	if err.Error() != "game not found" {
		t.Errorf("Expected 'game not found' error, got: %v", err)
	}
}

func TestJoinGameNameTaken(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()

	// First player joins
	m.JoinGame(game.Code, "Alice")

	// Try to join with same name
	_, _, err := m.JoinGame(game.Code, "Alice")
	if err == nil {
		t.Error("Should fail to join with duplicate name")
	}

	if err.Error() != "name already taken" {
		t.Errorf("Expected 'name already taken' error, got: %v", err)
	}
}

func TestJoinGamePlayerLimit(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()

	// Add 12 players
	for i := 1; i <= 12; i++ {
		name := "Player" + string(rune('0'+i))
		_, _, err := m.JoinGame(game.Code, name)
		if err != nil {
			t.Fatalf("Failed to add player %d: %v", i, err)
		}
	}

	// Try to add 13th player
	_, _, err := m.JoinGame(game.Code, "Player13")
	if err == nil {
		t.Error("Should fail to add 13th player")
	}

	if err.Error() != "game is full (max 12 players)" {
		t.Errorf("Expected 'game is full' error, got: %v", err)
	}
}

func TestGetGameByToken(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, player, _ := m.JoinGame(game.Code, "Alice")

	// Should find game by player's token
	g, p, err := m.GetGameByToken(player.SessionToken)
	if err != nil {
		t.Fatalf("Failed to get game by token: %v", err)
	}

	if g.Code != game.Code {
		t.Errorf("Expected game code %s, got %s", game.Code, g.Code)
	}

	if p.ID != player.ID {
		t.Errorf("Expected player ID %s, got %s", player.ID, p.ID)
	}

	// Should not find game with invalid token
	_, _, err = m.GetGameByToken("invalid-token")
	if err == nil {
		t.Error("Should fail to find game with invalid token")
	}
}

func TestNextRound(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, _, _ = m.JoinGame(game.Code, "Bob")
	_, _, _ = m.JoinGame(game.Code, "Charlie")

	// Start first round
	err := m.NextRound(game, host.SessionToken)
	if err != nil {
		t.Fatalf("Failed to start round: %v", err)
	}

	if game.RoundNumber != 1 {
		t.Errorf("Expected round number 1, got %d", game.RoundNumber)
	}

	if game.CurrentRound == nil {
		t.Fatal("CurrentRound should not be nil")
	}

	if game.CurrentRound.Word == "" {
		t.Error("Round should have a word")
	}

	if game.CurrentRound.Number != 1 {
		t.Errorf("Expected round number 1, got %d", game.CurrentRound.Number)
	}

	// Check that roles were assigned
	hasInnocent := false
	hasImpostor := false
	for _, player := range game.Players {
		if player.Role == models.RoleInnocent {
			hasInnocent = true
		}
		if player.Role == models.RoleImpostor {
			hasImpostor = true
		}
	}

	if !hasInnocent {
		t.Error("At least one player should be innocent")
	}

	// With 3 players, there should be at least 1 impostor (95% of the time)
	// Note: This test might occasionally fail due to randomness
	if !hasImpostor {
		t.Error("At least one player should be impostor")
	}
}

func TestNextRoundOnlyHostCanAdvance(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, _, _ = m.JoinGame(game.Code, "Alice")
	_, nonHost, _ := m.JoinGame(game.Code, "Bob")

	// Non-host tries to start round
	err := m.NextRound(game, nonHost.SessionToken)
	if err == nil {
		t.Error("Non-host should not be able to start round")
	}

	if err.Error() != "only the host can advance rounds" {
		t.Errorf("Expected 'only the host can advance rounds' error, got: %v", err)
	}
}

func TestVoteWordSkip(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, p2, _ := m.JoinGame(game.Code, "Bob")
	_, p3, _ := m.JoinGame(game.Code, "Charlie")

	// Start round
	m.NextRound(game, host.SessionToken)

	// Set roles: host is impostor, other 2 are innocent
	game.Players[host.ID].Role = models.RoleImpostor
	game.Players[p2.ID].Role = models.RoleInnocent
	game.Players[p3.ID].Role = models.RoleInnocent

	// First vote (from p2)
	shouldSkip, err := m.VoteWordSkip(game, game.Players[p2.ID])
	if err != nil {
		t.Fatalf("Failed to vote skip: %v", err)
	}

	if game.CurrentRound.SkipVotes != 1 {
		t.Errorf("Expected 1 skip vote, got %d", game.CurrentRound.SkipVotes)
	}

	// With 2 innocent players, need 1 vote (50%) to skip
	if !shouldSkip {
		t.Error("Should skip with 1/2 votes")
	}

	// Try to vote again
	_, err = m.VoteWordSkip(game, game.Players[p2.ID])
	if err == nil {
		t.Error("Should not allow double voting")
	}
}

func TestVoteWordSkipImpostorCannot(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, p2, _ := m.JoinGame(game.Code, "Bob")

	// Start round
	m.NextRound(game, host.SessionToken)

	// Make player an impostor
	game.Players[p2.ID].Role = models.RoleImpostor

	// Try to vote as impostor
	_, err := m.VoteWordSkip(game, game.Players[p2.ID])
	if err == nil {
		t.Error("Impostors should not be able to skip")
	}

	if err.Error() != "impostors cannot skip words" {
		t.Errorf("Expected 'impostors cannot skip words' error, got: %v", err)
	}
}

func TestSkipWord(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, _, _ = m.JoinGame(game.Code, "Bob")

	// Start round
	m.NextRound(game, host.SessionToken)

	originalSkipCount := game.CurrentRound.SkipCount

	// Skip word
	err := m.SkipWord(game)
	if err != nil {
		t.Fatalf("Failed to skip word: %v", err)
	}

	// Word should be set (might be same as before due to small wordlist)
	if game.CurrentRound.Word == "" {
		t.Error("Word should not be empty after skip")
	}

	// SkipCount should increment
	if game.CurrentRound.SkipCount != originalSkipCount+1 {
		t.Errorf("Expected skip count %d, got %d", originalSkipCount+1, game.CurrentRound.SkipCount)
	}

	// Skip votes should be reset
	if game.CurrentRound.SkipVotes != 0 {
		t.Errorf("Skip votes should be reset, got %d", game.CurrentRound.SkipVotes)
	}

	// Round number should NOT change
	if game.RoundNumber != 1 {
		t.Errorf("Round number should still be 1, got %d", game.RoundNumber)
	}
}

func TestKickPlayer(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, p2, _ := m.JoinGame(game.Code, "Bob")
	_, p3, _ := m.JoinGame(game.Code, "Charlie")

	initialCount := game.GetPlayerCount()

	// Host kicks Bob
	err := m.KickPlayer(game, host.SessionToken, p2.ID)
	if err != nil {
		t.Fatalf("Failed to kick player: %v", err)
	}

	// Player count should decrease
	if game.GetPlayerCount() != initialCount-1 {
		t.Errorf("Expected %d players, got %d", initialCount-1, game.GetPlayerCount())
	}

	// Bob should not be in game
	if _, exists := game.Players[p2.ID]; exists {
		t.Error("Kicked player should not be in game")
	}

	// Charlie should still be in game
	if _, exists := game.Players[p3.ID]; !exists {
		t.Error("Other players should still be in game")
	}

	// Host should still be Alice
	if game.HostID != host.ID {
		t.Error("Host should not change when kicking non-host")
	}
}

func TestKickPlayerOnlyHostCan(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, _, _ = m.JoinGame(game.Code, "Alice")
	_, nonHost, _ := m.JoinGame(game.Code, "Bob")
	_, p3, _ := m.JoinGame(game.Code, "Charlie")

	// Non-host tries to kick
	err := m.KickPlayer(game, nonHost.SessionToken, p3.ID)
	if err == nil {
		t.Error("Non-host should not be able to kick")
	}

	if err.Error() != "only the host can kick players" {
		t.Errorf("Expected 'only the host can kick players' error, got: %v", err)
	}
}

func TestKickPlayerCannotKickSelf(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")

	// Host tries to kick themselves
	err := m.KickPlayer(game, host.SessionToken, host.ID)
	if err == nil {
		t.Error("Host should not be able to kick themselves")
	}

	if err.Error() != "cannot kick yourself" {
		t.Errorf("Expected 'cannot kick yourself' error, got: %v", err)
	}
}

func TestKickHostReassignsHost(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, p2, _ := m.JoinGame(game.Code, "Bob")
	_, p3, _ := m.JoinGame(game.Code, "Charlie")

	// Host is Alice
	if game.HostID != host.ID {
		t.Error("Initial host should be Alice")
	}

	// Alice kicks herself (this should work via another player becoming host first in real scenario)
	// For testing, we'll directly remove host
	game.RemovePlayer(host.ID)

	// Bob should become host (next by join time)
	if game.HostID != p2.ID {
		t.Errorf("Expected Bob to be host, got player ID: %s", game.HostID)
	}

	// Remove Bob
	game.RemovePlayer(p2.ID)

	// Charlie should become host
	if game.HostID != p3.ID {
		t.Errorf("Expected Charlie to be host, got player ID: %s", game.HostID)
	}
}

func TestLeaveGame(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, _, _ = m.JoinGame(game.Code, "Bob")
	_, p3, _ := m.JoinGame(game.Code, "Charlie")

	initialCount := game.GetPlayerCount()

	// Charlie leaves
	err := m.LeaveGame(game, p3.SessionToken)
	if err != nil {
		t.Fatalf("Failed to leave game: %v", err)
	}

	// Player count should decrease
	if game.GetPlayerCount() != initialCount-1 {
		t.Errorf("Expected %d players, got %d", initialCount-1, game.GetPlayerCount())
	}

	// Charlie should not be in game
	if _, exists := game.Players[p3.ID]; exists {
		t.Error("Player who left should not be in game")
	}

	// Host should still be Alice
	if game.HostID != host.ID {
		t.Error("Host should not change when non-host leaves")
	}
}

func TestLeaveGameHostReassignment(t *testing.T) {
	m := createTestManager(t)

	game, _ := m.CreateGame()
	_, host, _ := m.JoinGame(game.Code, "Alice")
	_, p2, _ := m.JoinGame(game.Code, "Bob")

	// Alice (host) leaves
	err := m.LeaveGame(game, host.SessionToken)
	if err != nil {
		t.Fatalf("Failed to leave game: %v", err)
	}

	// Bob should become host
	if game.HostID != p2.ID {
		t.Errorf("Expected Bob to be host after Alice leaves, got player ID: %s", game.HostID)
	}

	// Alice should not be in game
	if _, exists := game.Players[host.ID]; exists {
		t.Error("Host who left should not be in game")
	}
}
