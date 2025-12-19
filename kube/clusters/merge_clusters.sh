#!/usr/bin/env bash

CONFIGS=""
SEPARATOR=":"
OUTPUT_DIR=".." # directory where you want to save the merged config
MERGE_SCRIPT_NAME="merge_clusters.sh" # script filename itself to exclude from merging
OUTPUT_FILE_NAME="config" # name of the merged config file

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Find all .yaml files in the current directory except the script itself
FILES=$(find . -maxdepth 1 -name "*.yaml" ! -name "$MERGE_SCRIPT_NAME")

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
    --merge --flatten > "${OUTPUT_DIR}/${OUTPUT_FILE_NAME}"

echo "The kubeconfig files have been merged into ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}"

