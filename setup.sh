#!/bin/bash
# Manual fallback if Codespaces secrets aren't configured.
# Usage: source setup.sh <endpoint_url> <encrypted_token>
# You'll be prompted for the passphrase.

if [ $# -lt 2 ]; then
    echo "Usage: source setup.sh <endpoint_url> <encrypted_token>"
    return 1 2>/dev/null || exit 1
fi

read -rsp "Passphrase: " PASSPHRASE
echo ""

TOKEN=$(echo "$2" | openssl enc -aes-256-cbc -d -a -pbkdf2 -pass "pass:$PASSPHRASE" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "Wrong passphrase."
    return 1 2>/dev/null || exit 1
fi

export AWS_CONTAINER_CREDENTIALS_FULL_URI="$1"
export AWS_CONTAINER_AUTHORIZATION_TOKEN="$TOKEN"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE

echo "Testing AWS access..."
aws sts get-caller-identity 2>/dev/null && echo "Success!" || echo "Failed - check with your instructor."
