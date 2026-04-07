package game

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/sjohnson-confluent/impostor/internal/models"
	"github.com/sjohnson-confluent/impostor/internal/wordlist"
)

// Manager handles all game operations
type Manager struct {
	games        map[string]*models.Game
	wordList     *wordlist.WordList
	roleAssigner *RoleAssigner
	mu           sync.RWMutex
}

// NewManager creates a new game manager
func NewManager(wordList *wordlist.WordList) *Manager {
	return &Manager{
		games:        make(map[string]*models.Game),
		wordList:     wordList,
		roleAssigner: NewRoleAssigner(),
	}
}

// CreateGame creates a new game with a unique code
func (m *Manager) CreateGame() (*models.Game, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	// Generate a unique 6-character game code
	code := m.generateGameCode()
	for m.games[code] != nil {
		code = m.generateGameCode()
	}

	game := models.NewGame(code)
	m.games[code] = game

	return game, nil
}

// GetGame retrieves a game by its code
func (m *Manager) GetGame(code string) (*models.Game, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	game, exists := m.games[code]
	if !exists {
		return nil, fmt.Errorf("game not found")
	}

	return game, nil
}

// GetGameByToken retrieves a game by a player's session token
func (m *Manager) GetGameByToken(token string) (*models.Game, *models.Player, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, game := range m.games {
		if player, exists := game.GetPlayerByToken(token); exists {
			return game, player, nil
		}
	}

	return nil, nil, fmt.Errorf("no game found for token")
}

// JoinGame adds a player to a game
func (m *Manager) JoinGame(code, name string) (*models.Game, *models.Player, error) {
	game, err := m.GetGame(code)
	if err != nil {
		return nil, nil, err
	}

	// Check if game is full (max 12 players)
	if game.GetPlayerCount() >= 12 {
		return nil, nil, fmt.Errorf("game is full (max 12 players)")
	}

	// Check if name is already taken
	if game.IsNameTaken(name) {
		return nil, nil, fmt.Errorf("name already taken")
	}

	// Create player
	player := &models.Player{
		ID:           m.generatePlayerID(),
		Name:         name,
		SessionToken: m.generateSessionToken(),
		Role:         models.RoleUnknown,
		HasSkipped:   false,
		JoinedAt:     time.Now(),
	}

	game.AddPlayer(player)

	return game, player, nil
}

// NextRound advances the game to the next round and assigns roles
func (m *Manager) NextRound(game *models.Game, playerToken string) error {
	// Verify the player is the host
	player, exists := game.GetPlayerByToken(playerToken)
	if !exists {
		return fmt.Errorf("player not found")
	}

	if player.ID != game.HostID {
		return fmt.Errorf("only the host can advance rounds")
	}

	// Get all players as a slice
	players := make([]*models.Player, 0, len(game.Players))
	for _, p := range game.Players {
		players = append(players, p)
	}

	if len(players) == 0 {
		return fmt.Errorf("no players in game")
	}

	// Assign roles
	m.roleAssigner.AssignRoles(players)

	// Reset skip votes
	game.ResetSkipVotes()

	// Get a random word
	word := m.wordList.GetRandomWord()

	// Increment round number and create new round
	game.RoundNumber++
	game.CurrentRound = &models.Round{
		Number:      game.RoundNumber,
		Word:        word,
		StartedAt:   time.Now(),
		SkipVotes:   0,
		SkipCount:   0,
		IsCompleted: false,
	}

	game.IsStarted = true

	return nil
}

// VoteWordSkip records a player's vote to skip the current word
func (m *Manager) VoteWordSkip(game *models.Game, player *models.Player) (bool, error) {
	if game.CurrentRound == nil {
		return false, fmt.Errorf("no active round")
	}

	// Check if player is an impostor
	if player.Role == models.RoleImpostor {
		return false, fmt.Errorf("impostors cannot skip words")
	}

	// Check if player has already voted to skip
	if player.HasSkipped {
		return false, fmt.Errorf("player has already voted to skip")
	}

	// Record the skip vote
	player.HasSkipped = true
	game.CurrentRound.SkipVotes++

	// Count total innocent players
	innocentCount := 0
	for _, p := range game.Players {
		if p.Role == models.RoleInnocent {
			innocentCount++
		}
	}

	// Check if 50% or more innocent players have voted to skip
	requiredVotes := (innocentCount + 1) / 2 // Ceiling division
	shouldSkip := game.CurrentRound.SkipVotes >= requiredVotes

	return shouldSkip, nil
}

// SkipWord starts a new round with a new word (without incrementing round number)
func (m *Manager) SkipWord(game *models.Game) error {
	if game.CurrentRound == nil {
		return fmt.Errorf("no active round")
	}

	// Get all players as a slice
	players := make([]*models.Player, 0, len(game.Players))
	for _, p := range game.Players {
		players = append(players, p)
	}

	// Reassign roles (as mentioned in spec to avoid tipping off players)
	m.roleAssigner.AssignRoles(players)

	// Reset skip votes
	game.ResetSkipVotes()

	// Get a new random word
	word := m.wordList.GetRandomWord()

	// Update current round with new word (don't increment round number)
	game.CurrentRound.Word = word
	game.CurrentRound.StartedAt = time.Now()
	game.CurrentRound.SkipVotes = 0
	game.CurrentRound.SkipCount++ // Increment skip counter so players can detect word changes

	return nil
}

// generateGameCode creates a random 6-character game code
func (m *Manager) generateGameCode() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	const codeLength = 6

	code := make([]byte, codeLength)
	for i := range code {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(charset))))
		code[i] = charset[n.Int64()]
	}

	return string(code)
}

// generatePlayerID creates a random player ID
func (m *Manager) generatePlayerID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// KickPlayer removes a player from the game (host only)
func (m *Manager) KickPlayer(game *models.Game, hostToken string, playerIDToKick string) error {
	// Verify the requester is the host
	host, exists := game.GetPlayerByToken(hostToken)
	if !exists {
		return fmt.Errorf("host not found")
	}

	if host.ID != game.HostID {
		return fmt.Errorf("only the host can kick players")
	}

	// Cannot kick yourself
	if playerIDToKick == host.ID {
		return fmt.Errorf("cannot kick yourself")
	}

	// Check if player exists
	if _, exists := game.GetPlayer(playerIDToKick); !exists {
		return fmt.Errorf("player not found")
	}

	// Reassign host and remove player atomically
	game.RemovePlayer(playerIDToKick)

	return nil
}

// LeaveGame removes a player from the game (self-initiated)
func (m *Manager) LeaveGame(game *models.Game, sessionToken string) error {
	// Find the player by token
	player, exists := game.GetPlayerByToken(sessionToken)
	if !exists {
		return fmt.Errorf("player not found")
	}

	// Reassign host and remove player atomically
	game.RemovePlayer(player.ID)

	return nil
}

// generateSessionToken creates a random session token
func (m *Manager) generateSessionToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}
