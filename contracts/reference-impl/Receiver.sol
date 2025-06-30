// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IReceiver} from "../standard/interfaces/IReceiver.sol";
import {IBlockHashProver} from "../standard/interfaces/IBlockHashProver.sol";
import {IBlockHashProverPointer} from "../standard/interfaces/IBlockHashProverPointer.sol";
import "../standard/Constants.sol";

/// @notice Reference implementation of an IReceiver
contract Receiver is IReceiver {
    /// @inheritdoc IReceiver
    mapping(bytes32 => IBlockHashProver) public blockHashProverCopy;

    /// @inheritdoc IReceiver
    function verifyBroadcastMessage(
        RemoteReadStorageSlotArgs calldata broadcasterReadArgs,
        bytes32 message,
        address publisher
    ) external view returns (bytes32, uint256) {
        // read the message slot from the broadcaster
        (bytes32 broadcasterId, uint256 messageSlot, bytes32 slotValue) = verifyRemoteSlot(broadcasterReadArgs);

        // ensure slotValue is non-zero
        require(slotValue != 0, "broadcast message not found");

        // calculate the expected slot
        uint256 expectedSlot = uint256(keccak256(abi.encode(message, publisher)));

        // check that the expected slot was proven
        require(messageSlot == expectedSlot, "broadcast message not in expected slot");

        // return the broadcasterId and timestamp
        return (broadcasterId, uint256(slotValue));
    }

    /// @notice Iterate over BHP's to obtain the block hash of a remote chain and finally read a storage slot.
    function verifyRemoteSlot(RemoteReadStorageSlotArgs calldata readArgs)
        public
        view
        returns (bytes32 remoteAccountId, uint256 slot, bytes32 slotValue)
    {
        require(
            readArgs.blockHashArgs.route.length == readArgs.blockHashArgs.bhpInputs.length,
            "route.length must equal blockHashProverInputs.length"
        );

        require(readArgs.blockHashArgs.route.length > 0, "route must have at least one element");

        // get the block hash of the remote chain and the last prover used to verify it
        bytes32 blockHash;
        IBlockHashProver lastProver;
        (remoteAccountId, blockHash, lastProver) = _verifyRemoteBlockHashInternal(readArgs.blockHashArgs);

        // now that the block hash has been obtained,
        // use the last prover to verify proofs to read the slot
        address remoteAccount;
        (remoteAccount, slot, slotValue) = lastProver.verifyStorageSlot(blockHash, readArgs.storageProof);

        // finally, calculate and set the remoteAccountId by adding the remoteAccount to the accumulator
        remoteAccountId = _acc(remoteAccountId, remoteAccount);
    }

    function verifyRemoteBlockHash(RemoteReadBlockHashArgs calldata readArgs)
        external
        view
        returns (bytes32 routeId, bytes32 blockHash)
    {
        (routeId, blockHash,) = _verifyRemoteBlockHashInternal(readArgs);
    }

    /// @inheritdoc IReceiver
    function updateBlockHashProverCopy(RemoteReadStorageSlotArgs calldata bhpPointerReadArgs, IBlockHashProver bhpCopy)
        external
        returns (bytes32 bhpPointerId)
    {
        // read the block hash prover pointer slot
        uint256 slot;
        bytes32 bhpCodeHash;
        (bhpPointerId, slot, bhpCodeHash) = verifyRemoteSlot(bhpPointerReadArgs);

        // ensure the slot is the correct slot
        require(slot == BLOCK_HASH_PROVER_POINTER_SLOT, "slot must match BLOCK_HASH_PROVER_POINTER_SLOT");

        // check code hash
        require(address(bhpCopy).codehash == bhpCodeHash, "code hash must match");

        // check increasing versions
        IBlockHashProver oldProverCopy = blockHashProverCopy[bhpPointerId];
        require(oldProverCopy.version() < bhpCopy.version(), "new version must be greater than old version");

        // set the copy in storage
        blockHashProverCopy[bhpPointerId] = bhpCopy;
    }

    /// @dev Verify the block hash of a remote chain and return the last prover used to verify it.
    ///      Returning the last prover is useful for verifying storage slots.
    function _verifyRemoteBlockHashInternal(RemoteReadBlockHashArgs calldata readArgs)
        internal
        view
        returns (bytes32 routeId, bytes32 blockHash, IBlockHashProver prover)
    {
        require(
            readArgs.route.length == readArgs.bhpInputs.length, "route.length must equal blockHashProverInputs.length"
        );

        require(readArgs.route.length > 0, "route must have at least one element");

        // iterate over the BHP's to get the block hash of the remote chain
        for (uint256 i = 0; i < readArgs.route.length; i++) {
            // add the BHPPointer to the accumulator
            routeId = _acc(routeId, readArgs.route[i]);

            if (i == 0) {
                // the first pointer in the route is handled specially.
                // instead of calling a copy, we get the implementation directly from the pointer and call it directly
                prover = IBlockHashProver(IBlockHashProverPointer(readArgs.route[0]).implementationAddress());
                blockHash = prover.getTargetBlockHash(readArgs.bhpInputs[i]);
            } else {
                // get the prover copy from storage, ensure it exists, and verify the block hash
                prover = blockHashProverCopy[routeId];
                require(address(prover) != address(0), "prover copy not found");
                blockHash = prover.verifyTargetBlockHash(blockHash, readArgs.bhpInputs[i]);
            }
        }
    }

    function _acc(bytes32 acc, address addr) internal pure returns (bytes32) {
        return keccak256(abi.encode(acc, addr));
    }
}
