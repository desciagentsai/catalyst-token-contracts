#[allow(unused_const)]
module catalyst::catl {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::coin_registry;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};
    use std::string::String;

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
    /// ✅ Hard cap: 100,000,000 CATL × 10^9 decimals = 100_000_000_000_000_000
    /// After this supply is reached, mint() will permanently abort — no more CATL can ever be minted.
    const E_MINT_CAP_REACHED: u64 = 4;

    /// 100M CATL hard cap (9 decimals)
    const TOTAL_SUPPLY: u64 = 100_000_000_000_000_000;

    fun init(witness: CATL, ctx: &mut TxContext) {
        let (currency, treasury_cap) = coin_registry::new_currency_with_otw(
            witness,
            9,
            b"CATL".to_string(),
            b"Catalyst".to_string(),
            b"Catalyst Token - DeSci Innovation Platform".to_string(),
            b"https://app.descilaunch.xyz/catl-wallet-icon.png".to_string(),
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

    /// Mint CATL tokens.
    /// ✅ Hard cap enforced: will abort with E_MINT_CAP_REACHED if
    ///    circulating_supply + amount would exceed 100,000,000 CATL.
    ///    Once the cap is hit, minting is permanently impossible.
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<CATL>,
        config: &mut TokenConfig,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(!config.paused, E_PAUSED);
        // ✅ 100M hard cap — this assert permanently blocks minting beyond the cap
        assert!(
            config.circulating_supply + amount <= TOTAL_SUPPLY,
            E_MINT_CAP_REACHED
        );

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

    // ======== Metadata Update Functions ========

    public entry fun update_icon_url(
        currency: &mut coin_registry::Currency<CATL>,
        metadata_cap: &coin_registry::MetadataCap<CATL>,
        new_icon_url: String,
    ) {
        coin_registry::set_icon_url(currency, metadata_cap, new_icon_url);
    }

    public entry fun update_name(
        currency: &mut coin_registry::Currency<CATL>,
        metadata_cap: &coin_registry::MetadataCap<CATL>,
        new_name: String,
    ) {
        coin_registry::set_name(currency, metadata_cap, new_name);
    }

    public entry fun update_description(
        currency: &mut coin_registry::Currency<CATL>,
        metadata_cap: &coin_registry::MetadataCap<CATL>,
        new_description: String,
    ) {
        coin_registry::set_description(currency, metadata_cap, new_description);
    }
}
