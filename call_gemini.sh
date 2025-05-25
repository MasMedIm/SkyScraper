#!/usr/bin/env bash
set -euo pipefail

# Navigate to script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure .env exists
if [ ! -f .env ]; then
  echo ".env file not found in project root. Please create one with:"
  echo "  GEMINI_API_KEY=your_google_api_key_here"
  exit 1
fi

# Load environment variables
set -o allexport
source .env
set +o allexport

# Check for API key
if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "GEMINI_API_KEY is not set. Please update your .env file."
  exit 1
fi

# Require image path argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 <image_path>"
  exit 1
fi
IMG_PATH="$1"

if [ ! -f "$IMG_PATH" ]; then
  echo "Image file not found: $IMG_PATH"
  exit 1
fi

# Determine MIME type
MIME_TYPE=$(file -b --mime-type "$IMG_PATH")

# Encode image to base64 (strip line breaks for JSON compatibility)
# Read image data via stdin for broad base64 compatibility
IMAGE_B64=$(base64 < "${IMG_PATH}" | tr -d '\n')

# Build request payload (temporary JSON file)
REQUEST_JSON="call_gemini_payload_$$.json"
cat > "$REQUEST_JSON" <<EOF
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
          "text": "Give me all the details in this aerial image. The objective is to detect : Graffiti, potholes, tree issues, trash, and homelessness."
        }
      ]
    }
  ]
}
EOF

# Call Gemini API
RESPONSE_JSON="response.json"
curl -sS \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  -d @"$REQUEST_JSON" \
  -o "$RESPONSE_JSON"

echo "Response saved to $RESPONSE_JSON"

# Pretty-print JSON if jq is available
if command -v jq >/dev/null 2>&1; then
  jq . "$RESPONSE_JSON"
else
  cat "$RESPONSE_JSON"
fi

# Cleanup
rm "$REQUEST_JSON"