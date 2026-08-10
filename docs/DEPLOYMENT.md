# Deployment Guide

## Prerequisites

### 1. Install Sui CLI

```bash
# Install Sui CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch mainnet sui

# Verify installation
sui --version
```

### 2. Create/Import Wallet

```bash
# Create new wallet
sui client new-address ed25519

# Or import existing wallet
sui keytool import "your-private-key" ed25519

# Check active address
sui client active-address

# Get test SUI (for testnet)
sui client faucet
```

### 3. Configure Network

```bash
# Add testnet (if not present)
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443

# Add mainnet
sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443

# Switch to testnet
sui client switch --env testnet
```

## Deployment Steps

### Step 1: Build Contracts

```bash
cd catalyst_contracts

# Build the Move package
sui move build

# Run tests (optional but recommended)
sui move test
```

### Step 2: Deploy to Testnet

```bash
# Make deployment script executable
chmod +x deployment/deploy.sh

# Deploy to testnet
./deployment/deploy.sh testnet
```

The script will output:
- **Package ID**: The deployed package identifier
- **Object IDs**: For TreasuryCap, AdminCap, etc.

Save all these IDs!

### Step 3: Update Move.toml

After deployment, update `Move.toml` with your Package ID:

```toml
[addresses]
catalyst = "0xYOUR_PACKAGE_ID_HERE"
```

### Step 4: Initialize Contracts

```bash
# Make initialization script executable
chmod +x deployment/initialize.sh

# Run initialization
./deployment/initialize.sh testnet YOUR_PACKAGE_ID
```

You'll need to provide:
1. **AdminCap Object ID** - For minting tokens (the TreasuryCap itself lives
   inside the shared `TokenConfig` object and is never used directly)
2. **TokenConfig Object ID** - Shared token config object
3. **SwapAdmin Object ID** - For creating the CATL/SUI pool
4. **VestingAdmin Object ID** - For vesting setup
5. **VestingVault Object ID** - Shared vesting object
6. **CATL Coin Object ID** - A coin holding exactly 90,000,000 CATL for the vault
7. **Team wallet address** - Receives the 17% team share
8. **Clock Object ID** - Use `0x6` (Sui's shared clock)

## Manual Deployment (Alternative)

If you prefer manual deployment:

### 1. Publish Package

```bash
sui client publish --gas-budget 500000000
```

### 2. Mint Initial Supply

`mint` requires the `AdminCap` — the `TreasuryCap` itself lives inside the
shared `TokenConfig` object and is never passed around directly.

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catl \
  --function mint \
  --args ADMIN_CAP_ID TOKEN_CONFIG_ID 100000000000000000 YOUR_ADDRESS \
  --gas-budget 100000000
```

### 3. Create the Swap Pool

The deployed swap contract supports a single CATL/SUI pool. `init_pool`
requires the `SwapAdmin` cap so only the deployer can create the canonical
pool object.

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catalyst_swap \
  --function init_pool \
  --args SWAP_ADMIN_ID \
  --gas-budget 50000000
```

### 4. Initialize Vesting

The vault expects exactly 90,000,000 CATL (`90000000000000000` base units) —
`initialize` will abort if the deposited coin doesn't match.

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catalyst_vesting \
  --function initialize \
  --args VESTING_ADMIN_ID VESTING_VAULT_ID CATL_COIN_ID TEAM_ADDRESS 0x6 \
  --gas-budget 100000000
```

## Mainnet Deployment

**⚠️ IMPORTANT: Test thoroughly on testnet first!**

```bash
# Switch to mainnet
sui client switch --env mainnet

# Deploy
./deployment/deploy.sh mainnet

# Initialize
./deployment/initialize.sh mainnet YOUR_PACKAGE_ID
```

## Verification

After deployment, verify contracts:

### 1. Check Token Config

```bash
sui client object TOKEN_CONFIG_ID
```

Expected fields:
- `total_supply: 100000000000000000`
- `circulating_supply: 100000000000000000`
- `paused: false`

### 2. Check Vesting Vault

```bash
sui client object VESTING_VAULT_ID
```

Expected:
- `initialized: true`
- `locked_balance: 90000000000000000` (90M CATL — the remaining 10M presale
  allocation is released at TGE outside this contract)

### 3. Check Swap Pools

```bash
sui client object CATL_SUI_POOL_ID
```

## Troubleshooting

### Error: Insufficient Gas

```bash
# Get more SUI
sui client faucet  # testnet

# Or check balance
sui client gas
```

### Error: Object Not Found

Make sure you're using the correct object IDs from deployment output.

### Error: Type Mismatch

Ensure you're using the correct package ID in all commands.

### Build Errors

```bash
# Clean and rebuild
rm -rf build/
sui move build
```

## Post-Deployment Checklist

- [ ] Package deployed successfully
- [ ] All object IDs saved securely
- [ ] Token minted (100M CATL)
- [ ] Vesting initialized
- [ ] Swap pools created
- [ ] Admin capabilities secured
- [ ] Frontend updated with contract addresses
- [ ] Documentation updated

## Security Recommendations

1. **Secure Admin Keys**: Use hardware wallet or multisig for admin capabilities
2. **Test Thoroughly**: Test all functions on testnet first
3. **Verify Contracts**: Double-check all parameters before mainnet
4. **Monitor Deployment**: Watch transactions on Sui Explorer
5. **Emergency Contacts**: Have pause mechanism ready

## Useful Commands

```bash
# View transaction details
sui client transaction TX_DIGEST

# View object details
sui client object OBJECT_ID

# Check gas balance
sui client gas

# View active address
sui client active-address

# Switch networks
sui client switch --env [testnet|mainnet]
```

## Next Steps

After successful deployment:

1. See [USAGE.md](USAGE.md) for contract interaction examples
2. See [VESTING_SCHEDULES.md](VESTING_SCHEDULES.md) for vesting timeline
3. Add initial liquidity to swap pools
4. Set up automated vesting releases
5. Update frontend with contract addresses
