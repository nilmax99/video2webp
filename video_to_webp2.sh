#!/bin/bash

# A script to convert video files to WebP using Zenity and Rofi.

# --- DEPENDENCY CHECKS ---
# The script now requires 'zenity' for file selection.
if ! command -v zenity &> /dev/null; then
    echo "Error: zenity is not installed. Please install it to select files."
    exit 1
fi
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first."
    exit 1
fi
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Please install it first."
    exit 1
fi

# --- CONFIGURATION ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROFI_THEME="$SCRIPT_DIR/custom_theme.rasi"

if [ ! -f "$ROFI_THEME" ]; then
    echo "Warning: Rofi theme not found. Using default theme."
    ROFI_THEME=""
fi

# --- CORE FUNCTIONS ---
cleanup_temp_files() {
    rm -f /tmp/ffmpeg_error_*.log
}
trap cleanup_temp_files EXIT

show_status() {
    rofi -e "$1" -theme "$ROFI_THEME"
}

show_timed_status() {
    local message="$1"
    local duration="${2:-5}"
    rofi -e "$message" -theme "$ROFI_THEME" &
    local rofi_pid=$!
    (sleep "$duration" && kill "$rofi_pid" &>/dev/null) &
}

# --- SELECTION FUNCTIONS ---

# This function now uses Zenity for file selection, completely removing Rofi from this step.
select_input_and_scope() {
    # Open a graphical file selection dialog using Zenity
    input_file=$(zenity --file-selection --title="Select a Video File" --file-filter="Video Files | *.mp4 *.mkv *.avi *.mov *.webm *.flv" 2>/dev/null)
    
    # Exit if the user cancelled the selection
    if [ -z "$input_file" ]; then
        echo "No file selected. Exiting." >&2
        exit 1
    fi
    
    # --- Scope Selection (still uses Rofi) ---
    convert_scope=$(echo -e "Only this file\nAll files in this folder" | rofi -dmenu -i -p "Conversion Scope" -mesg "Process one file or the whole folder?" -theme "$ROFI_THEME")
    if [ "$convert_scope" = "Only this file" ] || [ -z "$convert_scope" ]; then
        input_files=("$input_file")
    else
        input_dir=$(dirname "$input_file")
        mapfile -t input_files < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.webm" -o -iname "*.flv" \) 2>/dev/null)
    fi

    # --- Naming Structure Selection (still uses Rofi) ---
    naming_structure=$(echo -e "basename (original name)\nbasename-q<quality>\nbasename-<preset>-q<quality>\nbasename-<scale>-f<frame_rate>-q<quality>" | rofi -dmenu -i -p "Naming Structure" -theme "$ROFI_THEME")
    if [ -z "$naming_structure" ]; then
        naming_structure="basename (original name)"
    fi
}

# This function now provides suggestions for the output directory.
select_output_dir() {
    local current_dir
    current_dir=$(dirname "$input_file")

    # Create a list of suggested directories
    local suggestions=(
        "$current_dir"
        "$HOME/Videos"
        "$HOME/Downloads"
        "$HOME/Desktop"
    )
    
    # Use Rofi to show suggestions. The user can select one or type a new path.
    local choice
    choice=$(printf '%s\n' "${suggestions[@]}" | rofi -dmenu -i -p "Select or Type Output Directory" -mesg "Choose a folder from the list or type a new path." -theme "$ROFI_THEME")

    # If the user cancels, default to the video's original directory
    if [ -z "$choice" ]; then
        output_dir="$current_dir"
        return
    fi
    
    # Check if the chosen directory exists. If not, ask to create it.
    if [ ! -d "$choice" ]; then
        # Ask for confirmation to create the new directory
        confirm=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Create Folder?" -mesg "Directory '$choice' does not exist. Create it?" -theme "$ROFI_THEME")
        if [ "$confirm" = "Yes" ]; then
            if mkdir -p "$choice"; then
                output_dir="$choice"
            else
                show_status "Error: Could not create directory.\nUsing original video's folder instead."
                output_dir="$current_dir"
            fi
        else
            show_status "Cancelled. Using original video's folder instead."
            output_dir="$current_dir"
        fi
    else
        # If directory already exists
        output_dir="$choice"
    fi
}

