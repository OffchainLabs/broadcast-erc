// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {IBroadcaster} from "../standard/interfaces/IBroadcaster.sol";
import {IERC7786GatewaySource} from "../standard/interfaces/IERC7786.sol";

abstract contract ERC7786Broadcaster is IBroadcaster, IERC7786GatewaySource {
    function sendMessage(
        string calldata, /* chainId */
        string calldata receiver,
        bytes calldata data,
        bytes[] calldata /* attributes */
    ) external payable {
        require(bytes(receiver).length == 0); // Only broadcast semantics are supported
        require(data.length == 32); // Message must be 32 bytes

        bytes32 message = bytes32(data);
        broadcastMessage(message);
    }
}
