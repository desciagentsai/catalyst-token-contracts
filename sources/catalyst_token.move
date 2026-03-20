#[allow(unused_const)]
module catalyst::catl {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::coin_registry;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};

    public struct CATL has drop {}

    public struct AdminCap has key, store {
        id: UID
    }

    public struct TokenConfig has key {
        id: UID,
        total_supply: u64,
        circulating_supply: u64,
        paused: bool,
        treasury_address: address
    }

    const E_PAUSED: u64 = 1;
    const E_NOT_ADMIN: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    const E_INSUFFICIENT_SUPPLY: u64 = 4;

    const TOTAL_SUPPLY: u64 = 100_000_000_000_000_000;

    fun init(witness: CATL, ctx: &mut TxContext) {
        let (currency, treasury_cap) = coin_registry::new_currency_with_otw(
            witness,
            9,
            b"CATL".to_string(),
            b"Catalyst".to_string(),
            b"Catalyst Token - DeSci Innovation Platform".to_string(),
            b"https://app.descilaunch.xyz/favicon.ico".to_string(),
            ctx
        );

        let metadata_cap = currency.finalize(ctx);

        let sender = ctx.sender();

        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        let config = TokenConfig {
            id: object::new(ctx),
            total_supply: TOTAL_SUPPLY,
            circulating_supply: 0,
            paused: false,
            treasury_address: sender
        };

        transfer::share_object(config);
        transfer::transfer(admin_cap, sender);
        transfer::public_transfer(treasury_cap, sender);
        transfer::public_transfer(metadata_cap, sender);
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<CATL>,
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

    public entry fun burn(
        treasury_cap: &mut TreasuryCap<CATL>,
        config: &mut TokenConfig,
        coin_to_burn: Coin<CATL>
    ) {
        let amount = coin::value(&coin_to_burn);
        config.circulating_supply = config.circulating_supply - amount;
        coin::burn(treasury_cap, coin_to_burn);
    }

    public entry fun pause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = true;
    }

    public entry fun unpause(
        _admin: &AdminCap,
        config: &mut TokenConfig
    ) {
        config.paused = false;
    }

    public entry fun update_treasury(
        _admin: &AdminCap,
        config: &mut TokenConfig,
        new_treasury: address
    ) {
        config.treasury_address = new_treasury;
    }

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
