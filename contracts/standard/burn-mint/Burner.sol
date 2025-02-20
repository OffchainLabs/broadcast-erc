// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IBroadcaster} from "../interfaces/IBroadcaster.sol";
import {BurnMessage} from "./BurnMessage.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

/// @notice The burn side of an example one-way cross chain token migrator.
/// @dev    This contract is considered a "publisher"
contract Burner {
    /// @notice The token to burn.
    IERC20 public immutable burnToken;
    /// @notice The broadcaster to publish messages through.
    IBroadcaster public immutable broadcaster;
    /// @notice An incrementing nonce, so each burn is a unique message.
    uint256 public burnCount;

    /// @notice Event emitted when tokens are burned.
    /// @dev    Publishers SHOULD emit enough information to reconstruct the message.
    event Burn(BurnMessage messageData);

    constructor(IERC20 _burnToken, IBroadcaster _broadcaster) {
        burnToken = _burnToken;
        broadcaster = _broadcaster;
    }

    /// @notice Burn the tokens and broadcast the event.
    ///         The corresponding token minter will subscribe to the message on another chain and mint the tokens.
    function burn(address mintTo, uint256 amount) external {
        // first, pull in the tokens and burn them
        burnToken.transferFrom(msg.sender, address(this), amount);
        burnToken.burn(amount);

        // next, build a unique message
        BurnMessage memory messageData = BurnMessage({mintTo: mintTo, amount: amount, nonce: burnCount++});
        bytes32 message = keccak256(abi.encode(messageData));

        // finally, broadcast the message
        broadcaster.broadcastMessage(message);

        emit Burn(messageData);
    }
}
