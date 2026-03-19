# Git Repository Setup Guide

## Should You Create a Separate Git Repo?

### ✅ YES - Recommended for:
- Independent version control
- Separate deployment pipeline
- Different team/contributors
- Open source the contracts separately
- Cleaner organization

### ⚠️ NO - Keep in current repo if:
- Tightly integrated with existing codebase
- Shared deployment process
- Same team manages everything

## Recommendation: **Create a Separate Repo**

The Catalyst contracts are self-contained and production-ready. A separate repository provides:
- Clean contract versioning
- Independent security audits
- Easier collaboration with blockchain devs
- Clear deployment history

---

## Option 1: Create New Git Repository (Recommended)

### Step 1: Copy Contracts to New Location

```bash
# On your local machine, create new directory
mkdir catalyst-token-contracts
cd catalyst-token-contracts

# Copy all files from /app/catalyst_contracts/
# (Download from Emergent or copy manually)
```

### Step 2: Initialize Git Repository

```bash
# Initialize git
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Build artifacts
build/
*.lock
*.log

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Sui
.sui/
EOF

# Add all files
git add .

# Initial commit
git commit -m \"Initial commit: Catalyst Token contracts

- CATL token contract (100M supply)
- Vesting contract (6 schedules, 48 months)
- Swap contract (AMM for SUI/USDT/USDC)
- Complete documentation and deployment scripts\"
```

### Step 3: Create GitHub Repository

```bash
# On GitHub, create new repository: catalyst-token-contracts

# Link and push
git remote add origin https://github.com/YOUR_USERNAME/catalyst-token-contracts.git
git branch -M main
git push -u origin main
```

### Step 4: Add README Badges (Optional)

Add to top of README.md:

```markdown
![Sui](https://img.shields.io/badge/Sui-Blockchain-blue)
![Move](https://img.shields.io/badge/Language-Move-orange)
![License](https://img.shields.io/badge/License-MIT-green)
```

---

## Option 2: Keep in Current Repo (Monorepo Approach)

### Pros:
- Everything in one place
- Shared git history
- Single deployment pipeline

### Setup:

```bash
# Already done! Your contracts are in:
# /app/catalyst_contracts/

# Just commit to existing repo
cd /app
git add catalyst_contracts/
git commit -m \"Add Catalyst token contracts\"
git push
```

---

## Option 3: Git Submodule (Advanced)

If you want both approaches:

```bash
# In your main repo
cd /path/to/main/repo

# Create separate contracts repo first
# Then add as submodule
git submodule add https://github.com/YOUR_USERNAME/catalyst-token-contracts.git contracts/catalyst

# This keeps contracts separate but linked
```

---

## Recommended Repository Structure

For a **separate repository**:

```
catalyst-token-contracts/
├── .github/
│   └── workflows/
│       ├── build.yml          # CI: Build and test
│       └── deploy.yml         # CD: Deployment automation
├── sources/
│   ├── catalyst_token.move
│   ├── catalyst_vesting.move
│   └── catalyst_swap.move
├── tests/
│   └── (future test files)
├── deployment/
│   ├── deploy.sh
│   └── initialize.sh
├── docs/
│   ├── DEPLOYMENT.md
│   ├── VESTING_SCHEDULES.md
│   └── USAGE.md
├── examples/
│   ├── javascript/
│   ├── python/
│   └── react/
├── .gitignore
├── Move.toml
├── README.md
├── QUICKSTART.md
├── FILES.md
├── LICENSE
└── CHANGELOG.md
```

---

## GitHub Repository Setup Checklist

- [ ] Create repository on GitHub
- [ ] Add comprehensive README.md
- [ ] Add LICENSE file (MIT recommended)
- [ ] Set up branch protection (main branch)
- [ ] Enable Issues for bug tracking
- [ ] Add topics: `sui`, `blockchain`, `move`, `defi`, `token`
- [ ] Add description: \"Catalyst (CATL) token contracts on Sui blockchain\"
- [ ] Create releases for versions
- [ ] Set up CI/CD with GitHub Actions (optional)
- [ ] Add SECURITY.md for vulnerability reporting
- [ ] Add CODE_OF_CONDUCT.md if open source

---

## Download Files from Emergent

To get your files from this environment:

### Option A: Download via UI
1. Files are in `/app/catalyst_contracts/`
2. Use Emergent's download feature
3. Download entire `catalyst_contracts` folder

### Option B: Create Archive
```bash
# Create a zip file
cd /app
tar -czf catalyst_contracts.tar.gz catalyst_contracts/

# This creates: catalyst_contracts.tar.gz
# Download this file from Emergent
```

---

## Next Steps After Creating Repo

1. **Add CI/CD** (.github/workflows/build.yml):
```yaml
name: Build and Test
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Sui
        run: cargo install --git https://github.com/MystenLabs/sui.git sui
      - name: Build contracts
        run: sui move build
      - name: Run tests
        run: sui move test
```

2. **Create Releases**:
   - Tag version: `git tag -a v1.0.0 -m \"Initial release\"`
   - Push tags: `git push --tags`
   - Create release on GitHub with deployment artifacts

3. **Documentation**:
   - Add wiki pages
   - Create API documentation
   - Add integration tutorials

4. **Security**:
   - Request audit from Sui security firms
   - Add bug bounty program
   - Document security practices

---

## My Recommendation

**Create a separate Git repository** for these reasons:

1. ✅ Contracts are production-ready and self-contained
2. ✅ Easier to audit and review
3. ✅ Clean versioning for smart contracts
4. ✅ Can be open-sourced independently
5. ✅ Better for collaboration with blockchain devs
6. ✅ Separate deployment/release cycle

The contracts are in `/app/catalyst_contracts/` - download this entire folder and create a new Git repository.

---

## Questions?

- **Q: Can I move to separate repo later?**
  - A: Yes, use `git filter-branch` or `git subtree split`

- **Q: Should contracts be open source?**
  - A: Recommended for transparency and auditing

- **Q: How to handle updates?**
  - A: Create new releases and deploy new package versions on Sui

---

For any questions, refer to:
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com)
- [Sui Move Best Practices](https://docs.sui.io)
