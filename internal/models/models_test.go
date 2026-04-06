package models

import (
	"testing"
	"time"
)

func TestNewGame(t *testing.T) {
	game := NewGame("TEST123")

	if game.Code != "TEST123" {
		t.Errorf("Expected code TEST123, got %s", game.Code)
	}

	if game.Players == nil {
		t.Error("Players map should be initialized")
	}

	if game.IsStarted {
		t.Error("New game should not be started")
	}

	if game.RoundNumber != 0 {
		t.Errorf("Expected round number 0, got %d", game.RoundNumber)
	}
}

func TestAddPlayer(t *testing.T) {
	game := NewGame("TEST123")
	player := &Player{
		ID:           "player1",
		Name:         "Alice",
		SessionToken: "token1",
		Role:         RoleUnknown,
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player)

	// First player should become host
	if game.HostID != "player1" {
		t.Errorf("Expected first player to be host, got hostID: %s", game.HostID)
	}

	// Player should be in map
	if _, exists := game.Players["player1"]; !exists {
		t.Error("Player should be in players map")
	}

	// Add second player
	player2 := &Player{
		ID:           "player2",
		Name:         "Bob",
		SessionToken: "token2",
		Role:         RoleUnknown,
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player2)

	// Host should still be first player
	if game.HostID != "player1" {
		t.Error("Host should not change when second player joins")
	}

	if game.GetPlayerCount() != 2 {
		t.Errorf("Expected 2 players, got %d", game.GetPlayerCount())
	}
}

func TestGetPlayer(t *testing.T) {
	game := NewGame("TEST123")
	player := &Player{
		ID:           "player1",
		Name:         "Alice",
		SessionToken: "token1",
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player)

	// Should find existing player
	p, exists := game.GetPlayer("player1")
	if !exists {
		t.Error("Should find existing player")
	}
	if p.Name != "Alice" {
		t.Errorf("Expected player name Alice, got %s", p.Name)
	}

	// Should not find non-existent player
	_, exists = game.GetPlayer("nonexistent")
	if exists {
		t.Error("Should not find non-existent player")
	}
}

func TestGetPlayerByToken(t *testing.T) {
	game := NewGame("TEST123")
	player := &Player{
		ID:           "player1",
		Name:         "Alice",
		SessionToken: "token123",
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player)

	// Should find by token
	p, exists := game.GetPlayerByToken("token123")
	if !exists {
		t.Error("Should find player by token")
	}
	if p.ID != "player1" {
		t.Errorf("Expected player ID player1, got %s", p.ID)
	}

	// Should not find with wrong token
	_, exists = game.GetPlayerByToken("wrongtoken")
	if exists {
		t.Error("Should not find player with wrong token")
	}
}

func TestIsNameTaken(t *testing.T) {
	game := NewGame("TEST123")
	player := &Player{
		ID:           "player1",
		Name:         "Alice",
		SessionToken: "token1",
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player)

	if !game.IsNameTaken("Alice") {
		t.Error("Name 'Alice' should be taken")
	}

	if game.IsNameTaken("Bob") {
		t.Error("Name 'Bob' should not be taken")
	}
}

func TestRemovePlayer(t *testing.T) {
	game := NewGame("TEST123")

	// Add three players
	players := []*Player{
		{ID: "p1", Name: "Alice", SessionToken: "t1", JoinedAt: time.Now()},
		{ID: "p2", Name: "Bob", SessionToken: "t2", JoinedAt: time.Now().Add(1 * time.Second)},
		{ID: "p3", Name: "Charlie", SessionToken: "t3", JoinedAt: time.Now().Add(2 * time.Second)},
	}

	for _, p := range players {
		game.AddPlayer(p)
	}

	// Host should be first player
	if game.HostID != "p1" {
		t.Errorf("Expected host to be p1, got %s", game.HostID)
	}

	// Remove a non-host player
	game.RemovePlayer("p3")

	if game.GetPlayerCount() != 2 {
		t.Errorf("Expected 2 players after removal, got %d", game.GetPlayerCount())
	}

	// Host should still be p1
	if game.HostID != "p1" {
		t.Errorf("Host should still be p1, got %s", game.HostID)
	}

	// Remove the host
	game.RemovePlayer("p1")

	if game.GetPlayerCount() != 1 {
		t.Errorf("Expected 1 player after host removal, got %d", game.GetPlayerCount())
	}

	// Next player (by join time) should become host
	if game.HostID != "p2" {
		t.Errorf("Expected new host to be p2, got %s", game.HostID)
	}

	// Verify p1 is actually removed
	if _, exists := game.Players["p1"]; exists {
		t.Error("Player p1 should be removed from map")
	}
}

func TestRemovePlayerLastPlayerBecomesHost(t *testing.T) {
	game := NewGame("TEST123")

	// Add two players with specific join times
	p1 := &Player{ID: "p1", Name: "Alice", SessionToken: "t1", JoinedAt: time.Now()}
	p2 := &Player{ID: "p2", Name: "Bob", SessionToken: "t2", JoinedAt: time.Now().Add(1 * time.Second)}

	game.AddPlayer(p1)
	game.AddPlayer(p2)

	// Remove host
	game.RemovePlayer("p1")

	// Last remaining player should be host
	if game.HostID != "p2" {
		t.Errorf("Expected p2 to be host, got %s", game.HostID)
	}

	// Remove last player
	game.RemovePlayer("p2")

	// Host should be empty
	if game.HostID != "" {
		t.Errorf("Expected empty host when no players remain, got %s", game.HostID)
	}
}

func TestResetSkipVotes(t *testing.T) {
	game := NewGame("TEST123")

	player1 := &Player{ID: "p1", Name: "Alice", HasSkipped: true, JoinedAt: time.Now()}
	player2 := &Player{ID: "p2", Name: "Bob", HasSkipped: true, JoinedAt: time.Now()}

	game.AddPlayer(player1)
	game.AddPlayer(player2)

	game.CurrentRound = &Round{
		Number:    1,
		Word:      "test",
		SkipVotes: 5,
		StartedAt: time.Now(),
	}

	game.ResetSkipVotes()

	// All players should have HasSkipped reset
	for _, p := range game.Players {
		if p.HasSkipped {
			t.Errorf("Player %s still has HasSkipped=true", p.Name)
		}
	}

	// Round skip votes should be reset
	if game.CurrentRound.SkipVotes != 0 {
		t.Errorf("Expected skip votes to be 0, got %d", game.CurrentRound.SkipVotes)
	}
}

func TestGetSortedPlayers(t *testing.T) {
	game := NewGame("TEST123")

	// Add players with specific join times
	now := time.Now()
	players := []*Player{
		{ID: "p3", Name: "Charlie", JoinedAt: now.Add(2 * time.Second)},
		{ID: "p1", Name: "Alice", JoinedAt: now},
		{ID: "p2", Name: "Bob", JoinedAt: now.Add(1 * time.Second)},
	}

	for _, p := range players {
		game.AddPlayer(p)
	}

	sorted := game.GetSortedPlayers()

	if len(sorted) != 3 {
		t.Errorf("Expected 3 players, got %d", len(sorted))
	}

	// Should return all players (order not guaranteed by this method alone)
	names := make(map[string]bool)
	for _, p := range sorted {
		names[p.Name] = true
	}

	if !names["Alice"] || !names["Bob"] || !names["Charlie"] {
		t.Error("Not all players returned from GetSortedPlayers")
	}
}
