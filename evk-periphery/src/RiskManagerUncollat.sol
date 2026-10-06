// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IRiskManager, IEVCVault} from "evk/EVault/IEVault.sol";
import {Base} from "evk/EVault/shared/Base.sol";
import {LiquidityUtils} from "evk/EVault/shared/LiquidityUtils.sol";
import "evk/EVault/shared/types/Types.sol";

interface ICLM { function creditLimit(address account) external view returns (uint256); }

// Gov view mínimo (lo provee el mixin de Governance en Dispatch)
interface IGovernanceView { function governorAdmin() external view returns (address); }

abstract contract RiskManagerUncollatModule is IRiskManager, LiquidityUtils {
    error E_CreditLimitExceeded();
    error E_InvalidAddress();

    /// @dev El CLM vive en un slot FIJO, no en una variable declarada.
    ///
    /// Este módulo se ejecuta de dos maneras sobre el MISMO storage del vault:
    ///   - compilado dentro de EVault/Dispatch (`checkAccountStatus`, el getter y el setter), y
    ///   - por `delegatecall` desde el EVault (`accountLiquidity`, vía `useView(MODULE_RISKMANAGER)`).
    ///
    /// Una variable declarada acá cae en el primer slot libre de CADA contrato, y esos no
    /// coinciden: en el módulo suelto es el 22, que en el EVault es `BorrowingModule.totalWriteOffs`;
    /// en Dispatch/EVault es el 25. Resultado: `accountLiquidity()` leía el write-off en lugar
    /// del CLM y revertía. Con un slot fijo los dos contextos leen el mismo lugar.
    ///
    /// Valor: keccak256("lendoor.evault.creditLimitManager")
    bytes32 private constant CLM_SLOT = 0x27873fc74990e43524195687634004a774b8e650648522b7816d3e2888ce7d43;

    function _clmSlotRead() private view returns (address clm) {
        assembly {
            clm := sload(CLM_SLOT)
        }
    }

    function _clmSlotWrite(address clm) private {
        assembly {
            sstore(CLM_SLOT, clm)
        }
    }

    event CreditLimitManagerUpdated(address indexed oldCLM, address indexed newCLM);

    // Usa governorAdmin() del VAULT (mixin de Governance)
    modifier onlyGov() {
        if (IGovernanceView(address(this)).governorAdmin() != msg.sender) revert E_Unauthorized();
        _;
    }

    // GETTER simple (sin default hardcodeado)
    function creditLimitManager() public view returns (address) {
        return _clmSlotRead();
    }

    // SETTER gobernado
    function setCreditLimitManager(address clm)
        external
        virtual
        nonReentrant
        onlyGov
    {
        if (clm == address(0)) revert E_InvalidAddress();
        address old = _clmSlotRead();
        _clmSlotWrite(clm); // escribe en storage del VAULT, en CLM_SLOT
        emit CreditLimitManagerUpdated(old, clm);
    }

    // ---------------- Lógica uncollateral ----------------

    function accountLiquidity(address account, bool /*liquidation*/)
        public
        view
        virtual
        nonReentrantView
        returns (uint256 collateralValue, uint256 liabilityValue)
    {
        VaultCache memory vaultCache = loadVault();
        validateController(account);

        liabilityValue = getCurrentOwed(vaultCache, account).toAssetsUp().toUint();

        address clm = creditLimitManager();
        if (clm == address(0)) revert E_InvalidAddress();

        collateralValue = ICLM(clm).creditLimit(account);
    }

    function accountLiquidityFull(address account, bool liquidation)
        public
        view
        virtual
        override
        nonReentrantView
        returns (address[] memory collaterals, uint256[] memory collateralValues, uint256 liabilityValue) 
        {                                                               
            // sin colaterales (uncollat)                                                                                                                                             
            collaterals = new address[](0);                                                                       
            collateralValues = new uint256[](0);                                                                  
            (, liabilityValue) = accountLiquidity(account, liquidation);                                          
        }                                        

    function checkAccountStatus(address account, address[] calldata /*collaterals*/)
        public
        view
        virtual
        reentrantOK
        onlyEVCChecks
        returns (bytes4 magicValue)
    {
        VaultCache memory vaultCache = loadVault();
        uint256 owed = getCurrentOwed(vaultCache, account).toAssetsUp().toUint();

        address clm = creditLimitManager();
        if (clm == address(0)) revert E_InvalidAddress();

        uint256 limit = ICLM(clm).creditLimit(account);
        if (owed > limit) revert E_CreditLimitExceeded();

        magicValue = IEVCVault.checkAccountStatus.selector;
    }

    function disableController() public virtual nonReentrant {
        address account = EVCAuthenticate();
        if (!vaultStorage.users[account].getOwed().isZero()) revert E_OutstandingDebt();
        disableControllerInternal(account);
    }

    function checkVaultStatus() public virtual reentrantOK onlyEVCChecks returns (bytes4 magicValue) {
        VaultCache memory vaultCache = updateVault();
        uint256 newRate = computeInterestRate(vaultCache);
        logVaultStatus(vaultCache, newRate);

        if (vaultCache.snapshotInitialized) {
            vaultStorage.snapshotInitialized = vaultCache.snapshotInitialized = false;

            Assets snapshotCash = snapshot.cash;
            Assets snapshotBorrows = snapshot.borrows;

            uint256 prevBorrows = snapshotBorrows.toUint();
            uint256 borrows = vaultCache.totalBorrows.toAssetsUp().toUint();
            if (borrows > vaultCache.borrowCap && borrows > prevBorrows) revert E_BorrowCapExceeded();

            uint256 prevSupply = snapshotCash.toUint() + prevBorrows;
            uint256 supply = vaultCache.cash.toUint() + vaultCache.totalBorrows.toAssetsDown().toUint();
            if (supply > vaultCache.supplyCap && supply > prevSupply) revert E_SupplyCapExceeded();

            snapshot.reset();
        }

        callHookWithLock(vaultCache.hookedOps, OP_VAULT_STATUS_CHECK, address(evc));
        magicValue = IEVCVault.checkVaultStatus.selector;
    }
}

// (opcional) wrapper desplegable si quieres seguir el patrón de Euler para MODULE_RISKMANAGER
contract RiskManagerUncollat is RiskManagerUncollatModule {
    constructor(Integrations memory integrations) Base(integrations) {}
}