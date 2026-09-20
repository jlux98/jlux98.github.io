#! /usr/bin/env bash

convert_with_css() {
    INPUT_FILE_NAME="$1"
    OUTPUT_FILE_NAME="${2:-${INPUT_FILE_NAME}}"
    pandoc "$INPUT_FILE_NAME.md" -f markdown+smart+yaml_metadata_block+mark -t html -o "$OUTPUT_FILE_NAME.html.tmp"
    cat zoom-buttons.html > "$OUTPUT_FILE_NAME.html"
    cat "$OUTPUT_FILE_NAME.html.tmp" >> "$OUTPUT_FILE_NAME.html"
    echo '</body>' >> "$OUTPUT_FILE_NAME.html"
    sed -i -E 's|</mark><br />|<br /></mark>|g' "$OUTPUT_FILE_NAME.html"
    rm "$OUTPUT_FILE_NAME.html.tmp"
}
