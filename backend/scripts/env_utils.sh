#!/usr/bin/env bash

sync_visible_env() {
  local root_dir="$1"
  local label="$2"
  local visible_env="$root_dir/env"
  local dot_env="$root_dir/.env"

  apply_voice_profile_override() {
    if [[ -n "${VOICE_PIPELINE_PROFILE:-}" ]]; then
      if grep -q '^VOICE_PIPELINE_PROFILE=' "$dot_env"; then
        sed -i.bak "s/^VOICE_PIPELINE_PROFILE=.*/VOICE_PIPELINE_PROFILE=$VOICE_PIPELINE_PROFILE/" "$dot_env"
        rm -f "$dot_env.bak"
      else
        printf '\nVOICE_PIPELINE_PROFILE=%s\n' "$VOICE_PIPELINE_PROFILE" >> "$dot_env"
      fi
    fi
  }

  if [[ -f "$dot_env" ]]; then
    apply_voice_profile_override
    printf '[%s] Using existing root .env\n' "$label"
    return 0
  fi

  if [[ -f "$visible_env" ]]; then
    cp "$visible_env" "$dot_env"
    apply_voice_profile_override
    printf '[%s] Synced root env -> .env\n' "$label"
    return 0
  fi

  printf '[%s] ERROR: missing root .env and env. Copy .env.example to .env first.\n' "$label"
  return 1
}
