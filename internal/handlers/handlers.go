package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sort"

	"github.com/sjohnson-confluent/impostor/internal/game"
	"github.com/sjohnson-confluent/impostor/internal/models"
)

// Handler manages HTTP handlers
type Handler struct {
	gameManager *game.Manager
}

// New creates a new handler
func New(gameManager *game.Manager) *Handler {
	return &Handler{
		gameManager: gameManager,
	}
}

// CreateGame handles POST /create_game
func (h *Handler) CreateGame(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	game, err := h.gameManager.CreateGame()
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"gameCode": game.Code,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// JoinGame handles POST /join_game?gameCode=<code>&name=<name>
func (h *Handler) JoinGame(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	gameCode := r.URL.Query().Get("gameCode")
	name := r.URL.Query().Get("name")

	if gameCode == "" || name == "" {
		http.Error(w, "Missing gameCode or name parameter", http.StatusBadRequest)
		return
	}

	game, player, err := h.gameManager.JoinGame(gameCode, name)
	if err != nil {
		errMsg := err.Error()
		if errMsg == "game not found" || errMsg == "name already taken" || errMsg == "game is full (max 12 players)" {
			http.Error(w, errMsg, http.StatusBadRequest)
		} else {
			http.Error(w, "Internal server error", http.StatusInternalServerError)
		}
		return
	}

	response := map[string]interface{}{
		"sessionToken": player.SessionToken,
		"playerId":     player.ID,
		"playerName":   player.Name,
		"gameCode":     game.Code,
		"isHost":       player.ID == game.HostID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// NextRound handles POST /next_round
func (h *Handler) NextRound(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	game, _, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	err = h.gameManager.NextRound(game, sessionToken)
	if err != nil {
		if err.Error() == "only the host can advance rounds" {
			http.Error(w, err.Error(), http.StatusForbidden)
		} else if err.Error() == "player not found" || err.Error() == "no players in game" {
			http.Error(w, err.Error(), http.StatusBadRequest)
		} else {
			http.Error(w, "Error advancing to next round", http.StatusInternalServerError)
		}
		return
	}

	response := map[string]interface{}{
		"success":     true,
		"roundNumber": game.RoundNumber,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetWord handles GET /get_word
func (h *Handler) GetWord(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	game, player, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	if game.CurrentRound == nil {
		http.Error(w, "No active round", http.StatusBadRequest)
		return
	}

	var response map[string]interface{}

	if player.Role == models.RoleImpostor {
		response = map[string]interface{}{
			"isImpostor":  true,
			"roundNumber": game.RoundNumber,
			"skipCount":   game.CurrentRound.SkipCount,
		}
	} else {
		response = map[string]interface{}{
			"isImpostor":  false,
			"word":        game.CurrentRound.Word,
			"roundNumber": game.RoundNumber,
			"skipCount":   game.CurrentRound.SkipCount,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// VoteWordSkip handles POST /vote_word_skip
func (h *Handler) VoteWordSkip(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	game, player, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	shouldSkip, err := h.gameManager.VoteWordSkip(game, player)
	if err != nil {
		if err.Error() == "impostors cannot skip words" || err.Error() == "no active round" || err.Error() == "player has already voted to skip" {
			http.Error(w, err.Error(), http.StatusBadRequest)
		} else {
			http.Error(w, "Internal server error", http.StatusInternalServerError)
		}
		return
	}

	// If enough players voted to skip, start a new round with a new word
	if shouldSkip {
		err = h.gameManager.SkipWord(game)
		if err != nil {
			http.Error(w, "Error skipping word", http.StatusInternalServerError)
			return
		}
	}

	response := map[string]interface{}{
		"success":     true,
		"skipped":     shouldSkip,
		"skipVotes":   game.CurrentRound.SkipVotes,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// KickPlayer handles POST /kick_player?playerId=<id>
func (h *Handler) KickPlayer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	playerIDToKick := r.URL.Query().Get("playerId")
	if playerIDToKick == "" {
		http.Error(w, "Missing playerId parameter", http.StatusBadRequest)
		return
	}

	game, _, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	err = h.gameManager.KickPlayer(game, sessionToken, playerIDToKick)
	if err != nil {
		if err.Error() == "only the host can kick players" {
			http.Error(w, err.Error(), http.StatusForbidden)
		} else if err.Error() == "cannot kick yourself" || err.Error() == "player not found" {
			http.Error(w, err.Error(), http.StatusBadRequest)
		} else {
			http.Error(w, "Internal server error", http.StatusInternalServerError)
		}
		return
	}

	response := map[string]interface{}{
		"success":      true,
		"kickedPlayer": playerIDToKick,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetPlayers handles GET /players
func (h *Handler) GetPlayers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	game, _, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	// Build player list (excluding role information)
	type PlayerInfo struct {
		ID     string `json:"id"`
		Name   string `json:"name"`
		IsHost bool   `json:"isHost"`
	}

	// Get all players with proper locking
	playerList := game.GetSortedPlayers()

	// Sort by join time to maintain consistent order
	// Use stable sort to maintain consistent order even for same timestamps
	sort.SliceStable(playerList, func(i, j int) bool {
		// If join times are equal, sort by ID for consistency
		if playerList[i].JoinedAt.Equal(playerList[j].JoinedAt) {
			return playerList[i].ID < playerList[j].ID
		}
		return playerList[i].JoinedAt.Before(playerList[j].JoinedAt)
	})

	// Build sorted player info list
	players := make([]PlayerInfo, 0, len(playerList))
	for _, player := range playerList {
		players = append(players, PlayerInfo{
			ID:     player.ID,
			Name:   player.Name,
			IsHost: player.ID == game.HostID,
		})
	}

	response := map[string]interface{}{
		"players":     players,
		"playerCount": len(players),
		"gameCode":    game.Code,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// LeaveGame handles POST /leave_game
func (h *Handler) LeaveGame(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionToken := r.Header.Get("Authorization")
	if sessionToken == "" {
		http.Error(w, "Missing session token", http.StatusBadRequest)
		return
	}

	game, _, err := h.gameManager.GetGameByToken(sessionToken)
	if err != nil {
		http.Error(w, "Session not found", http.StatusBadRequest)
		return
	}

	err = h.gameManager.LeaveGame(game, sessionToken)
	if err != nil {
		http.Error(w, "Error leaving game", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"success": true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// HealthCheck handles GET /health
func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok"}`)
}
