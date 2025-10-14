# Troubleshooting Common Issues

This guide helps resolve common problems with the Certy APT repository setup.

## GitHub Actions Failures

### GPG Import Fails: "Inappropriate ioctl for device"

**Error Message**:
```
gpg: key E19FE883581E80CF/E19FE883581E80CF: error sending to agent: Inappropriate ioctl for device
gpg: error reading '[stdin]': Inappropriate ioctl for device
gpg: import from '[stdin]' failed: Inappropriate ioctl for device
```

**Cause**: GPG is trying to prompt for a passphrase interactively, but GitHub Actions has no TTY (terminal).

**Solution**: This is now fixed in the workflow! The workflow configures GPG for non-interactive use with:
- `--batch --yes` flags for non-interactive operation
- `--pinentry-mode loopback` to allow passphrase from command line
- GPG agent configuration for loopback pinentry

**Action Required**: 
1. Make sure you have added the `GPG_PASSPHRASE` secret (even if empty!)
2. Re-run the workflow - it should now work

**Manual Fix** (if needed):
```bash
# The workflow now automatically does this:
mkdir -p ~/.gnupg
echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
echo "allow-loopback-pinentry" >> ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye

# Import with passphrase
echo "$BASE64_KEY" | base64 -d | \
  gpg --batch --yes --pinentry-mode loopback \
      --passphrase "$PASSPHRASE" --import
```

### GPG Import Fails: "base64: invalid input"

**Error Message**:
```
base64: invalid input
gpg: no valid OpenPGP data found.
```

**Cause**: The `GPG_PRIVATE_KEY` secret is either:
- Not set
- Contains line breaks
- Is not properly base64 encoded

**Solution**:

1. **Re-export and encode your private key**:
   ```bash
   # Export private key
   gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc
   
   # Base64 encode WITHOUT line breaks
   # On Linux:
   base64 -w 0 private-key.asc > private-key-base64.txt
   
   # On macOS:
   base64 -i private-key.asc | tr -d '\n' > private-key-base64.txt
   ```

2. **Verify it's a single line**:
   ```bash
   wc -l private-key-base64.txt
   # Should output: 0 private-key-base64.txt
   ```

3. **Update the GitHub Secret**:
   - Go to Settings → Secrets and variables → Actions
   - Delete `GPG_PRIVATE_KEY` if it exists
   - Create new secret `GPG_PRIVATE_KEY`
   - Paste the **entire** contents of `private-key-base64.txt`
   - Ensure no extra whitespace or newlines

### GPG Signing Fails: "No secret key"

**Error Message**:
```
gpg: signing failed: No secret key
```

**Cause**: The `GPG_KEY_ID` doesn't match the imported key.

**Solution**:

1. **Get the correct key ID**:
   ```bash
   gpg --list-secret-keys --keyid-format LONG
   ```
   
   Look for the **40-character** key ID:
   ```
   sec   rsa4096/1234567890ABCDEF 2025-10-14
         1234567890ABCDEF1234567890ABCDEF12345678  <-- This one!
   ```

2. **Update the GitHub Secret**:
   - Delete `GPG_KEY_ID`
   - Create new `GPG_KEY_ID` with the 40-character ID

### GPG Signing Fails: "Bad passphrase"

**Error Message**:
```
gpg: signing failed: Bad passphrase
```

**Solutions**:

**If you HAVE a passphrase**:
1. Verify locally: `echo "test" | gpg --clearsign`
2. Update `GPG_PASSPHRASE` secret with correct passphrase

**If you DON'T have a passphrase**:
1. Set `GPG_PASSPHRASE` to empty value (create secret with no content)
2. Or remove passphrase from key:
   ```bash
   gpg --edit-key YOUR_KEY_ID
   passwd  # Set to empty
   save
   ```

## Build Script Errors

### Error: "mv: are the same file"

**Error Message**:
```
mv: 'build/certy_1.1.0_amd64.deb' and 'build/certy_1.1.0_amd64.deb' are the same file
```

**Cause**: Old version of build script.

**Solution**: Pull the latest changes:
```bash
git pull origin main
```

The issue has been fixed in the latest version.

### Error: "awk: newline in string"

**Error Message**:
```
awk: newline in string   * **Simple CA Mana...
```

**Cause**: Old version of build script with multiline handling issue.

**Solution**: Pull the latest changes:
```bash
git pull origin main
```

The script now uses `sed` instead of `awk` for multiline replacement.

### Binary Not Found

**Error Message**:
```
Error: Binary build/certy-amd64 not found
```

**Solution**: The workflow should download the binary automatically. If building locally:

```bash
VERSION="v1.1.0"
mkdir -p build

# Download binary
curl -L -o build/certy-amd64 \
  "https://github.com/chriskacerguis/certy/releases/download/$VERSION/certy-linux-amd64"

chmod +x build/certy-amd64

# Build package
./scripts/build-deb.sh "$VERSION" amd64
```

## Repository Access Issues

### 404 Not Found on GitHub Pages

**Error**: Repository URL returns 404

**Solutions**:

1. **Ensure GitHub Pages is enabled**:
   - Settings → Pages
   - Source: "GitHub Actions"
   - Save

2. **Wait for deployment**:
   - First deployment can take 5-10 minutes
   - Check Actions tab for deployment status

