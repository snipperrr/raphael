#!/bin/bash

# This script moves the compiled Expert Advisor to the build folder.

# 1. Compile RaphaelEA.mq5 in MetaEditor.
# 2. Run this script from your terminal: ./build.sh

SOURCE_FILE="src/RaphaelEA.ex5"
DEST_FOLDER="build"

if [ -f "$SOURCE_FILE" ]; then
    echo "Moving compiled EA to the build folder..."
    mv "$SOURCE_FILE" "$DEST_FOLDER/RaphaelEA.ex5"
    echo "Done. You can find the compiled EA in the '$DEST_FOLDER' folder."
else
    echo "Error: Compiled EA not found at '$SOURCE_FILE'."
    echo "Please make sure you have compiled 'RaphaelEA.mq5' in MetaEditor first."
fi
