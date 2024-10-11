//SPDX-License-Identifier : MIT

pragma solidity 0.8.26;

import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract DeVote is Ownable {
    using MerkleProof for bytes32;

    struct Candidate {
        int256 id;
        string name;
        string slogan;
        int256 voteCount;
    }

    bytes32 private immutable merkleRoot;
    uint256 private immutable votingPeriod;
    uint256 private candidateCount;
    Candidate[] private candidates;
    mapping(uint256 => Candidate) internal candidateMap;

    constructor(bytes32 _merkleRoot, uint256 _votingPeriod) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        votingPeriod = _votingPeriod;
        candidateCount = 0;
    }

    function startVoting() public onlyOwner {}

    function endVoting() public onlyOwner {}

    function addCandidate() public onlyOwner {}

    function voteCandidate() public returns (bool) {}
}
