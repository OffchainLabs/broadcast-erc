// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.6.0 <0.9.0;

import {IBlockHashProver} from "./IBlockHashProver.sol";

/// @notice Reads messages from a broadcaster.
interface IReceiver {
    /// @notice Arguments required to read and verify the block hash of a remote chain.
    /// @param  route The home chain addresses of the BlockHashProverPointers along the route to the remote chain.
    /// @param  bhpInputs The inputs to the BlockHashProver / BlockHashProverCopies.
    struct RemoteReadBlockHashArgs {
        address[] route;
        bytes[] bhpInputs;
    }

    /// @notice Arguments required to read and verify a storage slot of an account on a remote chain.
    /// @param  blockHashArgs The arguments required to read and verify the block hash of a remote chain.
    /// @param  storageProof Proof passed to the last BlockHashProver / BlockHashProverCopy to verify a storage slot given a target block hash.
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

    /// @notice Reads a storage slot of an account on a remote chain.
    /// @param  readArgs A RemoteReadStorageSlotArgs object:
    ///         - The route points to the remote chain
    ///         - The storage proof is for the desired slot
    /// @return remoteAccountId The account ID of the remote account.
    /// @return slot The slot number.
    /// @return slotValue The value of the slot.
    function verifyRemoteSlot(RemoteReadStorageSlotArgs calldata readArgs)
        external
        view
        returns (bytes32 remoteAccountId, uint256 slot, bytes32 slotValue);

    /// @notice Reads the block hash of a remote chain.
    /// @param  readArgs A RemoteReadBlockHashArgs object:
    ///         - The route points to the remote chain
    /// @return routeId The ID of the last BlockHashProverPointer in the route.
    /// @return blockHash The block hash of the remote chain.
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
