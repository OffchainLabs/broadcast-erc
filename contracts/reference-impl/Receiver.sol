// SPDX-License-Identifier: UNLICENSED
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
    function verifyBroadcastMessage(RemoteReadArgs calldata broadcasterReadArgs, bytes32 message, address publisher)
        external
        view
        returns (bytes32, uint256)
    {
        // read the message slot from the broadcaster
        (bytes32 broadcasterId, uint256 messageSlot, bytes32 slotValue) = _readRemoteSlot(broadcasterReadArgs);

        // ensure slotValue is non-zero
        require(slotValue != 0, "broadcast message not found");

        // calculate the expected slot
        uint256 expectedSlot = uint256(keccak256(abi.encode(message, publisher)));

        // check that the expected slot was proven
        require(messageSlot == expectedSlot, "broadcast message not in expected slot");

        // return the broadcasterId and timestamp
        return (broadcasterId, uint256(slotValue));
    }

    /// @inheritdoc IReceiver
    function updateBlockHashProverCopy(RemoteReadArgs calldata bhpPointerReadArgs, IBlockHashProver bhpCopy)
        external
        returns (bytes32 bhpPointerId)
    {
        // read the block hash prover pointer slot
        uint256 slot;
        bytes32 bhpCodeHash;
        (bhpPointerId, slot, bhpCodeHash) = _readRemoteSlot(bhpPointerReadArgs);

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

    /// @notice Iterate over BHP's to obtain the block hash of a remote chain and finally read a storage slot.
    function _readRemoteSlot(RemoteReadArgs calldata readArgs)
        internal
        view
        returns (bytes32 remoteAccountId, uint256 slot, bytes32 slotValue)
    {
        require(
            readArgs.route.length == readArgs.bhpInputs.length, "route.length must equal blockHashProverInputs.length"
        );

        require(readArgs.route.length > 0, "route must have at least one element");

        // iterate over the BHP's to get the block hash of the remote chain
        IBlockHashProver prover;
        bytes32 blockHash;
        for (uint256 i = 0; i < readArgs.route.length; i++) {
            // add the BHPPointer to the accumulator
            remoteAccountId = _acc(remoteAccountId, readArgs.route[i]);

            if (i == 0) {
                // the first pointer in the route is handled specially.
                // instead of calling a copy, we get the implementation directly from the pointer and call it directly
                prover = IBlockHashProver(IBlockHashProverPointer(readArgs.route[0]).implementationAddress());
                blockHash = prover.getTargetBlockHash(readArgs.bhpInputs[i]);
            } else {
                // get the prover copy from storage, ensure it exists, and verify the block hash
                prover = blockHashProverCopy[remoteAccountId];
                require(address(prover) != address(0), "prover copy not found");
                blockHash = prover.verifyTargetBlockHash(blockHash, readArgs.bhpInputs[i]);
            }
        }

        // now that the block hash has been obtained,
        // use the last prover to verify proofs to read the slot
        address remoteAccount;
        (remoteAccount, slot, slotValue) = prover.verifyStorageSlot(blockHash, readArgs.storageProof);

        // finally, calculate and set the remoteAccountId by adding the remoteAccount to the accumulator
        remoteAccountId = _acc(remoteAccountId, remoteAccount);
    }

    function _acc(bytes32 acc, address addr) internal pure returns (bytes32) {
        return keccak256(abi.encode(acc, addr));
    }
}
