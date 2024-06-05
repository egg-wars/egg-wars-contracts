// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import "../test/BaseTest.sol";

contract FeedTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_feed_success() public {
        deal(address(eggToken), accounts.deployer, 10 ether);
        assertEq(10 ether, eggToken.balanceOf(accounts.deployer));
        vm.startPrank(accounts.deployer);

        // set up
        chicken.birthChicken(accounts.deployer);
        assertEq(
            chicken.balanceOf(accounts.deployer),
            1,
            "balanceOf not right"
        );
        assertEq(chicken.ownerOf(1), accounts.deployer, "owner not right");
        assertEq(chicken.eggLevel(1), 1, "level not correct");
        uint256 totalSupplyBefore = eggToken.totalSupply();

        // feed
        uint256[] memory numberOfEggsToFeed = new uint256[](1);
        numberOfEggsToFeed[0] = 5;
        uint256[] memory tokenIdsToPowerUp = new uint256[](1);
        tokenIdsToPowerUp[0] = 1;

        chicken.feed(numberOfEggsToFeed, tokenIdsToPowerUp);

        assertEq(
            eggToken.totalSupply(),
            totalSupplyBefore - 5 ether,
            "egg total supply not matching"
        );
        assertEq(chicken.eggLevel(1), 6, "level not updated");
        assertEq(chicken.ownerOf(1), accounts.deployer, "owner not correct");
        assertEq(
            eggToken.balanceOf(accounts.deployer),
            5 ether,
            "balance of not right"
        );

        vm.stopPrank();
    }

    function test_feed_success_multiple() public {
        deal(address(eggToken), accounts.deployer, 10 ether);
        assertEq(10 ether, eggToken.balanceOf(accounts.deployer));
        vm.startPrank(accounts.deployer);

        // set up
        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        uint256 totalSupplyBefore = eggToken.totalSupply();

        // feed
        uint256[] memory numberOfEggsToFeed = new uint256[](3);
        numberOfEggsToFeed[0] = 5;
        numberOfEggsToFeed[1] = 1;
        numberOfEggsToFeed[2] = 3;
        uint256[] memory tokenIdsToPowerUp = new uint256[](3);
        tokenIdsToPowerUp[0] = 1;
        tokenIdsToPowerUp[1] = 3;
        tokenIdsToPowerUp[2] = 2;

        chicken.feed(numberOfEggsToFeed, tokenIdsToPowerUp);

        assertEq(
            eggToken.totalSupply(),
            totalSupplyBefore - 9 ether,
            "egg total supply not matching"
        );
        assertEq(chicken.eggLevel(1), 6, "level not updated");
        assertEq(chicken.eggLevel(3), 2, "level not updated");
        assertEq(chicken.eggLevel(2), 4, "level not updated");
        assertEq(
            eggToken.balanceOf(accounts.deployer),
            1 ether,
            "balance of not right"
        );

        vm.stopPrank();
    }

    function test_feed_not_enough_eggs() public {
        deal(address(eggToken), accounts.deployer, 2 ether);
        assertEq(2 ether, eggToken.balanceOf(accounts.deployer));
        vm.startPrank(accounts.deployer);

        // set up
        chicken.birthChicken(accounts.deployer);
        uint256 totalSupplyBefore = eggToken.totalSupply();
        assertEq(chicken.eggLevel(1), 1, "og level not correct");

        // feed
        uint256[] memory numberOfEggsToFeed0 = new uint256[](1);
        numberOfEggsToFeed0[0] = 3;
        uint256[] memory tokenIdsToPowerUp0 = new uint256[](1);
        tokenIdsToPowerUp0[0] = 1;

        vm.expectRevert(bytes("not enough eggs"));
        chicken.feed(numberOfEggsToFeed0, tokenIdsToPowerUp0);

        assertEq(chicken.eggLevel(1), 1, "end level not correct");
        assertEq(
            totalSupplyBefore,
            eggToken.totalSupply(),
            "egg total supply not matching"
        );
    }

    function test_feed_not_enough_eggs_multiple() public {
        deal(address(eggToken), accounts.deployer, 4 ether);
        assertEq(4 ether, eggToken.balanceOf(accounts.deployer));
        vm.startPrank(accounts.deployer);

        // set up
        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);
        chicken.birthChicken(accounts.deployer);

        uint256 totalSupplyBefore = eggToken.totalSupply();
        assertEq(chicken.eggLevel(1), 1, "og level not correct");
        assertEq(chicken.eggLevel(2), 1, "og level not correct");
        assertEq(chicken.eggLevel(3), 1, "og level not correct");
        assertEq(chicken.eggLevel(4), 1, "og level not correct");

        // feed
        uint256[] memory numberOfEggsToFeed0 = new uint256[](4);
        numberOfEggsToFeed0[0] = 1;
        numberOfEggsToFeed0[1] = 1;
        numberOfEggsToFeed0[2] = 1;
        numberOfEggsToFeed0[3] = 2;
        uint256[] memory tokenIdsToPowerUp0 = new uint256[](4);
        tokenIdsToPowerUp0[0] = 1;
        tokenIdsToPowerUp0[1] = 2;
        tokenIdsToPowerUp0[2] = 3;
        tokenIdsToPowerUp0[3] = 4;

        vm.expectRevert(bytes("not enough eggs"));
        chicken.feed(numberOfEggsToFeed0, tokenIdsToPowerUp0);

        assertEq(chicken.eggLevel(1), 1, "end level not correct");
        assertEq(chicken.eggLevel(2), 1, "end level not correct");
        assertEq(chicken.eggLevel(3), 1, "end level not correct");
        assertEq(chicken.eggLevel(4), 1, "end level not correct");

        assertEq(
            totalSupplyBefore,
            eggToken.totalSupply(),
            "egg total supply not matching"
        );
    }

    function test_feed_doesnt_own() public {
        chicken.birthChicken(accounts.deployer);
        deal(address(eggToken), address(2), 4 ether);
        vm.startPrank(address(2));

        uint256[] memory numberOfEggsToFeed0 = new uint256[](1);
        numberOfEggsToFeed0[0] = 1;

        uint256[] memory tokenIdsToPowerUp0 = new uint256[](1);
        tokenIdsToPowerUp0[0] = 1;

        vm.expectRevert(bytes("must own chicken"));
        chicken.feed(numberOfEggsToFeed0, tokenIdsToPowerUp0);
    }

    function test_feed_max_level() public {
        chicken.birthChicken(accounts.deployer);
        deal(address(eggToken), accounts.deployer, 100 ether);
        vm.startPrank(accounts.deployer);

        uint256[] memory numberOfEggsToFeed0 = new uint256[](1);
        numberOfEggsToFeed0[0] = 19;

        uint256[] memory tokenIdsToPowerUp0 = new uint256[](1);
        tokenIdsToPowerUp0[0] = 1;

        chicken.feed(numberOfEggsToFeed0, tokenIdsToPowerUp0);
        assertEq(chicken.eggLevel(1), 20, "end level not correct");
        assertEq(
            eggToken.balanceOf(accounts.deployer),
            81 ether,
            "end balance not correct"
        );

        uint256[] memory numberOfEggsToFeed1 = new uint256[](1);
        numberOfEggsToFeed1[0] = 1;

        uint256[] memory tokenIdsToPowerUp1 = new uint256[](1);
        tokenIdsToPowerUp1[0] = 1;

        vm.expectRevert(bytes("max level reached"));
        chicken.feed(numberOfEggsToFeed1, tokenIdsToPowerUp1);
    }
}