3. **Verify gh-pages branch exists**:
   ```bash
   git fetch origin gh-pages
   git branch -r | grep gh-pages
   ```

### Package Not Found During Install

**Error**:
```
E: Unable to locate package certy
```

**Solutions**:

1. **Verify repository was added correctly**:
   ```bash
   cat /etc/apt/sources.list.d/certy.list
   # Should show: deb [signed-by=...] https://...github.io/certy-apt stable main
   ```

2. **Check repository is accessible**:
   ```bash
   curl -I https://YOUR_USERNAME.github.io/certy-apt/dists/stable/Release
   # Should return: HTTP/2 200
   ```

3. **Update package list**:
   ```bash
   sudo apt update
   ```

4. **Check if package exists**:
   ```bash
   curl https://YOUR_USERNAME.github.io/certy-apt/dists/stable/main/binary-amd64/Packages
   # Should show package info
   ```

### GPG Verification Fails

**Error**:
```
NO_PUBKEY ...
```

**Solutions**:

1. **Re-add the GPG key**:
   ```bash
   curl -fsSL https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg | \
     sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg
   ```

2. **Verify key exists**:
   ```bash
   curl -I https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg
   # Should return: HTTP/2 200
   ```

3. **Check sources.list includes signed-by**:
   ```bash
   cat /etc/apt/sources.list.d/certy.list
   # Must include: [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg ...]
   ```

## Workflow Not Triggering

### Manual Run Doesn't Start

**Solutions**:

1. **Check workflow file syntax**:
   ```bash
   # Validate YAML
   yamllint .github/workflows/build-and-publish.yml
   ```

2. **Ensure workflow is enabled**:
   - Go to Actions tab
   - Check if workflows are enabled for the repository

3. **Check permissions**:
   - Settings → Actions → General
   - Workflow permissions: "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

### Scheduled Run Doesn't Work

**Solutions**:

1. **Verify schedule syntax**:
   ```yaml
   schedule:
     - cron: '0 2 * * *'  # Daily at 2 AM UTC
   ```

2. **Note**: Scheduled workflows may not run on forks or inactive repos

3. **Manually trigger to test**:
   - Actions → Select workflow → Run workflow

## Local Development Issues

### dpkg-deb Command Not Found (macOS)

**Expected**: `dpkg-deb` is not available on macOS.

**Solutions**:

1. **Use Docker**:
   ```bash
   docker run -it -v $(pwd):/work ubuntu:22.04
   cd /work
   apt-get update && apt-get install -y dpkg-dev
   ./scripts/build-deb.sh v1.1.0 amd64
   ```

2. **Use the test script** (stops before dpkg-deb):
   ```bash
   ./scripts/test-build.sh
   ```

3. **Push to GitHub** and let Actions build it

### Cannot Test GPG Signing Locally

**Solution**: Use environment variables to test:

```bash
# Set up test GPG key
export GPG_KEY_ID="YOUR_KEY_ID"
export GPG_PASSPHRASE="your_passphrase"

# Run update-repo script
./scripts/update-repo.sh
```

## Debugging Tips

### Enable Verbose Output

Add to workflow:

```yaml
- name: Debug step
  run: |
    set -x  # Enable verbose mode
    # Your commands here
```

### Check Workflow Logs

1. Go to Actions tab
2. Click on the failed run
3. Click on the failed job
4. Expand each step to see detailed output

### Test Locally First

```bash
# Test build script
./scripts/test-build.sh

# Test with actual binary
VERSION="v1.1.0"
curl -L -o build/certy-amd64 \
  "https://github.com/chriskacerguis/certy/releases/download/$VERSION/certy-linux-amd64"
chmod +x build/certy-amd64
./scripts/build-deb.sh "$VERSION" amd64
```

### Verify Secrets Are Set

In workflow, add a debug step:

```yaml
- name: Check secrets
  run: |
    echo "GPG_PRIVATE_KEY is set: ${{ secrets.GPG_PRIVATE_KEY != '' }}"
    echo "GPG_KEY_ID is set: ${{ secrets.GPG_KEY_ID != '' }}"
    echo "GPG_PASSPHRASE is set: ${{ secrets.GPG_PASSPHRASE != '' }}"
```

**Note**: Never echo the actual secret values!

## Getting Help

If you're still stuck:

1. **Review the documentation**:
   - [SETUP.md](SETUP.md) - Initial setup
   - [SECRETS_SETUP.md](SECRETS_SETUP.md) - GPG secrets guide
   - [GPG_SETUP.md](GPG_SETUP.md) - GPG key management

2. **Check existing issues**: [GitHub Issues](https://github.com/chriskacerguis/certy-apt/issues)

3. **Open a new issue** with:
   - Error message (full logs)
   - Steps to reproduce
   - What you've tried
   - Your environment (OS, versions)
   - **Never include private keys or secrets!**

## Quick Fixes Checklist

- [ ] Pull latest changes: `git pull origin main`
- [ ] Verify secrets are set in GitHub Settings
- [ ] Check GPG key ID is 40 characters
- [ ] Ensure base64 key has no line breaks
- [ ] Verify GitHub Pages is enabled
- [ ] Wait 5-10 minutes after first workflow run
- [ ] Check Actions tab for error details
- [ ] Test locally with test-build.sh
- [ ] Re-add GPG keys if signing fails
- [ ] Update apt cache: `sudo apt update`
