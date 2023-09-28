// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /*
    * @param minDelay the minimum delay for a proposal before it is executed
    * @param proposers the list of addresses that can propose a new proposal
    * @param executors the list of addresses that can execute a proposal
    */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors)
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}
}
