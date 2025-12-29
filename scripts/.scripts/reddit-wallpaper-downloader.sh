#!/bin/bash

# Cache file to save Reddit API response.
JSONCACHE="/tmp/reddit-wallpaper-cache.json"

# Directory where wallpapers are going to be saved.
WPATH=${WALLPAPER_PATH:-"$HOME/Pictures/reddit-wallpapers"}

# We need to change our user agent so Reddit allows us to get the JSON without errors.
USERAGENT="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"

#!/bin/bash

# Cache file to save Reddit API response.
JSONCACHE="/tmp/reddit-wallpaper-cache.json"

# Directory where wallpapers are going to be saved.
WPATH=${WALLPAPER_PATH:-"$HOME/Pictures/reddit-wallpapers"}

# We need to change our user agent so Reddit allows us to get the JSON without errors.
USERAGENT="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"

# Subreddit selection
echo "Which subreddit do you want to download wallpapers from?"
echo "1. r/wallpapers"
echo "2. r/wallpaper"
echo "3. r/wallpaperdump"
echo "4. r/backgrounds"
echo "5. r/earthporn"
echo "6. r/cityporn"
echo "7. r/cyberpunk"
echo "8. r/multiwall"
echo "9. Custom subreddit"
read -r CHOICE

case "$CHOICE" in
    1)
        SUBREDDIT="wallpapers"
        ;;
    2)
        SUBREDDIT="wallpaper"
        ;;
    3)
        SUBREDDIT="wallpaperdump"
        ;;
    4)
        SUBREDDIT="backgrounds"
        ;;
    5)
        SUBREDDIT="earthporn"
        ;;
    6)
        SUBREDDIT="cityporn"
        ;;
    7)
        SUBREDDIT="cyberpunk"
        ;;
    8)
        SUBREDDIT="multiwall"
        ;;
    9)
        echo "Enter custom subreddit:"
        read -r CUSTOM_SUBREDDIT
        SUBREDDIT="$CUSTOM_SUBREDDIT"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

APIURL="https://www.reddit.com/r/$SUBREDDIT.json?limit=100"

echo "How many wallpapers do you want to download?"
read -r COUNT

# Remove cached response if older than 2 hours.
find "$(dirname "$JSONCACHE")" -name "$(basename "$JSONCACHE")" -mmin +120 -exec rm {} \; 2>/dev/null

# Exit on error.
set -e

for (( i=1; i<=COUNT; i++ )); do
    # If the cache file doesn't exist or is older than 2 hours, we create a new one.
    if [ ! -f "$JSONCACHE" ] || test "$(find "$JSONCACHE" -mmin +120)" ; then
        echo "Fetching new data from Reddit API..."
        curl -H "User-Agent: $USERAGENT" "$APIURL" -s > "$JSONCACHE"
    fi

    # Loop through the JSON until a valid image is found.
    while : ; do
        # Get a random item from the returned JSON.
        WJSON=$(jq -c '.data.children[].data' --raw-output < "$JSONCACHE" | shuf -n 1)

        # Check if crosspost.
        CROSSPOST=$(echo "$WJSON" | jq -c '.crosspost_parent_list[0]' --raw-output)
        if [ "$CROSSPOST" != "null" ]; then
            WJSON=$CROSSPOST
        fi

        WDOMAIN=$(echo "$WJSON" | jq -r '.domain')
        if [[ "$WDOMAIN" =~ ^(i.redd.it|reddit.com|i.imgur.com)$ ]]; then
            break
        fi
    done

    # If the item is gallery, pick a random item from the gallery.
    WISGALLERY=$(echo "$WJSON" | jq -r '.is_gallery')
    if [ "$WISGALLERY" == "true" ]; then
        GITEM=$(echo "$WJSON" | jq -c '.media_metadata' --raw-output | jq -c 'to_entries[] | .value' | shuf -n 1)
        WMIME=$(echo "$GITEM" | jq -r '.m')
        WID=$(echo "$GITEM" | jq -r '.id')
        WURI="https://i.redd.it/$WID.jpg"
    # If the item is not gallery, obtain the image URL directly.
    else
        WURI=$(echo "$WJSON" | jq -r '.url_overridden_by_dest')
    fi

    echo "Downloading wallpaper $i of $COUNT: $WURI"

    # Get the title of the post and use it as the name of the downloaded wallpaper.
    WTITLE=$(echo "$WJSON" | jq -r '.title')
    WNAME=$(echo "$WTITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/_/g').jpg

    # Get the timestamp in a human-readable format (DD-MM-YY).
    TIMESTAMP=$(date +"%d-%m-%y")

    # Construct the filename with timestamp and appropriate name.
    FILENAME="${TIMESTAMP}_${WNAME}"

    # Check if the file already exists in the Wallpapers directory. If it does, skip downloading.
    if [ -f "$WPATH/$FILENAME" ]; then
        echo "File already exists: $FILENAME"
        continue
    fi

    # Download the image and save it to the Wallpapers directory with timestamp and appropriate name.
    curl -L "$WURI" -s -o "$WPATH/$FILENAME"

    # Update cache file to ensure next iteration gets fresh data, then sleep for a random amount of time to avoid overwhelming Reddit's servers.
    curl -H "User-Agent: $USERAGENT" "$APIURL" -s > "$JSONCACHE"

done

