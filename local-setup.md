# Local Setup (without Codespaces)

If you're not using GitHub Codespaces, you need to install the AWS CLI and configure credentials manually.

## Install AWS CLI

```bash
# Linux (x86_64)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli
```

Verify: `aws --version`

## Configure AWS Credentials

Run the setup script with the endpoint URL and encrypted token provided by your instructor:

```bash
source setup.sh <endpoint_url> <encrypted_token>
```

You'll be prompted for the passphrase. After entering it, verify:

```bash
aws sts get-caller-identity
```

## Set Default Region

```bash
export AWS_DEFAULT_REGION=eu-central-1
```
