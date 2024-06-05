// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/Chicken.sol";

contract MockAirnodeRrp {
    uint256 public currentRequest;
    Chicken public chicken;

    function setChicken(Chicken _chicken) public {
        chicken = _chicken;
    }

    function setSponsorshipStatus(
        address _requester,
        bool _sponsorshipStatus
    ) public pure {
        return;
    }

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32) {
        currentRequest += 1;
        bytes32 requestId = bytes32(currentRequest);
        // uint256(requestId);
        return requestId;
    }

    function pushReceive(bytes32 requestId, uint256 randomValue) public {
        chicken.randomNumberReceived(requestId, abi.encode(randomValue));
    }
}
