// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import "../test/BaseTest.sol";

contract ChickenTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_chicken() public {
        assertTrue(true);
    }

    function testFuzz_birth_chicken_succeeds(uint256 lastTokenId) public {
        lastTokenId = bound(lastTokenId, 0, type(uint256).max - 1);
        chicken.setLastTokenId(lastTokenId);
        address recipient = _randomAddress();
        uint256 recipientBalanceBefore = chicken.balanceOf(recipient);
        // vm.expectEmit(true,true,true,true);
        // emit Transfer
        uint256 newId = chicken.birthChicken(recipient);

        assertEq(newId, lastTokenId + 1, "tokenId not increased");
        assertEq(
            chicken.balanceOf(recipient),
            recipientBalanceBefore + 1,
            "balance not increased"
        );
        assertEq(chicken.eggLevel(newId), 1, "egg level not 1");
    }

    /*
    - feeding, throwing, hatching, laying
    */

    // ==================== withdrawStoredEth

    // should fail when not owner or withdrawal address
    function test_shouldFail_WhenNotOwnerOrWithdrawalAddress() public {
        address user = _randomAddress();
        vm.startPrank(user);
        vm.expectRevert(bytes("caller is not the owner or withdrawalAddress"));
        chicken.withdrawStoredEth(1 ether);
        vm.stopPrank();
    }

    // should fail when withdrawal address not set
    function test_shouldFail_WhenWithdrawalAddressNotSet() public {
        vm.prank(accounts.deployer);
        chicken.setWithdrawalAddress(payable(address(0)));

        vm.startPrank(accounts.deployer);
        vm.expectRevert(bytes("withdrawalAddress not set"));
        chicken.withdrawStoredEth(1 ether);
        vm.stopPrank();
    }

    // should fail when withdrawing too much
    function test_shouldFail_WhenWithdrawalAmountBalanceExceeded(
        uint256 balance
    ) public {
        balance = bound(balance, 10 gwei, 1000 ether);
        vm.deal(address(chicken), balance);
        vm.startPrank(accounts.deployer);
        vm.expectRevert(bytes("amount exceeds balance"));
        chicken.withdrawStoredEth(balance + 1);
        vm.stopPrank();
    }

    // should succeed withdrawing as owner
    function test_shouldSucceed_WithdrawingAsOwner(uint256 balance) public {
        uint256 deployerBalanceBefore = accounts.deployer.balance;
        balance = bound(balance, 1, type(uint256).max - deployerBalanceBefore);
        vm.deal(address(chicken), balance);

        vm.startPrank(accounts.deployer);
        chicken.withdrawStoredEth(balance);
        vm.stopPrank();
        assertEq(address(chicken).balance, 0, "balance not zero");
        assertEq(
            accounts.deployer.balance,
            deployerBalanceBefore + balance,
            "deployer balance incorrect"
        );
    }

    // should succeed withdrawing as withdrawal address
    function test_shouldSucceed_WithdrawingAsWithdrawalAddress(
        uint256 balance
    ) public {
        balance = bound(balance, 1, type(uint40).max);
        address withdrawer = _randomAddress();
        assertEq(withdrawer.balance, 0, "non-zero withdrawer balance");

        vm.deal(address(chicken), balance);

        vm.prank(accounts.deployer);
        chicken.setWithdrawalAddress(payable(withdrawer));

        vm.startPrank(withdrawer);
        chicken.withdrawStoredEth(balance);
        vm.stopPrank();
        assertEq(address(chicken).balance, 0, "balance not zero");
        assertEq(withdrawer.balance, balance, "deployer balance incorrect");
    }

    // ==================== tweaking numbers

    // succeeds setting seconds between lays
    function testFuzz_succeedsWhen_SettingSecondsBetweenLays_AsOwner(
        uint256 delay
    ) public {
        delay = bound(delay, 10 seconds, 14 days);
        vm.startPrank(accounts.deployer);
        chicken.setSecondsBetweenLays(delay);
        assertEq(delay, chicken.secondsBetweenLays(), "delay not set");
        vm.stopPrank();
    }

    // fails when setting delay seconds when tweaking numbers is disabled
    function testFuzz_failsWhen_SettingSecondsBetweenLaysWithTweakingDisabled_AsOwner(
        uint256 delay
    ) public {
        delay = bound(delay, 10 seconds, 14 days);

        vm.startPrank(accounts.deployer);
        chicken.disableTweakingNumbers();
        vm.expectRevert(bytes("numbers can not be tweaked"));
        chicken.setSecondsBetweenLays(delay);
        vm.stopPrank();
    }

    // fails when setting birthlikelihood when tweaking numbers is disabled
    function testFuzz_failsWhen_SettingBirthLikelihoodWithTweakingDisabled_AsOwner(
        uint256 pct
    ) public {
        pct = bound(pct, 0, 99);

        vm.startPrank(accounts.deployer);
        chicken.disableTweakingNumbers();
        vm.expectRevert(bytes("numbers can not be tweaked"));
        chicken.setBirthLikelihoodPercent(pct);
        vm.stopPrank();
    }

    // fails when setting max level when tweaking numbers is disabled
    function testFuzz_failsWhen_SettingMaxLevelWithTweakingDisabled_AsOwner(
        uint256 level
    ) public {
        uint256 existingLevel = chicken.maxLevel();
        vm.assume(level > existingLevel);

        vm.startPrank(accounts.deployer);
        chicken.disableTweakingNumbers();
        vm.expectRevert(bytes("numbers can not be tweaked"));
        chicken.setMaxLevel(level);
        vm.stopPrank();
    }

    // ==================== canLayEggsNow

    // should fail if timestamp exceeded
    function testFuzz_shouldFail_WhenTimestampExceeded(uint256 id) public {
        chicken.setNextTimeToLay(id, block.timestamp + 60 seconds);
        assertFalse(chicken.canLayEggsNow(id), "not false");
    }

    // should succeed if timestamp is below threshold
    function testFuzz_shouldFail_WhenTimestampBelowNextTime(
        uint256 id,
        uint256 time
    ) public {
        time = bound(time, 1, 100 days);
        vm.assume(time > 0);
        chicken.setNextTimeToLay(id, block.timestamp + time);
        vm.warp(block.timestamp + time + 1);
        assertTrue(chicken.canLayEggsNow(id), "not false");
    }

    // ==================== layEggs

    // should fail when caller is not owner
    function test_shouldFail_whenCallerIsNotChickenOwner() public {
        address user = _randomAddress();
        uint256[] memory ids = new uint256[](1);
        ids[0] = chicken.birthChicken(user);

        address newUser = _randomAddress();

        vm.startPrank(newUser);
        vm.expectRevert(bytes("caller is not the owner of the chicken"));
        chicken.layEggs(ids);
        vm.stopPrank();
    }

    // should fail when can't lay eggs
    function testFuzz_shouldFail_WhenCantLayEggsNow(uint256 time) public {
        time = bound(time, 1, type(uint240).max);

        address user = _randomAddress();
        uint256[] memory ids = new uint256[](1);
        ids[0] = chicken.birthChicken(user);
        chicken.setNextTimeToLay(ids[0], block.timestamp + time);

        vm.startPrank(user);
        vm.expectRevert(bytes("not time to lay yet"));
        chicken.layEggs(ids);
        vm.stopPrank();
    }

    // should succeed laying eggs for different chickens with differnet levels
    function testFuzz_shouldSucceed_LayingEggs_AsChickenOnwer(
        uint256 numChickens,
        uint256 time
    ) public {
        numChickens = bound(numChickens, 1, 10);
        time = bound(time, 1, type(uint240).max);

        address user = _randomAddress();
        uint256[] memory ids = new uint256[](numChickens);

        for (uint256 i; i < numChickens; ) {
            ids[i] = chicken.birthChicken(user);
            chicken.setNextTimeToLay(ids[i], block.timestamp + time);
            unchecked {
                ++i;
            }
        }

        vm.warp(block.timestamp + time + 1);

        uint256 totalSupplyBefore = eggToken.totalSupply();
        uint256 userBalance = eggToken.balanceOf(user);
        vm.startPrank(user);

        for (uint256 i; i < numChickens; ) {
            uint256 randLevel = _randomUint256() % 19;
            emit log_named_uint("new level", randLevel);
            chicken.increaseLevel(ids[i], randLevel);
            unchecked {
                ++i;
            }
        }

        uint256 cumulativeEggs = 0;
        for (uint256 i; i < numChickens; ) {
            uint256 level = chicken.eggLevel(ids[i]);
            cumulativeEggs += level * 10 ** 18;
            vm.expectEmit(true, true, true, true);
            emit Chicken.EggsLaid(user, ids[i], level);
            unchecked {
                ++i;
            }
        }
        chicken.layEggs(ids);
        vm.stopPrank();

        emit log_named_uint("cumulativeEggs", cumulativeEggs);

        assertEq(
            eggToken.totalSupply(),
            totalSupplyBefore + cumulativeEggs,
            "totalSupply not right"
        );
        assertEq(
            eggToken.balanceOf(user),
            userBalance + cumulativeEggs,
            "user balance not right"
        );
    }

    // ==================== randomNumberReceived

    // should fail if not pending
    function testFuzz_shouldFail_WhenHatchingStatusNotPending(
        bytes32 id,
        uint256 val
    ) public {
        vm.startPrank(address(airnode));
        bytes memory data = abi.encode(val);
        assertEq(
            uint256(chicken.hatchStatus(id)) !=
                uint256(Chicken.HatchStatus.Pending),
            true,
            "status is pending"
        );
        vm.expectRevert("hatch not pending");
        chicken.randomNumberReceived(id, data);
        vm.stopPrank();
    }

    // should fail if not owner
    function testFuzz_shouldFail_WhenStatusNotPending(
        bytes32 id,
        uint256 val
    ) public {
        address user = _randomAddress();
        chicken.setHatchStatus(id, Chicken.HatchStatus.None);
        chicken.setHatchOwner(id, user);

        vm.startPrank(address(airnode));
        bytes memory data = abi.encode(val);
        vm.expectRevert(bytes("hatch not pending"));
        chicken.randomNumberReceived(id, data);
        vm.stopPrank();
    }

    // should succeed hatching
    function testFuzz_shouldSucceed_WhenHatchFailed(
        bytes32 id,
        uint256 val
    ) public {
        address user = _randomAddress();

        chicken.setHatchStatus(id, Chicken.HatchStatus.Pending);
        chicken.setHatchOwner(id, user);
        uint256 birthLikelihood = chicken.birthLikelihoodPercent();
        uint256 randomNumber = val % 100;
        vm.assume(randomNumber > birthLikelihood);

        vm.startPrank(address(airnode));
        bytes memory data = abi.encode(val);

        vm.expectEmit(true, true, true, true);
        emit Chicken.HatchFailed(user, id, randomNumber);

        chicken.randomNumberReceived(id, data);
        vm.stopPrank();
    }

    // should succeed if hatching fails
    function testFuzz_shouldSucceed_WhenHatchSucceeded(
        bytes32 id,
        uint256 val
    ) public {
        address user = _randomAddress();

        chicken.setHatchStatus(id, Chicken.HatchStatus.Pending);
        chicken.setHatchOwner(id, user);
        uint256 birthLikelihood = chicken.birthLikelihoodPercent();
        uint256 newId = chicken.lastTokenId() + 1;
        uint256 randomNumber = val % 100;
        vm.assume(randomNumber < birthLikelihood);
        vm.startPrank(address(airnode));
        bytes memory data = abi.encode(val);

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), user, newId);

        vm.expectEmit(true, true, true, true);
        emit Chicken.HatchSucceeded(user, id, newId, randomNumber);

        chicken.randomNumberReceived(id, data);
        vm.stopPrank();
    }

    // ==================== lay eggs

    // should fail if not current owner
    function testFuzz_fails_whenNotOwnerOfTokenId(uint256 numIds) public {
        numIds = bound(numIds, 1, 256);

        uint256[] memory ids = new uint256[](numIds);
        uint256 rand;
        for (uint256 i; i < ids.length; ) {
            rand = _randomUint256();
            ids[i] = rand;
            unchecked {
                ++i;
            }
        }

        address user = _randomAddress();
        chicken.batchMint(user, ids);

        // modify the last tokenId

        vm.startPrank(user);
        chicken.safeTransferFrom(user, address(1), ids[ids.length - 1]);

        vm.expectRevert(bytes("caller is not the owner of the chicken"));
        chicken.layEggs(ids);
        vm.stopPrank();
    }

    // should mint
    function test_succeeds_whenUserIsOwner(uint256 numIds) public {
        numIds = bound(numIds, 1, 256);

        uint256[] memory ids = new uint256[](numIds);
        uint256 rand;
        for (uint256 i; i < ids.length; ) {
            rand = _randomUint256();
            ids[i] = rand;
            unchecked {
                ++i;
            }
        }

        address user = _randomAddress();
        chicken.batchMint(user, ids);
        vm.startPrank(user);
        chicken.layEggs(ids);
        vm.stopPrank();
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

    // should fail if balance is too low
    function testFuzz_shouldFail_WhenEggBalanceTooLow(
        bytes32 id,
        uint256 balance
    ) public {
        address user = _randomAddress();
        deal(address(eggToken), user, balance);
        vm.prank(accounts.deployer);
        chicken.setAirnode(address(airnode), id);
        vm.stopPrank();
    }

    // should succeed requesting hatch
}
