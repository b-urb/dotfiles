#!/usr/bin/env bash

# Location where you want to save the separate config files
OUTPUT_DIR="./"
mkdir -p "$OUTPUT_DIR"

# Get a list of all contexts in the kubeconfig
CONTEXTS=$(kubectl config get-contexts -o name)

for context in $CONTEXTS
do
    echo "Saving context $context"

    # Set the current context
    kubectl config use-context "$context"

    # Save the kubeconfig for the current context to a separate file
    kubectl config view --minify --flatten > "${OUTPUT_DIR}/${context}.yaml"
done

echo "All contexts have been saved to separate config files in $OUTPUT_DIR"

