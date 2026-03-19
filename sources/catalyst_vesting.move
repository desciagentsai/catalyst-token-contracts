/// Catalyst Vesting Contract
/// Manages token vesting for different allocation categories
/// All released tokens are sent to treasury for disbursement
#[allow(unused_const)]
module catalyst::catalyst_vesting {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use catalyst::catalyst_token::CATALYST_TOKEN;

    /// Vesting schedule types
    const SCHEDULE_LINEAR: u8 = 0;
    const SCHEDULE_CLIFF_VEST: u8 = 1;
    const SCHEDULE_EMISSION: u8 = 2;

    /// Allocation categories
    const CATEGORY_PRESALE: u8 = 0;
    const CATEGORY_ECOSYSTEM: u8 = 1;
    const CATEGORY_STAKING_REWARDS: u8 = 2;
    const CATEGORY_TEAM: u8 = 3;
    const CATEGORY_TREASURY_DAO: u8 = 4;
    const CATEGORY_STRATEGIC: u8 = 5;

    /// Error codes
    const E_NOT_ADMIN: u64 = 1;
    const E_NOT_STARTED: u64 = 2;
    const E_INVALID_SCHEDULE: u64 = 3;
    const E_NOTHING_TO_RELEASE: u64 = 4;
    const E_ALREADY_INITIALIZED: u64 = 5;

    /// Time constants (in milliseconds)
    const MONTH_MS: u64 = 2_592_000_000; // 30 days

    /// Admin capability
    public struct VestingAdmin has key, store {
        id: UID
    }

    /// Individual vesting schedule
    public struct VestingSchedule has store {
        category: u8,
        schedule_type: u8,
        total_amount: u64,
        released_amount: u64,
        start_time: u64,
        cliff_duration: u64,
        vesting_duration: u64,
        last_release_time: u64
    }

    /// Global vesting vault
    public struct VestingVault has key {
        id: UID,
        schedules: Table<u8, VestingSchedule>,
        locked_balance: Balance<CATALYST_TOKEN>,
        treasury_address: address,
        initialized: bool,
        paused: bool
    }

    /// Initialize the vesting vault
    fun init(ctx: &mut TxContext) {
        let admin = VestingAdmin {
            id: object::new(ctx)
        };

        let vault = VestingVault {
            id: object::new(ctx),
            schedules: table::new(ctx),
            locked_balance: balance::zero(),
            treasury_address: ctx.sender(),
            initialized: false,
            paused: false
        };

        transfer::share_object(vault);
        transfer::transfer(admin, ctx.sender());
    }

    /// Initialize all vesting schedules with token allocations
    /// Must be called once after deployment with all tokens
    public fun initialize_schedules(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        tokens: Coin<CATALYST_TOKEN>,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        assert!(!vault.initialized, E_ALREADY_INITIALIZED);

        let current_time = clock::timestamp_ms(clock);
        let _total_amount = coin::value(&tokens);

        // Expected: 100M CATL with 9 decimals = 100_000_000_000_000_000

        // Add tokens to vault
        let token_balance = coin::into_balance(tokens);
        balance::join(&mut vault.locked_balance, token_balance);

        // 1. Presale: 12M CATL - 6 month linear vest
        table::add(&mut vault.schedules, CATEGORY_PRESALE, VestingSchedule {
            category: CATEGORY_PRESALE,
            schedule_type: SCHEDULE_LINEAR,
            total_amount: 12_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 0,
            vesting_duration: 6 * MONTH_MS,
            last_release_time: current_time
        });

        // 2. Ecosystem Incentives: 30M CATL - 48 month linear vest
        table::add(&mut vault.schedules, CATEGORY_ECOSYSTEM, VestingSchedule {
            category: CATEGORY_ECOSYSTEM,
            schedule_type: SCHEDULE_LINEAR,
            total_amount: 30_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 0,
            vesting_duration: 48 * MONTH_MS,
            last_release_time: current_time
        });

        // 3. Staking Rewards: 20M CATL - 48 month emission-based
        table::add(&mut vault.schedules, CATEGORY_STAKING_REWARDS, VestingSchedule {
            category: CATEGORY_STAKING_REWARDS,
            schedule_type: SCHEDULE_EMISSION,
            total_amount: 20_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 0,
            vesting_duration: 48 * MONTH_MS,
            last_release_time: current_time
        });

        // 4. Team: 15M CATL - 12 month cliff + 24 month vest
        table::add(&mut vault.schedules, CATEGORY_TEAM, VestingSchedule {
            category: CATEGORY_TEAM,
            schedule_type: SCHEDULE_CLIFF_VEST,
            total_amount: 15_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 12 * MONTH_MS,
            vesting_duration: 24 * MONTH_MS,
            last_release_time: current_time
        });

        // 5. Treasury/DAO: 15M CATL - 48 month structured release
        table::add(&mut vault.schedules, CATEGORY_TREASURY_DAO, VestingSchedule {
            category: CATEGORY_TREASURY_DAO,
            schedule_type: SCHEDULE_LINEAR,
            total_amount: 15_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 0,
            vesting_duration: 48 * MONTH_MS,
            last_release_time: current_time
        });

        // 6. Strategic Partners: 10M CATL - 6 month cliff + 12 month vest
        table::add(&mut vault.schedules, CATEGORY_STRATEGIC, VestingSchedule {
            category: CATEGORY_STRATEGIC,
            schedule_type: SCHEDULE_CLIFF_VEST,
            total_amount: 10_000_000_000_000_000,
            released_amount: 0,
            start_time: current_time,
            cliff_duration: 6 * MONTH_MS,
            vesting_duration: 12 * MONTH_MS,
            last_release_time: current_time
        });

        vault.initialized = true;
    }

