#!/usr/bin/env bash
set -euo pipefail

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure .env exists and load
if [ ! -f .env ]; then
  echo ".env file not found. Please create one with:"
  echo "  GEMINI_API_KEY=your_google_api_key_here"
  exit 1
fi
set -o allexport
source .env
set +o allexport

# Check API key
if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "GEMINI_API_KEY is not set. Please update .env."
  exit 1
fi

# Require images directory
if [ $# -lt 1 ]; then
  echo "Usage: $0 <images_directory>"
  exit 1
fi
IMG_DIR="$1"
if [ ! -d "$IMG_DIR" ]; then
  echo "Directory not found: $IMG_DIR"
  exit 1
fi

# Ensure jq is available for merging results
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to merge responses. Please install jq."
  exit 1
fi

# Create output directory
OUT_DIR="gemini_responses"
mkdir -p "$OUT_DIR"

# Process each image
shopt -s nullglob
for IMG_PATH in "$IMG_DIR"/*.{jpg,JPG,jpeg,JPEG,png,PNG}; do
  [ -f "$IMG_PATH" ] || continue
  IMG_NAME="$(basename "$IMG_PATH")"
  NAME="${IMG_NAME%.*}"
  RESPONSE_JSON="${OUT_DIR}/response_${NAME}.json"
  echo "Processing $IMG_PATH -> $RESPONSE_JSON"

  MIME_TYPE=$(file -b --mime-type "$IMG_PATH")
  IMAGE_B64=$(base64 < "$IMG_PATH" | tr -d '\n')

  PAYLOAD="${OUT_DIR}/payload_${NAME}.json"
  cat > "$PAYLOAD" <<EOF
{
  "contents": [
    {
      "parts": [
        {
          "inline_data": {
            "mime_type": "$MIME_TYPE",
            "data": "$IMAGE_B64"
          }
        },
        {
          "text": "Give me all the details in this aerial image. The objective is to detect rooftop issues : cracks, missing tiles, leaks, debris, etc."
        }
      ]
    }
  ]
}
EOF

  curl -sS \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -X POST \
    -d @"$PAYLOAD" \
    -o "$RESPONSE_JSON"

  rm "$PAYLOAD"
done

# Merge all responses into a final JSON file
FINAL_JSON="${OUT_DIR}/final_responses_$(date +%Y%m%d_%H%M%S).json"
echo "[" > "$FINAL_JSON"
first=true
for f in "${OUT_DIR}"/response_*.json; do
  [ -f "$f" ] || continue
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$FINAL_JSON"
  fi
  echo "{\"image\":\"$(basename "$f")\"," >> "$FINAL_JSON"
  jq -c . "$f" >> "$FINAL_JSON"
  echo "}" >> "$FINAL_JSON"
done
echo "]" >> "$FINAL_JSON"

echo "All responses saved in $OUT_DIR and consolidated in $FINAL_JSON"