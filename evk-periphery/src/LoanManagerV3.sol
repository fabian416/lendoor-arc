// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ILoanManagerV3.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract LoanManagerV3 is
    ILoanManagerV3,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // ============ STORAGE BÁSICO ============

    address public override vault;

    // Grace global por defecto (ej: 1 día)
    uint32 public override defaultGracePeriod;
    // Tiempo después de due+grace a partir del cual podés marcar default duro
    uint32 public override defaultLatePeriod;

    // Tenor -> minHold en días (tiempo mínimo desde start antes de pedir otro préstamo)
    mapping(uint16 => uint16) public override minHoldDaysByTenor;
    // quien -> timestamp desde cuando puede volver a pedir
    mapping(address => uint64) public override nextBorrowTime;

    // ============ RIESGO / PROFILE ============
    mapping(address => UserRisk) public users;

    // ============ OFERTAS ============
    mapping(address => LoanOffer) public offers;

    // ============ PRÉSTAMO ACTIVO ============
    mapping(address => Loan) internal _loans;

    // ============ PRIMAS (DRP + LATE) ============
    mapping(address => PremiumConfig) public premiums;

    // ============ MODIFIERS ============
    modifier onlyVault() {
        require(msg.sender == vault, "not vault");
        _;
    }

    // ============ INITIALIZER (UPGRADEABLE) ============

    function initialize(address initialOwner, address _vault)
        public
        initializer
    {
        require(_vault != address(0), "vault=0");

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _transferOwnership(
            initialOwner == address(0) ? msg.sender : initialOwner
        );

        vault = _vault;

        // seteo explícito de defaults
        defaultGracePeriod = 1 days;
        defaultLatePeriod  = 15 days;

        // Setup default minHold por tenor
        minHoldDaysByTenor[3]  = 4;
        minHoldDaysByTenor[7]  = 4;
        minHoldDaysByTenor[14] = 7;
        minHoldDaysByTenor[21] = 7;
        minHoldDaysByTenor[30] = 7;
    }

    // ============ GETTER DE PRÉSTAMO ACTUAL ============

    function loans(address borrower)
        external
        view
        override
        returns (
            uint128 principal,
            uint128 amountDue,
            uint64  start,
            uint64  due,
            uint16  feeBps,
            uint32  gracePeriod,
            bool    active
        )
    {
        Loan memory L = _loans[borrower];
        return (
            L.principal,
            L.amountDue,
            L.start,
            L.due,
            L.feeBps,
            L.gracePeriod,
            L.active
        );
    }

    // ============ ADMIN BÁSICO ============

    function setOwner(address n) external override onlyOwner {
        require(n != address(0), "owner=0");
        address old = owner();
        _transferOwnership(n);
        emit OwnerChanged(old, n);
    }

    function setVault(address _vault) external override onlyOwner {
        require(_vault != address(0), "vault=0");
        vault = _vault;
        emit VaultSet(_vault);
    }

    // Arc testnet (2026-10): el minHold por tenor y el cooldown por deudor se
    // pueden ajustar desde el owner para instancias de prueba (en prod no existe).
    function setMinHoldDays(uint16 tenorDays, uint16 holdDays) external onlyOwner {
        minHoldDaysByTenor[tenorDays] = holdDays;
    }

    function setNextBorrowTime(address borrower, uint64 ts) external onlyOwner {
        nextBorrowTime[borrower] = ts;
        emit NextBorrowTimeSet(borrower, ts);
    }

    function setDefaultGracePeriod(uint32 g) external override onlyOwner {
        defaultGracePeriod = g;
        emit DefaultGracePeriodSet(g);
    }

    // ============ RIESGO / PROFILE ============

    function setUserRisk(
        address account,
        uint16 score,
        bool kycOk,
        uint64 validUntil,
        uint256 limit
    ) external override onlyOwner {
        require(account != address(0), "acct=0");

        users[account] = UserRisk({
            score:      score,
            kycOk:      kycOk,
            validUntil: validUntil,
            lastUpdate: uint64(block.timestamp),
            limit:      limit
        });

        emit UserRiskSet(account, score, kycOk, validUntil, limit);
    }

    function creditLimit(address account)
        public
        view
        override
        returns (uint256)
    {
        UserRisk memory u = users[account];
        if (!u.kycOk) return 0;
        if (u.validUntil != 0 && block.timestamp > u.validUntil) return 0;
        return u.limit;
    }

    // ============ OFERTAS ============

    function setLoanOffer(
        address borrower,
        uint16 tenorDays,
        uint16 feeBps,
        uint64 validUntil,
        uint256 maxAmount
    ) external override onlyOwner {
        require(borrower != address(0), "acct=0");
        require(tenorDays > 0, "tenor=0");
        require(feeBps > 0, "fee=0");
        require(validUntil > block.timestamp, "offer expired");
        require(maxAmount > 0, "amount=0");

        offers[borrower] = LoanOffer({
            tenorDays:  tenorDays,
            feeBps:     feeBps,
            validUntil: validUntil,
            maxAmount:  maxAmount,
            exists:     true
        });

        emit LoanOfferSet(borrower, tenorDays, feeBps, validUntil, maxAmount);
    }

    // ============ ABRIR PRÉSTAMO FIJO ============

    function openLoan(
        address borrower,
        uint256 principal,
        uint16 tenorDays,
        uint16 feeBps
    ) external override onlyVault {
        require(borrower != address(0), "acct=0");
        require(principal > 0, "principal=0");

        uint64 allowedSince = nextBorrowTime[borrower];
        if (allowedSince != 0) {
            require(block.timestamp >= allowedSince, "cooldown");
        }

        Loan storage L = _loans[borrower];
        require(!L.active, "loan active");

        uint256 limit = creditLimit(borrower);
        require(principal <= limit, "over cl");

        LoanOffer memory o = offers[borrower];
        require(o.exists, "no offer");
        require(block.timestamp <= o.validUntil, "offer expired");

        require(tenorDays == o.tenorDays, "bad tenor");
        require(feeBps   == o.feeBps,     "bad fee");
        require(principal <= o.maxAmount, "over offer");

        delete offers[borrower];

        uint256 amountDue = (principal * (10000 + uint256(feeBps))) / 10000;

        L.principal    = uint128(principal);
        L.amountDue    = uint128(amountDue);
        L.start        = uint64(block.timestamp);
        L.due          = uint64(block.timestamp + uint256(tenorDays) * 1 days);
        L.feeBps       = feeBps;
        L.gracePeriod  = defaultGracePeriod;
        L.tenorDays    = tenorDays;
        L.active       = true;
        L.lastAccrued  = uint64(block.timestamp);
        L.defaulted    = false;

        emit LoanOpened(
            borrower,
            principal,
            amountDue,
            L.due,
            feeBps,
            L.gracePeriod
        );
    }
    // ============ DEFAULT DURO ============
    function markDefault(address borrower) external override onlyOwner {
        Loan storage L = _loans[borrower];
        require(L.active, "no active loan");
        require(!L.defaulted, "already defaulted");

        uint64 limitTs = L.due + L.gracePeriod + defaultLatePeriod;
        require(block.timestamp > limitTs, "too early to default");

        L.defaulted = true;

        users[borrower].limit = 0;
        nextBorrowTime[borrower] = uint64(block.timestamp + 30 days);

        emit LoanDefaulted(borrower, block.timestamp);
    }

    // ============ CIERRE DE PRÉSTAMO + MIN HOLD ============

    function closeLoan(address borrower, uint256 paid)
        external
        override
        onlyVault
    {
        Loan storage L = _loans[borrower];
        require(L.active, "no loan");
        require(paid >= L.amountDue, "underpaid");

        L.active = false;

        uint16 minHoldDays = minHoldDaysByTenor[L.tenorDays];
        uint64 minHoldSecs = uint64(minHoldDays) * 1 days;

        uint64 minFromStart = L.start + minHoldSecs;
        uint64 nowTs = uint64(block.timestamp);
        uint64 waitUntil = nowTs >= minFromStart ? nowTs : minFromStart;

        nextBorrowTime[borrower] = waitUntil;
        emit NextBorrowTimeSet(borrower, waitUntil);

        L.principal   = 0;
        L.amountDue   = 0;
        L.start       = 0;
        L.due         = 0;
        L.feeBps      = 0;
        L.gracePeriod = 0;
        L.tenorDays   = 0;
        L.defaulted   = false;
        L.lastAccrued = 0;

        emit LoanClosed(borrower, paid);
    }

    function isDefaulted(address borrower)
        external
        view
        override
        returns (bool)
    {
        return _loans[borrower].defaulted;
    }

    // ============ LATE FEE (DRP / Mora) ============

    function setPremiumConfig(
        address borrower,
        uint128 premiumRatePerSecWad,
        uint128 lateRatePerSecWad
    ) external override onlyOwner {
        premiums[borrower] = PremiumConfig({
            premiumRatePerSecWad: premiumRatePerSecWad,
            lateRatePerSecWad:    lateRatePerSecWad
        });

        emit PremiumConfigSet(
            borrower,
            premiumRatePerSecWad,
            lateRatePerSecWad
        );
    }

    function previewLoanWithLate(address borrower)
        external
        view
        override
        returns (uint256 principal, uint256 amountDueWithLate)
    {
        Loan memory L = _loans[borrower];
        PremiumConfig memory p = premiums[borrower];

        if (!L.active || p.lateRatePerSecWad == 0) {
            return (L.principal, L.amountDue);
        }

        uint64 nowTs = uint64(block.timestamp);
        uint64 from = L.lastAccrued == 0 ? L.start : L.lastAccrued;
        uint64 lateStart = L.due + L.gracePeriod;

        if (nowTs <= lateStart || nowTs <= from) {
            return (L.principal, L.amountDue);
        }

        uint64 accrualFrom = from > lateStart ? from : lateStart;
        if (nowTs <= accrualFrom) {
            return (L.principal, L.amountDue);
        }

        uint64 tLate = nowTs - accrualFrom;
        uint256 base = uint256(L.amountDue);
        uint256 extraLate =
            (uint256(p.lateRatePerSecWad) * tLate * base) / 1e18;

        return (L.principal, base + extraLate);
    }

    function accrueLate(address borrower) external override onlyOwner {
        Loan storage L = _loans[borrower];
        _accrueLateInternal(borrower, L);
    }

    function _accrueLateInternal(address borrower, Loan storage L) internal {
        if (!L.active) return;

        PremiumConfig memory p = premiums[borrower];
        if (p.lateRatePerSecWad == 0) return;

        uint64 nowTs = uint64(block.timestamp);
        uint64 from = L.lastAccrued == 0 ? L.start : L.lastAccrued;
        uint64 lateStart = L.due + L.gracePeriod;

        if (nowTs <= lateStart || nowTs <= from) {
            L.lastAccrued = nowTs;
            return;
        }

        uint64 accrualFrom = from > lateStart ? from : lateStart;
        if (nowTs <= accrualFrom) {
            L.lastAccrued = nowTs;
            return;
        }

        uint64 tLate = nowTs - accrualFrom;
        uint256 base = uint256(L.amountDue);
        uint256 extraLate =
            (uint256(p.lateRatePerSecWad) * tLate * base) / 1e18;

        L.amountDue   = uint128(base + extraLate);
        L.lastAccrued = nowTs;
    }

    // ============ CONFIG MIN HOLD ============

    function setMinHoldForTenor(uint16 tenorDays, uint16 minHoldDays)
        external
        override
        onlyOwner
    {
        minHoldDaysByTenor[tenorDays] = minHoldDays;
        emit MinHoldSet(tenorDays, minHoldDays);
    }
}