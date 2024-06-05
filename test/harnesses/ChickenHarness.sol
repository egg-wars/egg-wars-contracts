// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "../../src/Chicken.sol";
import "../../src/EggToken.sol";
import "../../src/renderers/ITokenRenderer.sol";

/// @notice Harness contract for testing that exposes internal Chicken logic
contract ChickenHarness is Chicken {
    constructor(
        address _owner,
        EggToken _eggToken,
        address _airnodeRrp,
        ITokenRenderer _renderer
    ) Chicken(_owner, _eggToken, _airnodeRrp, _renderer) {}

    function setNextTimeToLay(uint256 tokenId, uint256 time) public {
        nextTimeToLay[tokenId] = time;
    }

    function setHatchStatus(bytes32 id, HatchStatus status) public {
        hatchStatus[id] = status;
    }

    function setHatchOwner(bytes32 id, address owner) public {
        hatchOwner[id] = owner;
    }

    function setLastTokenId(uint256 id) public {
        lastTokenId = id;
    }

    function birthChicken(address birthTo) public returns (uint256) {
        return _birthChicken(birthTo);
    }

    function decreaseLevel(uint256 tokenId, uint256 amountToDecrease) public {
        _decreaseLevel(tokenId, amountToDecrease);
    }

    function increaseLevel(uint256 tokenId, uint256 amountToIncrease) public {
        _increaseLevel(tokenId, amountToIncrease);
    }

    function batchMint(address receiver, uint256[] calldata ids) public {
        for (uint256 i; i < ids.length; ) {
            _safeMint(receiver, ids[i]);
            unchecked {
                ++i;
            }
        }
    }
}
