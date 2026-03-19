#!/bin/bash

# Catalyst Token Deployment Script
# Usage: ./deploy.sh [testnet|mainnet]

set -e

NETWORK=${1:-testnet}

echo "====================================="
echo "Catalyst Token Deployment"
echo "Network: $NETWORK"
echo "====================================="

# Check if Sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo "Error: Sui CLI not found. Please install it first."
    echo "Visit: https://docs.sui.io/build/install"
    exit 1
fi

# Set the active environment
echo "Setting active environment to $NETWORK..."
sui client switch --env $NETWORK

# Get active address
ACTIVE_ADDRESS=$(sui client active-address)
echo "Deploying from address: $ACTIVE_ADDRESS"

# Check balance
echo "Checking SUI balance..."
sui client gas

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Build the package
echo "Building Move package..."
sui move build

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"

# Deploy the package
echo "Deploying package to $NETWORK..."
DEPLOY_OUTPUT=$(sui client publish --gas-budget 500000000 --json)

if [ $? -ne 0 ]; then
    echo "Deployment failed!"
    exit 1
fi

# Parse deployment output
PACKAGE_ID=$(echo $DEPLOY_OUTPUT | jq -r '.objectChanges[] | select(.type=="published") | .packageId')

echo "====================================="
echo "Deployment Successful!"
echo "====================================="
echo "Package ID: $PACKAGE_ID"
echo ""
echo "Save this Package ID for contract initialization!"
echo ""

# Save deployment info
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DEPLOYMENT_FILE="deployment_${NETWORK}_${DATE}.json"

echo $DEPLOY_OUTPUT | jq '.' > $DEPLOYMENT_FILE

echo "Deployment details saved to: $DEPLOYMENT_FILE"
echo ""
echo "Next steps:"
echo "1. Update Move.toml with Package ID: $PACKAGE_ID"
echo "2. Run initialization script: ./initialize.sh $NETWORK $PACKAGE_ID"
echo "====================================="
