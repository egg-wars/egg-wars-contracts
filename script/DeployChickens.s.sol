// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "../src/EggToken.sol";
import "../src/Chicken.sol";
import "../src/renderers/ChickenModelRenderer.sol";

struct DeployConfiguration {
    address tokenAirdropRecipient;
    address airNodeRrpAddress;
    address airnode;
    bytes32 endpointIdUint256;
}


contract DeployChickensScript is Script {

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        address deployerAddress = vm.addr(privateKey);

        DeployConfiguration memory deployConfiguration = getDeployConfiguration();

        // deploy contracts
        EggToken eggToken = new EggToken(deployConfiguration.tokenAirdropRecipient, deployerAddress);
        ChickenModelRenderer cm = new ChickenModelRenderer("ipfs://QmdTThZYNZ2a7mDCrFqN5u5LhnpbYbQUxXmG83S7ycByng/");
        Chicken chicken = new Chicken(deployerAddress, eggToken, deployConfiguration.airNodeRrpAddress, cm);

        // set up EggToken
        eggToken.setChickenAddress(chicken);
        eggToken.renounceOwnership();

        // set up Chicken
        chicken.setAirnode(
            deployConfiguration.airnode,
            deployConfiguration.endpointIdUint256
        );

        if (block.chainid == 84532) {
            setupTestnet(chicken, eggToken);
        }

        console.log("~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~");
        console.log("Deployed to network ", block.chainid);
        console.log("eggToken:", address(eggToken));
        console.log("chicken:", address(chicken));
        console.log("~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~");
        console.log("NEXT STEPS:");
        console.log("1/ generate sponsorWallet via yarn generate_sponsor");
        console.log("2/ set sponsorWallet on chicken contract: ", address(chicken));
        console.log("3/ send sponsor wallet funds");
        console.log("~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~~*~*~*~");

        vm.stopBroadcast();
    }

    function getDeployConfiguration() private view returns (DeployConfiguration memory) {
        uint256 networkId = block.chainid;
        if (networkId == 84532) {
            return DeployConfiguration({
                tokenAirdropRecipient: 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697, // for testing
                airNodeRrpAddress: 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd,
                // https://docs.api3.org/reference/qrng/providers.html
                airnode: 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D,
                endpointIdUint256: 0x94555f83f1addda23fdaa7c74f27ce2b764ed5cc430c66f5ff1bcf39d583da36
            });
        } else if (networkId == 8453) {
            return DeployConfiguration({
                tokenAirdropRecipient: 0x8138f468D235fFA0C6B32ae70aA799555a91ee74,
                airNodeRrpAddress: 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd,
                // https://docs.api3.org/reference/qrng/providers.html
                airnode: 0x224e030f03Cd3440D88BD78C9BF5Ed36458A1A25,
                endpointIdUint256: 0xffd1bbe880e7b2c662f6c8511b15ff22d12a4a35d5c8c17202893a5f10e25284
            });
        }
        revert("Unknown network");
    }

    function setupTestnet(Chicken chicken, EggToken eggToken) private {
        // For testing on testnet
        address[] memory airdropAddresses = new address[](9);
        airdropAddresses[0] = 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697;
        airdropAddresses[1] = 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697;
        airdropAddresses[2] = 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697;
        airdropAddresses[3] = 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697;
        airdropAddresses[4] = 0xA24E48eA9AF5d122b99Af734Aaadfd9405D59697;
        airdropAddresses[5] = 0x8a00c2f7bA8ec5FDeFECbc0b3fFf8a96EAE0bC24;
        airdropAddresses[6] = 0x8a00c2f7bA8ec5FDeFECbc0b3fFf8a96EAE0bC24;
        airdropAddresses[7] = 0x8a00c2f7bA8ec5FDeFECbc0b3fFf8a96EAE0bC24;
        airdropAddresses[8] = 0x8a00c2f7bA8ec5FDeFECbc0b3fFf8a96EAE0bC24;
        chicken.airdrop(airdropAddresses);
        eggToken.transfer(0x8a00c2f7bA8ec5FDeFECbc0b3fFf8a96EAE0bC24, 50 ether);
        uint256[] memory tokenIdsToLay = new uint256[](2);
        tokenIdsToLay[0] = 1;
        tokenIdsToLay[1] = 2;
        chicken.layEggs(tokenIdsToLay);
    }

}
