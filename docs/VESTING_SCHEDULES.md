# Vesting Schedules

## Overview

Catalyst token has 6 different vesting schedules totaling 100M CATL tokens. All vested tokens are automatically released to the treasury address for controlled disbursement.

## Allocation Details

### 1. Presale (12M CATL - 12%)

- **Total**: 12,000,000 CATL
- **Schedule**: 6-month linear vest
- **Cliff**: None
- **Start**: Immediately on initialization
- **Monthly Unlock**: 2,000,000 CATL

**Timeline:**
```
Month 0:  0M CATL (0%)
Month 1:  2M CATL (16.67%)
Month 2:  4M CATL (33.33%)
Month 3:  6M CATL (50%)
Month 4:  8M CATL (66.67%)
Month 5:  10M CATL (83.33%)
Month 6:  12M CATL (100%)
```

---

### 2. Ecosystem Incentives (30M CATL - 30%)

- **Total**: 30,000,000 CATL
- **Schedule**: 48-month linear vest
- **Cliff**: None
- **Start**: Immediately on initialization
- **Monthly Unlock**: 625,000 CATL

**Timeline:**
```
Month 0:   0M CATL (0%)
Month 6:   3.75M CATL (12.5%)
Month 12:  7.5M CATL (25%)
Month 18:  11.25M CATL (37.5%)
Month 24:  15M CATL (50%)
Month 30:  18.75M CATL (62.5%)
Month 36:  22.5M CATL (75%)
Month 42:  26.25M CATL (87.5%)
Month 48:  30M CATL (100%)
```

---

### 3. Staking Rewards (20M CATL - 20%)

- **Total**: 20,000,000 CATL
- **Schedule**: 48-month emission-based
- **Cliff**: None
- **Start**: Immediately on initialization
- **Monthly Unlock**: ~416,667 CATL

**Timeline:**
```
Month 0:   0M CATL (0%)
Month 6:   2.5M CATL (12.5%)
Month 12:  5M CATL (25%)
Month 18:  7.5M CATL (37.5%)
Month 24:  10M CATL (50%)
Month 30:  12.5M CATL (62.5%)
Month 36:  15M CATL (75%)
Month 42:  17.5M CATL (87.5%)
Month 48:  20M CATL (100%)
```

---

### 4. Team (15M CATL - 15%)

- **Total**: 15,000,000 CATL
- **Schedule**: 12-month cliff + 24-month vest
- **Cliff**: 12 months (no tokens released)
- **Vesting Start**: Month 12
- **Vesting End**: Month 36
- **Monthly Unlock** (after cliff): 625,000 CATL

**Timeline:**
```
Month 0-11: 0M CATL (0%) - CLIFF PERIOD
Month 12:   0M CATL (0%) - Vesting starts
Month 18:   3.75M CATL (25%)
Month 24:   7.5M CATL (50%)
Month 30:   11.25M CATL (75%)
Month 36:   15M CATL (100%)
```

---

### 5. Treasury/DAO (15M CATL - 15%)

- **Total**: 15,000,000 CATL
- **Schedule**: 48-month structured release
- **Cliff**: None
- **Start**: Immediately on initialization
- **Monthly Unlock**: 312,500 CATL

**Timeline:**
```
Month 0:   0M CATL (0%)
Month 6:   1.875M CATL (12.5%)
Month 12:  3.75M CATL (25%)
Month 18:  5.625M CATL (37.5%)
Month 24:  7.5M CATL (50%)
Month 30:  9.375M CATL (62.5%)
Month 36:  11.25M CATL (75%)
Month 42:  13.125M CATL (87.5%)
Month 48:  15M CATL (100%)
```

---

### 6. Strategic Partners (10M CATL - 10%)

- **Total**: 10,000,000 CATL
- **Schedule**: 6-month cliff + 12-month vest
- **Cliff**: 6 months (no tokens released)
- **Vesting Start**: Month 6
- **Vesting End**: Month 18
- **Monthly Unlock** (after cliff): ~833,333 CATL

**Timeline:**
```
Month 0-5:  0M CATL (0%) - CLIFF PERIOD
Month 6:    0M CATL (0%) - Vesting starts
Month 9:    2.5M CATL (25%)
Month 12:   5M CATL (50%)
Month 15:   7.5M CATL (75%)
Month 18:   10M CATL (100%)
```

---

## Combined Release Schedule

Total tokens released over time:

```
Month 0:   0M CATL
Month 1:   2M CATL (Presale only)
Month 3:   6M CATL
Month 6:   13.125M CATL (Strategic cliff ends)
Month 12:  22.5M CATL (Team cliff ends)
Month 18:  35.625M CATL (Strategic complete)
Month 24:  47.5M CATL
Month 36:  73.5M CATL (Team complete)
Month 48:  100M CATL (All complete)
```

## Release Functions

### Manual Release (Single Category)

```bash
# Release presale tokens
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function release_category \
  --args VAULT_ID 0 CLOCK_ID \
  --gas-budget 50000000

# Categories:
# 0 = Presale
# 1 = Ecosystem
# 2 = Staking Rewards
# 3 = Team
# 4 = Treasury/DAO
# 5 = Strategic Partners
```

### Automated Release (All Categories)

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function release_all \
  --args VAULT_ID CLOCK_ID \
  --gas-budget 100000000
```

## Viewing Vesting Status

### Check Schedule Info

```bash
# Get presale vesting info
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function get_schedule_info \
  --args VAULT_ID 0 CLOCK_ID \
  --gas-budget 10000000

# Returns:
# - total_amount: Total allocated
# - released_amount: Already released
# - unlocked: Currently unlocked
# - releasable: Ready to release
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

## Automated Release Setup

For automated releases, set up a cron job or scheduled task:

### Daily Release Script

```bash
#!/bin/bash
# release_daily.sh

PACKAGE_ID="your_package_id"
VAULT_ID="your_vault_id"
CLOCK_ID="0x6"

sui client call \
  --package $PACKAGE_ID \
  --module catalyst_vesting \
  --function release_all \
  --args $VAULT_ID $CLOCK_ID \
  --gas-budget 100000000
```

### Cron Setup (Unix/Linux)

```bash
# Run daily at 12:00 UTC
0 12 * * * /path/to/release_daily.sh
```

## Emergency Controls

### Pause Vesting

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function pause \
  --args VESTING_ADMIN_ID VAULT_ID \
  --gas-budget 10000000
```

### Unpause Vesting

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function unpause \
  --args VESTING_ADMIN_ID VAULT_ID \
  --gas-budget 10000000
```

### Update Treasury Address

```bash
sui client call \
  --package PACKAGE_ID \
  --module catalyst_vesting \
  --function update_treasury \
  --args VESTING_ADMIN_ID VAULT_ID NEW_TREASURY_ADDRESS \
  --gas-budget 10000000
```

## Notes

1. **Time Calculations**: Vesting uses Sui's clock object (0x6) for timestamp
2. **Month Definition**: 1 month = 30 days = 2,592,000,000 milliseconds
3. **Precision**: All calculations use 9 decimals
4. **Treasury**: All released tokens go to treasury address
5. **Gas Costs**: Release operations cost ~0.001-0.01 SUI in gas

## Frontend Integration

For building a vesting dashboard, query these functions:

```javascript
// Get schedule info for all categories
const categories = [0, 1, 2, 3, 4, 5];
for (const cat of categories) {
  const info = await suiClient.call({
    packageId: PACKAGE_ID,
    module: 'catalyst_vesting',
    function: 'get_schedule_info',
    arguments: [VAULT_ID, cat, CLOCK_ID]
  });
  console.log(`Category ${cat}:`, info);
}
```
