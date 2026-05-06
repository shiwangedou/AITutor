#!/usr/bin/env bash

sync_visible_env() {
  local root_dir="$1"
  local label="$2"
  local visible_env="$root_dir/env"
  local dot_env="$root_dir/.env"

  if [[ -f "$visible_env" ]]; then
    cp "$visible_env" "$dot_env"
    printf '[%s] Synced root env -> .env\n' "$label"
    return 0
  fi

  if [[ -f "$dot_env" ]]; then
    printf '[%s] Using existing root .env\n' "$label"
    return 0
  fi

  printf '[%s] ERROR: missing root env and .env. Fill root env or copy env.example first.\n' "$label"
  return 1
}
