// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IBlockHashProver} from "../standard/interfaces/IBlockHashProver.sol";

interface IArbSys {
    function parentBlockHash(uint256 blockNumber) external view returns (bytes32);
}

// let's pretend that arbsys.parentBlockHash(uint256 blockNum) is a thing, and that these are stored in a map in arbsys

/// @notice Proves block hashes for a Nitro chain's parent chain.
///         The home chain is the nitro chain and the target chain is the parent chain.
contract NitroChildToParentProver is IBlockHashProver {
    uint256 public constant version = 1;
    uint256 public constant parentBlockHashSlot = 987497987234;
    address public constant arbSys = (address(100));
    uint256 public constant homeChainId = 0xA4B1;

    /// @notice Use ArbSys to get a block hash of the parent chain, then extract the block hash from the block header.
    /// @param  input ABI encoded (uint256 blockNumber)
    /// @return targetBlockHash The block hash of the target (parent) chain
    function getTargetBlockHash(bytes memory input) external view returns (bytes32 targetBlockHash) {
        require(block.chainid == homeChainId, "must be on home chain");

        (uint256 blockNumber) = abi.decode(input, (uint256));

        // get the block hash from the parent chain
        return IArbSys(arbSys).parentBlockHash(blockNumber);
    }

    /// @notice Use a nitro chain's block hash and proof to get the block hash of the parent chain.
    /// @param  homeBlockHash The block hash of the nitro chain
    /// @param  input ABI encoded (bytes homeBlockHeaderRlp, uint256 blockNumber, bytes arbSysAccountProof, bytes arbSysStorageProof)
    /// @return targetBlockHash The block hash of the target (parent) chain
    function verifyTargetBlockHash(bytes32 homeBlockHash, bytes memory input)
        external
        view
        returns (bytes32 targetBlockHash)
    {
        require(block.chainid != homeChainId, "must not be on home chain");

        (
            bytes memory homeBlockHeaderRlp,
            uint256 blockNumber,
            bytes memory arbSysAccountProof,
            bytes memory arbSysStorageProof
        ) = abi.decode(input, (bytes, uint256, bytes, bytes));

        // check the block hash matches the block header
        require(homeBlockHash == keccak256(homeBlockHeaderRlp), "block hash must match block header");

        // extract the state root from the block header
        // child chain has it at index 3
        bytes32 stateRoot = _extractFieldFromHeader(homeBlockHeaderRlp, 3);

        // verify the account proof
        (address account, bytes32 storageRoot) = _verifyAccountProof(stateRoot, arbSysAccountProof);

        // make sure the account proven is the arbSys contract
        require(account == arbSys, "account must match arbSys");

        // verify the storage proof
        (uint256 blockHashSlot, bytes32 blockHash) = _verifyStorageProof(storageRoot, arbSysStorageProof);

        // make sure the slot corresponds to the parentBlockHash map
        uint256 expectedSlot = uint256(keccak256(abi.encode(blockNumber, blockHashSlot)));
        require(blockHashSlot == expectedSlot, "unexpected slot");

        require(blockHash != bytes32(0), "block hash not found");

        return blockHash;
    }

    /// @notice Use a parent chain block hash to verify a storage slot.
    /// @param  targetBlockHash The block hash of the parent chain
    /// @param  input ABI encoded (bytes targetBlockHeaderRlp, bytes accountProof, bytes storageProof)
    /// @return account The account on the parent chain
    /// @return slot The storage slot of the account on the parent chain
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
        // parent chain has it at index 3
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
        returns (bytes32 headerField)
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
