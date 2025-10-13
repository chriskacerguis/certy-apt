# Next Steps - Getting Your APT Repository Live

Congratulations! You've set up the foundation for your Certy APT repository. Here's what to do next:

## 1. Push to GitHub (5 minutes)

```bash
cd /Users/chriskacerguis/Developer/certy-apt

# Initialize git if not already done
git init
git add .
git commit -m "Initial APT repository setup for Certy"

# Add remote (replace with your GitHub repo URL)
git remote add origin https://github.com/chriskacerguis/certy-apt.git

# Push to main branch
git branch -M main
git push -u origin main
```

## 2. Set Up GPG Key (15 minutes)

Follow the detailed guide in `docs/GPG_SETUP.md`:

```bash
# Generate GPG key
gpg --full-generate-key

# Export for GitHub Secrets
gpg --list-keys --keyid-format LONG
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc
base64 private-key.asc > private-key-base64.txt
gpg --armor --export YOUR_KEY_ID > KEY.gpg
```

**Important**: Save these files securely and never commit them!

## 3. Configure GitHub Secrets (5 minutes)

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- **GPG_PRIVATE_KEY**: Paste contents of `private-key-base64.txt`
- **GPG_KEY_ID**: Your 40-character key ID (format: `ABCD1234EFGH5678...`)
- **GPG_PASSPHRASE**: The passphrase you used when creating the key

## 4. Enable GitHub Pages (2 minutes)

1. Go to Settings → Pages
2. Under "Source", select **GitHub Actions**
3. Click Save

## 5. Run First Build (10 minutes)

1. Go to the **Actions** tab
2. Click on "Build and Publish APT Repository" workflow
3. Click **Run workflow** button
4. Enter the latest Certy version (e.g., `v1.1.0`)
5. Click **Run workflow**

Wait for the workflow to complete (usually 3-5 minutes).

## 6. Verify Deployment (5 minutes)

Once the workflow completes:

### Check GitHub Pages
Visit: `https://YOUR_USERNAME.github.io/certy-apt`

You should see a webpage with installation instructions.

### Check Package Files
Visit: `https://YOUR_USERNAME.github.io/certy-apt/pool/main/c/certy/`

You should see `.deb` package files.

### Check GPG Key
```bash
curl https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg
```

Should download your public GPG key.

## 7. Test Installation (10 minutes)

On a Ubuntu/Debian system (or VM):

```bash
# Add repository
curl -fsSL https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://YOUR_USERNAME.github.io/certy-apt stable main" | \
  sudo tee /etc/apt/sources.list.d/certy.list

# Update and install
sudo apt update
sudo apt install certy

# Test
certy --version
```

## 8. Update Documentation (10 minutes)

Update `README.md` to replace placeholder URLs with your actual repository:

```bash
# Find and replace YOUR_USERNAME with chriskacerguis
sed -i '' 's/YOUR_USERNAME/chriskacerguis/g' README.md
sed -i '' 's/YOUR_USERNAME/chriskacerguis/g' docs/*.md
sed -i '' 's/YOUR_USERNAME/chriskacerguis/g' QUICKREF.md

# Commit changes
git add .
git commit -m "Update repository URLs"
git push
```

## 9. Announce Your Repository

Consider creating a README in the main Certy repository mentioning APT installation:

```markdown
### Install via APT (Debian/Ubuntu)

```bash
curl -fsSL https://chriskacerguis.github.io/certy-apt/KEY.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://chriskacerguis.github.io/certy-apt stable main" | \
  sudo tee /etc/apt/sources.list.d/certy.list

sudo apt update
sudo apt install certy
```
```

## 10. Set Up Automation (Optional)

The repository will automatically:
- Check for new Certy releases daily at 2 AM UTC
- Build and publish new packages automatically
- Update the repository metadata

You can also manually trigger builds from the Actions tab.

## Troubleshooting First Run

### Workflow Fails with GPG Error
- Double-check your GPG secrets are correctly formatted
- Ensure GPG_KEY_ID is exactly 40 characters
- Verify the private key is base64 encoded

### 404 Error on GitHub Pages
- Wait 5-10 minutes after the first workflow completes
- Check Settings → Pages to ensure it's enabled
- Verify the gh-pages branch was created

### Package Not Found
- Ensure the workflow completed successfully
- Check the gh-pages branch has the `pool/` directory
- Verify the Packages file exists in `dists/stable/main/binary-amd64/`

### NO_PUBKEY Error
- Ensure you exported the correct public key
- Re-run the workflow to regenerate KEY.gpg
- Check the GPG_KEY_ID matches the key in your private key

## Success Checklist

- [ ] Repository pushed to GitHub
- [ ] GitHub Secrets configured (GPG_PRIVATE_KEY, GPG_KEY_ID, GPG_PASSPHRASE)
- [ ] GitHub Pages enabled
- [ ] First workflow run completed successfully
- [ ] gh-pages branch created and populated
- [ ] Repository webpage accessible
- [ ] Package files visible in pool/
- [ ] Test installation completed successfully
- [ ] Documentation updated with correct URLs
- [ ] (Optional) Main Certy repo updated with APT instructions

## Getting Help

If you run into issues:

1. **Check Workflow Logs**: Actions tab → Select the failed run → View logs
2. **Review Documentation**: See `docs/SETUP.md` for detailed setup
3. **Test Locally**: Use `docs/TESTING.md` for local testing procedures
4. **Common Issues**: Check `QUICKREF.md` for troubleshooting tips
5. **Open an Issue**: If still stuck, open an issue with logs and details

## What's Next?

After your repository is live:

1. **Monitor Builds**: Check Actions tab periodically for failed builds
2. **Update Packages**: New Certy releases will be packaged automatically
3. **Add Architectures**: Consider adding arm64 support (see docs/SETUP.md)
4. **Improve Documentation**: Add distribution-specific instructions
5. **Add Testing**: Set up automated installation tests
6. **Consider Custom Domain**: Point a domain to GitHub Pages for easier URLs

## Estimated Total Setup Time

- **Basic Setup**: ~30-40 minutes
- **With Testing**: ~1 hour
- **With Custom Domain**: ~1.5 hours

## Support

For help with:
- **Certy application**: https://github.com/chriskacerguis/certy/issues
- **APT repository**: https://github.com/chriskacerguis/certy-apt/issues
- **Packaging questions**: See Debian documentation

---

**Ready to start?** Begin with Step 1: Push to GitHub! 🚀
