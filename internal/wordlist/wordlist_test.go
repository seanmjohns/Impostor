package wordlist

import (
	"os"
	"testing"
)

func TestLoadWords(t *testing.T) {
	wl := &WordList{}
	words := []string{"apple", "banana", "cherry"}

	wl.LoadWords(words)

	if wl.Count() != 3 {
		t.Errorf("Expected 3 words, got %d", wl.Count())
	}

	// Verify words are actually loaded
	foundWords := make(map[string]bool)
	for i := 0; i < 100; i++ {
		word := wl.GetRandomWord()
		foundWords[word] = true
	}

	for _, w := range words {
		if !foundWords[w] {
			t.Errorf("Word '%s' not found in random selections", w)
		}
	}
}

func TestGetRandomWord(t *testing.T) {
	wl := &WordList{}
	words := []string{"apple", "banana", "cherry", "date", "elderberry"}
	wl.LoadWords(words)

	// Get many random words
	counts := make(map[string]int)
	for i := 0; i < 1000; i++ {
		word := wl.GetRandomWord()
		counts[word]++
	}

	// Should get all words at least once
	for _, w := range words {
		if counts[w] == 0 {
			t.Errorf("Word '%s' was never selected", w)
		}
	}

	// Distribution should be somewhat even (very loose check)
	// Each word should appear between 10% and 40% of the time
	for _, w := range words {
		percentage := float64(counts[w]) / 1000.0
		if percentage < 0.10 || percentage > 0.40 {
			t.Logf("Warning: Word '%s' appeared %.1f%% of the time", w, percentage*100)
		}
	}
}

func TestGetRandomWordEmpty(t *testing.T) {
	wl := &WordList{}
	wl.LoadWords([]string{})

	word := wl.GetRandomWord()
	if word != "" {
		t.Errorf("Expected empty string for empty wordlist, got '%s'", word)
	}
}

func TestNewFromFile(t *testing.T) {
	tmpFile, err := os.CreateTemp("", "wordlist-*.txt")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.WriteString("apple\nbanana\ncherry\ndog\ncat\nbird\n"); err != nil {
		t.Fatalf("Failed to write temp file: %v", err)
	}
	tmpFile.Close()

	wl, err := New(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load wordlist: %v", err)
	}

	if wl.Count() != 6 {
		t.Errorf("Expected 6 words, got %d", wl.Count())
	}

	foundWords := make(map[string]bool)
	for i := 0; i < 200; i++ {
		word := wl.GetRandomWord()
		foundWords[word] = true
	}

	for _, w := range []string{"apple", "banana", "cherry", "dog", "cat", "bird"} {
		if !foundWords[w] {
			t.Errorf("Expected word '%s' not found", w)
		}
	}
}

func TestNewFromFileMissing(t *testing.T) {
	_, err := New("/nonexistent/path/wordlist.txt")
	if err == nil {
		t.Error("Expected error when file does not exist")
	}
}

func TestNewFromEmptyFile(t *testing.T) {
	tmpFile, err := os.CreateTemp("", "wordlist-*.txt")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	_, err = New(tmpFile.Name())
	if err == nil {
		t.Error("Expected error when wordlist file is empty")
	}
}

func TestNewFromFileWithWhitespace(t *testing.T) {
	tmpFile, err := os.CreateTemp("", "wordlist-*.txt")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	content := "\n\tapple\n  banana\n\ncherry\n"
	if _, err := tmpFile.WriteString(content); err != nil {
		t.Fatalf("Failed to write temp file: %v", err)
	}
	tmpFile.Close()

	wl, err := New(tmpFile.Name())
	if err != nil {
		t.Fatalf("Failed to load wordlist: %v", err)
	}

	if wl.Count() != 3 {
		t.Errorf("Expected 3 words, got %d", wl.Count())
	}

	foundWords := make(map[string]bool)
	for i := 0; i < 100; i++ {
		word := wl.GetRandomWord()
		foundWords[word] = true
	}

	for _, w := range []string{"apple", "banana", "cherry"} {
		if !foundWords[w] {
			t.Errorf("Expected trimmed word '%s' not found", w)
		}
	}
}

func TestCount(t *testing.T) {
	wl := &WordList{}

	if wl.Count() != 0 {
		t.Errorf("Expected 0 for uninitialized wordlist, got %d", wl.Count())
	}

	wl.LoadWords([]string{"a", "b", "c", "d", "e"})

	if wl.Count() != 5 {
		t.Errorf("Expected 5 words, got %d", wl.Count())
	}
}