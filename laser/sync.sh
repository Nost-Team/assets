#!/bin/bash
set -e

ENVIRONMENTS=("dev" "prod")
VERSION="21.77.1"

for env in "${ENVIRONMENTS[@]}"; do
    if [ ! -d "$env" ]; then
        echo "'$env' not found"
        continue
    fi
    TEMP_DIR=".temp_$env"
    mkdir -p "$TEMP_DIR"
    shopt -s dotglob
    mv "$env"/* "$TEMP_DIR/" 2>/dev/null || true
    shopt -u dotglob
    FILE_LIST=""
    while IFS= read -r FILE_PATH; do
        CLEAN_PATH=$(echo "$FILE_PATH" | sed "s#^${TEMP_DIR}/##; s/\\\\/\//g")
        FILE_SHA=$(sha1sum "$FILE_PATH" | awk '{ print $1 }')
        FILE_LIST="${FILE_LIST},{\"file\":\"$CLEAN_PATH\",\"sha\":\"$FILE_SHA\"}"
    done < <(find "$TEMP_DIR" -type f | sort)
    FILES_ARRAY_JSON="[$(echo "$FILE_LIST" | sed 's/^,//')]"
    SHA1_INPUT="${FILES_ARRAY_JSON}${VERSION}"
    FINGERPRINT_SHA=$(echo -n "$SHA1_INPUT" | sha1sum | awk '{ print $1 }')
    FINAL_JSON="{\"files\":${FILES_ARRAY_JSON},\"sha\":\"${FINGERPRINT_SHA}\",\"version\":\"${VERSION}\"}"
    FINAL_JSON_ESCAPED=$(echo "$FINAL_JSON" | sed 's|/|\\/|g')
    echo -n "$FINAL_JSON_ESCAPED" > "$env/fingerprint.json"
    TARGET_SHA_DIR="$env/$FINGERPRINT_SHA"
    mkdir -p "$TARGET_SHA_DIR"
    shopt -s dotglob
    mv "$TEMP_DIR"/* "$TARGET_SHA_DIR/" 2>/dev/null || true
    shopt -u dotglob
    rm -rf "$TEMP_DIR"
done
