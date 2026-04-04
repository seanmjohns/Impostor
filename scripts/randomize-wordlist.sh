#!/bin/zsh

# Randomize the order of words in a wordlist
# Usage: ./randomize-wordlist.sh <input-file> [output-file]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input-file> [output-file]"
    echo "Example: $0 words.txt random-words.txt"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.txt}-random.txt}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Randomize using shuf (if available) or sort -R as fallback
if command -v shuf &> /dev/null; then
    shuf "$INPUT_FILE" > "$OUTPUT_FILE"
elif command -v gshuf &> /dev/null; then
    gshuf "$INPUT_FILE" > "$OUTPUT_FILE"
else
    # Fallback to sort -R (not as good randomization but works)
    sort -R "$INPUT_FILE" > "$OUTPUT_FILE"
fi

# Count words
word_count=$(wc -l < "$OUTPUT_FILE" | xargs)

echo "Randomized $word_count words"
echo "Output saved to: $OUTPUT_FILE"
