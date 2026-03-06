# Exasol Workshop Starter

Open this repo in GitHub Codespaces to get started with AWS access.

## For Participants

### 1. Set the passphrase

Your instructor will share the passphrase during the workshop.

Via the web UI:

1. Go to [github.com/settings/codespaces](https://github.com/settings/codespaces) → New secret
2. Name: `WORKSHOP_PASSPHRASE`
3. Value: the passphrase from your instructor
4. Repository access: select `alexeygrigorev/exasol-workshop-starter`

Or via the CLI:

```bash
gh secret set WORKSHOP_PASSPHRASE --user --repos alexeygrigorev/exasol-workshop-starter --app codespaces
# paste the passphrase when prompted
```

### 2. Create a Codespace

Via the web UI: go to the repo page → Code → Codespaces → Create codespace on main

Or via the CLI:

```bash
gh codespace create --repo alexeygrigorev/exasol-workshop-starter --branch main --machine basicLinux32gb
gh codespace ssh  # or open in VS Code
```

AWS access is configured automatically. Verify:

```bash
aws sts get-caller-identity
```

### If it didn't work

If you created the Codespace before setting the secret, either rebuild it
(`Cmd/Ctrl+Shift+P` → "Rebuild Container") or run manually:

```bash
bash .devcontainer/setup-aws.sh
```

Enter the passphrase when prompted. Then open a new terminal or run `source ~/.bashrc`.

### Troubleshooting

- **Codespace created before setting the secret?** Rebuild it: `Cmd/Ctrl+Shift+P` → "Rebuild Container"
- **"Wrong passphrase"?** Double-check with your instructor
- **Permission errors on AWS?** Ask your instructor — the role may need updated permissions

Credentials refresh automatically in the background. No keys to manage.

---

## For Instructors

Infrastructure lives in a separate private repo: [aws-credentials-vending-machine](https://github.com/alexeygrigorev/aws-credentials-vending-machine)

### Prerequisites

- AWS CLI configured with admin credentials
- The vending machine stack deployed (`./deploy.sh` in the infra repo)
- The passphrase stored in `.env` as `SECRET` in the infra repo

### Preparing for a workshop

#### 1. Deploy the infrastructure (first time only)

In the `aws-credentials-vending-machine` repo:

```bash
./deploy.sh
```

Save the `CredentialEndpoint` URL and `WorkshopToken` from the output.

#### 2. Rotate the token (before each workshop)

```bash
# In the aws-credentials-vending-machine repo
uv run rotate_token.py
```

This generates a new token and updates the Lambda. Note the new token.

#### 3. Encrypt the new token and update this repo

```bash
# In the aws-credentials-vending-machine repo
source .env
./encrypt-token.sh '<new-token>' "$SECRET"
```

Then edit `.devcontainer/devcontainer.json` in **this** repo:

**Via CLI:**
```bash
cd /path/to/exasol-workshop-starter

# Update the encrypted token (replace with your actual values)
# Edit .devcontainer/devcontainer.json — set WORKSHOP_TOKEN_ENC to the encrypted value
# and WORKSHOP_CRED_URL to the Lambda Function URL if it changed

git add .devcontainer/devcontainer.json
git commit -m "Rotate workshop token"
git push
```

**Manually:** edit `.devcontainer/devcontainer.json` and update `WORKSHOP_TOKEN_ENC` with the encrypted value from step above.

#### 4. During the workshop

Share the passphrase with participants and instruct them to:

1. Set it as a Codespaces secret named `WORKSHOP_PASSPHRASE` at [github.com/settings/codespaces](https://github.com/settings/codespaces)
2. Create a Codespace from this repo

#### 5. After the workshop

```bash
# Rotate the token to invalidate old credentials
uv run rotate_token.py

# Or delete the whole stack
aws cloudformation delete-stack --stack-name exasol-cred-vendor
```

### How it works

```
Participant Codespace          Lambda Function URL           AWS STS
  (AWS SDK)        ──────────▶  (validates token)  ────────▶ AssumeRole
                   auto-refresh                              temp creds
```

1. Encrypted token + Lambda URL are committed in `devcontainer.json`
2. Participant's Codespaces secret provides the passphrase to decrypt
3. `setup-aws.sh` decrypts the token and sets `AWS_CONTAINER_CREDENTIALS_FULL_URI` + `AWS_CONTAINER_AUTHORIZATION_TOKEN`
4. All AWS SDKs natively support this protocol and auto-refresh credentials
