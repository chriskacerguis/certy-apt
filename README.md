# Certy APT Repository

This repository hosts an APT package repository for [Certy](https://github.com/chriskacerguis/certy), a lightweight CLI tool for managing Certificate Authorities and generating certificates.

## Using the Repository

### Quick Setup

Add the repository to your system:

```bash
# Add the repository GPG key
curl -fsSL https://chriskacerguis.github.io/certy-apt/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

# Add the repository
echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://chriskacerguis.github.io/certy-apt stable main" | sudo tee /etc/apt/sources.list.d/certy.list

# Update package list
sudo apt update

# Install certy
sudo apt install certy
```

### Verify Installation

```bash
certy --version
```

### Updating

Updates will be delivered automatically through your regular system updates:

```bash
sudo apt update
sudo apt upgrade
```

## Repository Structure

```
certy-apt/
├── .github/
│   └── workflows/
│       └── build-and-publish.yml    # Automated package building and publishing
├── debian/
│   ├── control.template              # Debian package metadata template
│   ├── postinst                      # Post-installation script
│   └── prerm                         # Pre-removal script
├── scripts/
│   ├── build-deb.sh                  # Script to build .deb packages
│   ├── update-repo.sh                # Script to update repository metadata
│   └── get-certy-info.sh             # Helper for dynamic info extraction
├── .gitignore
├── LICENSE
└── README.md
```

## How It Works

This repository uses GitHub Actions to:

1. **Monitor Releases**: Watch for new releases in the [chriskacerguis/certy](https://github.com/chriskacerguis/certy) repository
2. **Build Packages**: Download release binaries and create `.deb` packages for different architectures
3. **Dynamic Documentation**: Automatically extract features and options from Certy binary and GitHub README
4. **Update Repository**: Generate repository metadata (Packages, Release, InRelease files)
5. **Sign Packages**: Sign the repository with GPG for secure package verification
6. **Publish**: Deploy to GitHub Pages for public access

### Dynamic Package Generation

The packaging system now uses **dynamic information extraction** to keep packages synchronized with Certy:

- **Man pages** are generated from `certy -h` output, ensuring documentation matches the actual binary
- **Package descriptions** are extracted from the GitHub README automatically
- **Version information** is pulled directly from the binary
- **Features list** updates automatically when Certy adds new capabilities

This means packages automatically stay up-to-date as Certy evolves, without manual intervention. See [docs/DYNAMIC_GENERATION.md](docs/DYNAMIC_GENERATION.md) for technical details.

## Manual Package Building

If you want to build packages manually:

```bash
# Clone this repository
git clone https://github.com/chriskacerguis/certy-apt.git
cd certy-apt

# Build a package for a specific version
./scripts/build-deb.sh <version> <architecture>

# Example:
./scripts/build-deb.sh v1.1.0 amd64
```

## Repository Maintenance

### Adding a New Architecture

1. Update `.github/workflows/build-and-publish.yml` to include the new architecture
2. Ensure the Certy releases include binaries for that architecture
3. Update the repository signing to include the new architecture

### Updating GPG Key

The repository is signed with a GPG key stored as GitHub secrets:

- `GPG_PRIVATE_KEY`: The private GPG key for signing
- `GPG_PASSPHRASE`: The passphrase for the private key

To generate a new key:

```bash
# Generate a new GPG key
gpg --full-generate-key

# Export the private key
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc

# Export the public key
gpg --armor --export YOUR_KEY_ID > KEY.gpg

# Add the private key and passphrase to GitHub Secrets
```

## Supported Distributions

Currently, the repository provides packages for:

- **Debian 10 (Buster)** and newer
- **Ubuntu 18.04 (Bionic)** and newer
- Other Debian-based distributions

## Supported Architectures

- `amd64` (x86_64)

Additional architectures (arm64, armhf) can be added as needed.

## Contributing

Contributions are welcome! If you encounter any issues with the APT repository or packaging:

1. Check existing [issues](https://github.com/chriskacerguis/certy-apt/issues)
2. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions
3. Open a new issue with details about your environment and the problem
4. Submit a pull request with fixes or improvements

## Troubleshooting

Having issues? Check these guides:

- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Solutions for common problems
- **[Secrets Setup Guide](docs/SECRETS_SETUP.md)** - How to configure GPG signing
- **[Setup Guide](docs/SETUP.md)** - Complete repository setup instructions
- **[Testing Guide](docs/TESTING.md)** - How to test packages locally

Common issues:
- **GPG errors**: See [SECRETS_SETUP.md](docs/SECRETS_SETUP.md)
- **Build failures**: See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Package not found**: Check repository configuration and GitHub Pages status

## Security

### Repository Signing

All packages and repository metadata are signed with GPG to ensure authenticity and integrity.

### Reporting Security Issues

If you discover a security vulnerability in the packaging or repository infrastructure, please report it to the maintainer directly rather than opening a public issue.

## License

This repository and its packaging scripts are released under the MIT License. See [LICENSE](LICENSE) for details.

The Certy application itself is also MIT licensed. See the [main repository](https://github.com/chriskacerguis/certy) for more information.

## Links

- **Main Project**: [chriskacerguis/certy](https://github.com/chriskacerguis/certy)
- **APT Repository**: [https://chriskacerguis.github.io/certy-apt](https://chriskacerguis.github.io/certy-apt)
- **Issues**: [GitHub Issues](https://github.com/chriskacerguis/certy-apt/issues)

## Acknowledgments

Built with inspiration from various community-maintained APT repositories and best practices for Debian packaging.
