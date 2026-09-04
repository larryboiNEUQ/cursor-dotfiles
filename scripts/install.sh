#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
destination_root=${CURSOR_CONFIG_HOME:-"$HOME/.cursor"}
timestamp=$(date '+%Y%m%d%H%M%S')

install_file() {
  source_file=$1
  destination_file=$2

  mkdir -p "$(dirname -- "$destination_file")"

  if [ -f "$destination_file" ] && cmp -s "$source_file" "$destination_file"; then
    printf 'unchanged  %s\n' "$destination_file"
    return
  fi

  if [ -e "$destination_file" ]; then
    backup_file="$destination_file.bak.$timestamp"
    cp -p "$destination_file" "$backup_file"
    printf 'backup     %s\n' "$backup_file"
  fi

  cp "$source_file" "$destination_file"
  printf 'installed  %s\n' "$destination_file"
}

for source_file in "$repo_root"/config/common/agents/*.md; do
  install_file "$source_file" "$destination_root/agents/$(basename -- "$source_file")"
done

for source_file in "$repo_root"/config/unix/rules/*.mdc; do
  install_file "$source_file" "$destination_root/rules/$(basename -- "$source_file")"
done

printf '\nCursor configuration installed in %s\n' "$destination_root"
printf 'Restart Cursor CLI so new rules and agent definitions are loaded.\n'
