// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IDeedToken} from "./IDeedToken.sol";
import {ITrustedAgent} from "./ITrustedAgent.sol";

/**
 * @title ERCXXXX Deeds Standard, Register of Deeds.
 * The Register of Deeds has for mission to trustlessly centralise the ERC71 tokens escrowing requests from Trusted Agents.
 * The Register of Deeds escrows the tokens on behalf of these Trusted Agents while delivering Deed Tokens in return to the original owner.
 * When the Trusted Agent which created a deed asks for its destruction, the escrowed token will be sent to the current owner of the deed.
 * Before tokens can be escrowed by the Register of Deeds, a Deed Token contract must be deployed via `registerUnderlyingToken(address)`.
 * Deed Tokens represent the ultimate ownership of the underlying tokens, and therefore a Deed Token cannot be registered as an underlying.
 * Deed creation happens through the safe reception of ERC721 tokens (`ERC721Receiver`.`onERC721Received(address,address,uint256,bytes)`):
 *  - it is initiated by the Trusted Agent (`operator`),
 *  - the previous owner of the underlying token (`from`) can be either its original owner or the Trusted Agent.
 * @dev See https://eips.ethereum.org/EIPS/eip-XXXX
 * @dev Note: The ERC-165 identifier for this interface is 0xfbd461f9.
 */
interface IRegisterOfDeeds {
    event UnderlyingTokenRegistered(IERC721 underlyingToken, IDeedToken deedToken);
    event DeedCreated(IERC721 underlyingToken, uint256 tokenId, address owner, ITrustedAgent trustedAgent);

    /**
     * Deploys a deeds contract to represent ownership of tokens from `underlyingToken`.
     * This function can be called by anyone.
     * @dev Reverts if a deeds contract has already been deployed for `underlyingToken`.
     * @dev Reverts if `underlyingToken` is itself a deeds contract.
     * @dev Emits an UnderlyingTokenRegistered event.
     * @param underlyingToken the underlying token contract.
     */
    function registerUnderlyingToken(IERC721 underlyingToken) external;

    /**
     * Mints a deed for the owner of a token using the same `tokenId`.
     * This contract takes ownership of the token until the destruction of the deed.
     * @dev Reverts if `underlyingToken` has not been registered.
     * @dev Reverts if the trusted agent sender does not own the token.
     * @dev Reverts if this contract is not approved to transfer the token on behalf of the sender.
     * @dev Emits a DeedCreated event.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     * @param owner the original token owner.
     */
    // function createDeed(
    //     IERC721 underlyingToken,
    //     uint256 tokenId,
    //     address owner
    // ) external;

    /**
     * Destroys a deed and gives back the underlying token ownership to the owner of the deed.
     * @dev Reverts if the sender is not the Trusted Agent which created the deed.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     */
    function destroyDeed(IERC721 underlyingToken, uint256 tokenId) external;

    // optional?
    /**
     * Gets the ultimate owner of a token, whether or not there is a deed in circulation for this token.
     * This is a convenience function.
     * @dev Reverts if the underlying token does not exist.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     * @return the owner of the deed if it exists, else the owner of the underlying token.
     */
    function ownerOf(IERC721 underlyingToken, uint256 tokenId) external returns (address);

    /**
     * Gets the address of the Deed Token contract for `underlyingToken`.
     * @param underlyingToken the underlying asset contract.
     * @return the address of the Deeds Token contract for `underlyingToken`, or the zero address if `underlyingToken` is not registered.
     */
    function deedToken(IERC721 underlyingToken) external view returns (IDeedToken);

    /**
     * Gets the address of the Trusted Agent which created a deed.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     * @return the address of the Trusted Agent which created the deed, or the zero address if the deed does not currently exist.
     */
    function trustedAgent(IERC721 underlyingToken, uint256 tokenId) external view returns (ITrustedAgent);
}
