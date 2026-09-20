#! /usr/bin/env bash

source ./convert_with_css.sh

FULL_TEXT_PATH="$1"

render_actor_part() {
    local markdown_text
    markdown_text="$(cat "$FULL_TEXT_PATH")"
    SPEAKING_EXPRESSION="$1"
    ROLE_NAME="$2"
    SOUND_EFFECT_EXPRESSION="($2|ALLE)"
    OUTPUT_FILE_NAME=$3
    # ACTOR_TEXT="$(echo "$markdown_text" | sed -E 's/^# Text/# '"$ROLE_NAME"'/;s/([^ ]) +\]\(\)/\1]()/g' )"
    ACTOR_TEXT="$(echo "$markdown_text" | sed -E 's/^# Text/# '"$ROLE_NAME"'/' )"
    ACTOR_TEXT="$(echo "$ACTOR_TEXT" | tr '\n' '|' |
        sed -E 's/(\*\*('"$SPEAKING_EXPRESSION"')[^*]*\*\* *(\|[^|]+)*)\|\|/==\1==\|\|/g' |
        # sed -E 's/([^|]*\\'"$SOUND_EFFECT_EXPRESSION"'\\\][^|]*) *\(\)((\|)|([^ ] *\|))\|/==\1\(\)==  \|\|/g' |
        sed -z -E 's/\|\|([^=][^|]*\\\['"$SOUND_EFFECT_EXPRESSION"'\\\][^|]*) *\(\)(  )?(\|)?\|/\|\|==\1\(\)==  \|\4/g' |
        tr '|' '\n')"
    echo "$ACTOR_TEXT" > "$OUTPUT_FILE_NAME.md"
    sed -i -E 's/([^ ]) +==/\1==/g' "$OUTPUT_FILE_NAME.md"
    convert_with_css "$OUTPUT_FILE_NAME"
    # rm "$OUTPUT_FILE_NAME.md"
}

render_actor_part "IEMON|PRIESTER" "IEMON" "iemon-text"
render_actor_part "NAOSUKE|AKI" "NAOSUKE" "naosuke-text"
render_actor_part "OSODE|OUME|OYUMI" "OSODE" "osode-text"
render_actor_part "SATO|SAMON" "SATO" "sato-text"
render_actor_part "OIWA" "OIWA" "oiwa-text"
render_actor_part "TAKUETSU|ITO KIHEI|MEISTER" "TAKUETSU" "takuetsu-text"
