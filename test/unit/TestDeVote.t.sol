//SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployDeVote} from "script/DeployDeVote.s.sol";
import {DeVote} from "src/DeVote.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract TestDeVote is Test {
    using stdJson for string;

    DeployDeVote private deployDevote;
    DeVote private deVote;

    uint256 private adminKey;
    address private admin;
    uint256 private constant INITIAL_BALANCE = 100 ether;
    address private candid1 = makeAddr("testCandidate1");
    address private candid2 = makeAddr("testCandidate2");
    address private candid3 = makeAddr("testCandidate3");


    function setUp() public {
        deployDevote = new DeployDeVote();
        deVote = deployDevote.run();
        if(block.chainid == 31337) {
            adminKey = vm.envUint("ANVIL_PRIVATE_KEY");
        }
        else{
            adminKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        }

        admin = vm.addr(adminKey);
        vm.deal(admin,INITIAL_BALANCE);
    }

    function testAdminIsSetSuccessfully() public view {
        address voteContractOwer = deVote.owner();

        assertEq(voteContractOwer,admin);
    }

    function testDeVoteIsInitializedProperly() public view {
        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        bytes32 merkleRoot = result.readBytes32("[0].root");
        bytes32 contractMerkleroot = deVote.getMerkleRoot();

        assertEq(merkleRoot,contractMerkleroot);
    }

    function testVotingStatus() public {
        int8 votingStatusInt = deVote.getVotingStatus();
        assertEq(votingStatusInt,-1);

        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        deVote.startVoting();
        vm.stopPrank();

        votingStatusInt = deVote.getVotingStatus();
        assertEq(votingStatusInt,1);

        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        address voter = result.readAddress("[0].inputs[0]");
        bytes32 voterRightHash = result.readBytes32("[0].inputs[1]");
        bytes32[] memory voterProof = result.readBytes32Array("[0].proof");
        vm.startPrank(voter);
        deVote.voteCandidate(voterProof,voterRightHash,0); // 0 is a candidate id of narendra modi :)
        vm.stopPrank();

        vm.warp(block.timestamp+ 2 days);
        vm.roll(block.number+1);

        vm.startPrank(admin);
        deVote.endVoting();
        vm.stopPrank();

        votingStatusInt = deVote.getVotingStatus();
        assertEq(votingStatusInt,0);

    }

    function testAdminCanNotAddCandidateOnceVotingIsStarted() public {

        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        deVote.startVoting();

        vm.expectRevert(DeVote.VotingAlreadyStarted.selector);
        deVote.addCandidate("Mamta Didi", "TMC");


        vm.stopPrank();

    }
}