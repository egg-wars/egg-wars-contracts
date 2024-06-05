// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/EggToken.sol";
import "../src/Chicken.sol";
import "./utils/MockRrp.sol";
import "../src/renderers/ChickenModelRenderer.sol";

contract EggWarsTest is Test {
    function test_logTokenUri() public {
        vm.startPrank(address(1));

        EggToken eggToken = new EggToken(address(2), address(1));
        ChickenModelRenderer cm = new ChickenModelRenderer(
            "ipfs://QmdTThZYNZ2a7mDCrFqN5u5LhnpbYbQUxXmG83S7ycByng/"
        );
        MockRrp mr = new MockRrp();
        Chicken chicken = new Chicken(address(1), eggToken, address(mr), cm);
        eggToken.setChickenAddress(chicken);

        address[] memory airdrops = new address[](2);
        airdrops[0] = vm.addr(2);
        airdrops[1] = vm.addr(2);
        chicken.airdrop(airdrops);

        console.log(chicken.tokenURI(2));
        vm.stopPrank();
    }
}
