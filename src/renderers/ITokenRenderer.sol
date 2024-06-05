// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../Chicken.sol";

interface ITokenRenderer {
  function tokenData(Chicken chicken, uint256 tokenId) external view returns (string memory);
  function contractData(Chicken chicken) external view returns (string memory);
}
