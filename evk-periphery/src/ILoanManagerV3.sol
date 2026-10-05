// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Interfaz mínima de Credit Limit Manager
interface ICLM {
    function creditLimit(address account) external view returns (uint256);
}

interface ILoanManagerV3 is ICLM {
    // =========================
    // TYPES
    // =========================

    struct UserRisk {
        uint16 score;       // 0–1000
        bool   kycOk;
        uint64 validUntil;
        uint64 lastUpdate;
        uint256 limit;      // USDC 6 dec
    }

    struct LoanOffer {
        uint16 tenorDays;    // p.ej. 3, 7, 14, 21, 30
        uint16 feeBps;       // p.ej. 300 = 3%
        uint64 validUntil;   // timestamp hasta cuando vale la oferta
        uint256 maxAmount;   // monto máximo que puede pedir con ESTA oferta
        bool   exists;       // flag para saber si hay oferta activa
    }

    struct Loan {
        uint128 principal;
        uint128 amountDue;
        uint64  start;
        uint64  due;
        uint32  gracePeriod;
        uint16  feeBps;
        uint16  tenorDays;
        bool    active;
        bool    defaulted;
        uint64  lastAccrued;
    }

    struct PremiumConfig {
        uint128 premiumRatePerSecWad;
        uint128 lateRatePerSecWad;
    }

    // =========================
    // EVENTS
    // =========================

    event LoanDefaulted(address indexed user, uint256 timestamp);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event VaultSet(address indexed vault);
    event UserRiskSet(address indexed user, uint16 score, bool kycOk, uint64 validUntil, uint256 limit);
    event LoanOfferSet(address indexed user, uint16 tenorDays, uint16 feeBps, uint64 validUntil, uint256 maxAmount);
    event LoanOpened(
        address indexed user,
        uint256 principal,
        uint256 amountDue,
        uint64  due,
        uint16  feeBps,
        uint32  gracePeriod
    );
    event LoanClosed(address indexed user, uint256 paid);
    event PremiumConfigSet(address indexed user, uint128 premiumRatePerSecWad, uint128 lateRatePerSecWad);
    event DefaultGracePeriodSet(uint32 newGracePeriod);
    event MinHoldSet(uint16 tenorDays, uint16 minHoldDays);
    event NextBorrowTimeSet(address indexed user, uint64 timestamp);

    // =========================
    // VIEW GETTERS (STATE)
    // =========================
    function vault() external view returns (address);

    function defaultGracePeriod() external view returns (uint32);
    function defaultLatePeriod() external view returns (uint32);

    // mapping(address => UserRisk) public users;
    function users(address account)
        external
        view
        returns (
            uint16 score,
            bool   kycOk,
            uint64 validUntil,
            uint64 lastUpdate,
            uint256 limit
        );

    // mapping(address => LoanOffer) public offers;
    function offers(address borrower)
        external
        view
        returns (
            uint16 tenorDays,
            uint16 feeBps,
            uint64 validUntil,
            uint256 maxAmount,
            bool   exists
        );

    // mapping(address => PremiumConfig) public premiums;
    function premiums(address borrower)
        external
        view
        returns (
            uint128 premiumRatePerSecWad,
            uint128 lateRatePerSecWad
        );

    // mapping(address => uint64) public nextBorrowTime;
    function nextBorrowTime(address borrower) external view returns (uint64);

    // mapping(uint16 => uint16) public minHoldDaysByTenor;
    function minHoldDaysByTenor(uint16 tenorDays) external view returns (uint16);

    // helper para ver el préstamo actual
    function loans(address borrower)
        external
        view
        returns (
            uint128 principal,
            uint128 amountDue,
            uint64  start,
            uint64  due,
            uint16  feeBps,
            uint32  gracePeriod,
            bool    active
        );

    // vista de late
    function previewLoanWithLate(address borrower)
        external
        view
        returns (
            uint256 principal,
            uint256 amountDueWithLate
        );

    function isDefaulted(address borrower) external view returns (bool);

    // creditLimit viene de ICLM:
    // function creditLimit(address account) external view returns (uint256);

    // =========================
    // ADMIN / CONFIG
    // =========================

    function setOwner(address n) external;
    function setVault(address _vault) external;
    function setDefaultGracePeriod(uint32 g) external;
    function setMinHoldForTenor(uint16 tenorDays, uint16 minHoldDays) external;

    function setUserRisk(
        address account,
        uint16 score,
        bool   kycOk,
        uint64 validUntil,
        uint256 limit
    ) external;

    function setLoanOffer(
        address borrower,
        uint16 tenorDays,
        uint16 feeBps,
        uint64 validUntil,
        uint256 maxAmount
    ) external;

    function setPremiumConfig(
        address borrower,
        uint128 premiumRatePerSecWad,
        uint128 lateRatePerSecWad
    ) external;

    function accrueLate(address borrower) external;

    // =========================
    // CORE LOAN FLOW
    // =========================

    function openLoan(
        address borrower,
        uint256 principal,
        uint16 tenorDays,
        uint16 feeBps
    ) external;

    function markDefault(address borrower) external;

    function closeLoan(address borrower, uint256 paid) external;
}