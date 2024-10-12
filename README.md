# DeVote - Decentralized Voting Platform

DeVote is a decentralized voting system built on Ethereum using Solidity smart contracts. It provides a secure and transparent platform for elections, with voter verification using Merkle Trees and hashed Aadhaar numbers.

## Smart Contract Features

- **Candidate Management**: Candidates are added with unique slogans, preventing duplication.
- **Voter Verification**: Ensures only verified voters can participate in the election using Merkle Proofs.
- **Voting Lifecycle**: Voting is allowed for a limited time and results are determined based on the vote count.
- **Tamper-Proof Voting**: Once voting starts, the results cannot be tampered with or altered.
- **Secure Voting**: Each vote is securely stored on the blockchain.

## Functions Overview

- **addCandidate**: Add a new candidate by providing a name and unique slogan.
- **startVoting**: Start the election.
- **voteCandidate**: Cast a vote for a verified candidate.
- **endVoting**: End the election and declare the winner.
- **getCandidInformation**: Retrieve candidate details.
- **getVotingStatus**: Check the current voting status.

## Documentation

- Solidity: Version 0.8.26
- Merkle Tree Library: OpenZeppelin MerkleProof
- Access Control: OpenZeppelin Ownable

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
