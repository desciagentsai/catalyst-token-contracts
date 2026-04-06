// ============================================================
// CATL CONTRACT WIRING — @mysten/dapp-kit (SUI TESTNET)
// Paste these constants into a shared config file, e.g.
//   frontend/src/config/contracts.ts
// ============================================================

// ── After deploying the fixed contracts, fill these in: ──────
export const PACKAGE_ID   = "0xYOUR_PACKAGE_ID";        // from `sui client publish`
export const POOL_ID      = "0xYOUR_POOL_OBJECT_ID";    // emitted by init_pool()
export const TOKEN_CONFIG = "0xYOUR_TOKEN_CONFIG_ID";   // emitted by catl::init
export const VAULT_ID     = "0xYOUR_VESTING_VAULT_ID";  // emitted by vesting::init
export const CLOCK_ID     = "0x6";                      // Sui system clock (always 0x6)

// ── Coin type string ─────────────────────────────────────────
export const CATL_TYPE    = `${PACKAGE_ID}::catl::CATL`;


// ============================================================
// LaunchDetailPage.jsx — swap SUI → CATL
// ============================================================
import { useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { PACKAGE_ID, POOL_ID } from "../config/contracts";

function useBuyCATL() {
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();

  // suiAmount: bigint, e.g. 1_000_000_000n = 1 SUI
  // minCatlOut: bigint slippage floor (set to 0n to skip for testing)
  return (suiAmount: bigint, minCatlOut: bigint) => {
    const tx = new Transaction();

    // Split the exact SUI amount from the gas coin
    const [suiCoin] = tx.splitCoins(tx.gas, [suiAmount]);

    tx.moveCall({
      target: `${PACKAGE_ID}::catalyst_swap::swap_sui_to_catl`,
      arguments: [
        tx.object(POOL_ID),   // &mut LiquidityPool_CATL_SUI
        suiCoin,              // Coin<SUI>
        tx.pure.u64(minCatlOut),
      ],
    });

    signAndExecute({ transaction: tx });
  };
}


// ============================================================
// LaunchDetailPage.jsx — swap CATL → SUI
// ============================================================
import { useSuiClient } from "@mysten/dapp-kit";
import { CATL_TYPE } from "../config/contracts";

function useSellCATL() {
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();
  const client = useSuiClient();

  // catlAmount: bigint, e.g. 1_000_000_000n = 1 CATL
  return async (catlAmount: bigint, minSuiOut: bigint, walletAddress: string) => {
    // 1. Fetch a CATL coin object the user owns
    const { data: coins } = await client.getCoins({
      owner: walletAddress,
      coinType: CATL_TYPE,
    });
    if (!coins.length) throw new Error("No CATL coins found");

    const tx = new Transaction();

    // 2. Merge all CATL coins, then split the exact amount needed
    const [primaryCoin, ...restCoins] = coins.map((c) => tx.object(c.coinObjectId));
    if (restCoins.length > 0) tx.mergeCoins(primaryCoin, restCoins);
    const [catlCoin] = tx.splitCoins(primaryCoin, [catlAmount]);

    tx.moveCall({
      target: `${PACKAGE_ID}::catalyst_swap::swap_catl_to_sui`,
      arguments: [
        tx.object(POOL_ID),
        catlCoin,
        tx.pure.u64(minSuiOut),
      ],
    });

    signAndExecute({ transaction: tx });
  };
}


// ============================================================
// PortfolioPage.jsx — add liquidity
// ============================================================
function useAddLiquidity() {
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();
  const client = useSuiClient();

  return async (
    catlAmount: bigint,
    suiAmount: bigint,
    minLpAmount: bigint,
    walletAddress: string
  ) => {
    const { data: coins } = await client.getCoins({
      owner: walletAddress,
      coinType: CATL_TYPE,
    });

    const tx = new Transaction();

    const [primaryCoin, ...restCoins] = coins.map((c) => tx.object(c.coinObjectId));
    if (restCoins.length > 0) tx.mergeCoins(primaryCoin, restCoins);
    const [catlCoin] = tx.splitCoins(primaryCoin, [catlAmount]);
    const [suiCoin]  = tx.splitCoins(tx.gas, [suiAmount]);

    tx.moveCall({
      target: `${PACKAGE_ID}::catalyst_swap::add_liquidity`,
      arguments: [
        tx.object(POOL_ID),
        catlCoin,
        suiCoin,
        tx.pure.u64(minLpAmount),
      ],
    });

    signAndExecute({ transaction: tx });
  };
}


// ============================================================
// PortfolioPage.jsx — remove liquidity
// ============================================================
function useRemoveLiquidity() {
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();
  const client = useSuiClient();

  return async (
    lpCoinObjectId: string,   // the LPCoin object ID from the user's wallet
    minCatlOut: bigint,
    minSuiOut: bigint
  ) => {
    const tx = new Transaction();

    tx.moveCall({
      target: `${PACKAGE_ID}::catalyst_swap::remove_liquidity`,
      arguments: [
        tx.object(POOL_ID),
        tx.object(lpCoinObjectId),
        tx.pure.u64(minCatlOut),
        tx.pure.u64(minSuiOut),
      ],
    });

    signAndExecute({ transaction: tx });
  };
}


// ============================================================
// Price preview (devInspect — no wallet, no gas)
// Use this in LaunchDetailPage to show estimated output before swap
// ============================================================
import { useSuiClient } from "@mysten/dapp-kit";

async function previewSwap(
  client: ReturnType<typeof useSuiClient>,
  amountIn: bigint,
  direction: "sui_to_catl" | "catl_to_sui"
): Promise<bigint> {
  // 1. Fetch current reserves from the shared pool object
  const poolObj = await client.getObject({
    id: POOL_ID,
    options: { showContent: true },
  });
  const fields = (poolObj.data?.content as any)?.fields;
  const catlReserve = BigInt(fields?.catl_reserve ?? 0);
  const suiReserve  = BigInt(fields?.sui_reserve  ?? 0);

  const FEE = 30n;
  const DENOM = 10000n;

  const [reserveIn, reserveOut] =
    direction === "sui_to_catl"
      ? [suiReserve, catlReserve]
      : [catlReserve, suiReserve];

  const amountInWithFee = amountIn * (DENOM - FEE);
  const amountOut = (amountInWithFee * reserveOut) / (reserveIn * DENOM + amountInWithFee);
  return amountOut;
}


// ============================================================
// POST-DEPLOY CHECKLIST
// ============================================================
// 1. sui client publish --network testnet
//    → copy PACKAGE_ID from output
//
// 2. Call init_pool() once (no args):
//    sui client call \
//      --package $PACKAGE_ID \
//      --module catalyst_swap \
//      --function init_pool \
//      --network testnet
//    → copy the new shared object ID → POOL_ID
//
// 3. Fill POOL_ID, PACKAGE_ID, TOKEN_CONFIG, VAULT_ID into contracts.ts
//
// 4. Wire hooks above into LaunchDetailPage and PortfolioPage
// ============================================================
