#!/usr/bin/env bash
#
# SSH Credential Manager for Clawdbot Setup Assistant
# Generates temporary SSH credentials for remote setup access
#
# Usage:
#   ./ssh-manager.sh generate [USER-ID]     Generate new temp credentials
#   ./ssh-manager.sh list                   List active credentials
#   ./ssh-manager.sh revoke [TOKEN]         Revoke specific credential
#   ./ssh-manager.sh cleanup                Remove expired credentials
#   ./ssh-manager.sh status [TOKEN]         Check credential status
#

set -euo pipefail

# Configuration
CRED_DIR="${HOME}/.openclaw/setup-assistant/ssh-creds"
KEY_DIR="/tmp/setup-assistant-keys"
EXPIRY_HOURS=2
LOG_FILE="${HOME}/.openclaw/logs/ssh-manager.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$CRED_DIR" "$KEY_DIR" "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    log "ERROR: $*"
    exit 1
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
    log "SUCCESS: $*"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
    log "WARNING: $*"
}

generate_token() {
    # Generate secure random token
    openssl rand -hex 16
}

generate_ssh_key() {
    local token="$1"
    local key_path="${KEY_DIR}/setup-key-${token}"

    # Generate Ed25519 key (secure, fast)
    ssh-keygen -t ed25519 \
        -f "$key_path" \
        -N "" \
        -C "clawdbot-setup-${token}" \
        &>/dev/null

    echo "$key_path"
}

create_credential() {
    local user_id="$1"
    local token
    token=$(generate_token)

    log "Creating credential for user: $user_id"

    # Generate SSH key pair
    local key_path
    key_path=$(generate_ssh_key "$token")

    # Calculate expiry time (2 hours from now)
    local expiry_epoch
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        expiry_epoch=$(date -u -v+${EXPIRY_HOURS}H '+%s')
    else
        # Linux date command
        expiry_epoch=$(date -u -d "+${EXPIRY_HOURS} hours" '+%s')
    fi

    # Store credential metadata
    local cred_file="${CRED_DIR}/${token}.json"
    cat > "$cred_file" <<EOF
{
  "token": "${token}",
  "user_id": "${user_id}",
  "created_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "expires_at": "$(date -u -r "$expiry_epoch" '+%Y-%m-%dT%H:%M:%SZ')",
  "expires_epoch": ${expiry_epoch},
  "key_path": "${key_path}",
  "public_key": "$(cat "${key_path}.pub")",
  "status": "active",
  "used": false
}
EOF

    log "Credential created: token=${token}, user=${user_id}, expires=$(date -r "$expiry_epoch")"

    # Output credential info
    cat <<EOF

${GREEN}✓ Temporary SSH Credential Created${NC}

Token: ${token}
User: ${user_id}
Expires: $(date -r "$expiry_epoch" '+%Y-%m-%d %H:%M:%S %Z')
Private Key: ${key_path}
Public Key: ${key_path}.pub

EOF

    # Generate setup command for user
    local setup_script_url="https://YOUR-SERVER.com/setup-ssh"
    cat <<EOF
${YELLOW}User Setup Command (send via SMS):${NC}

curl -fsSL ${setup_script_url} | bash -s ${token}

EOF

    # Output public key for authorized_keys (for reference)
    cat <<EOF
${YELLOW}Public Key (for authorized_keys):${NC}

$(cat "${key_path}.pub")

EOF

    echo "$token"
}

