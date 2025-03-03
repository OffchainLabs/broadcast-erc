// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

/// @notice Broadcasts messages to receivers.
interface IBroadcaster {
    /// @notice Emitted when a message is broadcast.
    /// @param  message The message that was broadcast by the publisher.
    /// @param  publisher The address of the publisher.
    event MessageBroadcast(bytes32 indexed message, address indexed publisher);

    /// @notice Broadcasts a message. Callers are called "publishers".
    /// @dev    MUST revert if the publisher has already broadcast the message.
    ///         MUST emit MessageBroadcast.
    ///         MUST store block.timestamp in slot keccak(message, msg.sender).
    /// @param  message The message to broadcast.
    function broadcastMessage(bytes32 message) external;

    /// @notice Checks if a message has been broadcast by a publisher.
    /// @param  message The message to check.
    /// @param  publisher The address of the publisher.
    /// @return True if the message has been broadcast by the publisher, false otherwise.
    function hasBroadcast(bytes32 message, address publisher) external view returns (bool);
}
