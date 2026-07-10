# Fixing Git push failure from large `.terraform` files

This guide explains exactly what was done to recover when push failed because Terraform provider files were too large.

## What happened

GitHub rejected push because this file was in commits:

- `Terraforms/ec2/.terraform/.../terraform-provider-aws_v6.54.0_x5.exe` (~843 MB)

`.gitignore` only prevents **new/untracked** files. If a file was already committed, it is still in history.

---

## What I did (safe case: commits were NOT pushed yet)

### 1) Confirm the exact error

```powershell
git push
```

### 2) Check how many local commits were ahead of remote

```powershell
git rev-list --count origin/main..HEAD
git log --oneline origin/main..HEAD
```

In your case, there were 2 unpushed commits.

### 3) Remove those unpushed commits from history (keep files in working tree)

```powershell
git reset origin/main
```

> This is a **mixed reset** (default):
> - Commit history moved back to `origin/main`
> - File changes kept locally (unstaged)

### 4) Stage again after `.gitignore` rules apply

```powershell
git add .
git status --short
```

At this point `.terraform` artifacts were no longer staged.

### 5) Fix key ignore pattern and untrack keys

Your pattern was `.terr-key*` (matches names starting with a dot). Your key files were `terr-key-ec2` and `terr-key-ec2.pub`, so pattern needed to be `terr-key*`.

```powershell
# update .gitignore entries in ec2/s3 folders to:
# terr-key*

# if keys got staged, remove from index

git rm --cached Terraforms/ec2/terr-key-ec2 Terraforms/ec2/terr-key-ec2.pub
```

### 6) Commit cleanly and push

```powershell
git commit -m "Add Terraform configs without local artifacts"
git push
```

Push succeeded.

---

## Important command meanings

### `git reset origin/main`
- Rewinds local branch to remote state.
- Keeps your file edits in working directory.
- Good when bad commits are local only.

### `git rm --cached <file>`
- Stops tracking file in Git index.
- Does **not** delete local file from disk.

---

## If bad commit was already pushed

If large file is already on remote, reset is not enough. You must rewrite history and force-push.

Example with `git filter-repo`:

```powershell
# install once (if needed)
python -m pip install git-filter-repo

# remove path from full history
git filter-repo --path Terraforms/ec2/.terraform --invert-paths

# push rewritten history
git push --force-with-lease
```

Use this carefully in shared repos (coordinate with team first).

---

## Recommended Terraform ignore template

Add in each Terraform project `.gitignore` (or one root `.gitignore`):

```gitignore
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
crash.log
*.tfvars
*.tfvars.json
terr-key*
```

---

## Quick recovery checklist

1. `git push` (read exact rejected file)
2. `git rev-list --count origin/main..HEAD`
3. If only local commits: `git reset origin/main`
4. Verify `.gitignore`
5. `git add . && git status`
6. `git commit -m "..." && git push`

