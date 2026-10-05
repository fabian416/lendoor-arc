// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "forge-std/Script.sol";

interface IEVC {
    struct Call { address target; address onBehalfOf; uint256 value; bytes data; }
    function batch(Call[] calldata calls) external;
}
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IPermit2 {
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

contract DepositViaEVC is Script {
    function run() external {
        // ==== Addresses (Optimism, chainId 10) ====
        // ME (your EOA / governor):         0x64D4C6795FDFE795f509dF45C1a0943c2816A94a
        // EVC (EthereumVaultConnector):    0xbfB28650Cd13CE879E7D56569Ed4715c299823E4
        // VAULT (EVK Vault eUSDC-1):       
        // USDC (OP USDC, 6 dec):           0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85
        // PERMIT2 (Uniswap Permit2):       0x000000000022D473030F116dDEE9F6B43aC78BA3
        address ME      = vm.envAddress("ME");
        address EVC     = vm.envAddress("EVC");
        address VAULT   = vm.envAddress("VAULT");
        address USDC    = vm.envAddress("USDC");
        address PERMIT2 = vm.envAddress("PERMIT2");
        IEVC.Call[] memory calls = new IEVC.Call[](1);

        // 0.50 USDC (USDC has 6 decimals)
        uint160 amount = 500_000; 
        uint48  exp    = uint48(block.timestamp + 365 days);

        vm.startBroadcast();

        // 1) Token -> Permit2 (global spender)
        IERC20(USDC).approve(PERMIT2, type(uint256).max);

        // 2) Permit2 -> VAULT for that token (Permit2 internal allowance)
        IPermit2(PERMIT2).approve(USDC, VAULT, type(uint160).max, exp);

        // 3) EVC.batch -> VAULT.deposit(amount, ME)
        bytes memory data = abi.encodeWithSignature("deposit(uint256,address)", amount, ME);
        IEVC.Call;
        calls[0] = IEVC.Call({ target: VAULT, onBehalfOf: ME, value: 0, data: data });
        IEVC(EVC).batch(calls);

        vm.stopBroadcast();
    }
}