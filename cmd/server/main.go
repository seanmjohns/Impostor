package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/sjohnson-confluent/impostor/internal/game"
	"github.com/sjohnson-confluent/impostor/internal/handlers"
	"github.com/sjohnson-confluent/impostor/internal/wordlist"
)

func main() {
	// Parse command line flags
	portFlag := flag.String("port", "", "Port to listen on (default: 8080, or PORT env var)")
	flag.Parse()
	// Determine wordlist file
	wordlistFile := os.Getenv("WORDLIST_FILE")
	if wordlistFile == "" {
		wordlistFile = "wordlist.txt"
	}

	// Load wordlist
	log.Printf("Loading wordlist from %s...", wordlistFile)
	wl, err := wordlist.New(wordlistFile)
	if err != nil {
		log.Fatalf("Failed to load wordlist: %v", err)
	}
	log.Printf("Loaded %d words", wl.Count())

	// Create game manager
	gameManager := game.NewManager(wl)

	// Create handlers
	h := handlers.New(gameManager)

	// Set up routes
	http.HandleFunc("/create_game", corsMiddleware(h.CreateGame))
	http.HandleFunc("/join_game", corsMiddleware(h.JoinGame))
	http.HandleFunc("/next_round", corsMiddleware(h.NextRound))
	http.HandleFunc("/get_word", corsMiddleware(h.GetWord))
	http.HandleFunc("/vote_word_skip", corsMiddleware(h.VoteWordSkip))
	http.HandleFunc("/kick_player", corsMiddleware(h.KickPlayer))
	http.HandleFunc("/leave_game", corsMiddleware(h.LeaveGame))
	http.HandleFunc("/players", corsMiddleware(h.GetPlayers))
	http.HandleFunc("/health", corsMiddleware(h.HealthCheck))

	// Serve static files
	staticDir := os.Getenv("STATIC_DIR")
	if staticDir == "" {
		staticDir = "."
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			http.ServeFile(w, r, filepath.Join(staticDir, "index.html"))
		} else {
			http.ServeFile(w, r, filepath.Join(staticDir, r.URL.Path))
		}
	})

	// Start server
	// Priority: command line flag > environment variable > default
	port := *portFlag
	if port == "" {
		port = os.Getenv("PORT")
	}
	if port == "" {
		port = "8080"
	}

	addr := fmt.Sprintf(":%s", port)
	log.Printf("Starting server on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// corsMiddleware adds CORS headers to allow cross-origin requests
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		// Handle preflight requests
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}