// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IBorrowing} from "../IEVault.sol";
import {Base} from "../shared/Base.sol";
import {BalanceUtils} from "../shared/BalanceUtils.sol";
import {LiquidityUtils} from "../shared/LiquidityUtils.sol";
import {AssetTransfers} from "../shared/AssetTransfers.sol";
import {SafeERC20Lib} from "../shared/lib/SafeERC20Lib.sol";
import {ProxyUtils} from "../../EVault/shared/lib/ProxyUtils.sol";
import {IFlashLoan} from "../../interfaces/IFlashLoan.sol";

import "../shared/types/Types.sol";

/// @dev Mínima vista de gobernanza que expone el EVault (mixin Governance en Dispatch)
error MustRepayFullAmountDue();
error BorrowDisabled();
error NoActiveLoan();
error LoanManagerNotSet();
error PullDebtDisabled();

interface IGovernanceView {
    function governorAdmin() external view returns (address);
}

interface ILoanManager {
    function loans(address) external view returns (
        uint128 principal,
        uint128 amountDue,
        uint64  start,
        uint64  due,
        uint16  feeBps,
        uint32  gracePeriod, 
        bool    active
    );

    function premiums(address) external view returns (
        uint128 premiumRatePerSecWad,
        uint128 lateRatePerSecWad
    );

    function openLoan(
        address borrower,
        uint256 principal,
        uint16 tenorDays,
        uint16 feeBps
    ) external;

    function closeLoan(
        address borrower,
        uint256 paid
    ) external;

    function isDefaulted(address borrower) external view returns (bool);

}

