#!/bin/bash
##########################################################################
# This script installs the python scripts to $HOME/opt/script.
#
# Usage:
#   ./install.sh [--help] [--dev] [--force]
#
# Options:
#   --help   : Display this help message and exit.
#   --dev    : Create symbolic links instead of copying files.
#              (This is useful when you want to keep the files under version control.)
#   --force  : Force replacement of files if they already exist.
#
# IMPORTANT: After running this script, add $HOME/opt/script to your PATH.
#
# Note:
#   Files in the "parameters" directory still have to be copied manually 
#   to the specific simulation directory.
#
# WARNING: This script will remove files in the destination if --force is used.
#          Please verify that \$DEST is set correctly to avoid accidental deletion.
##########################################################################

# Default mode: copy files
DEV_MODE=0
FORCE_MODE=0

# Process command-line options.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --help)
            echo "Usage: $(basename $0) [--help] [--dev] [--force]"
            echo ""
            echo "Options:"
            echo "  --help   : Display this help message and exit."
            echo "  --dev    : Create symbolic links instead of copying files."
            echo "             (Useful for keeping the files under version control.)"
            echo "  --force  : Force replacement of files if they already exist."
            echo ""
            echo "IMPORTANT: After running this script, add \$HOME/opt/script to your PATH."
            exit 0
            ;;
        --dev)
            DEV_MODE=1
            ;;
        --force)
            FORCE_MODE=1
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
    shift
done

# Set destination directory.
DEST="$HOME/opt/script"
mkdir -p "$DEST"

# Safety check: Ensure DEST is not empty or root.
if [[ -z "$DEST" || "$DEST" == "/" ]]; then
    echo "ERROR: Destination directory (\$DEST) is not properly set. Exiting."
    exit 1
fi

# Determine operation based on mode.
if [ $DEV_MODE -eq 1 ]; then
    # Use symbolic linking.
    OPERATION="Linking"
    CMD="ln -sv"
else
    # Use copying.
    OPERATION="Copying"
    CMD="cp -v"
fi

# Function to process files in a given source directory.
copy_or_link_dir() {
    local SRC_DIR="$1"
    for file in "$SRC_DIR"/*; do
        [ -e "$file" ] || continue
        base=$(basename "$file")
        target="$DEST/$base"
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ $FORCE_MODE -eq 1 ]; then
                echo "Found existing item: $target"
                if [ -f "$target" ] || [ -L "$target" ]; then
                    echo "Removing file/symlink: $target"
                    rm -v "$target"
                elif [ -d "$target" ]; then
                    echo "Not removing directory: $target"
                    #rm -rv "$target"
                else
                    echo "Unknown file type at $target. Skipping deletion."
                    continue
                fi
            else
                echo "Skipping $base; file exists. Use --force to overwrite."
                continue
            fi
        fi

        if [ $DEV_MODE -eq 1 ]; then
            # Create an absolute path for the source file
            src_abs=$(realpath "$file")
            ln -sv "$src_abs" "$DEST"/
        else
            cp -v "$file" "$DEST"/
        fi
    done
}

# Save the current directory.
CUR_DIR=$(pwd)

echo "[$OPERATION] files to $DEST..."

# Step 1: Process files in the current directory.
copy_or_link_dir "."

# Step 2: Process files in the results_analysis_tools directory.
cd ..
if [ ! -d results_analysis_tools ]; then
    echo -e "\nERROR: Cannot find the 'results_analysis_tools' directory!"
    echo "Please ensure it exists relative to this script."
    exit 1
fi

copy_or_link_dir "results_analysis_tools"

echo -e "\nFinished $OPERATION all the files and data!"

echo "Here is the list of installed files:"
ls -l "$DEST"

echo "Remember to add $DEST to your PATH (e.g., by updating your ~/.bashrc or ~/.profile)."
# Return to the original directory.
cd "$CUR_DIR"
