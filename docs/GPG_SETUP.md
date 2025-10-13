# GPG Key Setup for Certy APT Repository

This guide explains how to set up GPG signing for the Certy APT repository.

## Generating a New GPG Key

If you don't have a GPG key yet, generate one:

```bash
# Generate a new GPG key
gpg --full-generate-key
```

Select:
- Key type: RSA and RSA
- Key size: 4096 bits
- Expiration: 2 years (or your preference)
- Real name: Certy APT Repository
- Email: your-email@example.com

## Exporting Keys

### Export Public Key

```bash
# List your keys to find the Key ID
gpg --list-keys

# Export the public key (this will be published)
gpg --armor --export YOUR_KEY_ID > KEY.gpg
```

### Export Private Key

```bash
# Export the private key (for GitHub Secrets)
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc

# Base64 encode it for GitHub Secrets
base64 -w 0 private-key.asc > private-key-base64.txt
```

**Important**: Keep the private key secure and never commit it to the repository!

## Adding Keys to GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Add the following secrets:

### Required Secrets

- **GPG_PRIVATE_KEY**: The base64-encoded private key
  - Content from `private-key-base64.txt`
  
- **GPG_KEY_ID**: The GPG key ID
  - Format: `ABCD1234EFGH5678` (40-character key ID)
  - Get it with: `gpg --list-keys --keyid-format LONG`
  
- **GPG_PASSPHRASE**: The passphrase for your GPG key
  - If you didn't set a passphrase, use an empty string

## Testing Locally

Test signing locally before pushing:

```bash
# Import your key
gpg --import private-key.asc

# Set environment variables
export GPG_KEY_ID="YOUR_KEY_ID"
export GPG_PASSPHRASE="your_passphrase"

# Test signing
cd dists/stable
gpg --default-key "$GPG_KEY_ID" \
    --batch --yes \
    --passphrase "$GPG_PASSPHRASE" \
    --pinentry-mode loopback \
    -abs -o Release.gpg Release
```

## Key Management

### Extending Key Expiration

```bash
# Edit the key
gpg --edit-key YOUR_KEY_ID

# At the gpg> prompt:
expire
# Select new expiration
key 1
expire
# Select new expiration
save
```

### Revoking a Key

If your key is compromised:

```bash
# Generate revocation certificate
gpg --output revoke.asc --gen-revoke YOUR_KEY_ID

# Import the revocation
gpg --import revoke.asc

# Publish to keyservers
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

## Publishing the Public Key

The public key will be automatically published to:
- `https://chriskacerguis.github.io/certy-apt/KEY.gpg`

Users will add this key to their system with:

```bash
curl -fsSL https://chriskacerguis.github.io/certy-apt/KEY.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg
```

## Security Best Practices

1. **Use a Strong Passphrase**: Protect your private key with a strong passphrase
2. **Set Expiration**: Keys should expire and be renewed periodically
3. **Backup Keys**: Keep encrypted backups of your private key
4. **Rotate Secrets**: Periodically rotate GitHub Secrets
5. **Monitor Access**: Regularly review GitHub Actions logs

## Troubleshooting

### "gpg: signing failed: Inappropriate ioctl for device"

Add `--pinentry-mode loopback` to your GPG commands.

### "gpg: signing failed: No secret key"

Ensure the private key is properly imported and the GPG_KEY_ID matches.

### "gpg: signing failed: Bad passphrase"

Check that GPG_PASSPHRASE is set correctly in GitHub Secrets.

## Resources

- [GPG Documentation](https://gnupg.org/documentation/)
- [Debian Repository HOWTO](https://wiki.debian.org/DebianRepository/Setup)
- [GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
