// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";

// import {IRegisterOfDeeds} from "./IRegisterOfDeeds.sol";

/**
 * @title ERCXXXX Deeds Standard, Trusted Agent.
 * @dev See https://eips.ethereum.org/EIPS/eip-XXXX
 * @dev Note: The ERC-165 identifier for this interface is 0x58d179a5.
 */
interface ITrustedAgent {
    // optional
    // function registerOfDeeds() external view returns (IRegisterOfDeeds);

    /**
     * Handles the change of ownership for a deed which has been created via this agent.
     * @dev Reverts if the sender is not the deed contract deployed for `underlyingToken`.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     * @param previousOwner the previous owner of the deed.
     * @param newOwner the new owner of the deed.
     * @return the magic value `ITrustedAgent.onDeedTransferred.selector`.
     */
    function onDeedTransferred(
        IERC721 underlyingToken,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) external returns (bytes4);
}
