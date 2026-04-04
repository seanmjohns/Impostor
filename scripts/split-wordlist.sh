#!/bin/zsh

# Split a wordlist into chunks of 2000 words each
# Usage: ./split-wordlist.sh <input-file> [output-dir]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input-file> [output-dir]"
    echo "Example: $0 words.txt wordlists"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="${2:-wordlists}"
CHUNK_SIZE=200

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created directory: $OUTPUT_DIR"
fi

# Read words into array, filtering out empty lines
words=()
while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading/trailing whitespace without xargs
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -n "$line" ]; then
        words+=("$line")
    fi
done < "$INPUT_FILE"

total_words=${#words[@]}
echo "Total words: $total_words"

# Calculate number of chunks
num_chunks=$(( (total_words + CHUNK_SIZE - 1) / CHUNK_SIZE ))
echo "Splitting into $num_chunks chunks of up to $CHUNK_SIZE words each"

# Split into chunks and write to files
chunk_num=1
start_idx=1

while [ $start_idx -le $total_words ]; do
    end_idx=$(( start_idx + CHUNK_SIZE - 1 ))
    if [ $end_idx -gt $total_words ]; then
        end_idx=$total_words
    fi

    # Format chunk number with leading zeros (001, 002, etc.)
    chunk_file="$OUTPUT_DIR/words-$(printf '%03d' $chunk_num).txt"

    # Write chunk to file
    for i in {$start_idx..$end_idx}; do
        echo "${words[$i]}"
    done > "$chunk_file"

    actual_count=$(( end_idx - start_idx + 1 ))
    echo "  Wrote $actual_count words to: $chunk_file"

    start_idx=$(( end_idx + 1 ))
    chunk_num=$(( chunk_num + 1 ))
done

echo "\nDone! Created $num_chunks files in $OUTPUT_DIR/"
