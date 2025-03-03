// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IBlockHashProver} from "./IBlockHashProver.sol";

/// @notice Reads messages from a broadcaster.
interface IReceiver {
    // todo: natspec
    struct RemoteReadBlockHashArgs {
        address[] route;
        bytes[] bhpInputs;
    }

    // todo: natspec
    struct RemoteReadStorageSlotArgs {
        RemoteReadBlockHashArgs blockHashArgs;
        bytes storageProof;
    }

    /// @notice Reads a broadcast message from a remote chain.
    /// @param  broadcasterReadArgs A RemoteReadStorageSlotArgs object:
    ///         - The route points to the broadcasting chain
    ///         - The storage proof is for the broadcaster's message slot
    /// @param  message The message to read.
    /// @param  publisher The address of the publisher who broadcast the message.
    /// @return broadcasterId The broadcaster's unique identifier.
    /// @return timestamp The timestamp when the message was broadcast.
    function verifyBroadcastMessage(
        RemoteReadStorageSlotArgs calldata broadcasterReadArgs,
        bytes32 message,
        address publisher
    ) external view returns (bytes32 broadcasterId, uint256 timestamp);

    // todo: natspec
    function verifyRemoteSlot(RemoteReadStorageSlotArgs calldata readArgs)
        external
        view
        returns (bytes32 remoteAccountId, uint256 slot, bytes32 slotValue);

    // todo: natspec
    function verifyRemoteBlockHash(RemoteReadBlockHashArgs calldata readArgs)
        external
        view
        returns (bytes32 routeId, bytes32 blockHash);

    /// @notice Updates the block hash prover copy in storage.
    ///         Checks that BlockHashProverCopy has the same code hash as stored in the BlockHashProverPointer
    ///         Checks that the version is increasing.
    /// @param  bhpPointerReadArgs A RemoteReadArgs object:
    ///         - The route points to the BlockHashProverPointer's home chain
    ///         - The account proof is for the BlockHashProverPointer's account
    ///         - The storage proof is for the BLOCK_HASH_PROVER_POINTER_SLOT
    /// @param  bhpCopy The BlockHashProver copy on the local chain.
    /// @return bhpPointerId The ID of the BlockHashProverPointer
    function updateBlockHashProverCopy(RemoteReadStorageSlotArgs calldata bhpPointerReadArgs, IBlockHashProver bhpCopy)
        external
        returns (bytes32 bhpPointerId);

    /// @notice The BlockHashProverCopy on the local chain corresponding to the bhpPointerId
    ///         MUST return 0 if the BlockHashProverPointer does not exist.
    function blockHashProverCopy(bytes32 bhpPointerId) external view returns (IBlockHashProver bhpCopy);
}
