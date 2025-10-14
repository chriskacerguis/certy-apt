# Workflow Fix Summary

## Problem

The GitHub Actions workflow had invalid `if` conditions that were trying to check secrets directly:

```yaml
if: secrets.GPG_PRIVATE_KEY != ''
if: secrets.GPG_PRIVATE_KEY != '' && secrets.GPG_KEY_ID != ''
```

This caused workflow validation errors:
```
Unrecognized named-value: 'secrets'. Located at position 1 within expression
```

## Root Cause

GitHub Actions **does not support** checking secrets in `if` conditions at the step level. The `secrets` context is only available within the `run` script or `env` context, not in conditional expressions.

## Solution

Moved all secret validation from `if` conditions into the shell scripts themselves:

### Before (Invalid):
```yaml
- name: Set up GPG
  if: secrets.GPG_PRIVATE_KEY != ''  # ❌ Invalid
  run: |
    echo "${{ secrets.GPG_PRIVATE_KEY }}" | base64 -d | gpg --import
```

### After (Valid):
```yaml
- name: Set up GPG
  run: |
    # Check if GPG key secret is set
    if [ -z "${{ secrets.GPG_PRIVATE_KEY }}" ]; then
      echo "Warning: GPG_PRIVATE_KEY secret is not set"
      echo "Repository will be published without signing"
      exit 0
    fi
    
    echo "${{ secrets.GPG_PRIVATE_KEY }}" | base64 -d | gpg --import
```

## Changes Made

### 1. GPG Import Step
- Removed: `if: secrets.GPG_PRIVATE_KEY != ''`
- Added: Shell check for empty secret with graceful exit

### 2. Repository Signing Step
- Removed: `if: secrets.GPG_PRIVATE_KEY != '' && secrets.GPG_KEY_ID != ''`
- Added: Check for GPG_KEY_ID before attempting to sign
- Added: Graceful skip if key not found

### 3. Public Key Export Step
- Removed: `if: secrets.GPG_PRIVATE_KEY != '' && secrets.GPG_KEY_ID != ''`
- Added: Check if GPG_KEY_ID is set before exporting
- Creates placeholder file if no key available

## GPG Non-Interactive Mode Fix

**Issue**: GitHub Actions doesn't have an interactive TTY, causing GPG import errors:
```
gpg: key E19FE883581E80CF/E19FE883581E80CF: error sending to agent: Inappropriate ioctl for device
```

**Solution**: Configure GPG for non-interactive operation:

1. **Configure GPG and agent** for loopback pinentry:
   ```bash
   mkdir -p ~/.gnupg
   echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
   echo "allow-loopback-pinentry" >> ~/.gnupg/gpg-agent.conf
   ```

2. **Import with batch mode**:
   ```bash
   gpg --batch --yes --pinentry-mode loopback \
       --passphrase "$GPG_PASSPHRASE" \
       --import < private-key.asc
   ```

3. **Sign with batch mode**:
   ```bash
   gpg --batch --yes --pinentry-mode loopback \
       --passphrase "$GPG_PASSPHRASE" \
       --default-key "$GPG_KEY_ID" \
       -abs -o Release.gpg Release
   ```

**Important**: The `GPG_PASSPHRASE` secret **must exist** even if empty!

## Behavior Now

The workflow will:

1. **Always run** all GPG-related steps
2. **Check inside each step** if required secrets are set
3. **Configure GPG** for non-interactive use (no TTY needed)
4. **Use batch mode** with passphrase from secret
5. **Gracefully skip** signing operations if secrets are missing
6. **Continue execution** without errors
7. **Publish unsigned repository** if GPG is not configured
8. **Log warnings** when secrets are missing

## Benefits

✅ **Workflow validates** - No more syntax errors
✅ **Graceful degradation** - Works with or without GPG
✅ **Better debugging** - Clear warning messages
✅ **Flexible setup** - Can add GPG later
✅ **No breaking changes** - Existing setups work unchanged
✅ **Non-interactive GPG** - Works in CI/CD environments

## Testing the Fix

### Without GPG Secrets
The workflow will:
1. Warn about missing GPG_PRIVATE_KEY
2. Skip GPG import
3. Build packages normally
4. Warn about missing signing key
5. Skip signing
6. Create placeholder KEY.gpg
7. Publish unsigned repository

### With GPG Secrets
The workflow will:
1. Import GPG key successfully
2. Build packages normally
3. Sign Release files
4. Export public key
5. Publish signed repository

## How to Set Up GPG (Optional)

If you want signed packages, follow these steps:

1. **Generate GPG key** (see [SECRETS_SETUP.md](SECRETS_SETUP.md))
   ```bash
   gpg --full-generate-key
   ```

2. **Export and encode**
   ```bash
   gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc
   base64 -w 0 private-key.asc > private-key-base64.txt
   ```

3. **Add to GitHub Secrets**
   - `GPG_PRIVATE_KEY`: Contents of private-key-base64.txt
   - `GPG_KEY_ID`: Your 40-character key ID
   - `GPG_PASSPHRASE`: Your passphrase (or empty)

## Related Issues Fixed

- ❌ `base64: invalid input` - Now properly handles missing secrets
- ❌ `gpg: no valid OpenPGP data found` - Skips if secret empty
- ❌ Workflow validation errors - All `if` conditions removed
- ❌ Build failures due to GPG - Now optional

## Documentation

For detailed setup instructions, see:

- **[SECRETS_SETUP.md](SECRETS_SETUP.md)** - Step-by-step GPG configuration
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[SETUP.md](SETUP.md)** - Complete repository setup

## Verification

After pushing this fix, the workflow should:

1. ✅ Pass validation (no syntax errors)
2. ✅ Run successfully without secrets
3. ✅ Display helpful warnings
4. ✅ Build and publish packages
5. ✅ Work with secrets when added later

You can verify by:
- Checking the Actions tab - workflow should be valid
- Running the workflow without secrets - should complete
- Adding secrets - should sign and export key

## GitHub Actions Limitations

For future reference, these are **NOT** supported:

```yaml
# ❌ Cannot use secrets in if conditions
if: secrets.MY_SECRET != ''
if: ${{ secrets.MY_SECRET == 'value' }}

# ❌ Cannot check secret existence in expressions  
if: env.SECRET_EXISTS == 'true'  # Even with env var
```

Instead, use:

```yaml
# ✅ Check secrets in run scripts
run: |
  if [ -z "${{ secrets.MY_SECRET }}" ]; then
    echo "Secret not set"
    exit 0
  fi
  # Use secret
```

## Commit History

1. `38943ae` - Initial GPG optional implementation (had invalid syntax)
2. `8e64d52` - Fixed invalid `if` conditions with secrets ✅

The repository is now ready to use with or without GPG signing!
