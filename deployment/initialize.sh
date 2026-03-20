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
echo "Step 1: Getting contract objects..."

# Get token config object
TOKEN_CONFIG=$(sui client object --id $PACKAGE_ID --json | jq -r '.data.objectId')

echo "Token Config Object: $TOKEN_CONFIG"

echo ""
echo "Step 2: Minting 100M CATL tokens..."
echo "Note: You'll need the TreasuryCap object ID from deployment"
read -p "Enter TreasuryCap Object ID: " TREASURY_CAP

if [ -z "$TREASURY_CAP" ]; then
    echo "Error: TreasuryCap Object ID required"
    exit 1
fi

# Mint 100M tokens (with 9 decimals = 100_000_000_000_000_000)
echo "Minting tokens for vesting contract..."
sui client call 
    --package $PACKAGE_ID 
    --module CATL
    --function mint 
    --args $TREASURY_CAP $TOKEN_CONFIG 100000000000000000 $ACTIVE_ADDRESS 
    --gas-budget 100000000

if [ $? -ne 0 ]; then
    echo "Minting failed!"
    exit 1
fi

echo "Tokens minted successfully!"

echo ""
echo "Step 3: Creating swap pools..."

# Create CATL/SUI pool
echo "Creating CATL/SUI liquidity pool..."
read -p "Enter SwapAdmin Object ID: " SWAP_ADMIN

sui client call 
    --package $PACKAGE_ID 
    --module catalyst_swap 
    --function create_catl_sui_pool 
    --args $SWAP_ADMIN 
    --gas-budget 50000000

echo ""
echo "Step 4: Initializing vesting schedules..."
read -p "Enter VestingAdmin Object ID: " VESTING_ADMIN
read -p "Enter VestingVault Object ID: " VESTING_VAULT
read -p "Enter minted CATL Coin Object ID: " CATL_COIN
read -p "Enter Clock Object ID (0x6): " CLOCK

CLOCK=${CLOCK:-0x6}

sui client call 
    --package $PACKAGE_ID 
    --module catalyst_vesting 
    --function initialize_schedules 
    --args $VESTING_ADMIN $VESTING_VAULT $CATL_COIN $CLOCK 
    --gas-budget 100000000

if [ $? -ne 0 ]; then
    echo "Vesting initialization failed!"
    exit 1
fi

echo ""
echo "====================================="
echo "Initialization Complete!"
echo "====================================="
echo ""
echo "Contract Objects:"
echo "- Package ID: $PACKAGE_ID"
echo "- Token Config: $TOKEN_CONFIG"
echo "- Treasury Cap: $TREASURY_CAP"
echo "- Swap Admin: $SWAP_ADMIN"
echo "- Vesting Admin: $VESTING_ADMIN"
echo "- Vesting Vault: $VESTING_VAULT"
echo ""
echo "Next steps:"
echo "1. Save these object IDs securely"
echo "2. Add initial liquidity to swap pools"
echo "3. Test vesting releases"
echo "4. Update frontend with contract addresses"
echo "====================================="