    /// Calculate unlocked amount for a schedule
    fun calculate_unlocked(
        schedule: &VestingSchedule,
        current_time: u64
    ): u64 {
        let time_elapsed = current_time - schedule.start_time;

        // Before cliff
        if (time_elapsed < schedule.cliff_duration) {
            return 0
        };

        // After full vesting
        let total_duration = schedule.cliff_duration + schedule.vesting_duration;
        if (time_elapsed >= total_duration) {
            return schedule.total_amount
        };

        // During vesting period
        let vesting_elapsed = time_elapsed - schedule.cliff_duration;

        if (schedule.schedule_type == SCHEDULE_LINEAR || schedule.schedule_type == SCHEDULE_CLIFF_VEST) {
            // Linear vesting
            (schedule.total_amount * vesting_elapsed) / schedule.vesting_duration
        } else if (schedule.schedule_type == SCHEDULE_EMISSION) {
            // Emission-based (linear for now, can be customized)
            (schedule.total_amount * vesting_elapsed) / schedule.vesting_duration
        } else {
            0
        }
    }

    /// Release unlocked tokens for a specific category to treasury
    public fun release_category(
        vault: &mut VestingVault,
        category: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!vault.paused, E_NOT_ADMIN);
        assert!(vault.initialized, E_NOT_STARTED);

        let schedule = table::borrow_mut(&mut vault.schedules, category);
        let current_time = clock::timestamp_ms(clock);

        let unlocked_total = calculate_unlocked(schedule, current_time);
        let releasable = unlocked_total - schedule.released_amount;

        assert!(releasable > 0, E_NOTHING_TO_RELEASE);

        // Update schedule
        schedule.released_amount = schedule.released_amount + releasable;
        schedule.last_release_time = current_time;

        // Transfer tokens to treasury
        let released_balance = balance::split(&mut vault.locked_balance, releasable);
        let released_coin = coin::from_balance(released_balance, ctx);
        transfer::public_transfer(released_coin, vault.treasury_address);
    }

    /// Release all unlocked tokens from all categories
    public fun release_all(
        vault: &mut VestingVault,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!vault.paused, E_NOT_ADMIN);
        assert!(vault.initialized, E_NOT_STARTED);

        let current_time = clock::timestamp_ms(clock);
        let categories = vector[
            CATEGORY_PRESALE,
            CATEGORY_ECOSYSTEM,
            CATEGORY_STAKING_REWARDS,
            CATEGORY_TEAM,
            CATEGORY_TREASURY_DAO,
            CATEGORY_STRATEGIC
        ];

        let mut i = 0;
        let mut total_released = 0u64;

        while (i < 6) {
            let category = *vector::borrow(&categories, i);
            let schedule = table::borrow_mut(&mut vault.schedules, category);

            let unlocked_total = calculate_unlocked(schedule, current_time);
            let releasable = unlocked_total - schedule.released_amount;

            if (releasable > 0) {
                schedule.released_amount = schedule.released_amount + releasable;
                schedule.last_release_time = current_time;
                total_released = total_released + releasable;
            };

            i = i + 1;
        };

        // Transfer all released tokens to treasury
        if (total_released > 0) {
            let released_balance = balance::split(&mut vault.locked_balance, total_released);
            let released_coin = coin::from_balance(released_balance, ctx);
            transfer::public_transfer(released_coin, vault.treasury_address);
        };
    }

    /// Update treasury address
    public fun update_treasury(
        _admin: &VestingAdmin,
        vault: &mut VestingVault,
        new_treasury: address
    ) {
        vault.treasury_address = new_treasury;
    }

    /// Pause vesting releases (emergency)
    public fun pause(
        _admin: &VestingAdmin,
        vault: &mut VestingVault
    ) {
        vault.paused = true;
    }

    /// Resume vesting releases
    public fun unpause(
        _admin: &VestingAdmin,
        vault: &mut VestingVault
    ) {
        vault.paused = false;
    }

    /// View functions
    public fun get_locked_balance(vault: &VestingVault): u64 {
        balance::value(&vault.locked_balance)
    }

    public fun get_treasury_address(vault: &VestingVault): address {
        vault.treasury_address
    }

    /// Get schedule info (for frontend display)
    public fun get_schedule_info(
        vault: &VestingVault,
        category: u8,
        clock: &Clock
    ): (u64, u64, u64, u64) {
        let schedule = table::borrow(&vault.schedules, category);
        let current_time = clock::timestamp_ms(clock);
        let unlocked = calculate_unlocked(schedule, current_time);
        let releasable = if (unlocked > schedule.released_amount) {
            unlocked - schedule.released_amount
        } else {
            0
        };

        (
            schedule.total_amount,
            schedule.released_amount,
            unlocked,
            releasable
        )
    }
}
