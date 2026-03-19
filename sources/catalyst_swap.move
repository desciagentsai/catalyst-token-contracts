/// Catalyst Swap Contract
/// Automated Market Maker (AMM) for CATL token
/// Supports pairs: CATL/SUI, CATL/USDT, CATL/USDC
#[allow(unused_const)]
module catalyst::catalyst_swap {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance, Supply};
    use sui::sui::SUI;
    use catalyst::catalyst_token::CATALYST_TOKEN;

    /// LP Token for liquidity providers
    public struct LP_TOKEN has drop {}

    /// Error codes
    const E_ZERO_AMOUNT: u64 = 1;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 2;
    const E_SLIPPAGE_EXCEEDED: u64 = 3;
    const E_PAUSED: u64 = 4;
    const E_INVALID_PAIR: u64 = 5;

    /// Minimum liquidity locked forever
    const MINIMUM_LIQUIDITY: u64 = 1000;

    /// Fee in basis points (0.3% = 30 bps)
    const SWAP_FEE_BPS: u64 = 30;
    const BPS_DENOMINATOR: u64 = 10000;

    /// Admin capability
    public struct SwapAdmin has key, store {
        id: UID
    }

    /// Liquidity Pool for CATL/SUI pair
    public struct LiquidityPool_CATL_SUI has key {
        id: UID,
        catl_reserve: Balance<CATALYST_TOKEN>,
        sui_reserve: Balance<SUI>,
        lp_supply: Supply<LP_TOKEN>,
        locked_lp: Balance<LP_TOKEN>,
        paused: bool
    }

    /// Liquidity Pool for CATL/STABLE pair (generic for stable coins)
    /// Note: In production, replace GENERIC_STABLE with actual USDT type
    public struct LiquidityPool_CATL_STABLE<phantom STABLE> has key {
        id: UID,
        catl_reserve: Balance<CATALYST_TOKEN>,
        stable_reserve: Balance<STABLE>,
        lp_supply: Supply<LP_TOKEN>,
        locked_lp: Balance<LP_TOKEN>,
        paused: bool
    }

    /// LP Token representation
    public struct LPCoin has key, store {
        id: UID,
        balance: Balance<LP_TOKEN>
    }

    /// Initialize the swap module
    fun init(ctx: &mut TxContext) {
        let admin = SwapAdmin {
            id: object::new(ctx)
        };
        transfer::transfer(admin, ctx.sender());
    }

    /// Create CATL/SUI liquidity pool
    public fun create_catl_sui_pool(
        _admin: &SwapAdmin,
        ctx: &mut TxContext
    ) {
        let pool = LiquidityPool_CATL_SUI {
            id: object::new(ctx),
            catl_reserve: balance::zero(),
            sui_reserve: balance::zero(),
            lp_supply: balance::create_supply(LP_TOKEN {}),
            locked_lp: balance::zero(),
            paused: false
        };
        transfer::share_object(pool);
    }

    /// Create CATL/STABLE liquidity pool (for USDT, USDC)
    public fun create_catl_stable_pool<STABLE>(
        _admin: &SwapAdmin,
        ctx: &mut TxContext
    ) {
        let pool = LiquidityPool_CATL_STABLE<STABLE> {
            id: object::new(ctx),
            catl_reserve: balance::zero(),
            stable_reserve: balance::zero(),
            lp_supply: balance::create_supply(LP_TOKEN {}),
            locked_lp: balance::zero(),
            paused: false
        };
        transfer::share_object(pool);
    }

    // ======== CATL/SUI Pool Functions ========

    /// Add liquidity to CATL/SUI pool
    public fun add_liquidity_catl_sui(
        pool: &mut LiquidityPool_CATL_SUI,
        catl_coin: Coin<CATALYST_TOKEN>,
        sui_coin: Coin<SUI>,
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

        let lp_amount = if (lp_supply == 0) {
            // Initial liquidity
            let initial_lp = sqrt(catl_amount * sui_amount);
            assert!(initial_lp > MINIMUM_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);

            // Lock minimum liquidity forever in pool
            let minimum_lp_balance = balance::increase_supply(&mut pool.lp_supply, MINIMUM_LIQUIDITY);
            balance::join(&mut pool.locked_lp, minimum_lp_balance);

            initial_lp - MINIMUM_LIQUIDITY
        } else {
            // Subsequent liquidity
            let catl_lp = (catl_amount * lp_supply) / catl_reserve;
            let sui_lp = (sui_amount * lp_supply) / sui_reserve;
            if (catl_lp < sui_lp) catl_lp else sui_lp
        };

        assert!(lp_amount >= min_lp_amount, E_SLIPPAGE_EXCEEDED);

        // Add to reserves
        balance::join(&mut pool.catl_reserve, coin::into_balance(catl_coin));
        balance::join(&mut pool.sui_reserve, coin::into_balance(sui_coin));

        // Mint LP tokens
        let lp_balance = balance::increase_supply(&mut pool.lp_supply, lp_amount);
        let lp_coin = LPCoin {
            id: object::new(ctx),
            balance: lp_balance
        };

        transfer::transfer(lp_coin, ctx.sender());
    }

    /// Swap CATL for SUI
    public fun swap_catl_to_sui(
        pool: &mut LiquidityPool_CATL_SUI,
        catl_in: Coin<CATALYST_TOKEN>,
        min_sui_out: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let catl_amount = coin::value(&catl_in);
        assert!(catl_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let sui_reserve = balance::value(&pool.sui_reserve);

        // Calculate output with 0.3% fee
        let catl_in_with_fee = catl_amount * (BPS_DENOMINATOR - SWAP_FEE_BPS);
        let sui_out = (catl_in_with_fee * sui_reserve) / (catl_reserve * BPS_DENOMINATOR + catl_in_with_fee);

        assert!(sui_out >= min_sui_out, E_SLIPPAGE_EXCEEDED);
        assert!(sui_out < sui_reserve, E_INSUFFICIENT_LIQUIDITY);

        // Update reserves
        balance::join(&mut pool.catl_reserve, coin::into_balance(catl_in));
        let sui_balance_out = balance::split(&mut pool.sui_reserve, sui_out);

        // Transfer SUI to user
        let sui_coin_out = coin::from_balance(sui_balance_out, ctx);
        transfer::public_transfer(sui_coin_out, ctx.sender());
    }

    /// Swap SUI for CATL
    public fun swap_sui_to_catl(
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

        // Calculate output with 0.3% fee
        let sui_in_with_fee = sui_amount * (BPS_DENOMINATOR - SWAP_FEE_BPS);
        let catl_out = (sui_in_with_fee * catl_reserve) / (sui_reserve * BPS_DENOMINATOR + sui_in_with_fee);

        assert!(catl_out >= min_catl_out, E_SLIPPAGE_EXCEEDED);
        assert!(catl_out < catl_reserve, E_INSUFFICIENT_LIQUIDITY);

        // Update reserves
        balance::join(&mut pool.sui_reserve, coin::into_balance(sui_in));
        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);

        // Transfer CATL to user
        let catl_coin_out = coin::from_balance(catl_balance_out, ctx);
        transfer::public_transfer(catl_coin_out, ctx.sender());
    }

    /// Remove liquidity from CATL/SUI pool
    public fun remove_liquidity_catl_sui(
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

        let catl_out = (lp_amount * catl_reserve) / lp_supply;
        let sui_out = (lp_amount * sui_reserve) / lp_supply;

        assert!(catl_out >= min_catl_out && sui_out >= min_sui_out, E_SLIPPAGE_EXCEEDED);

        // Burn LP tokens
        balance::decrease_supply(&mut pool.lp_supply, lp_balance);

        // Withdraw from reserves
        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);
        let sui_balance_out = balance::split(&mut pool.sui_reserve, sui_out);

        // Transfer to user
        let sender = ctx.sender();
        transfer::public_transfer(coin::from_balance(catl_balance_out, ctx), sender);
        transfer::public_transfer(coin::from_balance(sui_balance_out, ctx), sender);
    }

    // ======== CATL/STABLE Pool Functions ========

    /// Add liquidity to CATL/STABLE pool
    public fun add_liquidity_catl_stable<STABLE>(
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>,
        catl_coin: Coin<CATALYST_TOKEN>,
        stable_coin: Coin<STABLE>,
        min_lp_amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let catl_amount = coin::value(&catl_coin);
        let stable_amount = coin::value(&stable_coin);

        assert!(catl_amount > 0 && stable_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let stable_reserve = balance::value(&pool.stable_reserve);
        let lp_supply = balance::supply_value(&pool.lp_supply);

        let lp_amount = if (lp_supply == 0) {
            let initial_lp = sqrt(catl_amount * stable_amount);
            assert!(initial_lp > MINIMUM_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);

            // Lock minimum liquidity forever in pool
            let minimum_lp_balance = balance::increase_supply(&mut pool.lp_supply, MINIMUM_LIQUIDITY);
            balance::join(&mut pool.locked_lp, minimum_lp_balance);

            initial_lp - MINIMUM_LIQUIDITY
        } else {
            let catl_lp = (catl_amount * lp_supply) / catl_reserve;
            let stable_lp = (stable_amount * lp_supply) / stable_reserve;
            if (catl_lp < stable_lp) catl_lp else stable_lp
        };

        assert!(lp_amount >= min_lp_amount, E_SLIPPAGE_EXCEEDED);

        balance::join(&mut pool.catl_reserve, coin::into_balance(catl_coin));
        balance::join(&mut pool.stable_reserve, coin::into_balance(stable_coin));

        let lp_balance = balance::increase_supply(&mut pool.lp_supply, lp_amount);
        let lp_coin = LPCoin {
            id: object::new(ctx),
            balance: lp_balance
        };

        transfer::transfer(lp_coin, ctx.sender());
    }

    /// Swap CATL for STABLE
    public fun swap_catl_to_stable<STABLE>(
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>,
        catl_in: Coin<CATALYST_TOKEN>,
        min_stable_out: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let catl_amount = coin::value(&catl_in);
        assert!(catl_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let stable_reserve = balance::value(&pool.stable_reserve);

        let catl_in_with_fee = catl_amount * (BPS_DENOMINATOR - SWAP_FEE_BPS);
        let stable_out = (catl_in_with_fee * stable_reserve) / (catl_reserve * BPS_DENOMINATOR + catl_in_with_fee);

        assert!(stable_out >= min_stable_out, E_SLIPPAGE_EXCEEDED);
        assert!(stable_out < stable_reserve, E_INSUFFICIENT_LIQUIDITY);

        balance::join(&mut pool.catl_reserve, coin::into_balance(catl_in));
        let stable_balance_out = balance::split(&mut pool.stable_reserve, stable_out);

        transfer::public_transfer(coin::from_balance(stable_balance_out, ctx), ctx.sender());
    }

    /// Swap STABLE for CATL
    public fun swap_stable_to_catl<STABLE>(
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>,
        stable_in: Coin<STABLE>,
        min_catl_out: u64,
        ctx: &mut TxContext
    ) {
        assert!(!pool.paused, E_PAUSED);

        let stable_amount = coin::value(&stable_in);
        assert!(stable_amount > 0, E_ZERO_AMOUNT);

        let catl_reserve = balance::value(&pool.catl_reserve);
        let stable_reserve = balance::value(&pool.stable_reserve);

        let stable_in_with_fee = stable_amount * (BPS_DENOMINATOR - SWAP_FEE_BPS);
        let catl_out = (stable_in_with_fee * catl_reserve) / (stable_reserve * BPS_DENOMINATOR + stable_in_with_fee);

        assert!(catl_out >= min_catl_out, E_SLIPPAGE_EXCEEDED);
        assert!(catl_out < catl_reserve, E_INSUFFICIENT_LIQUIDITY);

        balance::join(&mut pool.stable_reserve, coin::into_balance(stable_in));
        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);

        transfer::public_transfer(coin::from_balance(catl_balance_out, ctx), ctx.sender());
    }

    /// Remove liquidity from CATL/STABLE pool
    public fun remove_liquidity_catl_stable<STABLE>(
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>,
        lp_coin: LPCoin,
        min_catl_out: u64,
        min_stable_out: u64,
        ctx: &mut TxContext
    ) {
        let LPCoin { id, balance: lp_balance } = lp_coin;
        object::delete(id);

        let lp_amount = balance::value(&lp_balance);
        let catl_reserve = balance::value(&pool.catl_reserve);
        let stable_reserve = balance::value(&pool.stable_reserve);
        let lp_supply = balance::supply_value(&pool.lp_supply);

        let catl_out = (lp_amount * catl_reserve) / lp_supply;
        let stable_out = (lp_amount * stable_reserve) / lp_supply;

        assert!(catl_out >= min_catl_out && stable_out >= min_stable_out, E_SLIPPAGE_EXCEEDED);

        balance::decrease_supply(&mut pool.lp_supply, lp_balance);

        let catl_balance_out = balance::split(&mut pool.catl_reserve, catl_out);
        let stable_balance_out = balance::split(&mut pool.stable_reserve, stable_out);

        let sender = ctx.sender();
        transfer::public_transfer(coin::from_balance(catl_balance_out, ctx), sender);
        transfer::public_transfer(coin::from_balance(stable_balance_out, ctx), sender);
    }

    // ======== Admin Functions ========

    /// Pause all swaps (emergency)
    public fun pause_catl_sui_pool(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_SUI
    ) {
        pool.paused = true;
    }

    /// Unpause CATL/SUI pool
    public fun unpause_catl_sui_pool(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_SUI
    ) {
        pool.paused = false;
    }

    /// Pause CATL/STABLE pool
    public fun pause_catl_stable_pool<STABLE>(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>
    ) {
        pool.paused = true;
    }

    /// Unpause CATL/STABLE pool
    public fun unpause_catl_stable_pool<STABLE>(
        _admin: &SwapAdmin,
        pool: &mut LiquidityPool_CATL_STABLE<STABLE>
    ) {
        pool.paused = false;
    }

    // ======== View Functions ========

    public fun get_catl_sui_reserves(pool: &LiquidityPool_CATL_SUI): (u64, u64) {
        (
            balance::value(&pool.catl_reserve),
            balance::value(&pool.sui_reserve)
        )
    }

    public fun get_catl_stable_reserves<STABLE>(pool: &LiquidityPool_CATL_STABLE<STABLE>): (u64, u64) {
        (
            balance::value(&pool.catl_reserve),
            balance::value(&pool.stable_reserve)
        )
    }

    /// Calculate output amount for a swap (for frontend preview)
    public fun calculate_swap_output(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64
    ): u64 {
        let amount_in_with_fee = amount_in * (BPS_DENOMINATOR - SWAP_FEE_BPS);
        (amount_in_with_fee * reserve_out) / (reserve_in * BPS_DENOMINATOR + amount_in_with_fee)
    }

    // ======== Helper Functions ========

    /// Integer square root (Babylonian method)
    fun sqrt(y: u64): u64 {
        if (y < 4) {
            if (y == 0) {
                0
            } else {
                1
            }
        } else {
            let mut z = y;
            let mut x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            };
            z
        }
    }
}
