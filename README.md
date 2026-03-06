# Exasol Workshop Starter

Open this repo in GitHub Codespaces to get started with AWS access.

## Getting Started

### 1. Set the passphrase (your instructor will share it)

Go to [github.com/settings/codespaces](https://github.com/settings/codespaces) → **New secret**:

- **Name:** `WORKSHOP_PASSPHRASE`
- **Value:** the passphrase from your instructor
- **Repository access:** select `alexeygrigorev/exasol-workshop-starter`

### 2. Open a Codespace

Click **Code → Codespaces → Create codespace on main**

AWS access is configured automatically. Verify with:

```bash
aws sts get-caller-identity
```

Credentials refresh automatically in the background. No keys to manage.

### If it didn't work

If you created the Codespace before setting the secret, either:

- Rebuild the Codespace (Cmd/Ctrl+Shift+P → "Rebuild Container")
- Or run manually: `bash .devcontainer/setup-aws.sh`

## Instructor Setup

### Prerequisites

- AWS account with a deployed credential vending stack (see `infra/` in the main repo)
- The Lambda Function URL and workshop token from the stack output

### 1. Encrypt the token

The passphrase is stored in `.env` as `SECRET`. Use it to encrypt the workshop token:

```bash
source .env
./encrypt-token.sh '<workshop-token-from-deploy>' "$SECRET"
```

### 2. Update devcontainer.json

Edit `.devcontainer/devcontainer.json` and replace the values in `containerEnv`:

- `WORKSHOP_CRED_URL` → the Lambda Function URL
- `WORKSHOP_TOKEN_ENC` → the encrypted token from step 1

Commit and push. The encrypted token is safe to commit — it's useless without the passphrase.

### 3. Share the passphrase

Tell participants to set it as a personal Codespaces secret called `WORKSHOP_PASSPHRASE`.
