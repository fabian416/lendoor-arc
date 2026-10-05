// script/DeployMyRouter.s.sol
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {ScriptUtils} from "./utils/ScriptUtils.s.sol";

interface IEulerRouterFactory {
    function deploy(address governor) external returns (address);
}

contract DeployMyRouter is ScriptUtils {
    // Use the factory already deployed on your network (from the JSON you found)
    address constant ORACLE_ROUTER_FACTORY = 0xA0F284fe1788c389E5F9897e106e600F1D20ee5c;

    function run() public broadcast {
        // Maintains the EVK pattern: governor = getDeployer() (deployer's EOA or multisig if you migrate later)
        address governor = getDeployer();
        address router = IEulerRouterFactory(ORACLE_ROUTER_FACTORY).deploy(governor);

        // (Optional) save to disk as EVK scripts do:
        string memory object;
        object = vm.serializeAddress("router", "router", router);
        vm.writeJson(object, string.concat(vm.projectRoot(), "/script/07_Router_output.json"));
    }
}