package models

import (
	"sync"
	"time"
)

// PlayerRole represents whether a player is an impostor or innocent
type PlayerRole string

const (
	RoleInnocent PlayerRole = "innocent"
	RoleImpostor PlayerRole = "impostor"
	RoleUnknown  PlayerRole = "unknown"
)

// Player represents a player in the game
type Player struct {
	ID           string     `json:"id"`
	Name         string     `json:"name"`
	SessionToken string     `json:"sessionToken"`
	Role         PlayerRole `json:"role"`
	HasSkipped   bool       `json:"hasSkipped"`
	JoinedAt     time.Time  `json:"joinedAt"`
}

// Round represents a single round of the game
type Round struct {
	Number      int       `json:"number"`
	Word        string    `json:"word"`
	StartedAt   time.Time `json:"startedAt"`
	SkipVotes   int       `json:"skipVotes"`
	SkipCount   int       `json:"skipCount"`
	IsCompleted bool      `json:"isCompleted"`
}

// Game represents a game session
type Game struct {
	Code         string             `json:"code"`
	HostID       string             `json:"hostId"`
	Players      map[string]*Player `json:"players"`
	CurrentRound *Round             `json:"currentRound"`
	RoundNumber  int                `json:"roundNumber"`
	IsStarted    bool               `json:"isStarted"`
	CreatedAt    time.Time          `json:"createdAt"`
	mu           sync.RWMutex
}

// NewGame creates a new game session
func NewGame(code string) *Game {
	return &Game{
		Code:      code,
		Players:   make(map[string]*Player),
		IsStarted: false,
		CreatedAt: time.Now(),
		RoundNumber: 0,
	}
}

// AddPlayer adds a player to the game
func (g *Game) AddPlayer(player *Player) {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.HostID == "" {
		g.HostID = player.ID
	}

	g.Players[player.ID] = player
}

// GetPlayer retrieves a player by ID
func (g *Game) GetPlayer(playerID string) (*Player, bool) {
	g.mu.RLock()
	defer g.mu.RUnlock()

	player, exists := g.Players[playerID]
	return player, exists
}

// GetPlayerByToken retrieves a player by session token
func (g *Game) GetPlayerByToken(token string) (*Player, bool) {
	g.mu.RLock()
	defer g.mu.RUnlock()

	for _, player := range g.Players {
		if player.SessionToken == token {
			return player, true
		}
	}
	return nil, false
}

// IsNameTaken checks if a player name is already taken
func (g *Game) IsNameTaken(name string) bool {
	g.mu.RLock()
	defer g.mu.RUnlock()

	for _, player := range g.Players {
		if player.Name == name {
			return true
		}
	}
	return false
}

// GetPlayerCount returns the number of players in the game
func (g *Game) GetPlayerCount() int {
	g.mu.RLock()
	defer g.mu.RUnlock()

	return len(g.Players)
}

// ResetSkipVotes resets all skip votes for a new round
func (g *Game) ResetSkipVotes() {
	g.mu.Lock()
	defer g.mu.Unlock()

	for _, player := range g.Players {
		player.HasSkipped = false
	}

	if g.CurrentRound != nil {
		g.CurrentRound.SkipVotes = 0
	}
}

// GetSortedPlayers returns all players sorted by join time (with read lock)
func (g *Game) GetSortedPlayers() []*Player {
	g.mu.RLock()
	defer g.mu.RUnlock()

	// Collect all players
	players := make([]*Player, 0, len(g.Players))
	for _, player := range g.Players {
		players = append(players, player)
	}

	return players
}

// RemovePlayer removes a player and reassigns host if needed (atomic operation)
func (g *Game) RemovePlayer(playerID string) {
	g.mu.Lock()
	defer g.mu.Unlock()

	// Check if player exists
	if _, exists := g.Players[playerID]; !exists {
		return
	}

	// If removing the host, reassign to next player by join time
	if g.HostID == playerID {
		// Find the next host (excluding the player being removed)
		var nextHost *Player
		for id, player := range g.Players {
			if id == playerID {
				continue
			}
			if nextHost == nil || player.JoinedAt.Before(nextHost.JoinedAt) {
				nextHost = player
			}
		}

		if nextHost != nil {
			g.HostID = nextHost.ID
		} else {
			g.HostID = ""
		}
	}

	// Remove the player
	delete(g.Players, playerID)
}
