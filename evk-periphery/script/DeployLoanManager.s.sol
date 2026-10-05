// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {LoanManagerV3} from "../src/LoanManagerV3.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLoanManagerProxy is Script {
    function run() external {
        // 1) Leemos la PK desde .env
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        // 2) Opcional: dueño y vault desde env
        //    - OWNER por defecto = deployer
        //    - VAULT debe venir sí o sí por env
        address ownerAddr = vm.envOr("LOAN_MANAGER_OWNER", deployer);
        address vaultAddr = vm.envAddress("LOAN_MANAGER_VAULT");

        console.log("Deployer:", deployer);
        console.log("Owner   :", ownerAddr);
        console.log("Vault   :", vaultAddr);

        vm.startBroadcast(pk);

        // 3) Deploy de la implementación (lógica)
        LoanManagerV3 impl = new LoanManagerV3();
        console.log("Implementation deployed at:", address(impl));

        // 4) Datos para llamar initialize(owner, vault) en el proxy
        bytes memory data = abi.encodeCall(
            LoanManagerV3.initialize,
            (ownerAddr, vaultAddr)
        );

        // 5) Deploy del proxy ERC1967 con la llamada a initialize embebida
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        console.log("Proxy deployed at:", address(proxy));

        // 6) Casteamos el proxy como LoanManagerV3 para futura interacción
        LoanManagerV3 lm = LoanManagerV3(address(proxy));
        console.log("LoanManagerV3 via proxy at:", address(lm));

        vm.stopBroadcast();
    }
}