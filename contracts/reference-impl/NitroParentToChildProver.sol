// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IBlockHashProver} from "../standard/interfaces/IBlockHashProver.sol";

interface IOutbox {
    function roots(bytes32 sendRoot) external view returns (bytes32 blockHash);
}

/// @notice Proves block hashes for a Nitro chain.
///         The home chain is the parent chain and the target chain is the child nitro chain.
contract NitroParentToChildProver is IBlockHashProver {
    uint256 public constant version = 1;
    uint256 public constant homeChainId = 1;
    address public immutable outbox;
    uint256 public immutable rootsSlot;

    constructor(address _outbox, uint256 _rootsSlot) {
        outbox = _outbox;
        rootsSlot = _rootsSlot;
    }

    /// @notice Call the nitro chain's outbox to get the block hash
    /// @param  input ABI encoded (bytes32 sendRoot, bytes blockHeaderRlp)
    /// @return targetBlockHash The block hash of the target (child) chain
    function getTargetBlockHash(bytes memory input) external view returns (bytes32 targetBlockHash) {
        require(block.chainid == homeChainId, "must be on home chain");
        (bytes32 sendRoot) = abi.decode(input, (bytes32));
        targetBlockHash = IOutbox(outbox).roots(sendRoot);
        require(targetBlockHash != bytes32(0), "block hash not found");
    }

    /// @notice Use a nitro parent chain's block hash and proof to get the block hash of the nitro chain.
    /// @param  homeBlockHash The block hash of the parent chain
    /// @param  input ABI encoded (bytes homeBlockHeaderRlp, uint256 blockNumber, bytes outboxAccountProof, bytes outboxStorageProof)
    /// @return targetBlockHash The block hash of the target (child) chain
    function verifyTargetBlockHash(bytes32 homeBlockHash, bytes memory input)
        public
        view
        returns (bytes32 targetBlockHash)
    {
        require(block.chainid != homeChainId, "must not be on home chain");

        (
            bytes memory homeBlockHeaderRlp,
            bytes32 sendRoot,
            bytes memory outboxAccountProof,
            bytes memory outboxStorageProof
        ) = abi.decode(input, (bytes, bytes32, bytes, bytes));

        // check the block hash matches the block header
        require(homeBlockHash == keccak256(homeBlockHeaderRlp), "block hash must match block header");

        // extract the state root from the block header
        // parent chain has it at index 3
        bytes32 stateRoot = _extractFieldFromHeader(homeBlockHeaderRlp, 3);

        // verify the account proof
        (address account, bytes32 storageRoot) = _verifyAccountProof(stateRoot, outboxAccountProof);

        // make sure the account proven is the outbox contract
        require(account == outbox, "account must match outbox");

        // verify the storage proof
        (uint256 blockHashSlot, bytes32 blockHash) = _verifyStorageProof(storageRoot, outboxStorageProof);

        // make sure the slot corresponds to the roots map
        uint256 expectedSlot = uint256(keccak256(abi.encode(sendRoot, rootsSlot)));
        require(blockHashSlot == expectedSlot, "unexpected slot");

        require(blockHash != bytes32(0), "block hash not found");

        return blockHash;
    }

    /// @notice Use a child chain block hash to verify a storage slot.
    /// @param  targetBlockHash The block hash of the child chain
    /// @param  input ABI encoded (bytes targetBlockHeaderRlp, bytes accountProof, bytes storageProof)
    /// @return account The account on the child chain
    /// @return slot The storage slot of the account on the child chain
    /// @return value The value of the storage slot
    function verifyStorageSlot(bytes32 targetBlockHash, bytes calldata input)
        external
        pure
        returns (address account, uint256 slot, bytes32 value)
    {
        (bytes memory targetBlockHeaderRlp, bytes memory accountProof, bytes memory storageProof) =
            abi.decode(input, (bytes, bytes, bytes));

        // ensure the block hash matches the block header
        require(targetBlockHash == keccak256(targetBlockHeaderRlp), "block hash must match block header");

        // extract the state root from the block header
        // child chain has it at index 3
        bytes32 stateRoot = _extractFieldFromHeader(targetBlockHeaderRlp, 3);

        // verify the storage root
        bytes32 targetStorageRoot;
        (account, targetStorageRoot) = _verifyAccountProof(stateRoot, accountProof);

        // verify the storage slot
        (slot, value) = _verifyStorageProof(targetStorageRoot, storageProof);
    }

    function _extractFieldFromHeader(bytes memory rlpBlockHeader, uint256 index)
        internal
        pure
        returns (bytes32 stateRoot)
    {
        // extract the state root from the block header
    }
    function _verifyAccountProof(bytes32 stateRoot, bytes memory proof)
        internal
        pure
        returns (address account, bytes32 storageRoot)
    {
        // verify an account proof
    }
    function _verifyStorageProof(bytes32 storageRoot, bytes memory proof)
        internal
        pure
        returns (uint256 slot, bytes32 value)
    {
        // verify a storage proof
    }
}