/// @title BorrowingModule
/// @notice Módulo de borrowing del EVault + integración con LoanManager (DRP + late)
abstract contract BorrowingModule is IBorrowing, AssetTransfers, BalanceUtils, LiquidityUtils {
    using TypesLib for uint256;
    using SafeERC20Lib for IERC20;

    uint256 internal constant WAD = 1e18;
    uint256 public totalWriteOffs;

     // =========================
    // PROTOCOL FEE SOBRE INTERÉS LM
    // =========================

    /// @notice 5% del interés (no del principal)
    uint16 public constant PROTOCOL_FEE_BPS = 500; // 500 / 1e4 = 5%

    /// @notice address donde mandamos el fee del protocolo
    address public protocolFeeRecipient;

    // =========================
    // PREMIUMS / LATE 
    // =========================

    /// @notice LoanManager externo que guarda Loan + PremiumConfig
    ILoanManager public loanManager;


    event LoanManagerSet(address indexed lm);
    event WriteOff(address indexed borrower, uint256 amount);
    event ProtocolFeeRecipientSet(address indexed recipient);
    /// @dev Usa governorAdmin() del EVault (mixin Governance en Dispatch)
    modifier onlyGovCLM() {
        address gov = IGovernanceView(address(this)).governorAdmin();
        require(msg.sender == gov, "not gov");
        _;
    }

    function setLoanManager(address _lm) external onlyGovCLM nonReentrant {
        require(_lm != address(0), "lm=0");
        loanManager = ILoanManager(_lm);
        emit LoanManagerSet(_lm);
    }

    // =========================
    // VIEW HELPERS
    // =========================

    function totalBorrows() public view virtual nonReentrantView returns (uint256) {
        return loadVault().totalBorrows.toAssetsUp().toUint();
    }

    function totalBorrowsExact() public view virtual nonReentrantView returns (uint256) {
        return loadVault().totalBorrows.toUint();
    }

    function cash() public view virtual nonReentrantView returns (uint256) {
        return vaultStorage.cash.toUint();
    }

    function debtOf(address account) public view virtual nonReentrantView returns (uint256) {
        return getCurrentOwed(loadVault(), account).toAssetsUp().toUint();
    }

    function debtOfExact(address account) public view virtual nonReentrantView returns (uint256) {
        return getCurrentOwed(loadVault(), account).toUint();
    }

    function interestRate() public view virtual nonReentrantView returns (uint256) {
        return computeInterestRateView(loadVault());
    }

    function interestAccumulator() public view virtual nonReentrantView returns (uint256) {
        return loadVault().interestAccumulator;
    }

    function dToken() public view virtual reentrantOK returns (address) {
        return calculateDTokenAddress();
    }

    // =========================
    // CORE: BORROW / REPAY
    // =========================

    /// @inheritdoc IBorrowing
    function borrow(uint256, address) public virtual override nonReentrant returns (uint256) {
    revert BorrowDisabled();
    }

    /// @notice Borrow + registrar microloan en LoanManager (tenor + feeBps fijo)
    function borrowWithTerm(
        uint256 amount,
        address receiver,
        uint16 tenorDays,
        uint16 feeBps
    )
        public
        virtual
        nonReentrant
        returns (uint256)
    {
        if (address(loanManager) == address(0)) {
            revert LoanManagerNotSet();
        }

        (VaultCache memory vaultCache, address account) =
            initOperation(OP_BORROW, CHECKACCOUNT_CALLER);

        Assets assets = amount == type(uint256).max ? vaultCache.cash : amount.toAssets();
        if (assets.isZero()) return 0;
        if (assets > vaultCache.cash) revert E_InsufficientCash();

        increaseBorrow(vaultCache, account, assets);
        pushAssets(vaultCache, receiver, assets);

        // loanManager está garantizado ≠ 0 acá
        loanManager.openLoan(account, assets.toUint(), tenorDays, feeBps);

        return assets.toUint();
    }
    /// @inheritdoc IBorrowing
    // =========================
    // CORE: BORROW / REPAY
    // =========================

    /// @inheritdoc IBorrowing
    
        function repay(uint256 amount, address receiver) public virtual nonReentrant returns (uint256) {
        // payer = quien manda el USDC, receiver = deudor cuya deuda bajamos
        (VaultCache memory vaultCache, address payer) = initOperation(OP_REPAY, CHECKACCOUNT_NONE);

        if (address(loanManager) == address(0)) {
            revert LoanManagerNotSet();
        }

        // 1) leemos el loan en el LoanManager
        (
            uint128 principal,      // <--- ahora SÍ lo usamos
            uint128 amountDue,      // principal + fee fijo acordado en LM
            ,                       // start
            ,                       // due
            ,                       // feeBps
            ,                       // gracePeriod
            bool   active
        ) = loanManager.loans(receiver);

        // 2) exigimos que haya loan activo
        if (!active || amountDue == 0) {
            revert NoActiveLoan();
        }

        // 3) deuda actual en el vault (principal + IRM del EVault si existiera)
        uint256 owed = getCurrentOwed(vaultCache, receiver).toAssetsUp().toUint();

        // 4) No aceptamos pagos parciales:
        if (amount != type(uint256).max && amount != uint256(amountDue)) {
            revert MustRepayFullAmountDue();
        }

        // Forzamos que el payAmount sea SIEMPRE amountDue
        uint256 payAmount = uint256(amountDue);

        // Parte que realmente baja deuda en el EVault
        uint256 debtPart = payAmount < owed ? payAmount : owed;

        // CÁLCULO DEL FEE DE PROTOCOLO

        // interés fijo según LoanManager (amountDue - principal)
        uint256 interestPart = 0;
        if (payAmount > uint256(principal)) {
            interestPart = payAmount - uint256(principal);
        }

        uint256 protocolFee = 0;

        if (
            protocolFeeRecipient != address(0) &&
            PROTOCOL_FEE_BPS > 0 &&
            interestPart > 0
        ) {
            // margen "extra" por encima de la deuda real que estamos cancelando
            uint256 margin = payAmount > debtPart ? (payAmount - debtPart) : 0;

            // base sobre la que podemos cobrar fee sin romper contabilidad
            uint256 feeBase = interestPart < margin ? interestPart : margin;

            if (feeBase > 0) {
                protocolFee = (feeBase * PROTOCOL_FEE_BPS) / 1e4; // 5% del interés
            }
        }

        // 5) mover TODO lo que el user tiene que pagar hacia el vault (principal + fee)
        Assets assetsToPull = payAmount.toAssets();
        pullAssets(vaultCache, payer, assetsToPull);

        // 6) enviar fee de protocolo si corresponde
        if (protocolFee > 0) {
            (IERC20 asset,,) = ProxyUtils.metadata();
            asset.safeTransfer(protocolFeeRecipient, protocolFee);
        }

        // 7) bajar la deuda del EVault solo por la parte de deuda
        if (debtPart > 0) {
            Assets debtAssets = debtPart.toAssets();
            decreaseBorrow(vaultCache, receiver, debtAssets);
        }

        // 8) cerrar el microloan en el LoanManager
        loanManager.closeLoan(receiver, payAmount);

        // devolvemos cuánto se pagó en assets
        return assetsToPull.toUint();
    }

    /// @inheritdoc IBorrowing
    function repayWithShares(uint256, address)
        public
        virtual
        override
        nonReentrant
        returns (uint256, uint256)
    {
        revert("repayWithShares disabled for Lendoor");
    }
    function pullDebt(uint256, address) public virtual nonReentrant {
        revert PullDebtDisabled();
    }

    function flashLoan(uint256 amount, bytes calldata data) public virtual nonReentrant {
        address account = EVCAuthenticate();
        callHook(vaultStorage.hookedOps, OP_FLASHLOAN, account);

        (IERC20 asset,,) = ProxyUtils.metadata();
        uint256 origBalance = asset.balanceOf(address(this));

        asset.safeTransfer(account, amount);
        IFlashLoan(account).onFlashLoan(data);

        if (asset.balanceOf(address(this)) < origBalance) revert E_FlashLoanNotRepaid();
    }

    function touch() public virtual nonReentrant {
        initOperation(OP_TOUCH, CHECKACCOUNT_NONE);
    }

    // =========================
    // MANUAL WRITE OFF
    // =========================

    function manualWriteOff(address borrower, uint256 amount)
        external
        onlyGovCLM
        nonReentrant
    {
        if (!loanManager.isDefaulted(borrower)) {
            revert("loan not defaulted");
        }

        VaultCache memory vaultCache = loadVault();

        uint256 owed = getCurrentOwed(vaultCache, borrower).toAssetsUp().toUint();
        if (owed == 0) return;

        uint256 toWriteOff = amount > owed ? owed : amount;

        Assets wAssets = toWriteOff.toAssets();
        decreaseBorrow(vaultCache, borrower, wAssets);

        totalWriteOffs += toWriteOff;

        emit WriteOff(borrower, toWriteOff);
    }

    function setProtocolFeeRecipient(address recipient) external onlyGovCLM {
        require(recipient != address(0), "fee recipient = 0");
        protocolFeeRecipient = recipient;
        emit ProtocolFeeRecipientSet(recipient);
    }
}

/// @dev Deployable module contract
contract Borrowing is BorrowingModule {
    constructor(Integrations memory integrations) Base(integrations) {}
}