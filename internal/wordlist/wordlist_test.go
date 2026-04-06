package wordlist

import (
	"os"
	"path/filepath"
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

func TestNewFromDirectory(t *testing.T) {
	// Create a temporary directory with word files
	tmpDir := t.TempDir()

	// Create test word files
	file1 := filepath.Join(tmpDir, "words1.txt")
	file2 := filepath.Join(tmpDir, "words2.txt")

	err := os.WriteFile(file1, []byte("apple\nbanana\ncherry\n"), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	err = os.WriteFile(file2, []byte("dog\ncat\nbird\n"), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Load wordlist from directory
	wl, err := New(tmpDir)
	if err != nil {
		t.Fatalf("Failed to load wordlist: %v", err)
	}

	// Should have 6 words total
	if wl.Count() != 6 {
		t.Errorf("Expected 6 words, got %d", wl.Count())
	}

	// Verify all words can be retrieved
	foundWords := make(map[string]bool)
	for i := 0; i < 200; i++ {
		word := wl.GetRandomWord()
		foundWords[word] = true
	}

	expectedWords := []string{"apple", "banana", "cherry", "dog", "cat", "bird"}
	for _, w := range expectedWords {
		if !foundWords[w] {
			t.Errorf("Expected word '%s' not found", w)
		}
	}
}

func TestNewFromDirectoryNoFiles(t *testing.T) {
	tmpDir := t.TempDir()

	// Try to load from empty directory
	_, err := New(tmpDir)
	if err == nil {
		t.Error("Expected error when loading from directory with no word files")
	}
}

func TestNewFromDirectoryWithEmptyFiles(t *testing.T) {
	tmpDir := t.TempDir()

	// Create empty file
	emptyFile := filepath.Join(tmpDir, "empty.txt")
	err := os.WriteFile(emptyFile, []byte(""), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Try to load
	_, err = New(tmpDir)
	if err == nil {
		t.Error("Expected error when all word files are empty")
	}
}

func TestNewFromDirectoryWithWhitespace(t *testing.T) {
	tmpDir := t.TempDir()

	// Create file with whitespace
	file := filepath.Join(tmpDir, "words.txt")
	content := `
	apple
	  banana

	cherry
	`
	err := os.WriteFile(file, []byte(content), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	wl, err := New(tmpDir)
	if err != nil {
		t.Fatalf("Failed to load wordlist: %v", err)
	}

	// Should have 3 words (whitespace lines ignored)
	if wl.Count() != 3 {
		t.Errorf("Expected 3 words, got %d", wl.Count())
	}

	// Verify words are trimmed
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
