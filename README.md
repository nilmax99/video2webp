# Video to WebP Converter

## About The Project

<!-- It's highly recommended to add a screenshot or a GIF of the script in action! -->
<!-- !Project Screenshot -->

This project provides a powerful shell script that uses `ffmpeg`, `rofi`, and `zenity` to create a graphical user interface for converting video files into animated WebP images.

It is designed for Linux desktop users who want a quick and interactive way to create high-quality WebP animations without needing to remember or type complex `ffmpeg` commands in the terminal. The script guides you through every step, from file selection to customizing the output.

## Features

-   **User-Friendly GUI**: Uses Zenity for file selection and Rofi for option menus, making it easy to use.
-   **Batch Processing**: Convert a single video or all videos within the same directory in one go.
-   **Highly Customizable Output**:
    -   Adjust **frame rate (FPS)**.
    -   Set **quality** level (0-100).
    -   Define **resolution/scale** (choose from presets or enter a custom size).
    -   Select `libwebp` **compression presets** (e.g., `photo`, `drawing`, `text`) for optimal file size.
    -   Toggle **animation looping**.
-   **Flexible File Naming**: Choose from several predefined naming structures for output files, which is especially useful for batch conversions.
-   **Smart Directory Handling**: Select an output directory from a list of suggestions or type a new path. The script can create the directory if it doesn't exist.
-   **Status Notifications**: Get real-time feedback on the conversion process and a final summary of successful and failed operations.

## Requirements

This script depends on three command-line tools. You must install them using your system's package manager.

-   **`ffmpeg`**: The core engine for video conversion.
-   **`rofi`**: For creating interactive selection menus.
-   **`zenity`**: For the graphical file selection dialog.

### Installation on Debian/Ubuntu

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

### One-Time Setup

To set your newly created animation as a wallpaper, simply run:

```bash
swww img /path/to/your/output_file.webp
```

### Persistent Setup (Autostart)

To make your wallpaper persist across reboots, add the `swww img` command to your Wayland compositor's startup configuration file (e.g., `~/.config/hypr/hyprland.conf` or `~/.config/sway/config`).

```sh
# Example for Hyprland/Sway startup config
exec-once = swww init
exec-once = swww img /path/to/your/output_file.webp
```

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.