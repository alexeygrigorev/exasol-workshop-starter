#!/bin/bash
# Maps Codespaces secrets to the env vars AWS SDKs expect.
# WORKSHOP_CRED_URL: the Lambda Function URL (plain text secret)
# WORKSHOP_TOKEN_ENC: the workshop token, encrypted with a passphrase
#
# Participants must enter the passphrase (shared by the instructor) to unlock.

if [ -n "$WORKSHOP_CRED_URL" ] && [ -n "$WORKSHOP_TOKEN_ENC" ]; then
    echo "================================================"
    echo "  Enter the workshop passphrase to unlock AWS access"
    echo "================================================"
    echo ""
    read -rsp "Passphrase: " PASSPHRASE
    echo ""

    TOKEN=$(echo "$WORKSHOP_TOKEN_ENC" | openssl enc -aes-256-cbc -d -a -pbkdf2 -pass "pass:$PASSPHRASE" 2>/dev/null)

    if [ -z "$TOKEN" ]; then
        echo "Wrong passphrase. Run 'bash .devcontainer/setup-aws.sh' to try again."
    else
        echo "export AWS_CONTAINER_CREDENTIALS_FULL_URI=\"$WORKSHOP_CRED_URL\"" >> ~/.bashrc
        echo "export AWS_CONTAINER_AUTHORIZATION_TOKEN=\"$TOKEN\"" >> ~/.bashrc
        export AWS_CONTAINER_CREDENTIALS_FULL_URI="$WORKSHOP_CRED_URL"
        export AWS_CONTAINER_AUTHORIZATION_TOKEN="$TOKEN"
        echo "AWS credentials configured. Verifying..."
        aws sts get-caller-identity 2>/dev/null && echo "Success!" || echo "Credentials set but verification failed — check with your instructor."
    fi
else
    echo "WARNING: Codespaces secrets not set. Ask your instructor for help."
fi
