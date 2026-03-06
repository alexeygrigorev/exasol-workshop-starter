#!/bin/bash
# Auto-configures AWS credentials using:
# - WORKSHOP_CRED_URL and WORKSHOP_TOKEN_ENC from containerEnv (committed to repo)
# - WORKSHOP_PASSPHRASE from participant's personal Codespaces secret

if [ -z "$WORKSHOP_CRED_URL" ] || [ -z "$WORKSHOP_TOKEN_ENC" ]; then
    echo "ERROR: Workshop env vars not set. Ask your instructor for help."
    exit 1
fi

if [ -z "$WORKSHOP_PASSPHRASE" ]; then
    echo "=============================================="
    echo "  WORKSHOP_PASSPHRASE secret not set."
    echo "  Add it at: https://github.com/settings/codespaces"
    echo "  Then rebuild this codespace."
    echo ""
    echo "  Or run manually:"
    echo "    bash .devcontainer/setup-aws.sh"
    echo "=============================================="

    # Fall back to interactive prompt
    read -rsp "Or enter passphrase now: " WORKSHOP_PASSPHRASE
    echo ""

    if [ -z "$WORKSHOP_PASSPHRASE" ]; then
        exit 1
    fi
fi

TOKEN=$(echo "$WORKSHOP_TOKEN_ENC" | openssl enc -aes-256-cbc -d -a -pbkdf2 -pass "pass:$WORKSHOP_PASSPHRASE" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "Wrong passphrase. Check with your instructor."
    exit 1
fi

echo "export AWS_CONTAINER_CREDENTIALS_FULL_URI=\"$WORKSHOP_CRED_URL\"" >> ~/.bashrc
echo "export AWS_CONTAINER_AUTHORIZATION_TOKEN=\"$TOKEN\"" >> ~/.bashrc

echo "AWS credentials configured!"
