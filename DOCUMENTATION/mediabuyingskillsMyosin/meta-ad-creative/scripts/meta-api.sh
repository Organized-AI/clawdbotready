#!/bin/bash
# meta-api.sh — Helper script for Meta Marketing API operations
# Usage: bash meta-api.sh <command> [args...]
#
# Commands:
#   verify                          - Check account access and token
#   search-interests <query>        - Search targeting interests
#   search-behaviors <query>        - Search targeting behaviors
#   search-locations <query>        - Search geo locations
#   estimate-audience <json_file>   - Get delivery estimate for targeting spec
#   list-audiences                  - List custom audiences
#   list-campaigns                  - List campaigns in account
#   list-images                     - List uploaded images
#   create <type> <json_file>       - Create object from JSON file
#   status <object_id>              - Check object effective_status
#   activate <object_id>            - Set object status to ACTIVE
#   preview <ad_id>                 - Get ad preview link
#   upload-image <file_path>        - Upload image, return hash
#   upload-video <file_path>        - Upload video, poll until ready

set -euo pipefail

# --- Help (before env var checks so it works without credentials) ---
if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ -z "${1:-}" ]; then
  echo "meta-api.sh — Meta Marketing API Helper"
  echo ""
  echo "Commands:"
  echo "  verify                        Check account, page, pixel access"
  echo "  search-interests <query>      Search targeting interests"
  echo "  search-behaviors <query>      Search targeting behaviors"
  echo "  search-locations <query>      Search geo locations"
  echo "  estimate-audience <json>      Delivery estimate for targeting spec"
  echo "  list-audiences                List custom audiences"
  echo "  list-campaigns                List campaigns"
  echo "  list-images                   List uploaded images"
  echo "  create <type> <json>          Create campaign|adset|adcreative|ad"
  echo "  status <id>                   Check object status"
  echo "  activate <id>                 Set status to ACTIVE"
  echo "  preview <ad_id>               Get ad preview link"
  echo "  upload-image <path>           Upload image, return hash"
  echo "  upload-video <path>           Upload video, poll until ready"
  echo ""
  echo "Environment:"
  echo "  META_ACCESS_TOKEN   (required) System User token"
  echo "  META_AD_ACCOUNT_ID  (required) Ad account ID (without act_ prefix)"
  echo "  META_PAGE_ID        (optional) Facebook Page ID"
  echo "  META_PIXEL_ID       (optional) Pixel ID for conversion tracking"
  exit 0
fi

# --- Config ---
API_BASE="https://graph.facebook.com/v21.0"
TOKEN="${META_ACCESS_TOKEN:?ERROR: META_ACCESS_TOKEN not set}"
ACCOUNT="${META_AD_ACCOUNT_ID:?ERROR: META_AD_ACCOUNT_ID not set}"

# --- Helpers ---
api_get() {
  local url="$1"
  curl -s "${API_BASE}${url}&access_token=${TOKEN}" | jq .
}

api_post_json() {
  local url="$1"
  local json_file="$2"
  curl -s -X POST "${API_BASE}${url}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d @"${json_file}" | jq .
}

api_post_form() {
  local url="$1"
  shift
  curl -s -X POST "${API_BASE}${url}" \
    -H "Authorization: Bearer ${TOKEN}" \
    "$@" | jq .
}

# --- Commands ---
cmd_verify() {
  echo "=== Account Verification ==="
  echo ""
  echo "Account:"
  api_get "/act_${ACCOUNT}?fields=name,account_status,currency,timezone_name,amount_spent"
  echo ""
  echo "Page (${META_PAGE_ID:-NOT SET}):"
  if [ -n "${META_PAGE_ID:-}" ]; then
    api_get "/${META_PAGE_ID}?fields=name,id"
  else
    echo "  META_PAGE_ID not set"
  fi
  echo ""
  echo "Pixel (${META_PIXEL_ID:-NOT SET}):"
  if [ -n "${META_PIXEL_ID:-}" ]; then
    api_get "/${META_PIXEL_ID}?fields=name,id"
  else
    echo "  META_PIXEL_ID not set"
  fi
}

cmd_search_interests() {
  local query="${1:?Usage: search-interests <query>}"
  api_get "/act_${ACCOUNT}/targetingsearch?q=$(echo "$query" | sed 's/ /+/g')&type=adinterest"
}

cmd_search_behaviors() {
  local query="${1:?Usage: search-behaviors <query>}"
  api_get "/act_${ACCOUNT}/targetingsearch?q=$(echo "$query" | sed 's/ /+/g')&type=adbehavior"
}

cmd_search_locations() {
  local query="${1:?Usage: search-locations <query>}"
  api_get "/search?type=adgeolocation&q=$(echo "$query" | sed 's/ /+/g')&location_types=city,region,country,zip"
}

