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

import "../lib/airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "./EggToken.sol";
import "./renderers/ITokenRenderer.sol";

contract Chicken is ERC721Enumerable, RrpRequesterV0, Ownable {
    struct ChickenInfo {
        uint256 tokenId;
        string tokenInfo;
        uint256 eggLevel;
        uint256 nextTimeToLay;
        address owner;
    }
    enum HatchStatus {
        None,
        Pending,
        Hatched,
        NotHatched
    }

    using Strings for uint256;

    // Settings
    ITokenRenderer public tokenRenderer;
    EggToken public eggToken;
    address payable public withdrawalAddress;
    uint256 public royaltyFeeBp = 250;

    // Admin capabilities
    bool public canAirdrop = true;
    bool public canTweakNumbers = true;

    // Game mechanic variables
    uint256 public secondsBetweenLays = 24 hours;
    uint256 public birthLikelihoodPercent = 10; // 10%
    uint256 public minLevel = 1;
    uint256 public maxLevel = 20;

    // Tracking of chicken state
    uint256 public lastTokenId;
    mapping(uint256 => uint256) public eggLevel;
    mapping(uint256 => uint256) public nextTimeToLay;

    // Hatch requests
    mapping(bytes32 => address) public hatchOwner;
    mapping(bytes32 => HatchStatus) public hatchStatus;

    // Oracle set up
    address public airnode; // The address of the QRNG Airnode
    bytes32 public endpointIdUint256; // The endpoint ID for requesting a single random number
    address public sponsorWallet; // The wallet that will cover the gas costs of the request

    event EggsLaid(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 numberOfWholeEggs
    );
    event FedChicken(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 numberOfWholeEggs
    );
    event EggThrown(
        address indexed attacker,
        address indexed victim,
        uint256 indexed victimChickenId,
        uint256 numberOfWholeEggs
    );
    event LevelChanged(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 oldLevel,
        uint256 newLevel
    );
    event HatchRequested(address indexed owner, bytes32 indexed requestId);
    event HatchSucceeded(
        address indexed owner,
        bytes32 indexed requestId,
        uint256 newChickenId,
        uint256 randomNumber
    );
    event HatchFailed(
        address indexed owner,
        bytes32 indexed requestId,
        uint256 randomNumber
    );
    event MetadataUpdate(uint256 _tokenId); // https://eips.ethereum.org/EIPS/eip-4906

    modifier onlyWhenCanTweakNumbers() {
        require(canTweakNumbers, "numbers can not be tweaked");
        _;
    }

    constructor(
        address _ownerAddress,
        EggToken _eggToken,
        address _airnodeRrp,
        ITokenRenderer _tokenRenderer
    )
        ERC721("Egg Wars Chicken", "EWC")
        RrpRequesterV0(_airnodeRrp)
        Ownable(_ownerAddress)
    {
        eggToken = _eggToken;
        tokenRenderer = _tokenRenderer;
        withdrawalAddress = payable(_ownerAddress);
    }

    // ~*~*~*~*~*~ Admin Functionality ~*~*~*~*~*~
    function setAirnode(
        address _airnode,
        bytes32 _endpointIdUint256
    ) public onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
    }
    function setSponsorWallet(address _sponsorWallet) public onlyOwner {
        sponsorWallet = _sponsorWallet;
    }
    function setTokenRenderer(ITokenRenderer _tokenRenderer) public onlyOwner {
        tokenRenderer = _tokenRenderer;
    }
    function setWithdrawalAddress(
        address payable _withdrawalAddress
    ) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }
    function setSecondsBetweenLays(
        uint256 _secondsBetweenLays
    ) public onlyOwner onlyWhenCanTweakNumbers {
        secondsBetweenLays = _secondsBetweenLays;
    }
    function setBirthLikelihoodPercent(
        uint256 _birthLikelihoodPercent
    ) public onlyOwner onlyWhenCanTweakNumbers {
        birthLikelihoodPercent = _birthLikelihoodPercent;
    }
    function setMaxLevel(
        uint256 _maxLevel
    ) public onlyOwner onlyWhenCanTweakNumbers {
        require(_maxLevel > maxLevel, "max level must be higher than current");
        maxLevel = _maxLevel;
    }
    function setRoyaltyFeeBp(
        uint256 _royaltyFeeBp
    ) public onlyOwner onlyWhenCanTweakNumbers {
        royaltyFeeBp = _royaltyFeeBp;
    }
    function disableTweakingNumbers() public onlyOwner {
        canTweakNumbers = false;
    }
    function closeAirdrop() public onlyOwner {
        canAirdrop = false;
    }
    function withdrawStoredEth(uint256 amount) public {
        require(
            msg.sender == owner() || msg.sender == withdrawalAddress,
            "caller is not the owner or withdrawalAddress"
        );
        require(
            !(withdrawalAddress == address(0)),
            "withdrawalAddress not set"
        );
        require(address(this).balance >= amount, "amount exceeds balance");
        (bool success, ) = withdrawalAddress.call{value: amount}("");
        if (!success) {
            revert("withdrawal failed");
        }
    }
    function airdrop(address[] calldata to) public onlyOwner {
        require(canAirdrop, "airdrop not active");

        for (uint256 i = 0; i < to.length; i++) {
            _birthChicken(to[i]);
        }
    }
    function requestAirnodeWithdraw() external onlyOwner {
        airnodeRrp.requestWithdrawal(airnode, sponsorWallet);
    }

    // ~*~*~*~*~*~ Player Actions ~*~*~*~*~*~
    function layEggs(uint256[] calldata tokenIds) public {
        uint256 eggsToMintWei = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 curTokenId = tokenIds[i];

            require(
                ownerOf(curTokenId) == msg.sender,
                "caller is not the owner of the chicken"
            );
            require(canLayEggsNow(curTokenId), "not time to lay yet");

            nextTimeToLay[curTokenId] = block.timestamp + secondsBetweenLays;

            uint256 eggsToMintForChickenWei = eggLevel[curTokenId] * 10 ** 18;
            eggsToMintWei += eggsToMintForChickenWei;

            emit EggsLaid(msg.sender, curTokenId, eggLevel[curTokenId]);
        }
        eggToken.mintEggsWei(msg.sender, eggsToMintWei);
    }

    function feed(
        uint256[] calldata numbersOfWholeEggs,
        uint256[] calldata tokenIdsToPowerUp
    ) public {
        require(
            numbersOfWholeEggs.length == tokenIdsToPowerUp.length,
            "array length mismatch"
        );

        // Level up chickens and keep track of total
        uint256 totalEggsToBurnWei;
        for (uint256 i = 0; i < tokenIdsToPowerUp.length; i++) {
            uint256 numberOfWholeEggs = numbersOfWholeEggs[i];
            uint256 tokenIdToPowerUp = tokenIdsToPowerUp[i];

            totalEggsToBurnWei += numbersOfWholeEggs[i] * 10 ** 18;

            require(
                ownerOf(tokenIdToPowerUp) == msg.sender,
                "must own chicken"
            );

            _increaseLevel(tokenIdToPowerUp, numberOfWholeEggs);

            emit FedChicken(msg.sender, tokenIdToPowerUp, numberOfWholeEggs);
        }

        require(
            eggToken.balanceOf(msg.sender) >= totalEggsToBurnWei,
            "not enough eggs"
        );
        eggToken.burnEggsWei(msg.sender, totalEggsToBurnWei);
    }

    function throwEgg(
        uint256 numberOfWholeEggsToThrow,
        uint256 tokenIdToAttack
    ) public {
        require(balanceOf(msg.sender) >= 1, "must own chicken");
        uint256 amountEggsWei = numberOfWholeEggsToThrow * 10 ** 18;
        require(
            eggToken.balanceOf(msg.sender) >= amountEggsWei,
            "not enough eggs"
        );
        eggToken.burnEggsWei(msg.sender, amountEggsWei);
        _decreaseLevel(tokenIdToAttack, numberOfWholeEggsToThrow);
        emit EggThrown(
            msg.sender,
            ownerOf(tokenIdToAttack),
            tokenIdToAttack,
            numberOfWholeEggsToThrow
        );
    }

    function requestHatch(uint256 numberOfWholeEggs) public {
        require(!(this.airnode() == address(0)), "airnode not set");
        require(
            !(this.endpointIdUint256() == bytes32(0)),
            "endpointIdUint256 not set"
        );
        require(!(this.sponsorWallet() == address(0)), "sponsorWallet not set");

        uint256 numOfEggsWei = numberOfWholeEggs * 10 ** 18;

        require(
            eggToken.balanceOf(msg.sender) >= numOfEggsWei,
            "not enough eggs"
        );
        eggToken.burnEggsWei(msg.sender, numOfEggsWei);

        for (uint256 i = 0; i < numberOfWholeEggs; i++) {
            bytes32 requestId = airnodeRrp.makeFullRequest(
                airnode,
                endpointIdUint256,
                address(this),
                sponsorWallet,
                address(this),
                this.randomNumberReceived.selector,
                ""
            );
            hatchStatus[requestId] = HatchStatus.Pending;
            hatchOwner[requestId] = msg.sender;
            emit HatchRequested(msg.sender, requestId);
        }
    }

    function randomNumberReceived(
        bytes32 requestId,
        bytes calldata data
    ) external onlyAirnodeRrp {
        if (!(hatchStatus[requestId] == HatchStatus.Pending)) {
            revert("hatch not pending");
        }
        address hatchOwnerAddress = hatchOwner[requestId];
        if (hatchOwnerAddress == address(0)) {
            revert("no owner");
        }

        uint256 randomNumber = abi.decode(data, (uint256)) % 100;
        bool birthWorked = randomNumber < birthLikelihoodPercent;
        if (birthWorked) {
            hatchStatus[requestId] = HatchStatus.Hatched;
            uint256 newChickenId = _birthChicken(hatchOwnerAddress);
            emit HatchSucceeded(
                hatchOwnerAddress,
                requestId,
                newChickenId,
                randomNumber
            );
        } else {
            hatchStatus[requestId] = HatchStatus.NotHatched;
            emit HatchFailed(hatchOwnerAddress, requestId, randomNumber);
        }
    }

    function canLayEggsNow(uint256 tokenId) public view returns (bool) {
        return block.timestamp >= nextTimeToLay[tokenId];
    }

    // ~*~*~*~*~*~ Private helpers for modifying state ~*~*~*~*~*~
    function _increaseLevel(
        uint256 tokenId,
        uint256 amountToIncrease
    ) internal {
        uint256 newLevel = eggLevel[tokenId] + amountToIncrease;
        require(newLevel <= maxLevel, "max level reached");
        emit LevelChanged(
            ownerOf(tokenId),
            tokenId,
            eggLevel[tokenId],
            newLevel
        );
        emit MetadataUpdate(tokenId);
        eggLevel[tokenId] = newLevel;
    }

    function _decreaseLevel(
        uint256 tokenId,
        uint256 amountToDecrease
    ) internal {
        uint256 newLevel = eggLevel[tokenId] - amountToDecrease;
        require(newLevel >= minLevel, "min level reached");
        emit LevelChanged(
            ownerOf(tokenId),
            tokenId,
            eggLevel[tokenId],
            newLevel
        );
        emit MetadataUpdate(tokenId);
        eggLevel[tokenId] = newLevel;
    }

    function _birthChicken(address birthTo) internal returns (uint256) {
        lastTokenId++;
        eggLevel[lastTokenId] = 1;
        _mint(birthTo, lastTokenId);
        return lastTokenId;
    }

    // ~*~*~*~*~*~ ERC721 Functionality ~*~*~*~*~*~
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        // https://eips.ethereum.org/EIPS/eip-4906
        return
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    this.tokenRenderer().contractData(this)
                )
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(eggLevel[tokenId] > 0, "token not minted");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    this.tokenRenderer().tokenData(this, tokenId)
                )
            );
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        require(eggLevel[tokenId] > 0, "token not minted");
        return (withdrawalAddress, (salePrice * royaltyFeeBp) / 10000);
    }

    receive() external payable {} // For receiving ETH

    // ~*~*~*~*~*~ Helper functions for front-end ~*~*~*~*~*~
    function getChickenInfo(
        uint256 tokenId
    ) public view returns (ChickenInfo memory) {
        string memory tokenInfo = this.tokenURI(tokenId);
        uint256 curEggLevel = this.eggLevel(tokenId);
        uint256 curNextTimeToLay = this.nextTimeToLay(tokenId);
        address curOwner = this.ownerOf(tokenId);

        return
            ChickenInfo(
                tokenId,
                tokenInfo,
                curEggLevel,
                curNextTimeToLay,
                curOwner
            );
    }

    function getChickenInfos(
        uint256[] calldata tokenIds
    ) public view returns (ChickenInfo[] memory) {
        ChickenInfo[] memory chickenInfos = new ChickenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            chickenInfos[i] = getChickenInfo(tokenIds[i]);
        }
        return chickenInfos;
    }
}
