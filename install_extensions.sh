#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install jq to run this script."
    exit 1
fi

# Check for proper usage
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <browser-executable-name> <path-to-json-file>"
    exit 1
fi

BROWSER="$1"
JSON_FILE="$2"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "The specified JSON file does not exist: $JSON_FILE"
    exit 1
fi

# Read extensions from the JSON file and open each URL in the specified browser
jq -r '.[] | "https://chrome.google.com/webstore/detail/\(.id)"' "$JSON_FILE" | while read url; do
    echo "Opening $url in $BROWSER..."
    "$BROWSER" "$url" & sleep 10
done

echo "All extensions have been opened. Please install them manually."

