// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";

// import {IRegisterOfDeeds} from "./IRegisterOfDeeds.sol";

/**
 * @title ERCXXXX Deeds Standard, Trusted Agent.
 * A Trusted Agent can be any sort of application which typically requires users to escrow an ERC721 token.
 * This can include features such as delegation, renting, staking, or others.
 * A Trusted Agent is the interface between the users and the Register of Deeds and handles the requests for deed tokens creation and destruction.
 * A Trusted Agent must have an adapted logic to handle the transfer of deeds between users through
    the callback `onDeedTransferred(address,uint256,address,address)`. For example a staking contract would distribute outstanding interests to the
    previous owner before transfer, or a rental contract would handle outstanding payments to the prevous owner.
 * WARNING: There are several levels of trust involved with a Trusted Agent, which apply for both the original owner and a potential deed acquirer:
 *  - since the underlying token is safe-transferred to the RegisterOfDeeds while marking you as the owner.
 *  - as the original deed owner or acquirer, you must ensure the the un-escrowing of the underlying token is correclty implemented
 *    by calling `RegisterOfDeeds`.`destroyDeed(address,uint256)`. If not, the deed owner would not be able to become the underlying token owner.
 *  - the Trusted Agent grants some level of access-control to the deed owner, in particular for un-escrowing,
 *  - the Trusted Agent should work in a fashion that the handling of the deed transfer is fair for the previous owner. An example of an unfair
 *    logic would be that a staking contract locks up the interests for a long period: if the deed is transferred sometime near the end of the lockup
 *    period, the previous owner would get nothing and the new owner would be the beneficiary for some time where it was not yet the deed owner.
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
