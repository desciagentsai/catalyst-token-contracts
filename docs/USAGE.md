"# Contract Usage Guide

## Table of Contents

1. [Token Operations](#token-operations)
2. [Vesting Operations](#vesting-operations)
3. [Swap Operations](#swap-operations)
4. [Admin Operations](#admin-operations)
5. [Integration Examples](#integration-examples)

---

## Token Operations

### View Token Information

```bash
# Get total supply
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function total_supply \
  --args TOKEN_CONFIG_ID \
  --gas-budget 10000000

# Get circulating supply
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function circulating_supply \
  --args TOKEN_CONFIG_ID \
  --gas-budget 10000000

# Check if paused
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function is_paused \
  --args TOKEN_CONFIG_ID \
  --gas-budget 10000000
```

### Transfer CATL Tokens

```bash
# Standard transfer
sui client transfer \
  --to RECIPIENT_ADDRESS \
  --object-id CATL_COIN_OBJECT_ID \
  --gas-budget 10000000
```

### Burn Tokens

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function burn \
  --args TREASURY_CAP_ID TOKEN_CONFIG_ID CATL_COIN_ID \
  --gas-budget 10000000
```

---

## Vesting Operations

### Check Vesting Status

```bash
# Get vesting info for a category
# Categories: 0=Presale, 1=Ecosystem, 2=Staking, 3=Team, 4=Treasury, 5=Strategic
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function get_schedule_info \
  --args VAULT_ID CATEGORY_NUMBER 0x6 \
  --gas-budget 10000000
```

### Release Vested Tokens

```bash
# Release single category
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function release_category \
  --args VAULT_ID CATEGORY_NUMBER 0x6 \
  --gas-budget 50000000

# Release all categories at once
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function release_all \
  --args VAULT_ID 0x6 \
  --gas-budget 100000000
```

### Check Locked Balance

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function get_locked_balance \
  --args VAULT_ID \
  --gas-budget 10000000
```

---

## Swap Operations

### Add Liquidity

#### CATL/SUI Pool

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function add_liquidity_catl_sui \
  --args POOL_ID CATL_COIN_ID SUI_COIN_ID MIN_LP_AMOUNT \
  --gas-budget 100000000
```

#### CATL/USDT Pool

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function add_liquidity_catl_stable \
  --type-args USDT_TYPE \
  --args POOL_ID CATL_COIN_ID USDT_COIN_ID MIN_LP_AMOUNT \
  --gas-budget 100000000
```

### Swap Tokens

#### Swap CATL to SUI

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function swap_catl_to_sui \
  --args POOL_ID CATL_COIN_ID MIN_SUI_OUT \
  --gas-budget 50000000
```

#### Swap SUI to CATL

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function swap_sui_to_catl \
  --args POOL_ID SUI_COIN_ID MIN_CATL_OUT \
  --gas-budget 50000000
```

#### Swap CATL to USDT

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function swap_catl_to_stable \
  --type-args USDT_TYPE \
  --args POOL_ID CATL_COIN_ID MIN_USDT_OUT \
  --gas-budget 50000000
```

#### Swap USDT to CATL

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function swap_stable_to_catl \
  --type-args USDT_TYPE \
  --args POOL_ID USDT_COIN_ID MIN_CATL_OUT \
  --gas-budget 50000000
```

### Remove Liquidity

```bash
# CATL/SUI Pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function remove_liquidity_catl_sui \
  --args POOL_ID LP_COIN_ID MIN_CATL_OUT MIN_SUI_OUT \
  --gas-budget 100000000

# CATL/USDT Pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function remove_liquidity_catl_stable \
  --type-args USDT_TYPE \
  --args POOL_ID LP_COIN_ID MIN_CATL_OUT MIN_USDT_OUT \
  --gas-budget 100000000
```

### View Pool Reserves

```bash
# CATL/SUI Pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function get_catl_sui_reserves \
  --args POOL_ID \
  --gas-budget 10000000

# CATL/STABLE Pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function get_catl_stable_reserves \
  --type-args USDT_TYPE \
  --args POOL_ID \
  --gas-budget 10000000
```

### Calculate Swap Output

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function calculate_swap_output \
  --args AMOUNT_IN RESERVE_IN RESERVE_OUT \
  --gas-budget 10000000
```

---

## Admin Operations

### Token Admin

```bash
# Pause token operations
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function pause \
  --args ADMIN_CAP_ID TOKEN_CONFIG_ID \
  --gas-budget 10000000

# Unpause token operations
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function unpause \
  --args ADMIN_CAP_ID TOKEN_CONFIG_ID \
  --gas-budget 10000000

# Update treasury address
sui client call \
  --package PACKAGE_ID \
  --module catalyst_token \
  --function update_treasury \
  --args ADMIN_CAP_ID TOKEN_CONFIG_ID NEW_ADDRESS \
  --gas-budget 10000000
```

### Vesting Admin

```bash
# Pause vesting
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function pause \
  --args VESTING_ADMIN_ID VAULT_ID \
  --gas-budget 10000000

# Unpause vesting
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function unpause \
  --args VESTING_ADMIN_ID VAULT_ID \
  --gas-budget 10000000

# Update treasury
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function update_treasury \
  --args VESTING_ADMIN_ID VAULT_ID NEW_ADDRESS \
  --gas-budget 10000000
```

### Swap Admin

```bash
# Pause CATL/SUI pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function pause_catl_sui_pool \
  --args SWAP_ADMIN_ID POOL_ID \
  --gas-budget 10000000

# Pause CATL/STABLE pool
sui client call \
  --package PACKAGE_ID \
  --module catalyst_swap \
  --function pause_catl_stable_pool \
  --type-args USDT_TYPE \
  --args SWAP_ADMIN_ID POOL_ID \
  --gas-budget 10000000
```

---

## Integration Examples

### JavaScript/TypeScript (Sui SDK)

```typescript
import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';

const client = new SuiClient({ url: getFullnodeUrl('mainnet') });

// Example: Swap CATL to SUI
async function swapCatlToSui(
  packageId: string,
  poolId: string,
  catlCoinId: string,
  minSuiOut: number,
  signer: any
) {
  const tx = new TransactionBlock();
  
  tx.moveCall({
    target: `${packageId}::catalyst_swap::swap_catl_to_sui`,
    arguments: [
      tx.object(poolId),
      tx.object(catlCoinId),
      tx.pure(minSuiOut)
    ]
  });
  
  const result = await client.signAndExecuteTransactionBlock({
    signer,
    transactionBlock: tx,
    options: {
      showEffects: true,
      showObjectChanges: true
    }
  });
  
  return result;
}

// Example: Check vesting status
async function getVestingInfo(
  packageId: string,
  vaultId: string,
  category: number
) {
  const result = await client.devInspectTransactionBlock({
    transactionBlock: (() => {
      const tx = new TransactionBlock();
      tx.moveCall({
        target: `${packageId}::catalyst_vesting::get_schedule_info`,
        arguments: [
          tx.object(vaultId),
          tx.pure(category),
          tx.object('0x6') // Clock
        ]
      });
      return tx;
    })(),
    sender: '0x0000000000000000000000000000000000000000000000000000000000000000'
  });
  
  return result;
}

// Example: Add liquidity
async function addLiquidity(
  packageId: string,
  poolId: string,
  catlAmount: number,
  suiAmount: number,
  minLpAmount: number,
  signer: any
) {
  const tx = new TransactionBlock();
  
  // Split coins
  const [catlCoin] = tx.splitCoins(tx.object('CATL_COIN_OBJECT'), [
    tx.pure(catlAmount)
  ]);
  const [suiCoin] = tx.splitCoins(tx.gas, [tx.pure(suiAmount)]);
  
  tx.moveCall({
    target: `${packageId}::catalyst_swap::add_liquidity_catl_sui`,
    arguments: [
      tx.object(poolId),
      catlCoin,
      suiCoin,
      tx.pure(minLpAmount)
    ]
  });
  
  const result = await client.signAndExecuteTransactionBlock({
    signer,
    transactionBlock: tx
  });
  
  return result;
}
```

### Python (pysui)

```python
from pysui import SuiConfig, SyncClient
from pysui.sui.sui_txn import SyncTransaction

# Initialize client
config = SuiConfig.default_config()
client = SyncClient(config)

# Example: Release vested tokens
def release_vesting(package_id, vault_id, category):
    txn = SyncTransaction(client)
    
    txn.move_call(
        target=f\"{package_id}::catalyst_vesting::release_category\",
        arguments=[
            vault_id,
            category,
            \"0x6\"  # Clock object
        ]
    )
    
    result = txn.execute(gas_budget=50_000_000)
    return result

# Example: Get pool reserves
def get_pool_reserves(package_id, pool_id):
    txn = SyncTransaction(client)
    
    result = txn.inspect_transaction_block(
        target=f\"{package_id}::catalyst_swap::get_catl_sui_reserves\",
        arguments=[pool_id]
    )
    
    return result
```

### React Frontend Example

```jsx
import { useWalletKit } from '@mysten/wallet-kit';
import { TransactionBlock } from '@mysten/sui.js/transactions';

function SwapComponent() {
  const { signAndExecuteTransactionBlock } = useWalletKit();
  
  const handleSwap = async (catlAmount, minSuiOut) => {
    const tx = new TransactionBlock();
    
    tx.moveCall({
      target: `${PACKAGE_ID}::catalyst_swap::swap_catl_to_sui`,
      arguments: [
        tx.object(POOL_ID),
        tx.object(catlCoinId),
        tx.pure(minSuiOut)
      ]
    });
    
    try {
      const result = await signAndExecuteTransactionBlock({
        transactionBlock: tx,
        options: {
          showEffects: true
        }
      });
      
      console.log('Swap successful:', result);
    } catch (error) {
      console.error('Swap failed:', error);
    }
  };
  
  return (
    <button onClick={() => handleSwap(1000000000, 500000)}>
      Swap CATL to SUI
    </button>
  );
}
```

---

## Common Patterns

### Slippage Protection

Always set a minimum output amount to protect against slippage:

```javascript
// Calculate with 1% slippage tolerance
const expectedOutput = calculateOutput(amountIn, reserveIn, reserveOut);
const minOutput = expectedOutput * 0.99; // 1% slippage
```

### Gas Estimation

Typical gas costs:
- Simple view calls: 0.0001 SUI
- Token transfers: 0.001 SUI
- Swaps: 0.01-0.05 SUI
- Add/Remove liquidity: 0.05-0.1 SUI
- Vesting releases: 0.01-0.05 SUI

### Error Handling

```javascript
try {
  const result = await executeTransaction();
} catch (error) {
  if (error.message.includes('E_SLIPPAGE_EXCEEDED')) {
    // Handle slippage error
  } else if (error.message.includes('E_INSUFFICIENT_LIQUIDITY')) {
    // Handle liquidity error
  }
}
```

---

## Useful Resources

- [Sui Documentation](https://docs.sui.io)
- [Sui TypeScript SDK](https://sdk.mystenlabs.com/typescript)
- [Sui Explorer](https://suiexplorer.com)
- [Catalyst Token Website](#)

## Support

For questions or issues:
- GitHub Issues
- Discord Community
- Twitter: @CatalystToken
"
