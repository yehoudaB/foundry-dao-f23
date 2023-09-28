// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor public governor;
    Box public box;
    GovToken public govToken;
    TimeLock public timelock;
    address public USER = makeAddr("user");
    uint256 public constant MIN_DELAY = 3600; // 1 hour after vote is passed
    address[] public proposers; // if empty, anyone can propose
    address[] public executors; // if empty, anyone can execute
    uint256[] values;
    bytes[] calldatas;
    address[] targets;
    uint256 public constant VOTING_DELAY = 1; // how many blocks tills vote is active (1 block)
    uint256 public constant VOTING_PERIOD = 50400; // how many blocks till vote is closed (1 week)

    function setUp() public {
        govToken = new GovToken(USER, 100 ether);
        vm.startPrank(USER);
        govToken.delegate(USER);

        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor)); // only governor can propose votes
        timelock.grantRole(executorRole, address(0)); // anybody can execute votes
        timelock.revokeRole(adminRole, USER); // USER will not longer the admin of the timelock
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock)); // timelock will be the owner of the box (And the DAO own the timelock)
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        vm.startPrank(USER);
        box.store(1);
        vm.stopPrank();
    }

    function testGovernanceUpdateBox() public {
        uint256 valueToStore = 888;
        string memory description = "Store 888 in box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // 2. View the state
        console.log("Proposal state: %s", uint256(governor.state(proposalId))); // should be Pending (0)
        vm.warp(block.timestamp + VOTING_DELAY + 1); // simulate time passing
        vm.warp(block.number + VOTING_DELAY + 1); // simulate block passing
        console.log("Proposal state: %s", uint256(governor.state(proposalId))); // should be Active (1)

        string memory reason = "because I really want to";
        uint8 voteWay = 1; //  0 = against, 1 = for, 2 = abstain

        vm.startPrank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);
        vm.warp(block.timestamp + VOTING_PERIOD + 1); // simulate time passing
        vm.warp(block.number + VOTING_PERIOD + 1); // simulate block passing

        // 2. Queue the TX

        vm.stopPrank();
    }
}
