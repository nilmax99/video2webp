#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first."
    exit 1
fi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Please install it first."
    exit 1
fi

# Check if zenity is installed (optional for graphical file selection)
if command -v zenity &> /dev/null; then
    zenity_available=true
else
    zenity_available=false
fi

# Define path to rofi theme
ROFI_THEME="$HOME/Documents/Projects/video2webp/custom_theme.rasi"

# Verify theme file exists
if [ ! -f "$ROFI_THEME" ]; then
    echo "Error: Rofi theme file $ROFI_THEME not found. Exiting."
    exit 1
fi

# Directory for temporary preview images
PREVIEW_DIR="/tmp/rofi_video_previews"
mkdir -p "$PREVIEW_DIR"

# Function to clean up temporary preview images
cleanup_previews() {
    rm -rf "$PREVIEW_DIR"
}

# Function to show operation status
show_status() {
    local message="$1"
    echo "$message" | rofi -dmenu -p "Status" -theme "$ROFI_THEME" -mesg "$message" &
    STATUS_PID=$!
}

# Function to close status message
close_status() {
    if [ -n "$STATUS_PID" ]; then
        kill "$STATUS_PID" 2>/dev/null
    fi
}

# Function to extract first frame of a video
generate_preview() {
    local video_file="$1"
    local preview_file="$PREVIEW_DIR/$(basename "${video_file%.*}").png"
    if ffmpeg -i "$video_file" -vframes 1 -vf "scale=64:64" "$preview_file" 2>/dev/null; then
        echo "$preview_file"
    else
        echo ""
    fi
}

