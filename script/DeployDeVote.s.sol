//SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DeVote} from "../src/DeVote.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract DeployDeVote is Script {
    using stdJson for string;

    uint256 private constant VOTING_PERIOD = 2 days;


    function run() external returns (DeVote) {

        uint256 deployerKey = (block.chainid == 31337) ? (vm.envUint("ANVIL_PRIVATE_KEY")) : (vm.envUint("SEPOLIA_PRIVATE_KEY"));
        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        bytes32 merkleRoot = result.readBytes32("[0].root");

        console.logBytes32(merkleRoot);

        vm.startBroadcast(deployerKey);
        DeVote deVote = new DeVote(merkleRoot,VOTING_PERIOD);
        vm.stopBroadcast();

        return deVote;        
    }
}