list_credentials() {
    local now
    now=$(date -u '+%s')

    echo ""
    echo "Active SSH Credentials:"
    echo "======================================"

    local count=0
    for cred_file in "$CRED_DIR"/*.json; do
        if [[ ! -f "$cred_file" ]]; then
            echo "No active credentials"
            return
        fi

        local token user_id expires_epoch status
        token=$(jq -r '.token' "$cred_file")
        user_id=$(jq -r '.user_id' "$cred_file")
        expires_epoch=$(jq -r '.expires_epoch' "$cred_file")
        status=$(jq -r '.status' "$cred_file")

        local time_left=$((expires_epoch - now))
        local mins_left=$((time_left / 60))

        if [[ $time_left -lt 0 ]]; then
            echo -e "${RED}[EXPIRED]${NC} Token: ${token}"
        elif [[ "$status" == "revoked" ]]; then
            echo -e "${RED}[REVOKED]${NC} Token: ${token}"
        else
            echo -e "${GREEN}[ACTIVE]${NC} Token: ${token}"
        fi

        echo "  User: ${user_id}"
        echo "  Expires: $(date -r "$expires_epoch" '+%Y-%m-%d %H:%M:%S')"

        if [[ $time_left -gt 0 ]] && [[ "$status" == "active" ]]; then
            echo "  Time Left: ${mins_left} minutes"
        fi

        echo ""
        ((count++))
    done

    echo "Total: ${count} credential(s)"
}

revoke_credential() {
    local token="$1"
    local cred_file="${CRED_DIR}/${token}.json"

    if [[ ! -f "$cred_file" ]]; then
        error "Credential not found: ${token}"
    fi

    log "Revoking credential: ${token}"

    # Update status to revoked
    jq '.status = "revoked" | .revoked_at = "'$(date -u '+%Y-%m-%dT%H:%M:%SZ')'"' \
        "$cred_file" > "${cred_file}.tmp"
    mv "${cred_file}.tmp" "$cred_file"

    # Remove private key
    local key_path
    key_path=$(jq -r '.key_path' "$cred_file")
    if [[ -f "$key_path" ]]; then
        rm -f "$key_path" "${key_path}.pub"
    fi

    success "Credential revoked: ${token}"
}

cleanup_expired() {
    local now
    now=$(date -u '+%s')
    local removed=0

    log "Cleaning up expired credentials"

    for cred_file in "$CRED_DIR"/*.json; do
        if [[ ! -f "$cred_file" ]]; then
            continue
        fi

        local token expires_epoch
        token=$(jq -r '.token' "$cred_file")
        expires_epoch=$(jq -r '.expires_epoch' "$cred_file")

        if [[ $expires_epoch -lt $now ]]; then
            log "Removing expired credential: ${token}"

            # Remove key files
            local key_path
            key_path=$(jq -r '.key_path' "$cred_file")
            rm -f "$key_path" "${key_path}.pub"

            # Remove credential file
            rm -f "$cred_file"

            ((removed++))
        fi
    done

    if [[ $removed -gt 0 ]]; then
        success "Cleaned up ${removed} expired credential(s)"
    else
        echo "No expired credentials to clean up"
    fi
}

check_status() {
    local token="$1"
    local cred_file="${CRED_DIR}/${token}.json"

    if [[ ! -f "$cred_file" ]]; then
        error "Credential not found: ${token}"
    fi

    local now
    now=$(date -u '+%s')

    echo ""
    echo "Credential Status:"
    echo "======================================"

    jq -r '
        "Token: " + .token,
        "User: " + .user_id,
        "Created: " + .created_at,
        "Expires: " + .expires_at,
        "Status: " + .status,
        "Used: " + (.used | tostring)
    ' "$cred_file"

    local expires_epoch
    expires_epoch=$(jq -r '.expires_epoch' "$cred_file")
    local time_left=$((expires_epoch - now))
    local mins_left=$((time_left / 60))

    if [[ $time_left -gt 0 ]]; then
        echo "Time Left: ${mins_left} minutes"
    else
        echo -e "${RED}Status: EXPIRED${NC}"
    fi

    echo ""
}

mark_used() {
    local token="$1"
    local cred_file="${CRED_DIR}/${token}.json"

    if [[ ! -f "$cred_file" ]]; then
        error "Credential not found: ${token}"
    fi

    jq '.used = true | .used_at = "'$(date -u '+%Y-%m-%dT%H:%M:%SZ')'"' \
        "$cred_file" > "${cred_file}.tmp"
    mv "${cred_file}.tmp" "$cred_file"

    log "Credential marked as used: ${token}"
}

validate_token() {
    local token="$1"
    local cred_file="${CRED_DIR}/${token}.json"

    if [[ ! -f "$cred_file" ]]; then
        echo "invalid"
        return 1
    fi

    local now
    now=$(date -u '+%s')

    local expires_epoch status
    expires_epoch=$(jq -r '.expires_epoch' "$cred_file")
    status=$(jq -r '.status' "$cred_file")

    if [[ "$status" != "active" ]]; then
        echo "revoked"
        return 1
    fi

    if [[ $expires_epoch -lt $now ]]; then
        echo "expired"
        return 1
    fi

    echo "valid"
    return 0
}

get_key_path() {
    local token="$1"
    local cred_file="${CRED_DIR}/${token}.json"

    if [[ ! -f "$cred_file" ]]; then
        error "Credential not found: ${token}"
    fi

    jq -r '.key_path' "$cred_file"
}

# Main command dispatcher
case "${1:-}" in
    generate)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 generate [USER-ID]"
        fi
        create_credential "$2"
        ;;

    list)
        list_credentials
        ;;

    revoke)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 revoke [TOKEN]"
        fi
        revoke_credential "$2"
        ;;

    cleanup)
        cleanup_expired
        ;;

    status)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 status [TOKEN]"
        fi
        check_status "$2"
        ;;

    validate)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 validate [TOKEN]"
        fi
        validate_token "$2"
        ;;

    mark-used)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 mark-used [TOKEN]"
        fi
        mark_used "$2"
        ;;

    get-key)
        if [[ -z "${2:-}" ]]; then
            error "Usage: $0 get-key [TOKEN]"
        fi
        get_key_path "$2"
        ;;

    *)
        cat <<EOF
SSH Credential Manager for Clawdbot Setup Assistant

Usage:
  $0 generate [USER-ID]     Generate new temporary credential
  $0 list                   List all credentials
  $0 revoke [TOKEN]         Revoke specific credential
  $0 cleanup                Remove expired credentials
  $0 status [TOKEN]         Check credential status
  $0 validate [TOKEN]       Validate if credential is usable
  $0 mark-used [TOKEN]      Mark credential as used
  $0 get-key [TOKEN]        Get private key path

Examples:
  # Create credential for user
  $0 generate user-12345

  # Check status of token
  $0 status abc123def456

  # Clean up expired credentials (run in cron)
  $0 cleanup

EOF
        exit 1
        ;;
esac
