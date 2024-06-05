// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Chicken} from "../src/Chicken.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ITokenRenderer} from "../src/renderers/ITokenRenderer.sol";
import "../test/BaseTest.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC2981} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

contract InterfaceTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_supportsInterface() public {
        assertTrue(chicken.supportsInterface(type(IERC2981).interfaceId));
        assertTrue(chicken.supportsInterface(type(IERC721).interfaceId));
        assertTrue(!chicken.supportsInterface(type(IERC20).interfaceId));
    }
}
