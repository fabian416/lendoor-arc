// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";

import {EthereumVaultConnector} from "ethereum-vault-connector/EthereumVaultConnector.sol";
import {GenericFactory} from "evk/GenericFactory/GenericFactory.sol";
import {ProtocolConfig} from "evk/ProtocolConfig/ProtocolConfig.sol";
import {SequenceRegistry} from "evk/SequenceRegistry/SequenceRegistry.sol";
import {Base} from "evk/EVault/shared/Base.sol";
import {Dispatch} from "evk/EVault/Dispatch.sol";
import {EVault} from "evk/EVault/EVault.sol";
import {BalanceForwarder} from "evk/EVault/modules/BalanceForwarder.sol";
import {Borrowing} from "evk/EVault/modules/Borrowing.sol";
import {Governance} from "evk/EVault/modules/Governance.sol";
import {Initialize} from "evk/EVault/modules/Initialize.sol";
import {Liquidation} from "evk/EVault/modules/Liquidation.sol";
import {Token} from "evk/EVault/modules/Token.sol";
import {Vault} from "evk/EVault/modules/Vault.sol";
import {IEVault} from "evk/EVault/IEVault.sol";

import {TestERC20} from "evk-test/mocks/TestERC20.sol";
import {MockBalanceTracker} from "evk-test/mocks/MockBalanceTracker.sol";

import {RiskManagerUncollat} from "../../src/RiskManagerUncollat.sol";
import {LoanManagerV3} from "../../src/LoanManagerV3.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IUncollatVault {
    function setLoanManager(address) external;
    function setCreditLimitManager(address) external;
    function creditLimitManager() external view returns (address);
    function loanManager() external view returns (address);
    function totalWriteOffs() external view returns (uint256);
    function manualWriteOff(address, uint256) external;
    function borrowWithTerm(uint256, address, uint16, uint16) external returns (uint256);
}

