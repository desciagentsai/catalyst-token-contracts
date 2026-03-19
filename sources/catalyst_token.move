/// Catalyst Token (CATL) - Main token contract
/// Total Supply: 100,000,000 CATL
/// Fixed supply with no inflation
module catalyst::catalyst_token {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};

    /// One-Time-Witness for the token
    struct CATALYST_TOKEN has drop {}

    /// Admin capability for managing token operations
    struct AdminCap has key, store {
        id: UID
    }

    /// Token configuration and state
    struct TokenConfig has key {
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
        // Create the currency
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9, // decimals
            b"CATL",
            b"Catalyst",
            b"Catalyst Token - DeSci Innovation Platform",
            option::none(),
            ctx
        );

        // Freeze the metadata (immutable token info)
        transfer::public_freeze_object(metadata);

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
            treasury_address: tx_context::sender(ctx)
        };

        // Share the config object
        transfer::share_object(config);

        // Transfer admin cap to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        // Transfer treasury cap to deployer (for minting)
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    /// Mint tokens (only called during initial distribution)
    public entry fun mint(
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
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<CATALYST_TOKEN>,
        config: &mut TokenConfig,
        coin_to_burn: Coin<CATALYST_TOKEN>
    ) {
        let amount = coin::value(&coin_to_burn);
        config.circulating_supply = config.circulating_supply - amount;
        coin::burn(treasury_cap, coin_to_burn);
    }

    /// Pause token operations (emergency)
    public entry fun pause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = true;
    }

    /// Resume token operations
    public entry fun unpause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = false;
    }

    /// Update treasury address
    public entry fun update_treasury(
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
