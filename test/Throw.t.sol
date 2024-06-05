// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import "../test/BaseTest.sol";

contract ThrowTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_throw_success() public {
        deal(address(eggToken), accounts.deployer, 10 ether);
        assertEq(10 ether, eggToken.balanceOf(accounts.deployer));

        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        uint256[] memory eggsToFeed = new uint256[](1);
        eggsToFeed[0] = 3;

        uint256[] memory tokenIdsToPowerUp = new uint256[](1);
        tokenIdsToPowerUp[0] = 2;

        vm.startPrank(accounts.deployer);
        chicken.feed(eggsToFeed, tokenIdsToPowerUp);

        assertEq(chicken.eggLevel(2), 4, "level not updated");

        deal(address(eggToken), address(1), 10 ether);
        chicken.birthChicken(address(1));
        vm.stopPrank();
        vm.startPrank(address(1));

        chicken.throwEgg(2, 2);
        assertEq(
            eggToken.balanceOf(address(1)),
            8 ether,
            "balance not updated not updated"
        );
        assertEq(chicken.eggLevel(2), 2, "level not updated after throw");
    }

    function test_throw_not_enough() public {
        deal(address(eggToken), accounts.deployer, 10 ether);
        assertEq(10 ether, eggToken.balanceOf(accounts.deployer));

        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        uint256[] memory eggsToFeed = new uint256[](1);
        eggsToFeed[0] = 3;

        uint256[] memory tokenIdsToPowerUp = new uint256[](1);
        tokenIdsToPowerUp[0] = 2;

        vm.startPrank(accounts.deployer);
        chicken.feed(eggsToFeed, tokenIdsToPowerUp);

        deal(address(eggToken), address(1), 1 ether);
        chicken.birthChicken(address(1));
        vm.stopPrank();
        vm.startPrank(address(1));
        vm.expectRevert(bytes("not enough eggs"));
        chicken.throwEgg(2, 2);
    }

    function test_throw_min_level() public {
        deal(address(eggToken), accounts.deployer, 10 ether);
        assertEq(10 ether, eggToken.balanceOf(accounts.deployer));

        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        uint256[] memory eggsToFeed = new uint256[](1);
        eggsToFeed[0] = 3;

        uint256[] memory tokenIdsToPowerUp = new uint256[](1);
        tokenIdsToPowerUp[0] = 2;

        vm.startPrank(accounts.deployer);
        chicken.feed(eggsToFeed, tokenIdsToPowerUp);

        assertEq(chicken.eggLevel(2), 4, "level not updated");

        deal(address(eggToken), address(1), 10 ether);
        chicken.birthChicken(address(1));
        vm.stopPrank();
        vm.startPrank(address(1));

        vm.expectRevert(stdError.arithmeticError);
        chicken.throwEgg(2, 4);
    }
}