# Function to select input video file
select_input_file() {
    if [ "$zenity_available" = true ] && [ -n "$DISPLAY" ]; then
        input_file=$(zenity --file-selection --title="Select a video file" --file-filter="Video files | *.mp4 *.mkv *.avi *.mov *.webm *.flv" --filename="$HOME/Videos/")
        if [ -z "$input_file" ]; then
            echo "No file selected. Exiting."
            exit 1
        fi
    else
        mapfile -t video_files < <(find "$HOME/Videos" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.webm" -o -iname "*.flv" \) 2>/dev/null)
        if [ ${#video_files[@]} -eq 0 ]; then
            echo "No video files found in $HOME/Videos. Trying $HOME."
            mapfile -t video_files < <(find "$HOME" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.webm" -o -iname "*.flv" \) 2>/dev/null)
            if [ ${#video_files[@]} -eq 0 ]; then
                echo "No video files found in $HOME. Exiting."
                cleanup_previews
                exit 1
            fi
        fi

        rofi_input=""
        for file in "${video_files[@]}"; do
            preview=$(generate_preview "$file")
            if [ -n "$preview" ] && [ -f "$preview" ]; then
                rofi_input+="$file\0icon\x1f$preview\n"
            else
                rofi_input+="$file\0icon\x1f\n"
            fi
        done

        input_file=$(echo -ne "$rofi_input" | rofi -dmenu -i -mesg "Select video file" -theme "$ROFI_THEME" -show-icons)
        if [ -z "$input_file" ]; then
            echo "No file selected. Exiting."
            cleanup_previews
            exit 1
        fi
    fi

    if ! [[ "$input_file" =~ \.(mp4|mkv|avi|mov|webm|flv)$ ]]; then
        echo "Selected file is not a supported video format (.mp4, .mkv, .avi, .mov, .webm, .flv). Exiting."
        cleanup_previews
        exit 1
    fi

    if [ ! -f "$input_file" ]; then
        echo "Error: Selected file does not exist. Exiting."
        cleanup_previews
        exit 1
    fi
}

# Function to get frame rate
select_frame_rate() {
    frame_rate=$(echo -e "5\n10\n15\n24\n30\n60" | rofi -dmenu -i -mesg "Select frame rate (fps)" -theme "$ROFI_THEME")
    if [ -z "$frame_rate" ] || ! [[ "$frame_rate" =~ ^[0-9]+$ ]]; then
        frame_rate=10
    fi
}

# Function to get quality
select_quality() {
    quality=$(echo -e "10\n30\n50\n60\n70\n90\n100\nCustom" | rofi -dmenu -i -mesg "Select quality (0-100, higher is better)" -theme "$ROFI_THEME")
    if [ "$quality" = "Custom" ]; then
        quality=$(rofi -dmenu -i -mesg "Enter custom quality (0-100)" -filter "30" -theme "$ROFI_THEME")
        if [ -z "$quality" ] || ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ] || [ "$quality" -gt 100 ]; then
            quality=30
        fi
    fi
    if [ -z "$quality" ] || ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ] || [ "$quality" -gt 100 ]; then
        quality=30
    fi
}

# Function to get scale
select_scale() {
    scale=$(echo -e "Original size\nCustom size\n2560:1440\n1920:1080\n1280:720\n854:480\n640:360\n320:240" | rofi -dmenu -i -mesg "Select resolution (width:height)" -theme "$ROFI_THEME")
    if [ -z "$scale" ]; then
        scale="1280:720"
    fi
    if [ "$scale" = "Custom size" ]; then
        scale=$(rofi -dmenu -i -mesg "Enter custom resolution (width:height, e.g., 1920:1080)" -theme "$ROFI_THEME")
        if [ -z "$scale" ] || ! [[ "$scale" =~ ^[0-9]+:[0-9]+$ ]]; then
            echo "Invalid custom resolution. Using default 1280:720."
            scale="1280:720"
        fi
    fi
}

# Function to select preset
select_preset() {
    preset=$(echo -e "default\nphoto\ndrawing\nicon\ntext" | rofi -dmenu -i -mesg "Select preset (optimizes compression: default for general, photo for images, drawing for art, icon for small graphics, text for text)" -theme "$ROFI_THEME")
    if [ -z "$preset" ]; then
        preset="default"
    fi
}

# Function to select loop option
select_loop() {
    loop=$(echo -e "Yes\nNo" | rofi -dmenu -i -mesg "Loop the WebP animation?" -mesg "Loop the WebP animation?" -theme "$ROFI_THEME")
    if [ -z "$loop" ] || [ "$loop" != "Yes" ]; then
        loop_option="-loop 1"
    else
        loop_option="-loop 0"
    fi
}

# Function to select output directory
select_output_dir() {
    output_dir=$(echo -e "$HOME/Videos\n$HOME/Downloads\n$HOME/Desktop\n$HOME/Documents" | rofi -dmenu -i -mesg "Select output directory" -theme "$ROFI_THEME")
    if [ -z "$output_dir" ]; then
        output_dir="$HOME"
    fi
    if [ ! -d "$output_dir" ]; then
        echo "Error: Selected directory does not exist. Using home directory."
        output_dir="$HOME"
    fi
}

# Function to select output file name
select_output_file() {
    default_output=$(basename "${input_file%.*}")

    if [ "$scale" = "Original size" ]; then
        # Get input video resolution using ffprobe
        scale_name=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file" 2>/dev/null)
    else
        scale_name=$(echo "$scale" | sed 's/:/x/')
    fi

    output_file=$(echo -e "$default_output\n$default_output-q$quality\n$default_output-$scale_name-f$frame_rate-q$quality\noutput" | rofi -dmenu -i -mesg "Enter output file name (without extension)" -filter "$default_output" -theme "$ROFI_THEME")
    if [ -z "$output_file" ]; then
        output_file="$default_output"
    fi
    output_file="$output_dir/${output_file}.webp"
}

# Main script
select_input_file
select_frame_rate
select_quality
select_scale
select_preset
select_loop
select_output_dir
select_output_file

# Show conversion status
show_status "Converting $input_file to WebP..."

# Clean up temporary preview images
cleanup_previews

# Construct ffmpeg command based on scale selection
if [ "$scale" = "Original size" ]; then
    ffmpeg -y -i "$input_file" -vf "fps=$frame_rate" -c:v libwebp -preset "$preset" -qscale:v "$quality" $loop_option "$output_file"
else
    ffmpeg -y -i "$input_file" -vf "fps=$frame_rate,scale=$scale" -c:v libwebp -preset "$preset" -qscale:v "$quality" $loop_option "$output_file"
fi

# Close status message
close_status

if [ $? -eq 0 ]; then
    show_status "Conversion successful! Output saved as $output_file"
    sleep 2
    close_status
else
    show_status "Error during conversion."
    sleep 2
    close_status
    cleanup_previews
    exit 1
fi
