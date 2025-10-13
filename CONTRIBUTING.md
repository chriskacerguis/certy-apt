# Contributing to Certy APT Repository

Thank you for your interest in contributing to the Certy APT Repository!

## How to Contribute

### Reporting Issues

If you encounter any issues with the APT repository or package installation:

1. Check if the issue already exists in the [Issues](https://github.com/chriskacerguis/certy-apt/issues) section
2. If not, create a new issue with:
   - Your Linux distribution and version
   - The architecture you're using (amd64, arm64, etc.)
   - Steps to reproduce the issue
   - Any error messages you received

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear instructions in README.md
- Add examples for different distributions
- Improve installation instructions
- Add troubleshooting tips

### Enhancing the Repository

You can contribute by:

- Adding support for new architectures
- Improving the build scripts
- Enhancing the GitHub Actions workflow
- Adding tests for package validation
- Improving repository metadata

### Pull Request Process

1. Fork the repository
2. Create a new branch for your feature (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes locally if possible
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Use clear, descriptive commit messages
- Follow existing code style in shell scripts
- Comment complex logic
- Keep scripts POSIX-compliant when possible

### Testing

Before submitting a PR:

- Test build scripts locally
- Verify package metadata is correct
- Ensure scripts are executable
- Check for shell script errors with `shellcheck`

## Questions?

If you have questions, feel free to:

- Open an issue with the "question" label
- Check existing discussions in Issues
- Review the README for documentation

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to make this project better!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
