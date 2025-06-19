# Broadcast Standard and Reference Implementation

Link to ERC: https://github.com/ethereum/ERCs/pull/897

Link to Ethereum Magicians: https://ethereum-magicians.org/t/new-erc-cross-chain-broadcaster/22927

This repository contains text and contracts related to ERC-0000.

The standard's text can be found in [`/standard/README.md`](/standard/README.md)

`/standard/README.md` is generated from [`/standard/README-template.md`](./standard/README-template.md) by running `yarn build-standard` in the root of this repository.

Contracts appearing in the standard text can be found in [`/contracts/standard/`](/contracts/standard/).

A reference implementation of `IBroadcaster`, `IReceiver`, and `IBlockHashProverPointer` can be found in [`/contracts/reference-impl/`](/contracts/reference-impl/)

A reference implementation of `IBlockHashProver` contracts for Arbitrum chains can be found in [OffchainLabs/arbitrum-block-hash-prover](https://github.com/OffchainLabs/arbitrum-block-hash-prover)

A reference implementation of `IBlockHashProver` contracts for OP stack chains can be found in [OffchainLabs/op-block-hash-prover](https://github.com/OffchainLabs/op-block-hash-prover)
