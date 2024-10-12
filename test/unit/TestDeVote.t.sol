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
        bytes32 voterRightHash = keccak256("650852956851");   // which will be calculated by the user on frontend
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

    function testAdminCanNotAddCandidateOnceVotingIsStartedOrEnded() public {

        console.log(deVote.getVotingStatus());

        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        deVote.startVoting();

        vm.expectRevert(DeVote.VotingAlreadyStarted.selector);
        deVote.addCandidate("Mamta Didi", "TMC");
        vm.stopPrank();

        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        address voter = result.readAddress("[0].inputs[0]");
        bytes32 voterRightHash = keccak256("650852956851");   // which will be calculated by the user on frontend
        bytes32[] memory voterProof = result.readBytes32Array("[0].proof");
        vm.startPrank(voter);
        deVote.voteCandidate(voterProof,voterRightHash,0); // 0 is a candidate id of narendra modi :)
        vm.stopPrank();

        vm.warp(block.timestamp+3 days);
        vm.roll(block.number+1);

        vm.startPrank(admin);
        deVote.endVoting();

        vm.expectRevert(DeVote.VotingAlreadyStarted.selector);
        deVote.addCandidate("Mamta Didi", "TMC");
        vm.stopPrank();

    }

    function testInValidVoterCannotVote() public {
        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        deVote.startVoting();
        vm.stopPrank();

        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        address fakevoter = result.readAddress("[0].inputs[0]");
        bytes32 fakevoterRightHash = keccak256(abi.encode(345667892345));
        bytes32[] memory voterProof = result.readBytes32Array("[0].proof");
        
        vm.startPrank(fakevoter);
        vm.expectRevert(abi.encodeWithSelector(DeVote.InvalidVoterRight.selector,fakevoter));
        deVote.voteCandidate(voterProof,fakevoterRightHash,0); // 0 is a candidate id of narendra modi :)
        vm.stopPrank();
    }

    function testVoterCannotVoteMoreThanOneTime() public {

        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        deVote.startVoting();

        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        address voter = result.readAddress("[0].inputs[0]");
        bytes32 voterRightHash = keccak256("650852956851");   // which will be calculated by the user on frontend
        bytes32[] memory voterProof = result.readBytes32Array("[0].proof");
        vm.startPrank(voter);
        deVote.voteCandidate(voterProof,voterRightHash,0); // 0 is a candidate id of narendra modi :)
        vm.stopPrank();

        //now voter tries to vote again 

        vm.startPrank(voter);
        vm.expectRevert(abi.encodeWithSelector(DeVote.AlreadyVoted.selector,voter));
        deVote.voteCandidate(voterProof,voterRightHash,0);
        vm.stopPrank();
        
    }

    function testVoterCannotVoteOnceVotingIsFinished() public {

        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");
        deVote.startVoting();
        vm.stopPrank();

        string memory result = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json"));
        address voter1 = result.readAddress("[0].inputs[0]");
        bytes32 voter1RightHash = keccak256("650852956851");   // which will be calculated by the user on frontend
        bytes32[] memory voter1Proof = result.readBytes32Array("[0].proof");
        vm.startPrank(voter1);
        deVote.voteCandidate(voter1Proof,voter1RightHash,0); // 0 is a candidate id of narendra modi :)
        vm.stopPrank();

        vm.warp(block.timestamp+2 days);
        vm.roll(block.number+1);
        console.log(deVote.getVotingStatus());

        vm.startPrank(admin);
        deVote.endVoting();
        vm.stopPrank();

        address voter2 = result.readAddress("[1].inputs[0]");
        bytes32 voter2RightHash = keccak256("902900517015");
        bytes32[] memory voter2Proof = result.readBytes32Array("[1].proof");
        vm.startPrank(voter2);
        vm.expectRevert(DeVote.VotingFinished.selector);
        deVote.voteCandidate(voter2Proof,voter2RightHash,0);
        vm.stopPrank();       
    }

    function testNoTwoCandidateCanhaveSameSlogan() public {
        vm.startPrank(admin);
        deVote.addCandidate("NarendraModi","BJP");
        deVote.addCandidate("RahulGandhi","National Congress");
        deVote.addCandidate("Arvind Kejrival","AAP");

        vm.expectRevert(abi.encodeWithSelector(DeVote.CandidateWithThisSloganAlreadyAdded.selector,"BJP"));
        deVote.addCandidate("AmitShah","BJP");
        vm.stopPrank();        
    }

}