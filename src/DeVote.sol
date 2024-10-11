//SPDX-License-Identifier : MIT

pragma solidity 0.8.26;

import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract DeVote is Ownable {
    using MerkleProof for bytes32;

    error VotingNotStarted();
    error VotingAlreadyStarted();
    error VotingPeriodIsNotFinished();
    error VotingFinished();
    error CandidateWithThisSloganAlreadyAdded(string slogan);

    struct Candidate {
        uint256 id;
        string name;
        string slogan; //similar to symbol which should be uuinque for each candiate :
            // purpose is for removing duplicacy of single candidate having
            //multiple instanceson system
        uint256 voteCount;
    }

    event NewCandidateAdded(uint256 indexed id, string name, string slogan);

    bytes32 private immutable merkleRoot;
    uint256 private immutable votingPeriod;
    uint256 private votingStartTime;
    bool private votingFinished;
    uint256 private candidateCount;
    Candidate[] private candidates;
    mapping(bytes32 sloganHash => bool) internal isCandidateAdded; //each unique slogan will represent unique candidate

    modifier VotingOpen() {
        if (votingStartTime == 0) {
            revert VotingNotStarted();
        } else if (votingFinished) {
            revert VotingFinished();
        }
        _;
    }

    constructor(bytes32 _merkleRoot, uint256 _votingPeriod) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        votingPeriod = _votingPeriod;
        candidateCount = 0;
        votingFinished = false;
    }

    function startVoting() public onlyOwner {
        if (votingStartTime != 0) {
            revert VotingAlreadyStarted();
        }
        votingStartTime = block.timestamp;
    }

    function endVoting() public VotingOpen onlyOwner {
        if (block.timestamp - votingStartTime < votingPeriod) {
            revert VotingPeriodIsNotFinished();
        }
        votingFinished = true;
    }

    function addCandidate(string memory _cName, string memory _cSlogan) public onlyOwner {
        if (votingFinished) {
            revert VotingFinished();
        }
        if (votingStartTime != 0) {
            revert VotingAlreadyStarted();
        }

        bytes32 sloganHash = keccak256(abi.encode(_cSlogan));
        if (isCandidateAdded[sloganHash]) {
            revert CandidateWithThisSloganAlreadyAdded(_cSlogan);
        }

        Candidate memory newCandid = Candidate({id: candidateCount, name: _cName, slogan: _cSlogan, voteCount: 0});

        candidates.push(newCandid);
        candidateCount++;

        emit NewCandidateAdded(newCandid.id, _cName, _cSlogan);
    }

    function voteCandidate() public returns (bool) {}
}
