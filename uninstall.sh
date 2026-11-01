#!/usr/bin/env bash
set -euo pipefail

plugin_ids=(benq-ew270q-controls ew270q-controls)
plugins_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "This uninstaller requires Omarchy." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to safely remove this widget from the bar layout." >&2
  exit 1
fi

if [[ -f "$shell_config" ]]; then
  if jq -e '(.bar.layout // {}) | type == "object"' "$shell_config" >/dev/null; then
    temp_config=$(mktemp "${shell_config}.tmp.XXXXXX")
    trap 'rm -f "$temp_config"' EXIT

    jq --argjson ids "$(printf '%s\n' "${plugin_ids[@]}" | jq -R . | jq -s .)" '
      def widget_id:
        if type == "object" then (.id // "") else tostring end;

      .bar.layout |= with_entries(
        .value |= map(select(widget_id as $id | ($ids | index($id)) == null))
      )
    ' "$shell_config" > "$temp_config"

    if ! cmp -s "$shell_config" "$temp_config"; then
      backup="${shell_config}.bak.$(date -u +%Y%m%d%H%M%S)"
      cp -p "$shell_config" "$backup"
      mv "$temp_config" "$shell_config"
      trap - EXIT
      echo "Removed BenQ widget from the bar layout. Backup: $backup"
    else
      rm -f "$temp_config"
      trap - EXIT
    fi
  else
    echo "Warning: couldn't recognize the bar layout in $shell_config; leaving it unchanged." >&2
  fi
fi

found=0
for id in "${plugin_ids[@]}"; do
  if [[ -d "$plugins_dir/$id" || -L "$plugins_dir/$id" ]]; then
    omarchy plugin remove "$id" --yes
    found=1
  fi
done

if (( ! found )); then
  echo "No installed BenQ EW270Q controls plugin was found."
fi
