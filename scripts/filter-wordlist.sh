#!/bin/zsh

# Filter wordlist to keep only words with 5 or more characters
# Usage: ./filter-wordlist.sh <input-file> [output-file] [min-length]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input-file> [output-file] [min-length]"
    echo "Example: $0 words.txt filtered-words.txt 5"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.txt}-filtered.txt}"
MIN_LENGTH="${3:-5}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Filter words by length
awk -v min="$MIN_LENGTH" 'length($0) >= min' "$INPUT_FILE" > "$OUTPUT_FILE"

# Count results
original_count=$(wc -l < "$INPUT_FILE" | xargs)
filtered_count=$(wc -l < "$OUTPUT_FILE" | xargs)
removed_count=$((original_count - filtered_count))

echo "Original words: $original_count"
echo "Filtered words: $filtered_count (>= $MIN_LENGTH characters)"
echo "Removed: $removed_count"
echo "Output saved to: $OUTPUT_FILE"
