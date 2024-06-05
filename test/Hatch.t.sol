// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import "../test/BaseTest.sol";
import "../test/mock/MockAirnodeRrp.sol";

contract HatchTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    // ====================== requestHatch

    // should fail if airnode not set
    function test_souldFail_WhenAirnodeAddressNotSet() public {
        vm.expectRevert(bytes("airnode not set"));
        chicken.requestHatch(1);
    }

    // should fail if endpointId not set
    function test_shouldFail_WhenEndpointIdNotSet() public {
        vm.prank(accounts.deployer);
        chicken.setAirnode(address(airnode), bytes32(0));
        vm.expectRevert(bytes("endpointIdUint256 not set"));
        chicken.requestHatch(1);
    }

    // should fail if sponsor wallet not set
    function test_shouldFail_WhenSponsorWalletNotSet(bytes32 id) public {
        vm.assume(id != bytes32(0));
        vm.prank(accounts.deployer);
        chicken.setAirnode(address(airnode), id);
        vm.expectRevert(bytes("sponsorWallet not set"));
        chicken.requestHatch(1);
    }

    function test_successfulHatch() public {
        vm.startPrank(address(accounts.deployer));

        MockAirnodeRrp mockAirnodeRrp = new MockAirnodeRrp();
        EggToken et = new EggToken(
            accounts.airdropRecipient,
            accounts.deployer
        );
        ChickenModelRenderer cmr = new ChickenModelRenderer("ipfs://baseUrl");
        Chicken c = new Chicken(
            accounts.deployer,
            et,
            address(mockAirnodeRrp),
            cmr
        );
        et.setChickenAddress(c);
        mockAirnodeRrp.setChicken(c);
        c.setAirnode(address(1), bytes32("1"));
        c.setSponsorWallet(address(2));

        vm.expectRevert(bytes("not enough eggs"));
        c.requestHatch(1);

        deal(address(et), accounts.deployer, 100 ether);
        c.requestHatch(1);
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) == Chicken.HatchStatus.Pending,
            true,
            "hatch status not pending"
        );
        assertEq(et.balanceOf(accounts.deployer), 99 ether);

        assertEq(c.balanceOf(accounts.deployer), 0);
        mockAirnodeRrp.pushReceive(bytes32(mockAirnodeRrp.currentRequest()), 9);
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) == Chicken.HatchStatus.Hatched,
            true,
            "hatch status not updated"
        );
        assertEq(c.balanceOf(accounts.deployer), 1);
    }

    // test failure hatch
    function test_failureHatch() public {
        vm.startPrank(address(accounts.deployer));

        MockAirnodeRrp mockAirnodeRrp = new MockAirnodeRrp();
        EggToken et = new EggToken(
            accounts.airdropRecipient,
            accounts.deployer
        );
        ChickenModelRenderer cmr = new ChickenModelRenderer("ipfs://baseUrl");
        Chicken c = new Chicken(
            accounts.deployer,
            et,
            address(mockAirnodeRrp),
            cmr
        );
        et.setChickenAddress(c);
        mockAirnodeRrp.setChicken(c);
        c.setAirnode(address(1), bytes32("1"));
        c.setSponsorWallet(address(2));

        deal(address(et), accounts.deployer, 100 ether);
        c.requestHatch(1);
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) == Chicken.HatchStatus.Pending,
            true,
            "hatch status not pending"
        );
        assertEq(et.balanceOf(accounts.deployer), 99 ether);

        assertEq(c.balanceOf(accounts.deployer), 0);
        mockAirnodeRrp.pushReceive(
            bytes32(mockAirnodeRrp.currentRequest()),
            34920849032894239048392943892 // % 100 = 96
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status not correct"
        );
        assertEq(c.balanceOf(accounts.deployer), 0);
    }

    // try sending in request id that is already filled
    function test_alreadyFilled() public {
        vm.startPrank(address(accounts.deployer));

        MockAirnodeRrp mockAirnodeRrp = new MockAirnodeRrp();
        EggToken et = new EggToken(
            accounts.airdropRecipient,
            accounts.deployer
        );
        ChickenModelRenderer cmr = new ChickenModelRenderer("ipfs://baseUrl");
        Chicken c = new Chicken(
            accounts.deployer,
            et,
            address(mockAirnodeRrp),
            cmr
        );
        et.setChickenAddress(c);
        mockAirnodeRrp.setChicken(c);
        c.setAirnode(address(1), bytes32("1"));
        c.setSponsorWallet(address(2));

        vm.expectRevert(bytes("not enough eggs"));
        c.requestHatch(1);

        deal(address(et), accounts.deployer, 100 ether);
        c.requestHatch(1);
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) == Chicken.HatchStatus.Pending,
            true,
            "hatch status not pending"
        );
        assertEq(et.balanceOf(accounts.deployer), 99 ether);

        assertEq(c.balanceOf(accounts.deployer), 0);
        mockAirnodeRrp.pushReceive(bytes32(mockAirnodeRrp.currentRequest()), 9);
        assertEq(
            c.hatchStatus(bytes32(uint256(1))) == Chicken.HatchStatus.Hatched,
            true,
            "hatch status not updated"
        );
        assertEq(c.balanceOf(accounts.deployer), 1);

        string memory revertedReason;
        try
            mockAirnodeRrp.pushReceive(
                bytes32(mockAirnodeRrp.currentRequest()),
                9
            )
        {} catch Error(string memory reason) {
            revertedReason = reason;
        }
        assertEq(revertedReason, "hatch not pending");
        assertEq(c.balanceOf(accounts.deployer), 1);
    }

    // test multiple hatches from multiple people
    function test_multipleHatches() public {
        vm.startPrank(address(accounts.deployer));

        MockAirnodeRrp mockAirnodeRrp = new MockAirnodeRrp();
        EggToken et = new EggToken(
            accounts.airdropRecipient,
            accounts.deployer
        );
        ChickenModelRenderer cmr = new ChickenModelRenderer("ipfs://baseUrl");
        Chicken c = new Chicken(
            accounts.deployer,
            et,
            address(mockAirnodeRrp),
            cmr
        );
        et.setChickenAddress(c);
        c.setAirnode(address(1), bytes32("1"));
        c.setSponsorWallet(address(2));
        mockAirnodeRrp.setChicken(c);

        vm.stopPrank();

        // set up accounts
        address steve = _randomAddress();
        deal(address(et), steve, 100 ether);
        address jeremy = _randomAddress();
        deal(address(et), jeremy, 15 ether);
        address joshua = _randomAddress();
        deal(address(et), joshua, 3 ether);

        // request hatch
        vm.prank(steve);
        c.requestHatch(3);

        vm.prank(jeremy);
        c.requestHatch(5);

        vm.prank(joshua);
        c.requestHatch(2);

        // ensure all burned
        assertEq(et.balanceOf(steve), 97 ether, "steve balance not updated");
        assertEq(et.balanceOf(jeremy), 10 ether, "jeremy balance not updated");
        assertEq(et.balanceOf(joshua), 1 ether, "joshua balance not updated");

        // steve had second one work
        mockAirnodeRrp.pushReceive(bytes32(uint256(1)), 119); // 19
        mockAirnodeRrp.pushReceive(bytes32(uint256(2)), 108); // 8
        mockAirnodeRrp.pushReceive(bytes32(uint256(3)), 130); // 30

        // jeremy had first two work
        mockAirnodeRrp.pushReceive(bytes32(uint256(4)), 105); // 5
        mockAirnodeRrp.pushReceive(bytes32(uint256(5)), 103); // 3
        mockAirnodeRrp.pushReceive(bytes32(uint256(6)), 119); // 19
        mockAirnodeRrp.pushReceive(bytes32(uint256(7)), 119); // 19
        mockAirnodeRrp.pushReceive(bytes32(uint256(8)), 119); // 19

        // joshua had none work
        mockAirnodeRrp.pushReceive(bytes32(uint256(9)), 119); // 19
        mockAirnodeRrp.pushReceive(bytes32(uint256(10)), 119); // 19

        assertEq(c.balanceOf(steve), 1, "steve balance not updated");
        assertEq(c.ownerOf(1), address(steve), "steve chicken 1 not set");

        assertEq(c.balanceOf(jeremy), 2, "jeremy balance not updated");
        assertEq(c.ownerOf(2), address(jeremy), "jeremy chicken 2 not set");
        assertEq(c.ownerOf(3), address(jeremy), "jeremy chicken 3 not set");

        assertEq(c.balanceOf(joshua), 0, "joshua balance not updated");

        assertEq(
            c.hatchStatus(bytes32(uint256(1))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 1 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(2))) == Chicken.HatchStatus.Hatched,
            true,
            "hatch status 2 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(3))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 3 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(4))) == Chicken.HatchStatus.Hatched,
            true,
            "hatch status 4 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(5))) == Chicken.HatchStatus.Hatched,
            true,
            "hatch status 5 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(6))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 6 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(7))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 7 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(8))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 8 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(9))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 9 not updated"
        );
        assertEq(
            c.hatchStatus(bytes32(uint256(10))) ==
                Chicken.HatchStatus.NotHatched,
            true,
            "hatch status 10 not updated"
        );

        // test owners
        assertEq(c.hatchOwner(bytes32(uint256(1))), address(steve));
        assertEq(c.hatchOwner(bytes32(uint256(2))), address(steve));
        assertEq(c.hatchOwner(bytes32(uint256(3))), address(steve));

        assertEq(c.hatchOwner(bytes32(uint256(4))), address(jeremy));
        assertEq(c.hatchOwner(bytes32(uint256(5))), address(jeremy));
        assertEq(c.hatchOwner(bytes32(uint256(6))), address(jeremy));
        assertEq(c.hatchOwner(bytes32(uint256(7))), address(jeremy));
        assertEq(c.hatchOwner(bytes32(uint256(8))), address(jeremy));

        assertEq(c.hatchOwner(bytes32(uint256(9))), address(joshua));
        assertEq(c.hatchOwner(bytes32(uint256(10))), address(joshua));
    }
}
