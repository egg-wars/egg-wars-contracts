// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ITokenRenderer} from "../src/renderers/ITokenRenderer.sol";
import "../test/BaseTest.sol";

contract AdminTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_eggToken_chickenContract() public {
        EggToken et = new EggToken(address(1), accounts.deployer);
        vm.startPrank(accounts.deployer);
        et.setChickenAddress(chicken);

        vm.expectRevert(bytes("caller is not the chicken token"));
        et.mintEggsWei(address(3), 2 ether);

        vm.expectRevert(bytes("caller is not the chicken token"));
        et.burnEggsWei(address(3), 2 ether);

        vm.stopPrank();
        vm.startPrank(address(chicken));
        et.mintEggsWei(address(3), 2 ether);
        assertEq(et.balanceOf(address(3)), 2 ether, "balance not updated");
    }

    // test setAirnode onlyOwner
    function test_setAirnode_onlyOwner() public {
        Chicken c = new Chicken(
            accounts.deployer,
            eggToken,
            address(airnode),
            renderer
        );
        vm.startPrank(address(9));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(9)
            )
        );
        c.setAirnode(address(3), bytes32(""));

        // test setSponsorWallet onlyOwner
        vm.stopPrank();
        vm.startPrank(address(8));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(8)
            )
        );
        c.setSponsorWallet(address(3));

        // test setTokenRenderer onlyOwner
        vm.stopPrank();
        vm.startPrank(address(7));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(7)
            )
        );
        c.setTokenRenderer(ITokenRenderer(address(3)));

        vm.stopPrank();
        vm.startPrank(address(5));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(5)
            )
        );
        c.setWithdrawalAddress(payable(address(3)));

        // test setSecondsBetweenLays onlyOwner
        vm.stopPrank();
        vm.startPrank(address(4));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(4)
            )
        );
        c.setSecondsBetweenLays(100);

        // test setBirthLikelihoodPercent onlyOwner
        vm.stopPrank();
        vm.startPrank(address(3));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(3)
            )
        );
        c.setBirthLikelihoodPercent(100);

        // test setMaxLevel onlyOwner
        vm.stopPrank();
        vm.startPrank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(2)
            )
        );
        c.setMaxLevel(100);

        // testSetMaxLevel onlyOwner
        vm.stopPrank();
        vm.startPrank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(1)
            )
        );
        c.setMaxLevel(30);

        // setRoyaltyFeeBp onlyOwner
        vm.stopPrank();
        vm.startPrank(address(10));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(10)
            )
        );
        c.setRoyaltyFeeBp(100);

        // requestAirnodeWithdraw onlyOwner
        vm.stopPrank();
        vm.startPrank(address(11));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(11)
            )
        );
        c.requestAirnodeWithdraw();

        // test disableTweakingNumbers onlyOwner
        vm.stopPrank();
        vm.startPrank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(1)
            )
        );
        c.disableTweakingNumbers();

        // test closeAirdrop onlyOwner
        vm.stopPrank();
        vm.startPrank(address(11));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(11)
            )
        );
        c.closeAirdrop();
    }

    // test closeAirdrop functionality
    function test_airdrop() public {
        address[] memory someAddresses = new address[](2);
        someAddresses[0] = address(5);
        someAddresses[1] = address(6);
        vm.startPrank(address(accounts.deployer));
        chicken.airdrop(someAddresses);
        assertEq(chicken.totalSupply(), 2);
        assertEq(chicken.ownerOf(1), address(5));
        assertEq(chicken.ownerOf(2), address(6));
        chicken.closeAirdrop();

        vm.expectRevert(bytes("airdrop not active"));
        chicken.airdrop(someAddresses);
    }
}
