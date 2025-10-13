# Repository Setup Guide

This guide walks you through setting up the Certy APT repository from scratch.

## Prerequisites

- A GitHub account
- Git installed locally
- Basic knowledge of GitHub Actions
- GPG for package signing (optional but recommended)

## Step 1: Create the Repository

1. Create a new repository on GitHub named `certy-apt`
2. Clone it locally:

```bash
git clone https://github.com/YOUR_USERNAME/certy-apt.git
cd certy-apt
```

## Step 2: Set Up GPG Signing (Recommended)

For production use, you should sign your packages. See [GPG_SETUP.md](GPG_SETUP.md) for detailed instructions.

Quick version:

```bash
# Generate a GPG key
gpg --full-generate-key

# Export keys
gpg --list-keys --keyid-format LONG
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc
base64 -w 0 private-key.asc > private-key-base64.txt
gpg --armor --export YOUR_KEY_ID > KEY.gpg
```

Add to GitHub Secrets:
- `GPG_PRIVATE_KEY`: Contents of `private-key-base64.txt`
- `GPG_KEY_ID`: Your 40-character key ID
- `GPG_PASSPHRASE`: Your GPG key passphrase

## Step 3: Enable GitHub Pages

1. Go to your repository Settings
2. Navigate to Pages
3. Set Source to "GitHub Actions"
4. Save

## Step 4: Test the Workflow

### Manual Trigger (Recommended for First Run)

1. Go to Actions tab in your GitHub repository
2. Select "Build and Publish APT Repository"
3. Click "Run workflow"
4. Enter the Certy version (e.g., `v1.1.0`)
5. Click "Run workflow"

### Automatic Trigger

The workflow will automatically run:
- Daily at 2 AM UTC to check for new releases
- When you push changes to workflow files or scripts

## Step 5: Verify the Repository

After the workflow completes:

1. Check the gh-pages branch was created
2. Visit `https://YOUR_USERNAME.github.io/certy-apt`
3. Verify the package is available at `https://YOUR_USERNAME.github.io/certy-apt/pool/main/c/certy/`

## Step 6: Test Installation

On a Debian/Ubuntu system:

```bash
# Add the repository
curl -fsSL https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://YOUR_USERNAME.github.io/certy-apt stable main" | sudo tee /etc/apt/sources.list.d/certy.list

# Update and install
sudo apt update
sudo apt install certy

# Verify
certy --version
```

## Troubleshooting

### Workflow Fails with "GPG signing failed"

- Verify your GPG secrets are correctly set
- Check the key ID format (should be 40 characters)
- Ensure the private key is base64 encoded

### Packages Not Found

- Check the gh-pages branch exists
- Verify GitHub Pages is enabled
- Check the workflow logs for errors

### Permission Denied

- Ensure the repository has write permissions for GitHub Actions
- Check that GitHub Pages deployment is allowed

## Directory Structure

After setup, your repository will have:

```
certy-apt/
├── .github/
│   └── workflows/
│       └── build-and-publish.yml
├── debian/
│   ├── control.template
│   ├── postinst
│   └── prerm
├── docs/
│   ├── GPG_SETUP.md
│   └── SETUP.md (this file)
├── scripts/
│   ├── build-deb.sh
│   └── update-repo.sh
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

The `gh-pages` branch will contain:

```
gh-pages/
├── dists/
│   └── stable/
│       ├── InRelease
│       ├── Release
│       ├── Release.gpg
│       └── main/
│           └── binary-amd64/
│               ├── Packages
│               └── Packages.gz
├── pool/
│   └── main/
│       └── c/
│           └── certy/
│               └── certy_VERSION_amd64.deb
├── index.html
└── KEY.gpg
```

## Customization

### Supporting Multiple Architectures

Edit `.github/workflows/build-and-publish.yml`:

```yaml
strategy:
  matrix:
    arch: [amd64, arm64, armhf]
```

Ensure Certy releases include binaries for these architectures.

### Changing the Distribution Name

Edit the workflow and scripts to use your preferred distribution name instead of "stable".

### Custom Domain

1. Add a CNAME file to the gh-pages branch
2. Configure your custom domain in GitHub Pages settings
3. Update instructions to use your custom domain

## Maintenance

### Updating Packages

The workflow automatically checks for new Certy releases daily. You can also manually trigger it.

### Removing Old Versions

Old package files remain in the repository. To remove them:

```bash
git checkout gh-pages
rm pool/main/c/certy/certy_OLD_VERSION_amd64.deb
./scripts/update-repo.sh
git add -A
git commit -m "Remove old package version"
git push
```

### Monitoring

- Check GitHub Actions regularly for failed workflows
- Monitor repository size (packages can accumulate)
- Review security advisories for dependencies

## Security Considerations

1. **Keep GPG Keys Secure**: Never commit private keys to the repository
2. **Rotate Secrets**: Periodically update GPG keys and GitHub Secrets
3. **Monitor Access**: Review repository access and workflow permissions
4. **Sign Everything**: Always sign packages for production use
5. **Use Branch Protection**: Protect main and gh-pages branches

## Next Steps

1. Update README.md with your repository URL
2. Create a release for the certy-apt repository
3. Announce the APT repository to users
4. Consider setting up:
   - Issue templates
   - Pull request templates
   - Code of conduct
   - Security policy

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Debian Repository Format](https://wiki.debian.org/DebianRepository/Format)
- [APT Repository HOWTO](https://wiki.debian.org/DebianRepository/Setup)
- [GPG Documentation](https://gnupg.org/documentation/)

## Support

If you need help:

1. Check the documentation in the `docs/` directory
2. Review the workflow logs in GitHub Actions
3. Open an issue in the repository
4. Check existing issues for similar problems
