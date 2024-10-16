//SPDX-License-Identifier:MIT

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
    error InvalidVoterRight(address);
    error InvalidCandidateId();
    error AlreadyVoted(address voter);
    error NoVotesCastedHenceVotingFailed();

    struct Candidate {
        uint256 id;
        string name;
        string slogan; //similar to symbol which should be uuinque for each candiate :
            // purpose is for removing duplicacy of single candidate having
            //multiple instanceson system
        uint256 voteCount;
    }

    event NewCandidateAdded(uint256 indexed id, string name, string slogan);
    event VoteDeposited(bytes32 indexed voterRightHash);
    event WinnerCandidDeclared(uint256 candidId);

    bytes32 private immutable merkleRoot;
    uint256 private immutable votingPeriod;
    uint256 private votingStartTime;
    bool private votingStarted;
    bool private votingFinished;
    uint256 private candidateCount;
    Candidate private winnerCandid;
    Candidate[] private candidates;
    mapping(bytes32 sloganHash => bool) internal isCandidateAdded; //each unique slogan will represent unique candidate
    mapping(bytes32 voterRightHash => bool hasVoted) internal hasVoterVoted;

    modifier VotingOpen() {
        if (!votingStarted) {
            revert VotingNotStarted();
        } else if (votingFinished) {
            revert VotingFinished();
        }
        _;
    }

    modifier ValidCadidateId(uint256 candidIdToVote) {
        if (candidIdToVote >= candidateCount) {
            revert InvalidCandidateId();
        }
        _;
    }

    constructor(bytes32 _merkleRoot, uint256 _votingPeriod) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        votingPeriod = _votingPeriod;
        candidateCount = 0;
        votingFinished = false;
        votingStarted = false;
        votingStartTime = type(uint256).max;
    }

    function startVoting() public onlyOwner {
        if (votingStarted) {
            revert VotingAlreadyStarted();
        }
        votingStartTime = block.timestamp;
        votingStarted = true;
    }

    function endVoting() public {
        if (!votingStarted) {
            revert VotingNotStarted();
        }
        if (block.timestamp - votingStartTime < votingPeriod) {
            revert VotingPeriodIsNotFinished();
        }
        votingFinished = true;

        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidateCount; i++) {
            Candidate memory candid = candidates[i];
            if (maxVotes < candid.voteCount) {
                maxVotes = candid.voteCount;
                winnerCandid = candid;
            }
        }

        if (maxVotes == 0) {
            revert NoVotesCastedHenceVotingFailed();
        }

        emit WinnerCandidDeclared(winnerCandid.id);
    }

    function addCandidate(string memory _cName, string memory _cSlogan) public onlyOwner {
        if (votingStarted) {
            revert VotingAlreadyStarted();
        }

        bytes32 sloganHash = keccak256(abi.encode(_cSlogan));
        if (isCandidateAdded[sloganHash]) {
            revert CandidateWithThisSloganAlreadyAdded(_cSlogan);
        }

        Candidate memory newCandid = Candidate({id: candidateCount, name: _cName, slogan: _cSlogan, voteCount: 0});

        candidates.push(newCandid);
        isCandidateAdded[sloganHash] = true;
        candidateCount++;

        emit NewCandidateAdded(newCandid.id, _cName, _cSlogan);
    }

    /**
     * 
     * @param _proof proof of the voter's right
     * @param voterRightHash hash of the voter's adhar card number mind that it is calculated as follow
     *                       voterROghtHash = keccak256("123456789012") --> here adahar number given is in string format not uint256 digits
     * @param candidIdToVote whom voter wants to vote
     */
    function voteCandidate(
        bytes32[] memory _proof,
        bytes32 voterRightHash,   //hash of voter's adhaar number
        uint256 candidIdToVote
    ) public ValidCadidateId(candidIdToVote) VotingOpen returns (bool) {
        
        bytes32 leaf = keccak256(bytes.concat(abi.encode(keccak256(abi.encode(msg.sender,voterRightHash)))));
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert InvalidVoterRight(msg.sender);
        }
        if (hasVoterVoted[leaf]) {
            revert AlreadyVoted(msg.sender);
        }

        candidates[candidIdToVote].voteCount++;
        hasVoterVoted[leaf] = true;
        emit VoteDeposited(voterRightHash);
        return true;
    }

    function getCandidInformation(uint256 candidId)
        public
        view
        ValidCadidateId(candidId)
        returns (string memory, string memory, uint256)
    {
        return (candidates[candidId].name, candidates[candidId].slogan, candidates[candidId].voteCount);
    }

    function getListOfCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function getMerkleRoot() public view returns(bytes32) {
        return merkleRoot;
    }

    function getVotingStatus() public view returns(int8) {
        if(!votingStarted) {
            return -1;   // voting has not started yet
        }
        else if(votingFinished || (block.timestamp) - (votingStartTime) >= (votingPeriod)) {
            return 0;    //voting is finished
        }
        else{
            return 1; // voting is current ongoing
        }
    }
}
