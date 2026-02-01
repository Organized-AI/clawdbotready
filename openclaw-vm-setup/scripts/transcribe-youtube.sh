#!/usr/bin/env bash
# transcribe-youtube.sh - Download and transcribe YouTube videos
# Usage: ./transcribe-youtube.sh <youtube_url> [output_path]

set -euo pipefail

VIDEO_URL="${1:-https://youtube.com/watch?v=cTJbjM0T_Fs}"
OUTPUT_PATH="${2:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/BHT Promo iCloud/Organized AI/OpenClaw/openclaw_video_transcript.md}"

echo "=== YouTube Video Transcription Script ==="
echo "Video URL: $VIDEO_URL"
echo "Output: $OUTPUT_PATH"
echo ""

# Check for yt-dlp
if ! command -v yt-dlp &> /dev/null; then
    echo "Installing yt-dlp..."
    brew install yt-dlp || pip install yt-dlp
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
echo "Working in: $TEMP_DIR"

# Try to get auto-generated subtitles first
echo ""
echo "Step 1: Attempting to download auto-generated subtitles..."
if yt-dlp --write-auto-sub --skip-download --sub-lang en -o "video" "$VIDEO_URL" 2>/dev/null; then
    SUB_FILE=$(ls video.en.* 2>/dev/null | head -1)
    if [[ -n "$SUB_FILE" ]]; then
        echo "Found subtitles: $SUB_FILE"

        # Convert VTT/SRT to clean text
        echo ""
        echo "Step 2: Cleaning up transcript..."

        # Remove timestamps, metadata, and clean up the text
        sed -E '
            /^WEBVTT/d
            /^Kind:/d
            /^Language:/d
            /^[0-9]+$/d
            /^[0-9]{2}:[0-9]{2}/d
            /^$/d
            s/<[^>]*>//g
            s/^\s+//
            s/\s+$//
        ' "$SUB_FILE" | \
        awk '!seen[$0]++' | \
        tr '\n' ' ' | \
        sed 's/  */ /g' | \
        fold -s -w 80 > transcript_clean.txt

        # Get video title
        TITLE=$(yt-dlp --get-title "$VIDEO_URL" 2>/dev/null || echo "YouTube Video Transcript")

        # Create markdown file
        echo "Step 3: Creating markdown file..."
        {
            echo "# $TITLE"
            echo ""
            echo "**Source:** $VIDEO_URL"
            echo "**Transcribed:** $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "---"
            echo ""
            cat transcript_clean.txt
        } > transcript.md

        # Ensure output directory exists
        mkdir -p "$(dirname "$OUTPUT_PATH")"

        # Copy to final location
        cp transcript.md "$OUTPUT_PATH"
        echo ""
        echo "=== SUCCESS ==="
        echo "Transcript saved to: $OUTPUT_PATH"

        # Cleanup
        rm -rf "$TEMP_DIR"
        exit 0
    fi
fi

# Fallback: Use whisper for transcription
echo ""
echo "Subtitles not available. Using Whisper for transcription..."

# Check for whisper
if ! command -v whisper &> /dev/null; then
    echo "Installing openai-whisper..."
    pip install openai-whisper
fi

# Download audio
echo "Downloading audio..."
yt-dlp -x --audio-format mp3 -o "audio.%(ext)s" "$VIDEO_URL"

# Get video title
TITLE=$(yt-dlp --get-title "$VIDEO_URL" 2>/dev/null || echo "YouTube Video Transcript")

# Transcribe with whisper
echo ""
echo "Transcribing with Whisper (this may take a while)..."
whisper audio.mp3 --output_format txt --output_dir .

# Create markdown file
{
    echo "# $TITLE"
    echo ""
    echo "**Source:** $VIDEO_URL"
    echo "**Transcribed:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Method:** OpenAI Whisper"
    echo ""
    echo "---"
    echo ""
    cat audio.txt
} > transcript.md

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Copy to final location
cp transcript.md "$OUTPUT_PATH"

echo ""
echo "=== SUCCESS ==="
echo "Transcript saved to: $OUTPUT_PATH"

# Cleanup
rm -rf "$TEMP_DIR"
