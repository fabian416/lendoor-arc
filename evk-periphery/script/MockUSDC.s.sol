// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "@forge/src/Script.sol";
import {console2} from "@forge/src/Console2.sol";
 // Usando tu import existente hacia OpenZeppelin dentro del repo:
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @notice Mock USDC-like token (6 decimales) con mint() pública para TESTNETS.
/// NO usar en mainnet.
contract MockUSDC is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    /// @notice Mint público (cualquiera puede acuñar en test).
    /// @param to destino
    /// @param amount en unidades mínimas (p.ej. 1 USDC = 1_000_000 si 6 decimales)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice USDC usa 6 decimales.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract DeployMockUSDC is Script {
    function run() external {
        vm.startBroadcast();

        // Cambiá nombre/símbolo si querés
        MockUSDC token = new MockUSDC("Mock USDC", "mUSDC", 6);

        // Opcional: mint inicial al deployer (1,000 USDC => 1_000 * 10^6)
        token.mint(msg.sender, 1_000 * 10 ** 6);

        console2.log("MockUSDC deployed at:", address(token));

        vm.stopBroadcast();
    }
}