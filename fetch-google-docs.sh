#!/usr/bin/env bash
set -eu
# set -x

if [ -z $(type -P curl) ]; then
    echo "This script requires curl. Please install curl and try again."
    exit
fi

if [ -z $(type -P jq) ]; then
    echo "This script requires jq. Please install jq and try again."
    exit 1
fi

if [ -z $(type -P gcloud) ]; then
    echo "This script requires gcloud. Please install gcloud and try again."
    exit 1
fi

TAB_NAME="Geräusche nach Szenen (gefiltert aus Text)"
GOOGLE_APPLICATION_CREDENTIALS="${1:-"/opt/theater/.google-sa-auth.json"}"
PREAMBEL="Die nachfolgende Auflistung wurde maschinell erstellt, sie enthält jede Zeile aus dem Stücktext, in der eckige Klammern vorkommen.
Damit ein Geräusch in dieser Auflistung erscheint, muss in derselben Zeile mindestens eine Rollenzuweisung in eckigen Klammern stehen."

file_id="1vid5QOJ0HAOgU6rAsnjYwcP4QmdKABgYF3ro--UFOJo"

# Service account credentials keep this runnable unattended from cron.
if ! token=$(gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/drive); then
    gcloud auth activate-service-account --quiet --key-file="${GOOGLE_APPLICATION_CREDENTIALS}" > /dev/null
    token=$(gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/drive)
fi

get_file() {
    filetype=${1:-plain}
    url="https://www.googleapis.com/drive/v3/files/${file_id}/export?mimeType=text/${filetype}"
    # url="https://www.googleapis.com/drive/v3/files/${file_id}/export?mimeType=text/markdown"
    curl "$url" -sf -H "Authorization: Bearer ${token}" --compressed
}

TEXT="$(get_file | sed 's/\r//g')"
MARKDOWN_TEXT="$(get_file markdown | sed 's/\r//g')"
LINE_MARKDOWN_TEXT_BEGINNING="$(($(echo "$MARKDOWN_TEXT" | grep -n '^# Text$' | cut -d ':' -f 1 | head -n 1) - 1))"
LINE_MARKDOWN_TEXT_END="$(($(echo "$MARKDOWN_TEXT" | grep -n '^# Geräusche$' | cut -d ':' -f 1 | head -n 1) - 1))"
MARKDOWN_TEXT="$(echo "$MARKDOWN_TEXT" | sed -n "$((LINE_MARKDOWN_TEXT_BEGINNING + 1)),$LINE_MARKDOWN_TEXT_END p")"
MARKDOWN_TEXT="$(echo "$MARKDOWN_TEXT" | sed -E 's/^(.*\\\[[^]+\\\].*$)/[\1]()  /')"
MARKDOWN_TEXT="$(echo "$MARKDOWN_TEXT" | sed -E 's/  +/  /g')"
echo "$MARKDOWN_TEXT" > full-text.md
# MARKDOWN_TEXT="$(echo "$MARKDOWN_TEXT" | tr '\n' '|')"

render_actor_part() {
    SPEAKING_EXPRESSION="$1"
    SOUNDEFFECT_EXPRESSION="$2"
    OUTPUT_FILE_NAME=$3
    ACTOR_TEXT="$(echo "$MARKDOWN_TEXT" | tr '\n' '|' |
        sed -z -E 's/((\*\*('"$SPEAKING_EXPRESSION"')[^*]*\*\* *(\|[^|]+)*)|([^|]*\\\['"$SOUNDEFFECT_EXPRESSION"'\\\][^|]*\(\)))(  )?\|\|/==\1==  \|\|/g' |
        tr '|' '\n')"
    echo "$ACTOR_TEXT" > "$OUTPUT_FILE_NAME.md"
    pandoc "$OUTPUT_FILE_NAME.md" -f markdown+smart+yaml_metadata_block+mark -t html -o "$OUTPUT_FILE_NAME.html"
    rm "$OUTPUT_FILE_NAME.md"
}

