# Catalyst Token Contracts

## Overview

Catalyst (CATL) is a DeSci innovation platform token built on Sui blockchain with comprehensive tokenomics and vesting mechanisms.

### Token Details
- **Name**: Catalyst
- **Symbol**: CATL
- **Total Supply**: 100,000,000 CATL
- **Decimals**: 9
- **Blockchain**: Sui
- **Inflation**: None (fixed supply)

### Contracts

1. **catalyst_token.move** - Main token contract with mint/burn capabilities
2. **catalyst_vesting.move** - Multi-category vesting with automated treasury releases
3. **catalyst_swap.move** - AMM DEX for CATL trading pairs

## Token Distribution

| Allocation | Percentage | Tokens | Vesting Schedule |
|------------|-----------|---------|------------------|
| Ecosystem Incentives | 30% | 30,000,000 | Linear over 48 months |
| Staking Rewards | 20% | 20,000,000 | Emission-based over 48 months |
| Team | 15% | 15,000,000 | 12-month cliff + 24-month vest |
| Treasury/DAO | 15% | 15,000,000 | Structured release over 48 months |
| Strategic Partners | 10% | 10,000,000 | 6-month cliff + 12-month vest |
| Presale | 12% | 12,000,000 | 6-month linear vest |
| **Total** | **100%** | **100,000,000** | |

## Features

### Token Contract
- ✅ Fixed supply with no inflation
- ✅ Mint/Burn capabilities (admin controlled)
- ✅ Pause/Unpause for emergencies
- ✅ Treasury management

### Vesting Contract
- ✅ 6 separate vesting schedules
- ✅ Automated releases to treasury
- ✅ Multiple vesting types (linear, cliff+vest, emission)
- ✅ Real-time unlock calculations
- ✅ Emergency pause/unpause
- ✅ View functions for frontend integration

### Swap Contract (AMM)
- ✅ CATL/SUI liquidity pool
- ✅ CATL/USDT liquidity pool
- ✅ CATL/USDC liquidity pool
- ✅ 0.3% swap fee
- ✅ Add/Remove liquidity
- ✅ Slippage protection
- ✅ Emergency pause

## Project Structure

```
catalyst_contracts/
├── sources/
│   ├── catalyst_token.move
│   ├── catalyst_vesting.move
│   └── catalyst_swap.move
├── Move.toml
├── deployment/
│   ├── deploy.sh
│   └── initialize.sh
├── docs/
│   ├── DEPLOYMENT.md
│   ├── VESTING_SCHEDULES.md
│   └── USAGE.md
└── README.md
```

## Quick Start

### Prerequisites
- Sui CLI installed ([Installation Guide](https://docs.sui.io/build/install))
- Sui wallet with sufficient SUI for gas
- Node.js (for deployment scripts)

### Deployment

```bash
cd catalyst_contracts

# Build contracts
sui move build

# Test contracts
sui move test

# Deploy to testnet
./deployment/deploy.sh testnet

# Deploy to mainnet
./deployment/deploy.sh mainnet
```

## Security Features

1. **Admin Controls**: Separate admin capabilities for each contract
2. **Emergency Pause**: All contracts can be paused in case of issues
3. **Slippage Protection**: Swap contract includes minimum output checks
4. **Treasury Management**: All vested tokens automatically go to treasury
5. **Locked Liquidity**: Minimum liquidity locked forever in pools

## Integration

See [USAGE.md](docs/USAGE.md) for detailed integration examples.

## Vesting Timeline

See [VESTING_SCHEDULES.md](docs/VESTING_SCHEDULES.md) for detailed vesting timeline and calculations.

## Deployment Guide

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for step-by-step deployment instructions.

## Support

For issues or questions, please open an issue in the repository.

## License

MIT License
