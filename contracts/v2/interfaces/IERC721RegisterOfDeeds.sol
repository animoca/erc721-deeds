// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721DeedToken} from "./IERC721DeedToken.sol";
import {IERC721TrustedAgent} from "./IERC721TrustedAgent.sol";

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
interface IERC721RegisterOfDeeds {
    event TrustedAgentRegistered(IERC721 underlyingToken, IERC721TrustedAgent trustedAgent, IERC721DeedToken deedToken);

    // event DeedCreated(IERC721 underlyingToken, uint256 tokenId, address owner, IERC721TrustedAgent trustedAgent);

    /**
     * Gets the address of the Deed Token contract for `underlyingToken`.
     * @param underlyingToken the underlying token contract.
     * @param agent the trusted agent contract.
     * @return the address of the deed token contract for the underlying token contract and trusted agent,
     *  or the zero address if the pair has not been registered.
     */
    function deedToken(IERC721 underlyingToken, IERC721TrustedAgent agent) external view returns (IERC721DeedToken);

    /**
     * Gets the address of the trusted agent which created a deed.
     * @param underlyingToken the underlying token contract.
     * @param tokenId the token identifier.
     * @return the address of the trusted agent which created the deed, or the zero address if the deed does not currently exist.
     */
    function trustedAgent(IERC721 underlyingToken, uint256 tokenId) external view returns (IERC721TrustedAgent);

    /**
     * Registers a trusted agent for an ERC721 underlying token contract and returns the address of the corresponding deed token contract.
     * If the pair was not registered before, a deed token contract will be deployed.
     * @dev Reverts if `underlyingToken` is itself a deed contract.
     * @dev Emits an UnderlyingTokenRegistered event.
     * @param underlyingToken the underlying token contract.
     * @param agent the trusted agent contract.
     * @return the address of the deed token contract for the underlying token contract and trusted agent.
     */
    function registerTrustedAgent(IERC721 underlyingToken, IERC721TrustedAgent agent) external returns (IERC721DeedToken);

    /**
     * Mints a deed for the owner of an underlying token using the same `tokenId`.
     * The caller of this funtion is registered as the trusted agent for this token.
     * This contract takes ownership of the token until the destruction of the corresponding deed.
     * @dev Reverts if the caller (trusted agent) does not own the token.
     * @dev Reverts if this contract is not approved by the caller (trusted agent) to transfer the token on its behalf.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     * @param owner the original token owner.
     */
    function wrap(
        IERC721 underlyingToken,
        uint256 tokenId,
        address owner
    ) external;

    /**
     * Burns a deed and gives the underlying token ownership to the last deed owner.
     * @dev Reverts if the caller is not the trusted agent which created the deed.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     */
    function unwrap(IERC721 underlyingToken, uint256 tokenId) external;
}
