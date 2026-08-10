#!/bin/bash

# Catalyst Token Initialization Script
# Usage: ./initialize.sh [testnet|mainnet] [package_id]

set -e

NETWORK=${1:-testnet}
PACKAGE_ID=$2

if [ -z "$PACKAGE_ID" ]; then
    echo "Error: Package ID required"
    echo "Usage: ./initialize.sh [testnet|mainnet] [package_id]"
    exit 1
fi

echo "====================================="
echo "Catalyst Token Initialization"
echo "Network: $NETWORK"
echo "Package: $PACKAGE_ID"
echo "====================================="

# Set active environment
sui client switch --env $NETWORK

ACTIVE_ADDRESS=$(sui client active-address)
echo "Initializing from address: $ACTIVE_ADDRESS"

echo ""
echo "Step 1: Collect object IDs from deployment output"
echo "(AdminCap, TokenConfig and SwapAdmin/VestingAdmin/VestingVault are"
echo " emitted when the package was published/initialized on-chain.)"
read -p "Enter CATL AdminCap Object ID: " ADMIN_CAP
read -p "Enter TokenConfig Object ID: " TOKEN_CONFIG

if [ -z "$ADMIN_CAP" ] || [ -z "$TOKEN_CONFIG" ]; then
    echo "Error: AdminCap and TokenConfig Object IDs are required"
    exit 1
fi

# Mint 100M tokens (with 9 decimals = 100_000_000_000_000_000)
# mint() requires the CATL AdminCap — the TreasuryCap itself never leaves
# the TokenConfig object, so this is the only way to mint.
echo ""
echo "Step 2: Minting 100M CATL tokens..."
sui client call \
    --package $PACKAGE_ID \
    --module catl \
    --function mint \
    --args $ADMIN_CAP $TOKEN_CONFIG 100000000000000000 $ACTIVE_ADDRESS \
    --gas-budget 100000000

echo "Tokens minted successfully!"

echo ""
echo "Step 3: Creating the CATL/SUI swap pool..."
read -p "Enter SwapAdmin Object ID: " SWAP_ADMIN

if [ -z "$SWAP_ADMIN" ]; then
    echo "Error: SwapAdmin Object ID required"
    exit 1
fi

# init_pool() requires SwapAdmin so only the deployer can create the
# canonical pool object (prevents anyone else from spoofing a look-alike pool).
sui client call \
    --package $PACKAGE_ID \
    --module catalyst_swap \
    --function init_pool \
    --args $SWAP_ADMIN \
    --gas-budget 50000000

echo ""
echo "Step 4: Initializing the vesting vault..."
echo "The vault expects exactly 90,000,000 CATL (90000000000000000 base units)."
read -p "Enter VestingAdmin Object ID: " VESTING_ADMIN
read -p "Enter VestingVault Object ID: " VESTING_VAULT
read -p "Enter CATL Coin Object ID holding exactly 90,000,000 CATL: " CATL_COIN
read -p "Enter team wallet address: " TEAM_ADDRESS
read -p "Enter Clock Object ID (default 0x6): " CLOCK

CLOCK=${CLOCK:-0x6}

if [ -z "$VESTING_ADMIN" ] || [ -z "$VESTING_VAULT" ] || [ -z "$CATL_COIN" ] || [ -z "$TEAM_ADDRESS" ]; then
    echo "Error: VestingAdmin, VestingVault, CATL_COIN and team address are all required"
    exit 1
fi

sui client call \
    --package $PACKAGE_ID \
    --module catalyst_vesting \
    --function initialize \
    --args $VESTING_ADMIN $VESTING_VAULT $CATL_COIN $TEAM_ADDRESS $CLOCK \
    --gas-budget 100000000

echo ""
echo "====================================="
echo "Initialization Complete!"
echo "====================================="
echo ""
echo "Contract Objects:"
echo "- Package ID: $PACKAGE_ID"
echo "- Token Config: $TOKEN_CONFIG"
echo "- Admin Cap: $ADMIN_CAP"
echo "- Swap Admin: $SWAP_ADMIN"
echo "- Vesting Admin: $VESTING_ADMIN"
echo "- Vesting Vault: $VESTING_VAULT"
echo ""
echo "Next steps:"
echo "1. Save these object IDs securely"
echo "2. Add initial liquidity to the CATL/SUI swap pool"
echo "3. Test vesting releases"
echo "4. Update frontend with contract addresses"
echo "====================================="
