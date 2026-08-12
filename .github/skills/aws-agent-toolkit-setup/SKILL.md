---
name: aws-agent-toolkit-setup
description: Set up the Agent Toolkit for AWS by installing the AWS CLI, authenticating with aws login, configuring agent-toolkit, verifying the installation, and saving the AWS experience rules for the active AI tool. Use this when asked to set up AWS agent tooling.
---

# Set up Agent Toolkit for AWS

Use this skill when the user wants to set up the Agent Toolkit for AWS.

Follow these rules throughout the setup:

- Detect the user's operating system before asking follow-up questions.
- Require the user to provide an AWS Region before login. If it is missing, ask: `What AWS Region do you want to use as your default Region?`
- Never ask the user for AWS access keys, secret keys, or other credentials.
- Tell the user that `aws login` uses a browser sign-in flow, credentials are valid for 12 hours, and they can be renewed for 90 days without re-authenticating in the browser.
- Before each action, explain what step is being executed, why it is needed, and which tool is being used.
- Stop immediately and report the full error output if an unexpected error occurs.
- Respect the user's decision if they choose not to continue.

## Dependency checks

Before installation:

1. Verify the required download tool is available:
   - macOS/Linux: `curl`
   - Windows: PowerShell
2. Verify internet connectivity to `https://awscli.amazonaws.com`.
3. If a required tool or connectivity is missing, explain the problem clearly, ask whether the user wants to proceed anyway, and follow their decision.
4. Do not require Node.js, Python, or any other runtime beyond the shell.

## Step 1: Determine the operating system

Check session context first. If the OS is still unknown:

- Unix-like shell: run `uname -s`
- PowerShell: run `$env:OS`

If the OS still cannot be determined, ask the user which operating system they are using.

## Step 2: Install AWS CLI v2

### macOS or Linux

Run:

```bash
curl -fsSL 'https://awscli.amazonaws.com/v2/install.sh' | bash
export PATH="$HOME/.local/bin:$PATH"
SHELL_RC="$HOME/.bashrc"
if [ "$(basename "$SHELL")" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
fi
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC" && source "$SHELL_RC"
```

Handle these expected errors:

- `command not found: curl`: tell the user to install `curl` and re-run the setup
- HTTP or download failure: ask the user to verify network access to `https://awscli.amazonaws.com`
- Missing dependencies such as `unzip` or `pkgutil`: tell the user to install the missing dependency and re-run
- Unsupported OS or architecture: stop and explain the system is unsupported
- `musl-based Linux detected`: stop and explain the prebuilt installer cannot be used
- `post-install check failed` or `command not found: aws`: ensure `$HOME/.local/bin` is on `PATH` and retry
- `Permission denied` updating the shell rc file: tell the user to fix file permissions
- Missing rc file: create it first with `touch "$SHELL_RC"`

### Windows

Run:

```powershell
irm 'https://awscli.amazonaws.com/v2/install.ps1' | iex
```

Handle these expected errors:

- `irm` or `iex` not recognized: tell the user to run the setup in PowerShell instead of `cmd.exe`
- Download failure: ask the user to verify network access to `https://awscli.amazonaws.com`
- Admin privilege errors: re-run in an elevated PowerShell or omit system-wide install options
- `post-install check failed`: restart the shell and retry

## Step 3: Log in to AWS

If the user's AWS Region is not already known, ask for it before continuing.

Then run:

```bash
aws configure set region <user-region>
aws login --region <user-region>
```

Wait for `aws login` to finish before continuing.

Handle these expected errors:

- Region missing: ask for it and set it before retrying
- `command not found: aws`: fix `PATH` and retry
- Browser sign-in not completed or timed out: re-run `aws login`
- Browser did not open: look for a URL in the command output and ask the user to open it manually

## Step 4: Verify AWS access

Run:

```bash
aws sts get-caller-identity
```

If this fails with missing or expired credentials, repeat the login step.

## Step 5: Set up the Agent Toolkit

Run:

```bash
aws configure agent-toolkit --yes --region us-east-1
```

Important:

- Always use `us-east-1` for Agent Toolkit setup and verification, even if the user's default Region is different.

Handle these expected errors:

- `--yes` not recognized or `invalid choice`: retry without `--yes`
- Exit code 253 or interactive terminal error: tell the user to run `aws configure agent-toolkit --region us-east-1` in their own terminal, wait for them to confirm it completed, then continue
- Missing or expired credentials: repeat the login step
- `command not found: aws`: fix `PATH` and retry

## Step 6: Verify the Agent Toolkit installation

Run:

```bash
aws agent-toolkit list-available-skills --region us-east-1
```

Success means the command returns JSON describing the available skills.

If the command reports missing or expired credentials, repeat the login step. If it reports the command is unavailable, tell the user to update AWS CLI and re-run the installation step.

## Step 7: Save the AWS experience rules

Identify the active AI coding tool and write the full contents of `aws-agent-rules.md` from this skill directory into that tool's rules file:

| Agent | Rules file location |
| --- | --- |
| Claude Code | `CLAUDE.md` in the project root |
| Codex | `AGENTS.md` in the project root |
| Cursor | `.cursor/rules/*.mdc` in the repository |
| Kiro | `.kiro/steering/*.md` in the repository |

If the target directory does not exist, create it first. If the AI tool cannot be determined, ask the user which AI coding tool they are using and where its rules live.

After saving the rules, end by telling the user:

`The steps to get set up have all been completed. Start a new session to create new AWS resources`
