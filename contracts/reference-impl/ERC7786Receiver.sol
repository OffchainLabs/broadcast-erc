// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IReceiver} from "../standard/interfaces/IReceiver.sol";
import {IERC7786Receiver} from "../standard/interfaces/IERC7786.sol";

abstract contract ERC7786Receiver is IReceiver, IERC7786Receiver {
    /// @notice Processes a cross-chain message using ERC-7786 interface
    /// @param payload Message payload containing encoded data for IReceiver.verifyBroadcastMessage or IReceiver.updateBlockHashProverCopy
    function executeMessage(
        string calldata, /* messageId */
        string calldata, /* sourceChain */
        string calldata, /* sender */
        bytes calldata payload,
        bytes[] calldata /*  */
    ) external returns (bytes4) {
        bytes4 selector = bytes4(payload[:4]);

        if (selector == IReceiver.verifyBroadcastMessage.selector) {
            (RemoteReadArgs memory broadcasterReadArgs, bytes32 message, address publisher) =
                abi.decode(payload[0][4:], (RemoteReadArgs, bytes32, address));
            verifyBroadcastMessage(broadcasterReadArgs, message, publisher);
        } else if (selector == IReceiver.updateBlockHashProverCopy.selector) {
            (RemoteReadArgs memory bhpPointerReadArgs, IBlockHashProver bhp) =
                abi.decode(payload[0][4:], (RemoteReadArgs, IBlockHashProver));
            updateBlockHashProverCopy(bhpPointerReadArgs, bhp);
        } else {
            revert("Invalid operation");
        }

        return IERC7786Receiver.executeMessage.selector;
    }
}
