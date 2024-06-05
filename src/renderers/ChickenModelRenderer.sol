// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ITokenRenderer.sol";
import "../../lib/solady/src/utils/Base64.sol";
import "../Chicken.sol";

contract ChickenModelRenderer is ITokenRenderer {
  using Strings for uint256;

  string public baseTokenUri;

  string[] private prefixes = [
      "Abigail", "Annabelle", "Beatrice", "Caroline", "Delilah", "Eleanor", "Felicity", "Georgia", "Harriet", "Isabella",
      "Josephine", "Katherine", "Lillian", "Magnolia", "Natalie", "Olivia", "Penelope", "Quinn", "Rosalie", "Scarlett",
      "Tallulah", "Ursula", "Violet", "Willa", "Xenia", "Yvette", "Ada", "Belle", "Clara", "Daisy", "Eloise",
      "Flora", "Grace", "Hazel", "Ivy", "Juliet", "Katie", "Leona", "Mabel", "Nora", "Opal", "Pearl", "Ruby", "Stella",
      "Tessa", "Vera", "Winnie", "Xanthe", "Yolanda", "Zoe", "Ava", "Blanche", "Cecilia", "Dinah", "Estelle",
      "Faye", "Gwendolyn", "Henrietta", "Ida", "June", "Kay", "Lucinda", "Mae", "Nellie", "Olive", "Priscilla",
      "Ruth", "Susannah", "Tabitha", "Unity", "Viola", "Wilma", "Yasmin", "Zara", "Amelia", "Bethany", "Coral",
      "Jeremy", "Froyo", "Chicaletta", "Thunder", "Coco", "Worm", "Mickette", "Loset", "Coffee", "Wren", "Ed",
      "Dorothy", "Edith", "Genevieve", "Hope", "Irene", "Jessica", "Kimberly", "Louise", "Myrtle", "Nadine",
      "Ophelia", "Phoebe", "Rose", "Savannah", "Trudy", "Uma", "Valerie", "Whitney", "Zinnia","Betsy", 
      "Clara", "Daisy", "Ella", "Fern", "Gertie", "Hattie", "Ivy", "Jolene", "Kiki", "Lulu", "Mabel", "Nellie", "Opal", 
      "Patsy", "Rosie", "Sadie", "Tilly", "Violet", "Winnie", "Yolanda", "Zelda", "Annabelle", 
      "Bea", "Cleo", "Delilah", "Etta", "Flossie", "Ginger", "Henrietta", "Ida", "June", "Katy", "Lottie", "Minnie", "Nora", 
      "Olive", "Pearl", "Quincy", "Ruthie", "Stella", "Tess", "Ursula", "Velma", "Wilma", "Xyla", "Yvonne", "Zoe", "Abby", 
      "Bella", "Cassie", "Dottie", "Elsie", "Flora", "Goldie", "Harper", "Iris", "Joy", "Kendra", "Lucy", "Millie", "Nancy", 
      "Ophelia", "Penny", "Ruby", "Sally", "Trixie", "Una", "Vera", "Wendy", "Xanthe", "Yasmin", "Zara", "Amelia", "Betty", 
      "Charlotte", "Dinah", "Emmy", "Faye", "Grace", "Holly", "Isabelle", "Jessie", "Kim", "Lena", "Maggie", "Nina", "Olga", 
      "Polly", "Queen", "Rita", "Suzie", "Tammy", "Ulla", "Val", "Willow", "JoJo", "Polly", "Sweetie", "Pookie", "Daisy"
  ];

  string[] private suffixes = [
      "Belle", "Blair", "Blythe", "Bree", "Brooke", "Claire", "Dawn", "Eve", "Faith", "Fawn",
      "Grace", "Hope", "Jade", "Jane", "June", "Kay", "Leigh", "Lynn", "Mae",
      "May", "Nelle", "Paige", "Pearl", "Rae", "Rose", "Rue", "Skye", "Sloane",
      "Tess", "Wren", "Zoe", "Ada", "Anne", "Beth", "Cate", "Dee", "Elle", "Faye",
      "Gail", "Gwen", "Haze", "Iris", "Jo", "Joy", "Kate", "Lee", "Liv", "Lou",
      "Mae", "Neve", "Rea", "Reese", "Ruth", "Sue", "Vale", "Jo"
  ];

  constructor(string memory _baseTokenUri) {
    baseTokenUri = _baseTokenUri;
  }

  function contractData(Chicken chicken) external view override returns (string memory) {
    bytes memory contractInfo = abi.encodePacked(
      '{',
          '"name": "Egg Wars Chicken",',
          '"description": "Welcome to Egg Wars, where players compete to build an army of chickens and earn the most eggs.",',
          '"seller_fee_basis_points": ', chicken.royaltyFeeBp().toString() ,',',
          '"fee_recipient": "', Strings.toHexString(uint160(address(chicken.withdrawalAddress())), 20) ,'",',
          '"image": "ipfs://QmdTThZYNZ2a7mDCrFqN5u5LhnpbYbQUxXmG83S7ycByng/img/0/20.png"',
      '}'
    );
    return Base64.encode(contractInfo);
  }


  function tokenData(Chicken chicken, uint256 tokenId) external view override returns (string memory) {
      uint256 _chickenType = tokenId % 4;
      bytes memory dataURI = abi.encodePacked(
      '{',
          '"name": "', getName(tokenId), '",',
          '"attributes": [{"trait_type": "Level", "value": "', chicken.eggLevel(tokenId).toString(), '"}],',
          '"image": "',baseTokenUri,'img/' , _chickenType.toString(),'/',chicken.eggLevel(tokenId).toString(), '.png",',
          '"animation_url": "',baseTokenUri,'3d/' , _chickenType.toString(),'/',chicken.eggLevel(tokenId).toString(), '.glb"',
      '}'
      );
      return Base64.encode(dataURI);
  }

  function getName(uint256 seed) public view returns (string memory) {
    if ((uint(keccak256(abi.encodePacked(seed))) % 100 < 60)) { // chance of single name
        // single name
        uint256 prefixIndex = uint256(keccak256(abi.encodePacked(seed * 10000))) % prefixes.length;
        return prefixes[prefixIndex];
    } else {
        // double name
        uint256 prefixIndex = uint256(keccak256(abi.encodePacked(seed * 10000))) % prefixes.length;
        uint256 suffixIndex = uint256(keccak256(abi.encodePacked((seed + 1) * 10000))) % suffixes.length;
        return string(abi.encodePacked(prefixes[prefixIndex], " ", suffixes[suffixIndex]));
    }
  }
}
