// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

// Merkle tree input file generator script
contract GenerateInput is Script {
    string[] types = new string[](2);
    uint256 count;
    string[] whitelist = new string[](4);
    string[] adhaarHash = new string[](4);
    string private constant INPUT_PATH = "/script/target/input.json";

    function run() public {
        types[0] = "address";
        types[1] = "uint";
        whitelist[0] = "0xDB005dF9b15b01A01288AdC68A1253fDb4961c1a";
        whitelist[1] = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
        whitelist[2] = "0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd";
        whitelist[3] = "0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D";
        adhaarHash[0] = "0xd201b792b568e5b1e3583b6141b6e2d508158eb2f37fbfd3b2bbc8f72afdd892"; // adharr:650852956851
        adhaarHash[1] = "0x5deb03c01d3280a39082314f0d85b1f1cb3b9c8a924b4d0ea0420958f63b6a14"; // adharr:902900517015
        adhaarHash[2] = "0xa91db896f7621719213c6355d3fb2c7dd9bb6ab9a6f635406d082c984b871288"; // adharr:164800253134
        adhaarHash[3] = "0xc0f6f80b83f60e953c612da5a838e407bcb42b05f29a5de952c159d6c9fa22fc"; // adharr:243783536334
        count = whitelist.length;
        string memory input = _createJSON();
        // write to the output file the stringified output json tree dumpus
        vm.writeFile(string.concat(vm.projectRoot(), INPUT_PATH), input);

        console.log("DONE: The output is found at %s", INPUT_PATH);
    }

    function _createJSON() internal view returns (string memory) {
        string memory countString = vm.toString(count); // convert count to string
        string memory json = string.concat('{ "types": ["address", "bytes32"], "count":', countString, ',"values": {');
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (i == whitelist.length - 1) {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    adhaarHash[i],
                    '"',
                    " }"
                );
            } else {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    adhaarHash[i],
                    '"',
                    " },"
                );
            }
        }
        json = string.concat(json, "} }");

        return json;
    }
}
