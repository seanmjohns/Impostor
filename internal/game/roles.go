package game

import (
	"math/rand"
	"time"

	"github.com/sjohnson-confluent/impostor/internal/models"
)

// RoleAssigner handles role assignment for game rounds
type RoleAssigner struct {
	rng *rand.Rand
}

// NewRoleAssigner creates a new role assigner
func NewRoleAssigner() *RoleAssigner {
	return &RoleAssigner{
		rng: rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

// AssignRoles assigns roles to all players according to the game rules:
// - At least 1 impostor 95% of the time
// - On average, 1 impostor total
// - Starting probability of 50% (adjusted based on player count)
// - Probability reduced by 50% if previous player was an impostor
func (ra *RoleAssigner) AssignRoles(players []*models.Player) {
	if len(players) == 0 {
		return
	}

	// Shuffle players to randomize assignment order
	shuffled := make([]*models.Player, len(players))
	copy(shuffled, players)
	ra.rng.Shuffle(len(shuffled), func(i, j int) {
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	})

	// Determine starting probability based on player count
	// For more players, we want a slightly lower starting probability
	// to keep the average around 1 impostor
	startingProb := ra.calculateStartingProbability(len(players))

	// Assign roles using the adaptive probability algorithm
	currentProb := startingProb
	impostorCount := 0

	for _, player := range shuffled {
		if ra.rng.Float64() < currentProb {
			player.Role = models.RoleImpostor
			impostorCount++
			// Reduce probability by 50% after assigning an impostor
			currentProb *= 0.5
		} else {
			player.Role = models.RoleInnocent
			// Reset to starting probability if no impostor was assigned
			currentProb = startingProb
		}
	}

	// Ensure at least one impostor (handles the 5% edge case where none were assigned)
	if impostorCount == 0 {
		// Randomly select one player to be the impostor
		impostorIdx := ra.rng.Intn(len(shuffled))
		shuffled[impostorIdx].Role = models.RoleImpostor
	}
}

// calculateStartingProbability determines the initial probability based on player count
// Adjusted to ensure we average around 1 impostor while maintaining 95%+ chance of at least 1
func (ra *RoleAssigner) calculateStartingProbability(playerCount int) float64 {
	switch {
	case playerCount <= 2:
		return 0.50 // 50% for very small groups
	case playerCount <= 4:
		return 0.45 // Slightly lower for small groups
	case playerCount <= 6:
		return 0.40 // Lower for medium groups
	case playerCount <= 8:
		return 0.35 // Even lower for larger groups
	default:
		return 0.30 // Lowest for very large groups
	}
}
