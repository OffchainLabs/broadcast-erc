// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

/// @notice Message format for the burn and mint migrator.
struct BurnMessage {
    address mintTo;
    uint256 amount;
    uint256 nonce;
}
