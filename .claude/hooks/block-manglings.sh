#!/bin/bash

FILE_PATH=$(jq -r '.tool_input.file_path' < /dev/stdin)

case "$FILE_PATH" in
  */Resources/manglings*)
    echo "BLOCKED: test resource file" >&2
    exit 2
    ;;
esac

exit 0
