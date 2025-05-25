# SkyScrapper: Aerial Image Analysis with Google Gemini

This repository demonstrates how to extract frames from aerial drone videos and analyze them using the Google Gemini generative AI API. Use this toolkit to detect rooftop issues (cracks, missing tiles, leaks, debris) or street-level concerns (graffiti, potholes, tree issues, trash, homelessness) from drone footage.

## Features
- Extract one frame every N seconds from videos using `ffmpeg` (via Python script).
- Analyze a single image or batch-process a directory of images with Google Gemini.
- Consolidate JSON responses for downstream processing or visualization.

## Prerequisites
- Bash shell (macOS/Linux) or compatible environment.
- Python 3.6+.
- ffmpeg installed and available on `$PATH`.
- `curl` and `base64` utilities (standard on most systems).
- `jq` (optional, for pretty-printing and merging JSON responses).
- A Google API key with access to the Generative Language API.

## Setup
1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/drone-hack.git
   cd drone-hack
   ```
2. Create a `.env` file in the project root with your API key:
   ```dotenv
   GEMINI_API_KEY=your_google_api_key_here
   ```

## Usage

### 1. Extract Frames from Videos
Place your drone video files (e.g. `.mp4`, `.mov`, `.avi`, `.mkv`) in the `videos/` directory, then run:
```bash
./extract_images.py
```
By default, this extracts one frame every 2 seconds into the `images/` directory. Adjust the `INTERVAL` constant in `extract_images.py` to change the frequency.

### 2. Analyze a Single Image
To analyze one image, run:
```bash
./call_gemini.sh <path/to/image.png>
```
The script builds a JSON payload, sends it to the Gemini API, and writes the response to `response.json`. If `jq` is installed, the output is pretty-printed.

### 3. Batch-Process a Directory of Images
To send all images in a directory to Gemini and merge their responses:
```bash
./call_gemini_batch.sh images
```
Responses are stored per-image in `gemini_responses/response_<image>.json`, and a consolidated file `gemini_responses/final_responses_<TIMESTAMP>.json` is created.

## Directory Structure
```
.
├── videos/                 # Raw drone video files
├── images/                 # Extracted image frames
├── extract_images.py       # Script to extract frames via ffmpeg
├── call_gemini.sh         # Analyze a single image with Gemini
├── call_gemini_batch.sh   # Batch analysis and merging of responses
├── gemini_responses/       # Per-image and consolidated JSON outputs
├── response.json           # Last single-image API response
└── README.md               # This documentation
```

## Customization
- Modify the prompt text in `call_gemini.sh` or `call_gemini_batch.sh` to tailor the analysis (e.g., change detection objectives).
- Change the frame extraction interval in `extract_images.py` by editing the `INTERVAL` constant.

