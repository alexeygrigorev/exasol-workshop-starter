# Local Setup (without Codespaces)

If you're not using GitHub Codespaces, you need to install the tools and configure AWS credentials using your own AWS account.

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

## Install the Exasol CLI

```bash
mkdir -p ~/bin
curl https://downloads.exasol.com/exasol-personal/installer.sh | bash
mv exasol ~/bin/
```

Or download it from the [Exasol Personal Edition page](https://downloads.exasol.com/exasol-personal) and place it in `~/bin/` (or any other folder on the `PATH`).

For Windows, use [this link](https://downloads.exasol.com/exasol-personal).

For more details about installing and running Exasol Personal, see the [official documentation](https://docs.exasol.com/db/latest/get_started/exasol_personal.htm) and the [Exasol Personal GitHub page](https://github.com/exasol/exasol-personal).


## Configure AWS Credentials

You'll need your own AWS account. 

We tested this workshop with the following IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "ec2:*", "Resource": "*" },
    { "Effect": "Allow", "Action": "s3:*", "Resource": "*" },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole", "iam:PassRole", "iam:DeleteRole",
        "iam:GetRole", "iam:GetRolePolicy", "iam:TagRole",
        "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
        "iam:PutRolePolicy", "iam:DeleteRolePolicy",
        "iam:CreateInstanceProfile", "iam:TagInstanceProfile",
        "iam:AddRoleToInstanceProfile", "iam:DeleteInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile", "iam:GetInstanceProfile",
        "iam:ListInstanceProfiles", "iam:ListInstanceProfilesForRole",
        "iam:ListRoles"
      ],
      "Resource": "*"
    },
    { "Effect": "Allow", "Action": "ssm:*", "Resource": "*" },
    { "Effect": "Allow", "Action": "logs:*", "Resource": "*" }
  ]
}
```

The permissions are broad. You may be able to make them more restrictive for your setup.
