/// Catalyst Token (CATL) - Main token contract
/// Total Supply: 100,000,000 CATL
/// Fixed supply with no inflation
#[allow(unused_const)]
module catalyst::catalyst_token {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::coin_registry;

    /// One-Time-Witness for the token
    public struct CATALYST_TOKEN has drop {}

    /// Admin capability for managing token operations
    public struct AdminCap has key, store {
        id: UID
    }

    /// Token configuration and state
    public struct TokenConfig has key {
        id: UID,
        total_supply: u64,
        circulating_supply: u64,
        paused: bool,
        treasury_address: address
    }

    /// Error codes
    const E_PAUSED: u64 = 1;
    const E_NOT_ADMIN: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_SUPPLY: u64 = 4;

    /// Total supply: 100 million CATL (with 9 decimals)
    const TOTAL_SUPPLY: u64 = 100_000_000_000_000_000;

    /// Initialize the CATL token
    /// This is called automatically on publish
    fun init(witness: CATALYST_TOKEN, ctx: &mut TxContext) {
        // Create the currency using coin_registry (replaces deprecated coin::create_currency)
        let (currency, treasury_cap) = coin_registry::new_currency_with_otw(
            witness,
            9, // decimals
            b\"CATL\".to_string(),
            b\"Catalyst\".to_string(),
            b\"Catalyst Token - DeSci Innovation Platform\".to_string(),
            b\"\".to_string(),
            ctx
        );

        // Finalize currency registration (creates shared Currency object)
        let metadata_cap = currency.finalize(ctx);

        let sender = ctx.sender();

        // Create admin capability
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        // Create token configuration
        let config = TokenConfig {
            id: object::new(ctx),
            total_supply: TOTAL_SUPPLY,
            circulating_supply: 0,
            paused: false,
            treasury_address: sender
        };

        // Share the config object
        transfer::share_object(config);

        // Transfer admin cap to deployer
        transfer::transfer(admin_cap, sender);

        // Transfer treasury cap to deployer (for minting)
        transfer::public_transfer(treasury_cap, sender);

        // Transfer metadata cap to deployer
        transfer::public_transfer(metadata_cap, sender);
    }

    /// Mint tokens (only called during initial distribution)
    public fun mint(
        treasury_cap: &mut TreasuryCap<CATALYST_TOKEN>,
        config: &mut TokenConfig,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(!config.paused, E_PAUSED);
        assert!(config.circulating_supply + amount <= TOTAL_SUPPLY, E_INSUFFICIENT_SUPPLY);

        let coins = coin::mint(treasury_cap, amount, ctx);
        config.circulating_supply = config.circulating_supply + amount;

        transfer::public_transfer(coins, recipient);
    }

    /// Burn tokens (reduce circulating supply)
    public fun burn(
        treasury_cap: &mut TreasuryCap<CATALYST_TOKEN>,
        config: &mut TokenConfig,
        coin_to_burn: Coin<CATALYST_TOKEN>
    ) {
        let amount = coin::value(&coin_to_burn);
        config.circulating_supply = config.circulating_supply - amount;
        coin::burn(treasury_cap, coin_to_burn);
    }

    /// Pause token operations (emergency)
    public fun pause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = true;
    }

    /// Resume token operations
    public fun unpause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = false;
    }

    /// Update treasury address
    public fun update_treasury(
        _admin: &AdminCap,
        config: &mut TokenConfig,
        new_treasury: address
    ) {
        config.treasury_address = new_treasury;
    }

    /// View functions
    public fun total_supply(config: &TokenConfig): u64 {
        config.total_supply
    }

    public fun circulating_supply(config: &TokenConfig): u64 {
        config.circulating_supply
    }

    public fun is_paused(config: &TokenConfig): bool {
        config.paused
    }

    public fun treasury_address(config: &TokenConfig): address {
        config.treasury_address
    }
}
