#!/bin/sh

# Define default options
HIGHLIGHT_COLOR='\e[32m' # Green
NC='\e[0m' # No Color
SHOW_OUTPUT=true
COPY_TO_CLIPBOARD=true

# Detect display server
if [ "$WAYLAND_DISPLAY" ]; then
  DISPLAY_SERVER='wayland'
elif [ "$DISPLAY" ]; then
  DISPLAY_SERVER='xorg'
fi

# Detect clipboard manager
if command -v xclip >/dev/null 2>&1 && [ "$DISPLAY_SERVER" == "xorg" ]; then
  CLIPBOARD_MANAGER='xclip -selection clipboard'
elif command -v wl-copy >/dev/null 2>&1 && [ "$DISPLAY_SERVER" == "wayland" ]; then
  CLIPBOARD_MANAGER='wl-copy'
else
  CLIPBOARD_MANAGER='echo'
fi

# Define usage function
function usage {
  echo "Usage: $0 [OPTIONS] FILE"
  echo "Options:"
  echo "  -c, --color COLOR    Set the highlight color (default: green)"
  exit 1
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -c|--color)
      HIGHLIGHT_COLOR="$2"
      shift
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      FILE="$1"
      shift
      ;;
  esac
done

# Check if a filename was provided
if [ -z "$FILE" ]; then
  usage
fi

# Check if the file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE not found"
  exit 1
fi

# Upload the contents of the file to paste.rs using curl
OUTPUT=$(curl -X POST -s -d "$(cat $FILE)" https://paste.rs)

# Highlight the paste.rs link in the specified color
if [ "$SHOW_OUTPUT" = true ]; then
  LINK=$(echo "$OUTPUT" | grep -o 'https://paste.rs/[a-zA-Z0-9]\+')
  if [ -n "$LINK" ]; then
    echo -e "${OUTPUT//$LINK/${HIGHLIGHT_COLOR}$LINK${NC}}"
  else
    echo "Error: No paste.rs link found in output"
    exit 1
  fi
fi

# Copy the paste.rs link to clipboard if requested
if [ "$COPY_TO_CLIPBOARD" = true ]; then
  echo "$LINK" | $CLIPBOARD_MANAGER
  echo "Paste.rs link copied to clipboard"
fi