render_actor_part "IEMON|PRIESTER" "IEMON" "iemon-text"
render_actor_part "NAOSUKE|AKI" "NAOSUKE" "naosuke-text"
render_actor_part "OSODE|OUME|OYUMI" "OSODE" "osode-text"
render_actor_part "SATO|SAMON" "SATO" "sato-text"
render_actor_part "OIWA" "OIWA" "oiwa-text"
render_actor_part "TAKUETSU|ITO KIHEI|MEISTER" "TAKUETSU" "takuetsu-text"

LINE_TEXT_END="$(($(echo "$TEXT" | grep -n '^Geräusche$' | cut -d ':' -f 1 | head -n 1) - 1))"
SHORTENED_TEXT="$(echo "$TEXT" | head -n "$LINE_TEXT_END")"
echo "$TEXT" > text.txt
FILTERED_TEXT="$(echo "$SHORTENED_TEXT" | grep -E '(^Einführung$)|(^Szene [0-9]+: )|(\[[^]]+\])' | sed -E 's/ +/ /g;s/^((Einführung)|(Szene [0-9]+: .+))$/\n\1\n/g')"
FILTERED_TEXT="$(echo "$FILTERED_TEXT" | sed 's/>/\n >/g')"
FILTERED_TEXT="${PREAMBEL}
${FILTERED_TEXT}"

LINE_FILTERED_TEXT_BEGINNING="$(($(echo "$TEXT" | grep -n "^$TAB_NAME"'$' | cut -d ':' -f 1 | head -n 1) - 1))"
LINE_FILTERED_TEXT_END="$(($(echo "$TEXT" | grep -n '^Osode-Notizen$' | cut -d ':' -f 1 | head -n 1) - 1))"

CURRENT_FILTERED_TEXT=$(echo "$TEXT" | sed -n "$((LINE_FILTERED_TEXT_BEGINNING + 2)),${LINE_FILTERED_TEXT_END}p")
CURRENT_FILTERED_TEXT=${CURRENT_FILTERED_TEXT//$'\n'$'\n'/$'\n'}

echo "$CURRENT_FILTERED_TEXT" > current_filtered_text.txt
echo "$FILTERED_TEXT" > filtered_text.txt
if diff current_filtered_text.txt filtered_text.txt; then
    echo "No differences found between current and filtered text."
    echo "Exiting..."
    exit 0
fi

DOCUMENT="$(curl "https://docs.googleapis.com/v1/documents/${file_id}?includeTabsContent=true" -sf \
    -H "Authorization: Bearer ${token}" --compressed | sed 's/\r//g')"
TAB_INFO="$(echo "$DOCUMENT" | jq -er --arg tab_name "$TAB_NAME" '
    [.. | objects | select(.tabProperties? and .tabProperties.title == $tab_name)]
    | if length == 0 then error("No Google Docs tab named \"\($tab_name)\" was found") else .[0] end
    | {tab_id: .tabProperties.tabId, end_index: (.documentTab.body.content | last | .endIndex)}')"
TAB_ID="$(echo "$TAB_INFO" | jq -r '.tab_id')"
TAB_END_INDEX="$(echo "$TAB_INFO" | jq -r '.end_index')"

if ((TAB_END_INDEX > 2)); then
    REQUESTS="$(jq -cn --arg tab_id "$TAB_ID" --arg text "$FILTERED_TEXT" --arg preambel "$PREAMBEL" --argjson end_index "$TAB_END_INDEX" '
        [{deleteContentRange: {range: {startIndex: 1, endIndex: ($end_index - 1), tabId: $tab_id}}},
         {insertText: {location: {index: 1, tabId: $tab_id}, text: $text}}]')"
else
    REQUESTS="$(jq -cn --arg tab_id "$TAB_ID" --arg text "$FILTERED_TEXT" --arg preambel "$PREAMBEL" '
        [{insertText: {location: {index: 1, tabId: $tab_id}, text: $text}}]')"
fi

jq -cn --argjson requests "$REQUESTS" '{requests: $requests}' |
    curl "https://docs.googleapis.com/v1/documents/${file_id}:batchUpdate" -s \
        -H "Authorization: Bearer ${token}" \
        -H 'Content-Type: application/json' \
        --compressed \
        --data-binary @-
