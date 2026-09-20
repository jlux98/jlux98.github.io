#! /usr/bin/env bash

source ./convert_with_css.sh

FULL_TEXT_PATH="$1"

render_actor_part() {
    local markdown_text
    markdown_text="$(cat "$FULL_TEXT_PATH")"
    SPEAKING_EXPRESSION="$1"
    SOUNDEFFECT_EXPRESSION="$2|ALLE"
    OUTPUT_FILE_NAME=$3
    ACTOR_TEXT="$(echo "$markdown_text" | sed -E 's/^# Text/# '"$SOUNDEFFECT_EXPRESSION"'/' )"
    ACTOR_TEXT="$(echo "$ACTOR_TEXT" | tr '\n' '|' |
        sed -z -E 's/(\*\*('"$SPEAKING_EXPRESSION"')[^*]*\*\* *(\|[^|]+)*)\|\|/==\1==\|\|/g' |
        sed -z -E 's/([^|]*\\\[[a-zA-Z, ]*'"$SOUNDEFFECT_EXPRESSION"'[a-zA-Z, ]*\\\][^|]*) *\(\)((\|)|([^ ] *\|))\|/==\1\(\)==  \|\|/g' |
        tr '|' '\n')"
    echo "$ACTOR_TEXT" > "$OUTPUT_FILE_NAME.md"
    convert_with_css "$OUTPUT_FILE_NAME"
    # rm "$OUTPUT_FILE_NAME.md"
}

render_actor_part "IEMON|PRIESTER" "IEMON|ALLE" "iemon-text"
render_actor_part "NAOSUKE|AKI" "NAOSUKE|ALLE" "naosuke-text"
render_actor_part "OSODE|OUME|OYUMI" "OSODE|ALLE" "osode-text"
render_actor_part "SATO|SAMON" "SATO|ALLE" "sato-text"
render_actor_part "OIWA" "OIWA|ALLE" "oiwa-text"
render_actor_part "TAKUETSU|ITO KIHEI|MEISTER" "TAKUETSU|ALLE" "takuetsu-text"