cmd_estimate_audience() {
  local json_file="${1:?Usage: estimate-audience <targeting_spec.json>}"
  local targeting_json
  targeting_json=$(cat "$json_file" | jq -c .)
  local encoded
  encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$targeting_json")
  api_get "/act_${ACCOUNT}/delivery_estimate?targeting_spec=${encoded}&optimization_goal=OFFSITE_CONVERSIONS"
}

cmd_list_audiences() {
  api_get "/act_${ACCOUNT}/customaudiences?fields=id,name,approximate_count,subtype&limit=50"
}

cmd_list_campaigns() {
  api_get "/act_${ACCOUNT}/campaigns?fields=name,objective,status,effective_status,daily_budget,lifetime_budget,created_time&limit=50"
}

cmd_list_images() {
  api_get "/act_${ACCOUNT}/adimages?fields=hash,url,name,width,height,created_time&limit=50"
}

cmd_create() {
  local type="${1:?Usage: create <campaign|adset|adcreative|ad> <json_file>}"
  local json_file="${2:?Usage: create <type> <json_file>}"

  case "$type" in
    campaign)    api_post_json "/act_${ACCOUNT}/campaigns" "$json_file" ;;
    adset)       api_post_json "/act_${ACCOUNT}/adsets" "$json_file" ;;
    adcreative)  api_post_json "/act_${ACCOUNT}/adcreatives" "$json_file" ;;
    ad)          api_post_json "/act_${ACCOUNT}/ads" "$json_file" ;;
    *)           echo "Unknown type: $type. Use: campaign, adset, adcreative, ad" >&2; exit 1 ;;
  esac
}

cmd_status() {
  local object_id="${1:?Usage: status <object_id>}"
  api_get "/${object_id}?fields=name,effective_status,configured_status,issues_info"
}

cmd_activate() {
  local object_id="${1:?Usage: activate <object_id>}"
  curl -s -X POST "${API_BASE}/${object_id}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d '{"status":"ACTIVE"}' | jq .
}

cmd_preview() {
  local ad_id="${1:?Usage: preview <ad_id>}"
  echo "=== Preview Links ==="
  api_get "/${ad_id}?fields=preview_shareable_link"
  echo ""
  echo "=== Desktop Feed Preview ==="
  api_get "/${ad_id}/previews?ad_format=DESKTOP_FEED_STANDARD"
}

cmd_upload_image() {
  local file_path="${1:?Usage: upload-image <file_path>}"
  echo "Uploading image: ${file_path}"
  RESPONSE=$(api_post_form "/act_${ACCOUNT}/adimages" -F "filename=@${file_path}")
  echo "$RESPONSE"
  HASH=$(echo "$RESPONSE" | jq -r '.images | to_entries[0].value.hash // empty')
  if [ -n "$HASH" ]; then
    echo ""
    echo "==> image_hash: ${HASH}"
  fi
}

cmd_upload_video() {
  local file_path="${1:?Usage: upload-video <file_path>}"
  echo "Uploading video: ${file_path}"
  RESPONSE=$(api_post_form "/act_${ACCOUNT}/advideos" \
    -F "source=@${file_path}" \
    -F "title=$(basename "${file_path}" | sed 's/\.[^.]*$//')")
  echo "$RESPONSE"
  VIDEO_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
  if [ -z "$VIDEO_ID" ]; then
    echo "ERROR: Upload failed" >&2
    return 1
  fi

  echo ""
  echo "Polling video status (ID: ${VIDEO_ID})..."
  for i in $(seq 1 60); do
    STATUS=$(curl -s "${API_BASE}/${VIDEO_ID}?fields=status&access_token=${TOKEN}" | jq -r '.status.video_status // "unknown"')
    echo "  Status: ${STATUS} (${i}/60)"
    if [ "$STATUS" = "ready" ]; then
      echo ""
      echo "==> video_id: ${VIDEO_ID}"
      return 0
    fi
    sleep 10
  done
  echo "WARNING: Video still processing after 10 minutes. ID: ${VIDEO_ID}" >&2
}

# --- Router ---
COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
  verify)           cmd_verify ;;
  search-interests) cmd_search_interests "$@" ;;
  search-behaviors) cmd_search_behaviors "$@" ;;
  search-locations) cmd_search_locations "$@" ;;
  estimate-audience) cmd_estimate_audience "$@" ;;
  list-audiences)   cmd_list_audiences ;;
  list-campaigns)   cmd_list_campaigns ;;
  list-images)      cmd_list_images ;;
  create)           cmd_create "$@" ;;
  status)           cmd_status "$@" ;;
  activate)         cmd_activate "$@" ;;
  preview)          cmd_preview "$@" ;;
  upload-image)     cmd_upload_image "$@" ;;
  upload-video)     cmd_upload_video "$@" ;;
  *) echo "Unknown command: $COMMAND. Run with 'help' for usage." >&2; exit 1 ;;
esac
