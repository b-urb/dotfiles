#!/usr/bin/env bash

CONFIGS=""
SEPARATOR=":"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/../config"

# Find all .yaml files in the clusters directory
FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.yaml")

for f in $FILES
do
  # Append the file name to the CONFIGS string, separated by the colon
  CONFIGS="${CONFIGS}${SEPARATOR}${f}"
done

# Remove the initial colon from the string
CONFIGS=${CONFIGS#":"}

echo "Merging the following kubeconfig files:"
echo $CONFIGS

# Merge the kubeconfig files and save the output
KUBECONFIG=$CONFIGS kubectl config view \
    --merge --flatten > "$OUTPUT"
echo "The kubeconfig files have been merged into $OUTPUT"

