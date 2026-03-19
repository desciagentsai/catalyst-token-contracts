# Catalyst Token - Quick Start Guide

## 🚀 Fast Track to Deployment

This is a 5-minute guide to deploy Catalyst (CATL) token contracts on Sui blockchain.

## Prerequisites

```bash
# 1. Install Sui CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch mainnet sui

# 2. Verify installation
sui --version

# 3. Create wallet (or import existing)
sui client new-address ed25519

# 4. Get testnet SUI
sui client faucet
```

## Deploy in 3 Steps

### Step 1: Build & Test

```bash
cd catalyst_contracts

# Build contracts
sui move build

# Run tests (optional)
sui move test
```

### Step 2: Deploy to Testnet

```bash
# Set network to testnet
sui client switch --env testnet

# Deploy contracts
./deployment/deploy.sh testnet
```

**Save all Object IDs from the output!**

### Step 3: Initialize Contracts

```bash
# Run initialization script
./deployment/initialize.sh testnet YOUR_PACKAGE_ID
```

You'll be prompted for:
- TreasuryCap Object ID
- SwapAdmin Object ID
- VestingAdmin Object ID
- VestingVault Object ID
- CATL Coin Object ID

## What Gets Deployed

✅ **CATL Token** (100M supply, 9 decimals)
✅ **Vesting Contract** (6 schedules, 48-month timeline)
✅ **Swap Pools** (CATL/SUI, CATL/USDT, CATL/USDC)

## Token Allocations

| Category | Amount | Vesting |
|----------|--------|---------|
| Presale | 12M | 6 months |
| Ecosystem | 30M | 48 months |
| Staking | 20M | 48 months |
| Team | 15M | 12m cliff + 24m vest |
| Treasury | 15M | 48 months |
| Strategic | 10M | 6m cliff + 12m vest |

## First Actions After Deployment

### 1. Release Initial Vesting

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catalyst_vesting \
  --function release_all \
  --args VAULT_ID 0x6 \
  --gas-budget 100000000
```

### 2. Add Initial Liquidity (CATL/SUI)

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catalyst_swap \
  --function add_liquidity_catl_sui \
  --args POOL_ID CATL_COIN_ID SUI_COIN_ID MIN_LP \
  --gas-budget 100000000
```

### 3. Test a Swap

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module catalyst_swap \
  --function swap_sui_to_catl \
  --args POOL_ID SUI_COIN_ID MIN_CATL_OUT \
  --gas-budget 50000000
```

## Verify Deployment

### Check Token Supply

```bash
sui client object TOKEN_CONFIG_ID | grep total_supply
# Expected: 100000000000000000 (100M with 9 decimals)
```

### Check Vesting Initialization

```bash
sui client object VESTING_VAULT_ID | grep initialized
# Expected: true
```

### Check Pool Creation

```bash
sui client object POOL_ID
# Should show reserves and LP supply
```

## Common Issues

### ❌ \"Insufficient Gas\"
**Solution**: Get more SUI from faucet
```bash
sui client faucet
```

### ❌ \"Object Not Found\"
**Solution**: Check you're using correct Object IDs from deployment output

### ❌ \"Package Already Published\"
**Solution**: Use existing package ID, don't redeploy

## Next Steps

1. 📖 Read [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed guide
2. 📅 Check [VESTING_SCHEDULES.md](docs/VESTING_SCHEDULES.md) for timeline
3. 🔧 See [USAGE.md](docs/USAGE.md) for integration examples
4. 🌐 Build frontend UI for your token
5. 🔄 Set up automated vesting releases

## Production Deployment

**⚠️ Before mainnet deployment:**

1. ✅ Test all functions thoroughly on testnet
2. ✅ Verify vesting calculations
3. ✅ Test swap functionality
4. ✅ Prepare admin key security (multisig/hardware wallet)
5. ✅ Document all object IDs securely

```bash
# Switch to mainnet
sui client switch --env mainnet

# Deploy
./deployment/deploy.sh mainnet

# Initialize
./deployment/initialize.sh mainnet YOUR_PACKAGE_ID
```

## Important Addresses

After deployment, save these addresses:

- **Package ID**: `0x...`
- **Token Config**: `0x...`
- **Treasury Cap**: `0x...` (KEEP SECURE!)
- **Vesting Vault**: `0x...`
- **CATL/SUI Pool**: `0x...`
- **Admin Capabilities**: `0x...` (KEEP SECURE!)

## Support & Resources

- 📚 [Full Documentation](README.md)
- 🔗 [Sui Documentation](https://docs.sui.io)
- 🌐 [Sui Explorer](https://suiexplorer.com)
- 💬 Discord/Telegram Community

## File Structure

```
catalyst_contracts/
├── sources/              # Move smart contracts
├── deployment/           # Deployment scripts
├── docs/                # Detailed documentation
├── Move.toml            # Package configuration
├── README.md            # Full overview
└── QUICKSTART.md        # This file
```

---
