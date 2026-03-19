# Catalyst Contracts - File Overview

## All Contract Files

### 📁 `/app/catalyst_contracts/`

#### Smart Contracts (`sources/`)

1. **catalyst_token.move**
   - Main CATL token contract
   - 100M fixed supply, 9 decimals
   - Mint/burn capabilities
   - Admin controls (pause/unpause)
   - Treasury management

2. **catalyst_vesting.move**
   - Multi-category vesting system
   - 6 different vesting schedules
   - Auto-release to treasury
   - Linear, cliff+vest, and emission-based vesting
   - Emergency pause/unpause
   - Real-time unlock calculations

3. **catalyst_swap.move**
   - Automated Market Maker (AMM)
   - CATL/SUI liquidity pool
   - CATL/USDT liquidity pool (generic stable)
   - CATL/USDC liquidity pool (generic stable)
   - 0.3% swap fee
   - Add/remove liquidity
   - Slippage protection

#### Configuration

4. **Move.toml**
   - Package configuration
   - Dependencies (Sui framework)
   - Package metadata

#### Documentation (`docs/`)

5. **DEPLOYMENT.md**
   - Complete deployment guide
   - Prerequisites and setup
   - Step-by-step instructions
   - Manual deployment alternative
   - Troubleshooting
   - Post-deployment checklist

6. **VESTING_SCHEDULES.md**
   - Detailed vesting timeline for all 6 categories
   - Monthly unlock schedules
   - Release functions and commands
   - Automated release setup
   - Emergency controls
   - Frontend integration examples

7. **USAGE.md**
   - Contract interaction guide
   - CLI commands for all functions
   - JavaScript/TypeScript examples
   - Python examples
   - React frontend examples
   - Common patterns and best practices

#### Deployment Scripts (`deployment/`)

8. **deploy.sh**
   - Automated deployment script
   - Network selection (testnet/mainnet)
   - Build and publish contracts
   - Capture deployment output
   - Save deployment info

9. **initialize.sh**
   - Contract initialization script
   - Mint initial token supply
   - Create swap pools
   - Initialize vesting schedules
   - Setup complete system

#### Main Documentation

10. **README.md**
    - Project overview
    - Token details and distribution
    - Feature list
    - Project structure
    - Quick start guide
    - Security features

11. **QUICKSTART.md**
    - 5-minute deployment guide
    - Essential commands only
    - Common issues and solutions
    - First actions checklist

12. **FILES.md**
    - This file
    - Complete file listing
    - Purpose of each file

## File Usage by Role

### For Blockchain Developers
- `sources/*.move` - Smart contract code
- `Move.toml` - Package configuration
- `deployment/*.sh` - Deployment automation

### For Integration Developers
- `docs/USAGE.md` - API and integration guide
- `docs/DEPLOYMENT.md` - Deployed addresses
- Example code in all docs

### For Project Managers
- `README.md` - Project overview
- `QUICKSTART.md` - Fast deployment
- `docs/VESTING_SCHEDULES.md` - Tokenomics timeline

### For System Administrators
- `deployment/*.sh` - Deployment scripts
- `docs/DEPLOYMENT.md` - Operations guide
- `docs/VESTING_SCHEDULES.md` - Maintenance tasks

## Quick Access

| Need to... | Go to... |
|------------|----------|
| Deploy contracts | `deployment/deploy.sh` |
| Initialize system | `deployment/initialize.sh` |
| Understand vesting | `docs/VESTING_SCHEDULES.md` |
| Integrate in app | `docs/USAGE.md` |
| Get started fast | `QUICKSTART.md` |
| Full reference | `README.md` |

## Directory Tree

```
catalyst_contracts/
├── sources/
│   ├── catalyst_token.move       # Token contract
│   ├── catalyst_vesting.move     # Vesting contract
│   └── catalyst_swap.move        # Swap/AMM contract
├── deployment/
│   ├── deploy.sh                 # Deployment script
│   └── initialize.sh             # Initialization script
├── docs/
│   ├── DEPLOYMENT.md            # Deployment guide
│   ├── VESTING_SCHEDULES.md     # Vesting details
│   └── USAGE.md                 # Usage examples
├── Move.toml                     # Package config
├── README.md                     # Main documentation
├── QUICKSTART.md                # Quick start guide
└── FILES.md                     # This file
```

## Lines of Code

- **catalyst_token.move**: ~140 lines
- **catalyst_vesting.move**: ~330 lines
- **catalyst_swap.move**: ~580 lines
- **Total Contract Code**: ~1,050 lines
- **Documentation**: ~2,000+ lines
- **Scripts**: ~200 lines

## Contract Capabilities

### Token Contract (catalyst_token.move)
- ✅ Create currency
- ✅ Mint tokens
- ✅ Burn tokens
- ✅ Pause/unpause
- ✅ Update treasury
- ✅ View functions

### Vesting Contract (catalyst_vesting.move)
- ✅ Initialize 6 schedules
- ✅ Calculate unlocks
- ✅ Release by category
- ✅ Release all
- ✅ Pause/unpause
- ✅ Update treasury
- ✅ View schedules

### Swap Contract (catalyst_swap.move)
- ✅ Create pools
- ✅ Add liquidity
- ✅ Remove liquidity
- ✅ Swap CATL ↔ SUI
- ✅ Swap CATL ↔ USDT
- ✅ Swap CATL ↔ USDC
- ✅ Calculate outputs
- ✅ Pause/unpause pools
- ✅ View reserves

## Next Steps

1. Review all Move contracts in `sources/`
2. Read `QUICKSTART.md` for deployment
3. Check `docs/VESTING_SCHEDULES.md` for tokenomics
4. Use `docs/USAGE.md` for integration

## Need Help?

- For deployment: See `docs/DEPLOYMENT.md`
- For integration: See `docs/USAGE.md`
- For vesting: See `docs/VESTING_SCHEDULES.md`
- For quick start: See `QUICKSTART.md`
