// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBlockHashProverPointer} from "../standard/interfaces/IBlockHashProverPointer.sol";
import "../standard/Constants.sol";

/// @notice Reference implementation of a BHPPointer
contract BlockHashProverPointer is IBlockHashProverPointer, Ownable {
    /// @dev Implementation Address does not need to be stored in a specific slot.
    address public implementationAddress;

    constructor() Ownable(msg.sender) {}

    /// @notice Privileged function to update the BHP.
    function setBHP(address bhp) external onlyOwner {
        implementationAddress = bhp;
        _storeCodeHash(bhp.codehash);
        emit ProverUpdated(bhp);
    }

    /// @dev Return the code hash stored in BLOCK_HASH_PROVER_POINTER_SLOT.
    function implementationCodeHash() external view override returns (bytes32 codeHash) {
        uint256 slot = BLOCK_HASH_PROVER_POINTER_SLOT;
        assembly {
            codeHash := sload(slot)
        }
    }

    /// @dev Store the code hash in BLOCK_HASH_PROVER_POINTER_SLOT.
    function _storeCodeHash(bytes32 codeHash) internal {
        uint256 slot = BLOCK_HASH_PROVER_POINTER_SLOT;
        assembly {
            sstore(slot, codeHash)
        }
    }
}
