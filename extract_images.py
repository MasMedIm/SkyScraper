#!/usr/bin/env python3
"""
Script to extract one frame every INTERVAL seconds from videos in the 'videos' directory.
Extracted frames are saved in the 'images' directory with filenames '{video_base}_%06d.png'.
"""

import os
import sys
import subprocess
import shutil

# Configuration
VIDEOS_DIR = "videos"
IMAGES_DIR = "images"
INTERVAL = 2  # seconds between extracted frames

def main():
    if shutil.which("ffmpeg") is None:
        print("Error: ffmpeg not found. Please install ffmpeg.", file=sys.stderr)
        sys.exit(1)

    if not os.path.isdir(VIDEOS_DIR):
        print(f"Error: Videos directory '{VIDEOS_DIR}' not found.", file=sys.stderr)
        sys.exit(1)

    os.makedirs(IMAGES_DIR, exist_ok=True)

    video_extensions = (".mp4", ".mov", ".avi", ".mkv")
    videos = [f for f in os.listdir(VIDEOS_DIR) if f.lower().endswith(video_extensions)]
    if not videos:
        print(f"No video files found in '{VIDEOS_DIR}'.")
        return

    for video in videos:
        input_path = os.path.join(VIDEOS_DIR, video)
        base_name, _ = os.path.splitext(video)
        output_pattern = os.path.join(IMAGES_DIR, f"{base_name}_%06d.png")
        print(f"Extracting from '{video}' -> '{output_pattern}' every {INTERVAL} seconds...")
        cmd = [
            "ffmpeg",
            "-hide_banner",
            "-loglevel", "error",
            "-i", input_path,
            "-vf", f"fps=1/{INTERVAL}",
            output_pattern,
        ]
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error extracting frames from '{video}': {e}", file=sys.stderr)

    print("Extraction complete.")

if __name__ == "__main__":
    main()