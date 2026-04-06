/// Catalyst Vesting Contract — Restructured Tokenomics
///
/// TOKENOMICS:
///   Total Supply:    100,000,000 CATL
///   Presale (TGE):    10,000,000 CATL  (released at TGE, outside this contract)
///   Vesting Vault:    90,000,000 CATL  (locked in this contract)
///
/// EMISSION SCHEDULE (48 months):
///   Monthly emission: 1,872,340.425531915 CATL
///
///   Treasury (83% of emission):
///     - Months 1–48: receives 83% each month
///     - Months 37–48: also receives team's 17% (team fully vested)
///
///   Team (17% of emission):
///     - Months 1–12:  withheld (cliff — tokens accumulate in contract)
///     - Month 13:     lump sum of 12 months' accumulated 17% + month 13 regular 17%
///     - Months 14–36: receives 17% monthly (23 additional months)
///     - Months 37–48: team fully vested, 17% redirected to treasury
///     - Team payment window: months 13–36 (24 months of payouts)
///
/// DUST:
///   48 * 1,872,340.425531915 = 89,872,340.425531920 CATL emitted
///   Vault holds 90,000,000 CATL → ~127,659.57 CATL remainder
///   Admin can withdraw remainder after all 48 months are released.
///
#[allow(unused_const)]
module catalyst::catalyst_vesting {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use catalyst::catl::CATL;

    // ======== Constants ========

    /// 30 days in milliseconds
    const MONTH_MS: u64 = 2_592_000_000;

    /// Monthly total emission in base units (9 decimals)
    /// 1,872,340.425531915 CATL = 1_872_340_425_531_915 base units
    const MONTHLY_EMISSION: u64 = 1_872_340_425_531_915;

    /// Team percentage: 17 / 100
    const TEAM_PCT: u64 = 17;
    const PCT_BASE: u64 = 100;

    /// Team cliff: first 12 months, no team payouts (tokens accumulate)
    const TEAM_CLIFF_MONTHS: u64 = 12;

    /// Last month the team receives their 17% share (inclusive)
    /// Months 13–36 = 24 payout months
    const TEAM_LAST_MONTH: u64 = 36;

    /// Total vesting duration
    const TOTAL_MONTHS: u64 = 48;

    // ======== Error Codes ========

    const E_NOT_ADMIN: u64 = 1;
    const E_NOT_STARTED: u64 = 2;
    const E_NOTHING_TO_RELEASE: u64 = 4;
    const E_ALREADY_INITIALIZED: u64 = 5;
    const E_VESTING_NOT_COMPLETE: u64 = 6;

    // ======== Objects ========

    public struct VestingAdmin has key, store {
        id: UID
    }

    public struct VestingVault has key {
        id: UID,
        /// All locked CATL tokens
        locked_balance: Balance<CATL>,
        /// Receives 83% of monthly emission (+ team overflow after month 36)
        treasury_address: address,
        /// Receives 17% of monthly emission (with cliff logic)
        team_address: address,
        /// Timestamp (ms) when vesting started
        start_time: u64,
        /// Number of monthly emissions already processed
        months_released: u64,
        /// Team tokens accumulated during the 12-month cliff
        team_accumulated: u64,
        initialized: bool,
        paused: bool
    }

    // ======== Init ========

    fun init(ctx: &mut TxContext) {
        let admin = VestingAdmin { id: object::new(ctx) };
        let vault = VestingVault {
            id: object::new(ctx),
            locked_balance: balance::zero(),
            treasury_address: ctx.sender(),
            team_address: ctx.sender(),
            start_time: 0,
            months_released: 0,
            team_accumulated: 0,
            initialized: false,
            paused: false
        };
        transfer::share_object(vault);
        transfer::transfer(admin, ctx.sender());
    }

    // ======== Setup ========

    /// Call once after deployment. Deposits CATL tokens into the vault and
    /// sets the team wallet address. The clock marks the vesting start time.
    ///
    /// @param tokens   — Coin<CATL> holding the 90M tokens for the vault
    /// @param team_addr — wallet address that will receive team allocations
    public entry fun initialize(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        tokens: Coin<CATL>,
        team_addr: address,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        assert!(!vault.initialized, E_ALREADY_INITIALIZED);

        let token_balance = coin::into_balance(tokens);
        balance::join(&mut vault.locked_balance, token_balance);

        vault.start_time = clock::timestamp_ms(clock);
        vault.team_address = team_addr;
        vault.initialized = true;
    }

    // ======== Release ========

    /// Release all unlocked monthly emissions up to the current time.
    /// Callable by anyone (permissionless) — tokens go to treasury and team
    /// addresses stored in the vault.
    ///
    /// For each unreleased month:
    ///   - Treasury always receives 83% of MONTHLY_EMISSION
    ///   - Months 1–12:  team 17% accumulated (cliff)
    ///   - Month 13:     team receives lump sum (12 months accumulated + month 13 share)
    ///   - Months 14–36: team receives 17% monthly
    ///   - Months 37–48: team done, their 17% goes to treasury
    public entry fun release(
        vault: &mut VestingVault,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!vault.paused, E_NOT_ADMIN);
        assert!(vault.initialized, E_NOT_STARTED);

        let current_time = clock::timestamp_ms(clock);
        let elapsed_ms = current_time - vault.start_time;
        let mut months_elapsed = elapsed_ms / MONTH_MS;

