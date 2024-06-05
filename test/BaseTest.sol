// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/StdUtils.sol";
import {TestUtils} from "./utils/TestUtils.sol";

import {EggToken} from "../src/EggToken.sol";
import {ChickenModelRenderer} from "../src/renderers/ChickenModelRenderer.sol";
import {ChickenHarness} from "./harnesses/ChickenHarness.sol";
import {MockAirnode} from "./mock/MockAirnode.sol";

struct Accounts {
    address deployer;
    address airdropRecipient;
}

contract BaseTest is Test, TestUtils {
    Accounts internal accounts;

    string internal rendererBaseUrl = "ipfs://baseUrl";

    EggToken eggToken;
    MockAirnode airnode;
    ChickenModelRenderer renderer;
    ChickenHarness chicken;

    function setUp() public virtual {
        _createAccounts();
        _deploy();
    }

    function _deploy() internal {
        vm.startPrank(accounts.deployer);
        airnode = new MockAirnode();
        eggToken = new EggToken(accounts.airdropRecipient, accounts.deployer);
        renderer = new ChickenModelRenderer(rendererBaseUrl);
        chicken = new ChickenHarness(
            accounts.deployer,
            eggToken,
            address(airnode),
            renderer
        );
        eggToken.setChickenAddress(chicken);
        vm.stopPrank();
    }

    function _createAccounts() internal {
        accounts = Accounts({
            deployer: vm.addr(uint256(keccak256("deployer"))),
            airdropRecipient: vm.addr(uint256(keccak256("airdropRecipient")))
        });
    }
}
