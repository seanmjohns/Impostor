package wordlist

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// WordList manages the collection of words for the game
type WordList struct {
	words []string
	rng   *rand.Rand
}

// New creates a new WordList by loading all word files from the specified directory
func New(wordlistDir string) (*WordList, error) {
	wl := &WordList{
		words: make([]string, 0),
		rng:   rand.New(rand.NewSource(time.Now().UnixNano())),
	}

	// Find all .txt files in the wordlist directory
	pattern := filepath.Join(wordlistDir, "*.txt")
	files, err := filepath.Glob(pattern)
	if err != nil {
		return nil, fmt.Errorf("failed to find wordlist files: %w", err)
	}

	if len(files) == 0 {
		return nil, fmt.Errorf("no wordlist files found in %s", wordlistDir)
	}

	// Load words from each file
	for _, file := range files {
		if err := wl.loadFile(file); err != nil {
			return nil, fmt.Errorf("failed to load %s: %w", file, err)
		}
	}

	if len(wl.words) == 0 {
		return nil, fmt.Errorf("no words loaded from wordlist files")
	}

	return wl, nil
}

// loadFile loads words from a single file
func (wl *WordList) loadFile(filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		word := strings.TrimSpace(scanner.Text())
		if word != "" {
			wl.words = append(wl.words, word)
		}
	}

	return scanner.Err()
}

// GetRandomWord returns a random word from the wordlist
func (wl *WordList) GetRandomWord() string {
	if len(wl.words) == 0 {
		return ""
	}

	idx := wl.rng.Intn(len(wl.words))
	return wl.words[idx]
}

// Count returns the total number of words in the wordlist
func (wl *WordList) Count() int {
	return len(wl.words)
}

// LoadWords loads words from a slice (useful for testing)
func (wl *WordList) LoadWords(words []string) {
	wl.words = make([]string, len(words))
	copy(wl.words, words)
	wl.rng = rand.New(rand.NewSource(time.Now().UnixNano()))
}
