// SPDX-License-Identifier: UNLICENSED

//
//                    //
//  ww_          ___.///
// o__ `._.-'''''    //
// |/  \   ,     /   //
//      \  ``,,,' _//
//       `-.  \--'   .'`.
//          \_/_/    `.,'
//           \\\\
//          ,,','`
//        EGG WARS
//

// WARNING: This is an unaudited barnyard experimental game.
// It has been reviewed but not officially audited. Use at your own risk.
// This is a game for fun, not for financial gain or speculation! There are no plans for future development.

pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EggToken is ERC20, ERC20Burnable, Ownable {
  uint256 public AMOUNT_FOR_AIRDROP = 2_000 ether;
  
  IERC721 public chickenContract;

  modifier onlyChickenContract() {
    require(address(chickenContract) == msg.sender, "caller is not the chicken token");
    _;
  }

  constructor(address _airdropRecipient, address _owner) ERC20("Egg Token", "EGG") Ownable(_owner) {
    require(_owner != address(0), "owner is the zero address");
    _mint(_airdropRecipient, AMOUNT_FOR_AIRDROP);
  }

  function setChickenAddress(IERC721 _chickenContract) public onlyOwner {
    chickenContract = _chickenContract;
  }

  function mintEggsWei(address _to, uint256 _amount) public onlyChickenContract {
    _mint(_to, _amount);
  }

  function burnEggsWei(address _from, uint256 _amount) public onlyChickenContract {
    require(balanceOf(_from) >= _amount, "not enough");
    _burn(_from, _amount);
  }

}
