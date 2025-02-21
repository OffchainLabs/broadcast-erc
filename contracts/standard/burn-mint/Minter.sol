// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IReceiver} from "../interfaces/IReceiver.sol";
import {BurnMessage} from "./BurnMessage.sol";

interface IERC20 {
    function mint(address recipient, uint256 amount) external;
}

/// @notice The mint side of an example one-way cross chain token migrator.
///         This contract must be given minting permissions on its token.
/// @dev    This contract is considered a "subscriber"
contract Minter {
    /// @notice Address of the Burner contract on the other chain.
    address public immutable burner;
    /// @notice The BroadcasterID corresponding to the broadcaster on the other chain that the Burner uses.
    ///         The Minter will only accept messages published by the Burner through this Broadcaster.
    bytes32 public immutable broadcasterId;
    /// @notice The receiver to listen for messages through.
    IReceiver public immutable receiver;
    /// @notice A mapping to keep track of which messages have been processed.
    ///         Subscribers SHOULD keep track of processed messages because the Receiver does not.
    ///         The Broadcaster ensures messages are unique, so true duplicates are not possible.
    mapping(bytes32 => bool) public processedMessages;
    /// @notice The token to mint.
    IERC20 public immutable mintToken;

    constructor(address _burner, bytes32 _broadcasterId, IReceiver _receiver, IERC20 _mintToken) {
        burner = _burner;
        broadcasterId = _broadcasterId;
        receiver = _receiver;
        mintToken = _mintToken;
    }

    /// @notice Mint the tokens when a message is received.
    function mintTokens(IReceiver.RemoteReadArgs calldata broadcasterReadArgs, BurnMessage calldata messageData)
        external
    {
        // calculate the message from the data
        bytes32 message = keccak256(abi.encode(messageData));

        // ensure the message has not been processed
        require(!processedMessages[message], "Minter: Message already processed");

        // verify the broadcast message
        (bytes32 actualBroadcasterId,) = receiver.verifyBroadcastMessage(broadcasterReadArgs, message, burner);

        // ensure the message is from the expected broadcaster
        require(actualBroadcasterId == broadcasterId, "Minter: Invalid broadcaster ID");

        // mark the message as processed
        processedMessages[message] = true;

        // mint tokens to the recipient
        mintToken.mint(messageData.mintTo, messageData.amount);
    }
}
