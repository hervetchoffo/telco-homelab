# Storing Per-Repository GitHub PATs with libsecret on Linux Mint

> **Version:** v1.1.1
> **Status:** Implemented

This guide explains how to securely store two different GitHub Personal Access Tokens (PATs)
in **libsecret** on Linux Mint, so that Git automatically uses the correct token per repository —
without mixing them up.

---

## Context

This setup was introduced as part of the `telco-homelab` security baseline (`v1.1.1`).
Two fine-grained PATs are configured:

| Token name | Scoped to | Permissions |
|---|---|---|
| `telco-homelab-local` | `hervetchoffo/telco-homelab` | Contents R/W, Metadata R, Pull requests R/W |
| `measure-dynamics-test-local` | `hervetchoffo/measure-dynamics-test` | Contents R/W, Metadata R, Pull requests R/W |

---

## The problem: Git defaults to host-only credential matching

By default, Git stores HTTPS credentials keyed by **host only**:

```
host=github.com
```

This means both repositories would share the same credential — whichever token was
stored last would be used for all GitHub repos. That is not acceptable when each repo
has its own scoped PAT.

The solution is `credential.useHttpPath=true`, which tells Git to key credentials by
**host + full repository path**:

```
host=github.com
path=hervetchoffo/telco-homelab
```

```
host=github.com
path=hervetchoffo/measure-dynamics-test
```

These are stored and retrieved as two completely separate keyring entries.

---

## Prerequisites

- Linux Mint (GNOME keyring available)
- Git installed
- `libsecret` helper available at:
  `/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret`
- Both repos accessed over **HTTPS** (not SSH)
- One fine-grained GitHub PAT per repository

---

## Step 1 — Confirm HTTPS remotes

Verify both repos use HTTPS with the username embedded in the URL:

```bash
cd ~/Dropbox/Github/telco-homelab
git remote -v
# origin  https://hervetchoffo@github.com/hervetchoffo/telco-homelab.git

cd ~/Dropbox/Github/measure-dynamics-test
git remote -v
# origin  https://hervetchoffo@github.com/hervetchoffo/measure-dynamics-test.git
```

If the username is missing from a remote URL, add it:

```bash
git remote set-url origin https://hervetchoffo@github.com/hervetchoffo/<repo>.git
```

---

## Step 2 — Confirm the libsecret helper exists

```bash
ls /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
```

If missing, build it:

```bash
sudo apt update
sudo apt install -y libsecret-1-0 libsecret-1-dev libglib2.0-dev make gcc
cd /usr/share/doc/git/contrib/credential/libsecret/
sudo make
```

---

## Step 3 — Remove any local credential helpers

If either repo has a local `credential.helper` set (from a previous setup attempt),
remove it so the global config takes over cleanly:

```bash
cd ~/Dropbox/Github/telco-homelab
git config --unset credential.helper

cd ~/Dropbox/Github/measure-dynamics-test
git config --unset credential.helper
```

No output is normal. If the command returns
`error: no such key`, the local helper was never set — that is fine.

---

## Step 4 — Configure Git globally

Set the libsecret helper and enable per-repo path matching globally:

```bash
git config --global credential.helper \
  /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret

git config --global credential.useHttpPath true
```

Verify:

```bash
git config --global --list | grep credential
```

Expected output:

```
credential.helper=/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
credential.usehttppath=true
```

---

## Step 5 — Clear any old generic GitHub credential

Remove any previously stored credential that was keyed by host only:

```bash
secret-tool clear service git host github.com
```

No output is normal.

---

## Step 6 — Store the PAT for `telco-homelab`

```bash
cd ~/Dropbox/Github/telco-homelab
git fetch
```

When prompted:

```
Username for 'https://hervetchoffo@github.com': hervetchoffo
Password for 'https://hervetchoffo@github.com': <paste telco-homelab PAT>
```

Git stores this token in libsecret keyed to `github.com/hervetchoffo/telco-homelab`.

---

## Step 7 — Store the PAT for `measure-dynamics-test`

```bash
cd ~/Dropbox/Github/measure-dynamics-test
git fetch
```

When prompted:

```
Username for 'https://hervetchoffo@github.com': hervetchoffo
Password for 'https://hervetchoffo@github.com': <paste measure-dynamics-test PAT>
```

Git stores this token in libsecret keyed to `github.com/hervetchoffo/measure-dynamics-test`.

---

## Step 8 — Verify per-repo credential resolution

### Method A — Normal Git operation (recommended)

Run `git fetch` inside each repo. If it completes without prompting, the correct PAT
is stored and working:

```bash
cd ~/Dropbox/Github/telco-homelab && git fetch
cd ~/Dropbox/Github/measure-dynamics-test && git fetch
```

### Method B — Manual credential plumbing (advanced)

Ask Git which credential it resolves for each repo path:

```bash
# telco-homelab
printf "protocol=https\nhost=github.com\npath=hervetchoffo/telco-homelab\nusername=hervetchoffo\n\n" \
  | git credential fill

# measure-dynamics-test
printf "protocol=https\nhost=github.com\npath=hervetchoffo/measure-dynamics-test\nusername=hervetchoffo\n\n" \
  | git credential fill
```

Expected output for each (token values will differ):

```
protocol=https
host=github.com
path=hervetchoffo/<repo>
username=hervetchoffo
password=github_pat_...
```

> **Note:** depending on your libsecret setup, `git credential fill` may prompt
> interactively for the password rather than returning it silently. Both behaviours
> are valid — what matters is that Git resolves the correct path for each repo.

---

## How it works internally

| Setting | Without `useHttpPath` | With `useHttpPath=true` |
|---|---|---|
| Credential key | `https://github.com` | `https://github.com/hervetchoffo/<repo>` |
| Repos sharing one token | All GitHub repos | None — each repo has its own entry |
| libsecret entries | 1 | 1 per repo |

---

## PAT renewal

Fine-grained PATs are set to expire after **90 days**. When a token expires:

```bash
# Erase the old entry for the relevant repo
printf "protocol=https\nhost=github.com\npath=hervetchoffo/<repo>\nusername=hervetchoffo\n\n" \
  | git credential reject

# Trigger a new prompt to store the fresh token
cd ~/Dropbox/Github/<repo>
git fetch
```

---

## Final configuration reference

```bash
git config --global --list | grep credential
# credential.helper=/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
# credential.usehttppath=true
```

```bash
git remote -v   # inside each repo — username must be embedded in URL
# origin  https://hervetchoffo@github.com/hervetchoffo/<repo>.git
```