        // Cap at total vesting duration
        if (months_elapsed > TOTAL_MONTHS) {
            months_elapsed = TOTAL_MONTHS;
        };

        assert!(months_elapsed > vault.months_released, E_NOTHING_TO_RELEASE);

        let mut treasury_payout = 0u64;
        let mut team_payout = 0u64;

        let mut m = vault.months_released + 1;
        while (m <= months_elapsed) {
            // Split: treasury gets 83%, team gets 17%
            // We compute treasury first, then team = total - treasury (no rounding loss)
            let treasury_share = (MONTHLY_EMISSION * (PCT_BASE - TEAM_PCT)) / PCT_BASE;
            let team_share = MONTHLY_EMISSION - treasury_share;

            // Treasury always receives their 83%
            treasury_payout = treasury_payout + treasury_share;

            if (m <= TEAM_CLIFF_MONTHS) {
                // Months 1–12: cliff — accumulate team tokens in vault
                vault.team_accumulated = vault.team_accumulated + team_share;
            } else if (m == TEAM_CLIFF_MONTHS + 1) {
                // Month 13: lump-sum release of all accumulated + this month's share
                team_payout = team_payout + vault.team_accumulated + team_share;
                vault.team_accumulated = 0;
            } else if (m <= TEAM_LAST_MONTH) {
                // Months 14–36: regular monthly team payout
                team_payout = team_payout + team_share;
            } else {
                // Months 37–48: team fully vested, redirect 17% to treasury
                treasury_payout = treasury_payout + team_share;
            };

            m = m + 1;
        };

        vault.months_released = months_elapsed;

        // Transfer to treasury
        if (treasury_payout > 0) {
            let t_bal = balance::split(&mut vault.locked_balance, treasury_payout);
            let t_coin = coin::from_balance(t_bal, ctx);
            transfer::public_transfer(t_coin, vault.treasury_address);
        };

        // Transfer to team
        if (team_payout > 0) {
            let tm_bal = balance::split(&mut vault.locked_balance, team_payout);
            let tm_coin = coin::from_balance(tm_bal, ctx);
            transfer::public_transfer(tm_coin, vault.team_address);
        };
    }

    // ======== Admin Functions ========

    public entry fun update_treasury(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        new_treasury: address
    ) {
        vault.treasury_address = new_treasury;
    }

    public entry fun update_team_address(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        new_team: address
    ) {
        vault.team_address = new_team;
    }

    public entry fun pause(
        _admin: &VestingAdmin,
        vault: &mut VestingVault
    ) {
        vault.paused = true;
    }

    public entry fun unpause(
        _admin: &VestingAdmin,
        vault: &mut VestingVault
    ) {
        vault.paused = false;
    }

    /// Withdraw any remaining dust after all 48 months have been released.
    /// Sends remainder to the treasury address.
    public entry fun withdraw_remainder(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        ctx: &mut TxContext
    ) {
        assert!(vault.months_released == TOTAL_MONTHS, E_VESTING_NOT_COMPLETE);

        let remaining = balance::value(&vault.locked_balance);
        if (remaining > 0) {
            let rem_bal = balance::split(&mut vault.locked_balance, remaining);
            let rem_coin = coin::from_balance(rem_bal, ctx);
            transfer::public_transfer(rem_coin, vault.treasury_address);
        };
    }

    // ======== View Functions ========

    public fun get_locked_balance(vault: &VestingVault): u64 {
        balance::value(&vault.locked_balance)
    }

    public fun get_treasury_address(vault: &VestingVault): address {
        vault.treasury_address
    }

    public fun get_team_address(vault: &VestingVault): address {
        vault.team_address
    }

    public fun get_months_released(vault: &VestingVault): u64 {
        vault.months_released
    }

    public fun get_team_accumulated(vault: &VestingVault): u64 {
        vault.team_accumulated
    }

    /// Returns (total_locked, months_released, team_accumulated, treasury_pending, team_pending)
    /// Use via devInspect from frontend to check vesting status without executing a release.
    public fun get_vesting_status(
        vault: &VestingVault,
        clock: &Clock
    ): (u64, u64, u64, u64, u64) {
        let current_time = clock::timestamp_ms(clock);
        let elapsed_ms = current_time - vault.start_time;
        let mut months_elapsed = elapsed_ms / MONTH_MS;
        if (months_elapsed > TOTAL_MONTHS) {
            months_elapsed = TOTAL_MONTHS;
        };

        let mut treasury_pending = 0u64;
        let mut team_pending = 0u64;
        let mut temp_accumulated = vault.team_accumulated;

        let mut m = vault.months_released + 1;
        while (m <= months_elapsed) {
            let treasury_share = (MONTHLY_EMISSION * (PCT_BASE - TEAM_PCT)) / PCT_BASE;
            let team_share = MONTHLY_EMISSION - treasury_share;

            treasury_pending = treasury_pending + treasury_share;

            if (m <= TEAM_CLIFF_MONTHS) {
                temp_accumulated = temp_accumulated + team_share;
            } else if (m == TEAM_CLIFF_MONTHS + 1) {
                team_pending = team_pending + temp_accumulated + team_share;
                temp_accumulated = 0;
            } else if (m <= TEAM_LAST_MONTH) {
                team_pending = team_pending + team_share;
            } else {
                treasury_pending = treasury_pending + team_share;
            };

            m = m + 1;
        };

        (
            balance::value(&vault.locked_balance),
            vault.months_released,
            vault.team_accumulated,
            treasury_pending,
            team_pending
        )
    }
}