/// @notice Monta el stack uncollat igual que los scripts 01/05/06/07 + DeployLoanManager y
/// traba la colision de storage del CLM.
///
/// El bug: `_creditLimitManager` era una variable declarada en RiskManagerUncollatModule. El
/// modulo corre de dos formas sobre el mismo storage — compilado dentro de EVault/Dispatch, y
/// por delegatecall vía `useView(MODULE_RISKMANAGER)` — y el primer slot libre no coincide: 25
/// en EVault, 22 en el modulo suelto, donde EVault tiene `BorrowingModule.totalWriteOffs`.
/// Por eso `accountLiquidity()` leia el write-off en lugar del CLM y revertia con
/// E_InvalidAddress, mientras `creditLimitManager()` devolvia el valor correcto.
contract CreditLimitManagerSlotTest is Test {
    address internal gov = makeAddr("gov");
    address internal depositor = makeAddr("depositor");
    address internal borrower = makeAddr("borrower");

    uint16 internal constant TENOR_DAYS = 7;
    uint16 internal constant FEE_BPS = 160;
    uint256 internal constant LIMIT = 5e6;
    uint256 internal constant DEPOSIT = 5e6;
    uint256 internal constant PRINCIPAL = 1e6;

    EthereumVaultConnector internal evc;
    TestERC20 internal asset;
    IEVault internal vault;
    LoanManagerV3 internal lm;

    function setUp() public {
        vm.warp(1_700_000_000);

        // --- paso 01: integraciones ---
        evc = new EthereumVaultConnector();
        Base.Integrations memory integrations = Base.Integrations({
            evc: address(evc),
            protocolConfig: address(new ProtocolConfig(gov, gov)),
            sequenceRegistry: address(new SequenceRegistry()),
            balanceTracker: address(new MockBalanceTracker()),
            permit2: new DeployPermit2().deployPermit2()
        });

        // --- paso 05: modulos + implementacion ---
        Dispatch.DeployedModules memory m = Dispatch.DeployedModules({
            balanceForwarder: address(new BalanceForwarder(integrations)),
            borrowing: address(new Borrowing(integrations)),
            governance: address(new Governance(integrations)),
            initialize: address(new Initialize(integrations)),
            liquidation: address(new Liquidation(integrations)),
            riskManager: address(new RiskManagerUncollat(integrations)),
            token: address(new Token(integrations)),
            vault: address(new Vault(integrations))
        });
        address implementation = address(new EVault(integrations, m));

        // --- paso 06 + 07: factory y vault (asset = USDC de 6 decimales) ---
        asset = new TestERC20("USDC", "USDC", 6, false);
        GenericFactory factory = new GenericFactory(gov);
        vm.prank(gov);
        factory.setImplementation(implementation);
        vm.prank(gov);
        vault = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(address(asset), address(0), address(asset)))
        );

        // --- DeployLoanManager ---
        LoanManagerV3 impl = new LoanManagerV3();
        lm = LoanManagerV3(
            address(new ERC1967Proxy(address(impl), abi.encodeCall(LoanManagerV3.initialize, (gov, address(vault)))))
        );

        // --- cableado. setHookConfig es obligatorio: initialize() deja TODAS las ops
        //     hookeadas con target 0, o sea deshabilitadas. ---
        vm.startPrank(gov);
        vault.setHookConfig(address(0), 0);
        IUncollatVault(address(vault)).setLoanManager(address(lm));
        IUncollatVault(address(vault)).setCreditLimitManager(address(lm));
        lm.setUserRisk(borrower, 700, true, uint64(block.timestamp + 1 days), LIMIT);
        lm.setLoanOffer(borrower, TENOR_DAYS, FEE_BPS, uint64(block.timestamp + 1 days), LIMIT);
        vm.stopPrank();

        asset.mint(depositor, 100e6);
        asset.mint(borrower, 100e6);
    }

    /// @dev El getter corre en el contexto de EVault y el write-off no se pisa.
    function test_wiring_noPisaElWriteOff() public view {
        assertEq(IUncollatVault(address(vault)).creditLimitManager(), address(lm));
        assertEq(IUncollatVault(address(vault)).loanManager(), address(lm));
        assertEq(IUncollatVault(address(vault)).totalWriteOffs(), 0, "setCreditLimitManager piso totalWriteOffs");
    }

    /// @dev LA prueba de la colision: `accountLiquidity` llega por delegatecall al modulo.
    /// Antes del fix revertia con E_InvalidAddress porque leia el slot 22.
    function test_accountLiquidity_noRevierte_yDevuelveElLimite() public {
        _deposit();
        _enableControllerAndBorrow();

        (uint256 collateralValue, uint256 liabilityValue) = vault.accountLiquidity(borrower, false);
        assertEq(collateralValue, LIMIT, "collateralValue tiene que ser el limite del CLM");
        assertEq(liabilityValue, PRINCIPAL, "liabilityValue tiene que ser la deuda");

        (address[] memory collaterals, uint256[] memory values, uint256 liability) =
            vault.accountLiquidityFull(borrower, false);
        assertEq(collaterals.length, 0);
        assertEq(values.length, 0);
        assertEq(liability, PRINCIPAL);
    }

    /// @dev El mismo slot leido desde los dos contextos tiene que dar lo mismo.
    function test_elModuloYElEVaultLeenElMismoSlot() public {
        _deposit();
        _enableControllerAndBorrow();

        (uint256 fromModule,) = vault.accountLiquidity(borrower, false); // delegatecall al modulo
        uint256 fromEVault = lm.creditLimit(borrower); // fuente de verdad
        assertEq(fromModule, fromEVault, "el modulo y el EVault leen CLMs distintos");
    }

    /// @dev El flujo del Entregable 1, completo.
    function test_flujoEntregable1_depositoPrestamoRepago() public {
        _deposit();
        assertEq(vault.totalAssets(), DEPOSIT);

        _enableControllerAndBorrow();
        assertEq(vault.debtOf(borrower), PRINCIPAL);
        (, uint128 amountDue,,,,, bool active) = lm.loans(borrower);
        assertTrue(active);
        assertEq(amountDue, PRINCIPAL * (10000 + FEE_BPS) / 10000);

        vm.startPrank(borrower);
        asset.approve(address(vault), amountDue);
        vault.repay(amountDue, borrower);
        vm.stopPrank();

        assertEq(vault.debtOf(borrower), 0, "la deuda tiene que quedar en cero");
        assertEq(vault.totalAssets(), DEPOSIT + (amountDue - PRINCIPAL), "el interes queda en el vault");
        (,,,,,, bool stillActive) = lm.loans(borrower);
        assertFalse(stillActive, "closeLoan tiene que apagar el prestamo");
    }

    /// @dev `borrow()` esta deshabilitado a proposito: el entry point es `borrowWithTerm`.
    /// Deja constancia para que el runbook no vuelva a prometer `vault.borrow(...)`.
    function test_borrowPlano_estaDeshabilitado() public {
        _deposit();
        vm.prank(borrower);
        evc.enableController(borrower, address(vault));
        vm.prank(borrower);
        vm.expectRevert();
        vault.borrow(PRINCIPAL, borrower);
    }

    /// @dev Cierra la pregunta abierta de las 860 wallets del write-off: despues de
    /// markDefault + manualWriteOff, ¿el repago entra? Ejecutado, no leido.
    function test_repagoDespuesDelWriteOff() public {
        _deposit();
        _enableControllerAndBorrow();
        (, uint128 amountDue,,,,,) = lm.loans(borrower);

        // default duro: initialize() pone defaultGracePeriod=1d y defaultLatePeriod=15d,
        // asi que el limite es due + 16d = start + 23d. Antes de eso: "too early to default".
        vm.warp(block.timestamp + 24 days);
        vm.prank(gov);
        lm.markDefault(borrower);
        assertTrue(lm.isDefaulted(borrower));

        // write-off del total adeudado al vault
        uint256 owedAlVault = vault.debtOf(borrower);
        vm.prank(gov);
        IUncollatVault(address(vault)).manualWriteOff(borrower, owedAlVault);

        // estado post write-off
        assertEq(vault.debtOf(borrower), 0, "el vault ya no ve deuda");
        assertEq(IUncollatVault(address(vault)).totalWriteOffs(), owedAlVault);
        (,,,,,, bool activeTrasWriteOff) = lm.loans(borrower);
        assertTrue(activeTrasWriteOff, "el write-off NO cierra el prestamo en el LM");

        uint256 assetsAntes = vault.totalAssets();
        uint256 cashAntes = vault.cash();

        // el repago: ¿entra?
        vm.startPrank(borrower);
        asset.approve(address(vault), amountDue);
        vault.repay(amountDue, borrower);
        vm.stopPrank();

        (,,,,,, bool activeTrasRepago) = lm.loans(borrower);
        assertFalse(activeTrasRepago, "el repago si cierra el prestamo");
        assertEq(vault.cash(), cashAntes + amountDue, "el amountDue COMPLETO entra como caja");
        assertEq(vault.totalAssets(), assetsAntes + amountDue, "y suma a totalAssets");

        // pero la linea quedo en cero: markDefault hizo users[b].limit = 0
        assertEq(lm.creditLimit(borrower), 0, "hace falta un setUserRisk off-chain para volver a pedir");
    }

    function _deposit() internal {
        vm.startPrank(depositor);
        asset.approve(address(vault), DEPOSIT);
        vault.deposit(DEPOSIT, depositor);
        vm.stopPrank();
    }

    function _enableControllerAndBorrow() internal {
        vm.prank(borrower);
        evc.enableController(borrower, address(vault));
        vm.prank(borrower);
        IUncollatVault(address(vault)).borrowWithTerm(PRINCIPAL, borrower, TENOR_DAYS, FEE_BPS);
    }
}
