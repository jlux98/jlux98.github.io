#! /usr/bin/env bash
set -euo pipefail
# set -x

source ./convert_with_css.sh

FULL_TEXT_PATH="$1"

render_actor_part() {
    markdown_text="$(cat "$FULL_TEXT_PATH")"
    ROLE_NAME="$1"
    OUTPUT_FILE_NAME=$2
    echo "rendering part for $ROLE_NAME in ./$OUTPUT_FILE_NAME.md..."
    TEXT_PROCESSED="$(
        printf '%s\n' "$markdown_text" |
        sed -E 's/^# Text/# '"$ROLE_NAME"'/' |
        awk -v role="$ROLE_NAME" '
    BEGIN {
      in_block = 0
      last = ""
      out = ""
    }

    {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)

      if (line == "") {
        if (in_block) {
          last = last "=="
        }
        in_block = 0
      }

      if (line ~ ("^\\*\\*+[^*]*" role)) {
        in_block = 1
        line = "==" line
      }

      if (((index(line, "[" role "]") > 0) || (index(line, "\\[" role "\\]") > 0)) && !in_block) {
        line = "==" line "=="
      }

      out = out last "  \n"
      last = line
    }

    END {
      print out last "  "
    }
        '
    )"
    TEXT_PROCESSED="$(echo "$TEXT_PROCESSED" | sed -E 's/==+/==/g;s/ *==$/==  /g;s/  \]\(\)/]()/g')"
    echo "$TEXT_PROCESSED" > "$OUTPUT_FILE_NAME.md"
    convert_with_css "$OUTPUT_FILE_NAME"
    # rm "$OUTPUT_FILE_NAME.md"
}

render_actor_part "OIWA" "oiwa-text"
render_actor_part "IEMON" "iemon-text"
render_actor_part "NAOSUKE" "naosuke-text"
render_actor_part "OSODE" "osode-text"
render_actor_part "SATO" "sato-text"
render_actor_part "TAKUETSU" "takuetsu-text"
