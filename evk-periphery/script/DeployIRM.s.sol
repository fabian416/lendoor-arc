// script/DeployIRM.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ScriptUtils} from "./utils/ScriptUtils.s.sol";

interface IIRM {
    error E_IRMUpdateUnauthorized();
    function computeInterestRate(address vault, uint256, uint256) external returns (uint256);
    function computeInterestRateView(address vault, uint256, uint256) external view returns (uint256);
}

contract TestIRMFixedAPR is IIRM {
    uint256 public immutable ratePerSecondRay;
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    constructor(uint256 aprBps) {
        ratePerSecondRay = (aprBps * 1e27) / 10_000 / SECONDS_PER_YEAR;
    }
    function computeInterestRate(address vault, uint256, uint256) external view override returns (uint256) {
        if (msg.sender != vault) revert E_IRMUpdateUnauthorized();
        return ratePerSecondRay;
    }
    function computeInterestRateView(address, uint256, uint256) external view override returns (uint256) {
        return ratePerSecondRay;
    }
}

contract DeployIRM is ScriptUtils {
    function run() external {
        vm.startBroadcast();
        // 10000 bps = 100% APR
        TestIRMFixedAPR irm = new TestIRMFixedAPR(1200);

        vm.stopBroadcast();
    }
}