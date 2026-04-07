package game

import (
	"testing"

	"github.com/sjohnson-confluent/impostor/internal/models"
)

func TestAssignRoles(t *testing.T) {
	ra := NewRoleAssigner()

	tests := []struct {
		name        string
		playerCount int
	}{
		{"3 players", 3},
		{"4 players", 4},
		{"5 players", 5},
		{"8 players", 8},
		{"12 players", 12},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create players
			players := make([]*models.Player, tt.playerCount)
			for i := 0; i < tt.playerCount; i++ {
				players[i] = &models.Player{
					ID:   string(rune('A' + i)),
					Name: string(rune('A' + i)),
				}
			}

			// Assign roles
			ra.AssignRoles(players)

			// Count roles
			innocentCount := 0
			impostorCount := 0

			for _, p := range players {
				if p.Role == models.RoleInnocent {
					innocentCount++
				} else if p.Role == models.RoleImpostor {
					impostorCount++
				} else {
					t.Errorf("Player %s has invalid role: %s", p.Name, p.Role)
				}
			}

			// Total should equal player count
			if innocentCount+impostorCount != tt.playerCount {
				t.Errorf("Expected %d total roles, got %d", tt.playerCount, innocentCount+impostorCount)
			}

			// Should have at least 1 impostor
			if impostorCount < 1 {
				t.Error("Should have at least 1 impostor")
			}

			// Should have at least 1 innocent (assuming more than 1 player)
			if tt.playerCount > 1 && innocentCount < 1 {
				t.Error("Should have at least 1 innocent player")
			}

			t.Logf("%s: %d innocent, %d impostor", tt.name, innocentCount, impostorCount)
		})
	}
}

func TestAssignRolesGuaranteesAtLeastOneImpostor(t *testing.T) {
	ra := NewRoleAssigner()

	// Run multiple times to test statistical guarantee
	for run := 0; run < 100; run++ {
		players := make([]*models.Player, 5)
		for i := 0; i < 5; i++ {
			players[i] = &models.Player{
				ID:   string(rune('A' + i)),
				Name: string(rune('A' + i)),
			}
		}

		ra.AssignRoles(players)

		impostorCount := 0
		for _, p := range players {
			if p.Role == models.RoleImpostor {
				impostorCount++
			}
		}

		if impostorCount < 1 {
			t.Errorf("Run %d: Should have at least 1 impostor", run)
		}
	}
}

func TestAssignRolesAverageImpostorCount(t *testing.T) {
	ra := NewRoleAssigner()

	// Test with 5 players over many runs
	// With 5 players, we expect average closer to 1-2 impostors
	const runs = 1000
	totalImpostors := 0

	for run := 0; run < runs; run++ {
		players := make([]*models.Player, 5)
		for i := 0; i < 5; i++ {
			players[i] = &models.Player{
				ID:   string(rune('A' + i)),
				Name: string(rune('A' + i)),
			}
		}

		ra.AssignRoles(players)

		for _, p := range players {
			if p.Role == models.RoleImpostor {
				totalImpostors++
			}
		}
	}

	avgImpostors := float64(totalImpostors) / float64(runs)

	// With 5 players, average should be between 0.5 and 2.5
	if avgImpostors < 0.5 || avgImpostors > 2.5 {
		t.Errorf("Expected average between 0.5 and 2.5 impostors, got %.2f", avgImpostors)
	}

	t.Logf("Average impostors over %d runs with 5 players: %.2f", runs, avgImpostors)
}

// TestCalculateStartingProbability tests the probability calculation indirectly
// by verifying role distribution over many runs
func TestProbabilityDistribution(t *testing.T) {
	ra := NewRoleAssigner()

	tests := []struct {
		playerCount int
		runs        int
		minAvg      float64
		maxAvg      float64
	}{
		{3, 100, 0.5, 2.0},    // Small games
		{5, 100, 0.5, 2.5},    // Medium games
		{10, 100, 0.5, 4.0},   // Larger games can have more impostors
	}

	for _, tt := range tests {
		totalImpostors := 0

		for run := 0; run < tt.runs; run++ {
			players := make([]*models.Player, tt.playerCount)
			for i := 0; i < tt.playerCount; i++ {
				players[i] = &models.Player{
					ID:   string(rune('A' + i)),
					Name: string(rune('A' + i)),
				}
			}

			ra.AssignRoles(players)

			for _, p := range players {
				if p.Role == models.RoleImpostor {
					totalImpostors++
				}
			}
		}

		avgImpostors := float64(totalImpostors) / float64(tt.runs)
		t.Logf("Player count %d: average %.2f impostors per game over %d runs",
			tt.playerCount, avgImpostors, tt.runs)

		// Average should be within expected range
		if avgImpostors < tt.minAvg || avgImpostors > tt.maxAvg {
			t.Errorf("Player count %d: expected average between %.2f and %.2f, got %.2f",
				tt.playerCount, tt.minAvg, tt.maxAvg, avgImpostors)
		}
	}
}

func TestAssignRolesWithSinglePlayer(t *testing.T) {
	ra := NewRoleAssigner()

	players := []*models.Player{
		{ID: "1", Name: "Alice"},
	}

	ra.AssignRoles(players)

	// Single player should be impostor
	if players[0].Role != models.RoleImpostor {
		t.Errorf("Single player should be impostor, got %s", players[0].Role)
	}
}

func TestAssignRolesWithTwoPlayers(t *testing.T) {
	ra := NewRoleAssigner()

	// Run multiple times and track distribution
	impostorCounts := make(map[int]int)

	for run := 0; run < 100; run++ {
		players := []*models.Player{
			{ID: "1", Name: "Alice"},
			{ID: "2", Name: "Bob"},
		}

		ra.AssignRoles(players)

		impostorCount := 0
		for _, p := range players {
			if p.Role == models.RoleImpostor {
				impostorCount++
			}
		}

		impostorCounts[impostorCount]++

		// Should have at least 1 impostor (guarantee)
		if impostorCount < 1 {
			t.Errorf("Run %d: Should have at least 1 impostor, got %d", run, impostorCount)
		}
	}

	t.Logf("Two player distribution: %v", impostorCounts)
	// Most common should be 1 impostor, but 2 is possible due to randomness
}

func TestAssignRolesReassignment(t *testing.T) {
	ra := NewRoleAssigner()

	players := make([]*models.Player, 5)
	for i := 0; i < 5; i++ {
		players[i] = &models.Player{
			ID:   string(rune('A' + i)),
			Name: string(rune('A' + i)),
		}
	}

	// Assign roles first time
	ra.AssignRoles(players)

	firstAssignment := make(map[string]models.PlayerRole)
	for _, p := range players {
		firstAssignment[p.ID] = p.Role
	}

	// Assign roles again (simulating word skip)
	ra.AssignRoles(players)

	secondAssignment := make(map[string]models.PlayerRole)
	for _, p := range players {
		secondAssignment[p.ID] = p.Role
	}

	// Roles should potentially change (not guaranteed to be different, but test structure)
	// Just verify that roles are assigned
	for _, p := range players {
		if p.Role != models.RoleInnocent && p.Role != models.RoleImpostor {
			t.Errorf("Player %s has invalid role after reassignment: %s", p.Name, p.Role)
		}
	}
}
