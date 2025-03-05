#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
echo "Current working directory: $SCRIPT_DIR"

DIGESTS_INSTRUCTION_MESSAGE="Please make sure you have built or downloaded the latest release, and that it's present in the bin directory."

# Path to your Go binary
GO_BINARY="../bin/hello"

TARGET_DIRECTORY="../bin/digests"
mkdir -p $TARGET_DIRECTORY

# Function to calculate and save hashes for a file
process_file() {
    local file=$1
    if [ -f "$file" ]; then
        local SHA1_HASH=$(sha1sum "$file" | awk '{print $1}')
        local SHA256_HASH=$(sha256sum "$file" | awk '{print $1}')
        local SHA512_HASH=$(sha512sum "$file" | awk '{print $1}')
        local MD5_HASH=$(md5sum "$file" | awk '{print $1}')
        
        local FILENAME="$(basename "$file")"
        local HASH_FILE="${FILENAME}"
        # Write the hashes to the file
        echo "$MD5_HASH" > "$TARGET_DIRECTORY/$HASH_FILE"
        echo "$SHA1_HASH" >> "$TARGET_DIRECTORY/$HASH_FILE"
        echo "$SHA256_HASH" >> "$TARGET_DIRECTORY/$HASH_FILE"
        echo "$SHA512_HASH" >> "$TARGET_DIRECTORY/$HASH_FILE"
        echo "Hashes computed for $file"
    else
        echo "File not found: $file. $DIGESTS_INSTRUCTION_MESSAGE"
        exit 1
    fi
}

# Process your Go binary
process_file "$GO_BINARY"

echo "Hashes computed for all files"