# The logic of this function is correct and remains unchanged.
select_output_file() {
    local input_file="$1"
    local scale_name="$2"
    local preset_val="$3"
    local default_output
    default_output=$(basename "${input_file%.*}")
    local output_file_name

    if [ "${#input_files[@]}" -gt 1 ]; then
        # BATCH MODE
        case "$naming_structure" in
            "basename-q<quality>") output_file_name="$default_output-q$quality" ;;
            "basename-<preset>-q<quality>") output_file_name="$default_output-$preset_val-q$quality" ;;
            "basename-<scale>-f<frame_rate>-q<quality>") output_file_name="$default_output-$scale_name-f$frame_rate-q$quality" ;;
            *) output_file_name="$default_output" ;;
        esac
    else
        # SINGLE FILE MODE
        local suggested_name
        case "$naming_structure" in
            "basename-q<quality>") suggested_name="$default_output-q$quality" ;;
            "basename-<preset>-q<quality>") suggested_name="$default_output-$preset_val-q$quality" ;;
            "basename-<scale>-f<frame_rate>-q<quality>") suggested_name="$default_output-$scale_name-f$frame_rate-q$quality" ;;
            *) suggested_name="$default_output" ;;
        esac
        
        output_file_name=$(rofi -dmenu -i -p "Output filename (no extension)" -mesg "Confirm or edit the name" -filter "$suggested_name" -theme "$ROFI_THEME")
        
        if [ -z "$output_file_name" ]; then
            output_file_name="$default_output"
        fi
    fi

    local output_file="$output_dir/$output_file_name.webp"
    printf "%s" "$output_file"
}

# Other selection functions remain unchanged
select_frame_rate() { frame_rate=$(echo -e "10\n15\n24\n30" | rofi -dmenu -i -p "Frame Rate" -theme "$ROFI_THEME"); if ! [[ "$frame_rate" =~ ^[0-9]+$ ]]; then frame_rate=10; fi; }
select_quality() { quality=$(echo -e "30\n50\n60\n70\n90\nCustom" | rofi -dmenu -i -p "Quality" -theme "$ROFI_THEME"); if [ "$quality" = "Custom" ]; then quality=$(rofi -dmenu -i -p "Custom Quality" -theme "$ROFI_THEME"); fi; if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 0 ] || [ "$quality" -gt 100 ]; then quality=70; fi; }
select_scale() { scale=$(echo -e "Original Size\n2880x1620\n2560:1440\n1920:1080\n1280:720\nCustom Size" | rofi -dmenu -i -p "Resolution" -theme "$ROFI_THEME"); if [ "$scale" = "Custom Size" ]; then scale=$(rofi -dmenu -i -p "Custom Res (e.g., 1280:720)" -theme "$ROFI_THEME"); if ! [[ "$scale" =~ ^[0-9]+:-?[0-9]+$ ]]; then scale="Original Size"; fi; fi; if [ -z "$scale" ]; then scale="Original Size"; fi; }
select_preset() { preset_selection=$(echo -e "Default\nPhoto\nDrawing\nIcon\nText" | rofi -dmenu -i -p "Preset" -theme "$ROFI_THEME"); case "$preset_selection" in "Photo") preset="photo" ;; "Drawing") preset="drawing" ;; "Icon") preset="icon" ;; "Text") preset="text" ;; *) preset="default" ;; esac; }
select_loop() { loop_answer=$(echo -e "Yes (infinite)\nNo (play once)" | rofi -dmenu -i -p "Loop?" -theme "$ROFI_THEME"); if [ "$loop_answer" = "No (play once)" ]; then loop_option="-loop 1"; else loop_option="-loop 0"; fi; }


# --- Main Script Execution ---
select_input_and_scope
# Note: select_output_dir is now called after other selections
# to ensure input_file is defined for directory suggestions.
select_frame_rate
select_quality
select_scale
select_preset
select_loop
select_output_dir

mkdir -p "$output_dir" || { show_status "Error: Could not create output directory."; exit 1; }

successful_files=()
failed_files=()

for input_file in "${input_files[@]}"; do
    
    if [ "$scale" = "Original Size" ]; then
        vf_scale_option=""
        scale_name_for_file="orig"
    else
        vf_scale_option=",scale=$scale"
        scale_name_for_file=$(echo "$scale" | sed 's/:/x/')
    fi

    output_file=$(select_output_file "$input_file" "$scale_name_for_file" "$preset")
    
    if [ -z "$output_file" ]; then continue; fi
    
    ffmpeg_log="/tmp/ffmpeg_error_$(basename "$input_file").log"
    
    echo "Converting $(basename "$input_file") to $(basename "$output_file")..."
    ffmpeg -y -i "$input_file" -vf "fps=$frame_rate$vf_scale_option" -c:v libwebp -preset "$preset" -qscale:v "$quality" $loop_option "$output_file" > "$ffmpeg_log" 2>&1
    
    if [ $? -eq 0 ]; then
        successful_files+=("$output_file")
    else
        failed_files+=("$(basename "$input_file")")
    fi
done

# --- Final Summary ---
summary_message="✅ Processing Complete\n\nSuccessful: ${#successful_files[@]}\nFailed:     ${#failed_files[@]}"
show_timed_status "$summary_message"