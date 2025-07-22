# Video to WebP Converter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dependencies](https://img.shields.io/badge/dependencies-ffmpeg%20|%20rofi%20|%20zenity-blue)](https://shields.io/)

A simple yet powerful shell script to convert videos into high-quality animated WebP files using a friendly graphical interface.

<!-- TODO: Add a GIF of the script in action! -->
<!-- !Script Demo -->

This script is for Linux desktop users who want a fast, interactive way to create WebP animations without typing complex `ffmpeg` commands. It guides you through every step, from picking a file to customizing the final output.

## Features

-   **Graphical & Interactive**: Uses Zenity for file browsing and Rofi for menus. No command-line flags to memorize.
-   **Single or Batch Mode**: Convert one video or all videos in a folder at once.
-   **Full Conversion Control**: Easily set the FPS, quality, resolution, compression preset, and looping.
-   **Smart & Flexible**: Offers suggestions for output directories and filenames, but lets you choose your own.
-   **Instant Feedback**: See the conversion progress and get a summary when it's done.

## Getting Started

### 1. Prerequisites

This script requires `ffmpeg`, `rofi`, and `zenity`. You can install them using your system's package manager.

**On Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install ffmpeg rofi zenity
```

### Installation on Arch Linux

```bash
sudo pacman -Syu ffmpeg rofi zenity
```

### Installation on Fedora

```bash
sudo dnf install ffmpeg rofi zenity
```

## Setup

1.  **Clone the repository or download the files:**
    ```bash
    git clone <your-repo-url>
    cd video2webp
    ```

2.  **Make the script executable:**
    The main script is `video_to_webp2.sh`.
    ```bash
    chmod +x video_to_webp2.sh
    ```

3.  **(Optional) Rofi Theme:**
    The script is configured to look for a Rofi theme file named `custom_theme.rasi` in the same directory. If you have a theme, place it here. If the file is not found, the script will gracefully fall back to your default Rofi theme.

## Usage

Simply run the script from your terminal:

```bash
./video_to_webp2.sh
```

The script will guide you through the following steps:

1.  **Select Video File**: A Zenity file browser will open. Select any video file in the folder you want to work with.
2.  **Choose Conversion Scope**: A Rofi menu will ask if you want to convert only the selected file or all video files in that directory.
3.  **Configure Conversion Settings**: You will be prompted with a series of Rofi menus to select the frame rate, quality, resolution, preset, and loop behavior.
4.  **Select Output Directory**: Choose where to save the converted WebP file(s). You can pick a suggestion or type a new path.
5.  **Confirm Filename**: If you are converting a single file, you can confirm or edit the proposed output filename. For batch conversions, a pre-selected naming structure is used.
6.  **Conversion**: The script will start converting the files. You can see the progress in your terminal.
7.  **Summary**: A final Rofi notification will appear, summarizing how many files were converted successfully and how many failed.

## Bonus: Animated Wallpaper with `swww`

The animated WebP files you create with this script are perfect for use as dynamic wallpapers on Wayland-based desktops using the swww wallpaper daemon.

`swww` is a lightweight and efficient wallpaper daemon for Wayland compositors like Hyprland or Sway.

```bash
swww img /path/to/your/output_file.webp
```

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.