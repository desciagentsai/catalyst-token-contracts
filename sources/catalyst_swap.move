/// Catalyst Swap Contract — FIXED for frontend integration
/// ✅ All user-facing functions are `public entry` (callable from PTBs / dapp-kit)
/// ✅ `init_pool` is a `public entry fun` — requires SwapAdmin so only the
///    deployer can create the canonical pool (prevents pool spoofing)
/// ✅ Pool is a shared object — single object ID referenceable from LaunchDetailPage / PortfolioPage
/// ✅ Admin-only functions (init_pool, pause/unpause) require SwapAdmin cap
#[allow(unused_const)]
module catalyst::catalyst_swap {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance, Supply};
    use sui::sui::SUI;
    use catalyst::catl::CATL;

    /// LP Token for liquidity providers
    public struct LP_TOKEN has drop {}

    // ======== Error Codes ========
    const E_ZERO_AMOUNT: u64 = 1;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 2;
    const E_SLIPPAGE_EXCEEDED: u64 = 3;
    const E_PAUSED: u64 = 4;

    /// Minimum liquidity locked forever (Uniswap-style)
    const MINIMUM_LIQUIDITY: u64 = 1000;

    /// Fee: 0.3% = 30 bps
    const SWAP_FEE_BPS: u64 = 30;
    const BPS_DENOMINATOR: u64 = 10000;

    // ======== Objects ========

    /// Admin capability — held by deployer, required for pause/unpause only
    public struct SwapAdmin has key, store {
        id: UID
    }

    /// ✅ SHARED POOL — this is the object ID you pass into LaunchDetailPage / PortfolioPage
    /// Created once via `init_pool`, then shared. Everyone references its ID.
    public struct LiquidityPool_CATL_SUI has key {
        id: UID,
        catl_reserve: Balance<CATL>,
        sui_reserve: Balance<SUI>,
        lp_supply: Supply<LP_TOKEN>,
        locked_lp: Balance<LP_TOKEN>,
        paused: bool
    }

    /// LP token object held by liquidity providers
    public struct LPCoin has key, store {
        id: UID,
        balance: Balance<LP_TOKEN>
    }

    // ======== Module Init ========

    fun init(ctx: &mut TxContext) {
        let admin = SwapAdmin {
            id: object::new(ctx)
        };
        transfer::transfer(admin, ctx.sender());
    }

    // ======== Pool Creation ========

    /// ✅ PUBLIC ENTRY — call this once after deployment to create the shared pool.
    /// Requires SwapAdmin so only the deployer can create the canonical pool —
    /// this prevents anyone else from spoofing a look-alike LiquidityPool_CATL_SUI
    /// object and tricking a frontend/user into trading against a fake pool.
    /// Returns a shared LiquidityPool_CATL_SUI object.
    /// Capture the emitted object ID → use it as POOL_ID in your frontend env vars.
    public entry fun init_pool(_admin: &SwapAdmin, ctx: &mut TxContext) {
        let pool = LiquidityPool_CATL_SUI {
            id: object::new(ctx),
            catl_reserve: balance::zero(),
            sui_reserve: balance::zero(),
            lp_supply: balance::create_supply(LP_TOKEN {}),
            locked_lp: balance::zero(),
            paused: false
        };
        // ✅ Shared — accessible by all transactions via object ID
        transfer::share_object(pool);
    }

    // ======== Liquidity Functions ========

    /// ✅ PUBLIC ENTRY — add liquidity to the CATL/SUI pool.
    /// Called from PortfolioPage when a user provides liquidity.
    /// Returns LP tokens to the caller.
    public entry fun add_liquidity(
        pool: &mut LiquidityPool_CATL_SUI,
        mut catl_coin: Coin<CATL>,
        mut sui_coin: Coin<SUI>,
        min_lp_amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let catl_amount = coin::value(&catl_coin);
        let sui_amount = coin::value(&sui_coin);
        assert!(catl_amount > 0 && sui_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let sui_reserve = balance::value(&pool.sui_reserve);
        let lp_supply = balance::supply_value(&pool.lp_supply);

        let sender = ctx.sender();

        let lp_amount = if (lp_supply == 0) {
            // Initial deposit — geometric mean minus locked minimum.
            // Both full coins are used to seed the reserves at whatever ratio
            // the caller chose, since there's no existing price to match yet.
            let initial_lp = sqrt(catl_amount, sui_amount);
            assert!(initial_lp > MINIMUM_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
            let minimum_lp_balance = balance::increase_supply(&mut pool.lp_supply, MINIMUM_LIQUIDITY);
            balance::join(&mut pool.locked_lp, minimum_lp_balance);

            balance::join(&mut pool.catl_reserve, coin::into_balance(catl_coin));
            balance::join(&mut pool.sui_reserve, coin::into_balance(sui_coin));

            initial_lp - MINIMUM_LIQUIDITY
        } else {
            // Proportional deposit — only the amount matching the pool's current
            // ratio is pulled in; any excess on one side is refunded to the
            // caller instead of being silently absorbed into the reserves.
            let catl_lp = mul_div(catl_amount, lp_supply, catl_reserve);
            let sui_lp = mul_div(sui_amount, lp_supply, sui_reserve);

            let (lp_amount, catl_used, sui_used) = if (catl_lp <= sui_lp) {
                (catl_lp, catl_amount, mul_div(catl_amount, sui_reserve, catl_reserve))
            } else {
                (sui_lp, mul_div(sui_amount, catl_reserve, sui_reserve), sui_amount)
            };
            assert!(lp_amount > 0, E_INSUFFICIENT_LIQUIDITY);

            if (catl_used < catl_amount) {
                transfer::public_transfer(coin::split(&mut catl_coin, catl_amount - catl_used, ctx), sender);
            };
            if (sui_used < sui_amount) {
                transfer::public_transfer(coin::split(&mut sui_coin, sui_amount - sui_used, ctx), sender);
            };

            balance::join(&mut pool.catl_reserve, coin::into_balance(catl_coin));
            balance::join(&mut pool.sui_reserve, coin::into_balance(sui_coin));

            lp_amount
        };

        assert!(lp_amount >= min_lp_amount, E_SLIPPAGE_EXCEEDED);

        let lp_balance = balance::increase_supply(&mut pool.lp_supply, lp_amount);
        let lp_coin = LPCoin {
            id: object::new(ctx),
            balance: lp_balance
        };
        transfer::transfer(lp_coin, sender);
    }

    /// ✅ PUBLIC ENTRY — remove liquidity from the CATL/SUI pool.
    /// Called from PortfolioPage when a user withdraws their position.
    public entry fun remove_liquidity(
        pool: &mut LiquidityPool_CATL_SUI,
        lp_coin: LPCoin,
        min_catl_out: u64,
        min_sui_out: u64,
        ctx: &mut TxContext
    ) {
        let LPCoin { id, balance: lp_balance } = lp_coin;
        object::delete(id);

        let lp_amount = balance::value(&lp_balance);
        let catl_reserve = balance::value(&pool.catl_reserve);
        let sui_reserve = balance::value(&pool.sui_reserve);
        let lp_supply = balance::supply_value(&pool.lp_supply);

        let catl_out = mul_div(lp_amount, catl_reserve, lp_supply);
        let sui_out = mul_div(lp_amount, sui_reserve, lp_supply);

        assert!(catl_out >= min_catl_out && sui_out >= min_sui_out, E_SLIPPAGE_EXCEEDED);

        balance::decrease_supply(&mut pool.lp_supply, lp_balance);

        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);
        let sui_balance_out = balance::split(&mut pool.sui_reserve, sui_out);

        let sender = ctx.sender();
        transfer::public_transfer(coin::from_balance(catl_balance_out, ctx), sender);
        transfer::public_transfer(coin::from_balance(sui_balance_out, ctx), sender);
    }

    // ======== Swap Functions ========

    /// ✅ PUBLIC ENTRY — swap SUI → CATL.
    /// Called from LaunchDetailPage when user buys CATL with SUI.
    /// @param pool         — shared LiquidityPool_CATL_SUI object ID
    /// @param sui_in       — Coin<SUI> from user's wallet (split before passing)
    /// @param min_catl_out — slippage floor; abort if output < this value
    public entry fun swap_sui_to_catl(
        pool: &mut LiquidityPool_CATL_SUI,
        sui_in: Coin<SUI>,
        min_catl_out: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let sui_amount = coin::value(&sui_in);
        assert!(sui_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let sui_reserve = balance::value(&pool.sui_reserve);

        // x*y=k with 0.3% fee applied to input
        let catl_out = get_amount_out(sui_amount, sui_reserve, catl_reserve);

        assert!(catl_out >= min_catl_out, E_SLIPPAGE_EXCEEDED);
        assert!(catl_out < catl_reserve, E_INSUFFICIENT_LIQUIDITY);

        balance::join(&mut pool.sui_reserve, coin::into_balance(sui_in));
        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);

        transfer::public_transfer(coin::from_balance(catl_balance_out, ctx), ctx.sender());
    }

    /// ✅ PUBLIC ENTRY — swap CATL → SUI.
    /// Called from LaunchDetailPage / PortfolioPage when user sells CATL for SUI.
    /// @param pool        — shared LiquidityPool_CATL_SUI object ID
    /// @param catl_in     — Coin<CATL> from user's wallet (split before passing)
    /// @param min_sui_out — slippage floor; abort if output < this value
    public entry fun swap_catl_to_sui(
        pool: &mut LiquidityPool_CATL_SUI,
        catl_in: Coin<CATL>,
        min_sui_out: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let catl_amount = coin::value(&catl_in);
        assert!(catl_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let sui_reserve = balance::value(&pool.sui_reserve);

        let sui_out = get_amount_out(catl_amount, catl_reserve, sui_reserve);

        assert!(sui_out >= min_sui_out, E_SLIPPAGE_EXCEEDED);
        assert!(sui_out < sui_reserve, E_INSUFFICIENT_LIQUIDITY);

        balance::join(&mut pool.catl_reserve, coin::into_balance(catl_in));
        let sui_balance_out = balance::split(&mut pool.sui_reserve, sui_out);

        transfer::public_transfer(coin::from_balance(sui_balance_out, ctx), ctx.sender());
    }

    // ======== Admin Functions ========

    /// Emergency pause — requires SwapAdmin cap
    public entry fun pause_pool(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_SUI
    ) {
        pool.paused = true;
    }

    /// Resume pool — requires SwapAdmin cap
    public entry fun unpause_pool(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_SUI
    ) {
        pool.paused = false;
    }

    // ======== View Functions (for frontend price preview) ========

    /// Returns (catl_reserve, sui_reserve) — call via sui_client.getObject for UI display
    public fun get_reserves(pool: &LiquidityPool_CATL_SUI): (u64, u64) {
        (
            balance::value(&pool.catl_reserve),
            balance::value(&pool.sui_reserve)
        )
    }

    /// Preview output amount before submitting a swap.
    /// Call off-chain (devInspect) from LaunchDetailPage to show estimated output.
    /// @param amount_in  — raw token amount (with decimals)
    /// @param reserve_in — from get_reserves()
    /// @param reserve_out — from get_reserves()
    public fun calculate_swap_output(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64
    ): u64 {
        get_amount_out(amount_in, reserve_in, reserve_out)
    }

    // ======== Helpers ========

    /// (a * b) / c computed in u128 to avoid u64 overflow on the intermediate
    /// product — reserves and amounts can individually fit u64 while their
    /// product cannot.
    fun mul_div(a: u64, b: u64, c: u64): u64 {
        (((a as u128) * (b as u128)) / (c as u128)) as u64
    }

    /// Constant-product output with the 0.3% fee applied to the input,
    /// computed in u128 to avoid overflow on reserve_in * BPS_DENOMINATOR.
    fun get_amount_out(amount_in: u64, reserve_in: u64, reserve_out: u64): u64 {
        let amount_in_with_fee = (amount_in as u128) * ((BPS_DENOMINATOR - SWAP_FEE_BPS) as u128);
        let numerator = amount_in_with_fee * (reserve_out as u128);
        let denominator = (reserve_in as u128) * (BPS_DENOMINATOR as u128) + amount_in_with_fee;
        (numerator / denominator) as u64
    }

    /// Integer sqrt of x*y, computed in u128 so the product of two large u64
    /// deposit amounts can't overflow before the square root shrinks it back
    /// down to a u64-sized LP amount.
    fun sqrt(x: u64, y: u64): u64 {
        let product = (x as u128) * (y as u128);
        if (product < 4) {
            if (product == 0) { 0 } else { 1 }
        } else {
            let mut z = product;
            let mut w = product / 2 + 1;
            while (w < z) {
                z = w;
                w = (product / w + w) / 2;
            };
            z as u64
        }
    }
}
