# ERC721 Deeds

[![Coverage Status](https://codecov.io/gh/animoca/erc721-deeds/graph/badge.svg)](https://codecov.io/gh/animoca/erc721-deeds)

## Simple Summary

A standard for deed tokens representing ownership of escrowed non-fungible tokens.

## Abstract

This standard allows for the creation of deed tokens for ERC721 tokens while they are under escrow in a smart-contract. Deed tokens represent the ultimate ownership of a non-fungible token: at the end of the escrow, the owner of the deed token will become the owner of the underlying token.

## Motivation

Escrowing (ownership lockup) of non-fungible tokens is a typical feature which can apply to use-cases such as staking, rental or delegation.

One problem which arises with escrowing is that the locked token cannot be exchanged or sold by its original owner, which can be counter-intuitive: in the real world, renting out a real-estate asset does not prevent the owner from selling the property, getting dividends out of a stock does not prevent to sell it out, etc.

By introducing the concept of a non-fungible token deed, we allow a token owner to trade the property of the token while it is being escrowed.

## Specification

This standard proposed three types of contracts: the **Register Of Deeds**, the **Deed Tokens** and the **Trusted Agents**.

- The **Register Of Deeds**:

 1. The Register of Deeds has for mission to trustlessly centralise the ERC71 tokens escrowing requests from Trusted Agents.
 2. The Register of Deeds is unique per network.
 3. The Register of Deeds escrows the tokens on behalf of these Trusted Agents while delivering Deed Tokens in return to the original owner.
 4. When the Trusted Agent which created a deed asks for its destruction, the escrowed token will be sent to the current owner of the deed.
 5. Before tokens can be escrowed by the Register of Deeds, a Deed Token contract must be deployed via `registerUnderlyingToken(address)`.
 6. Deed Tokens represent the ultimate ownership of the underlying tokens, and therefore a Deed Token cannot be registered as an underlying.

- The **Deed Tokens**:

 1. A Deed Token contract in an ERC721 deployed by the Register of Deeds for a specific underlying ERC721 contract.
 2. A Deed Token contract mimics its underlying contract-level metadata (`name()`, `symbol()`) if provided (ERC721Metadata).
 3. Deed tokens, as long as they exist, represent the ultimate ownership of the underlying tokens while these are escrowed by the Register of Deeds.
 4. Deed tokens mimic the token identifier of the underlying tokens, as well as the token metadata (`tokenURI(uint256)`) if provided (ERC721Metadata).
 5. Deed tokens can be created and destroyed only by the Register of Deeds when fulfilling requests coming from a Trusted Agent.
 6. Deed tokens can be transferred only if the Trusted Agent which created it correctly implements the `onDeedTransferred(address,uint256,address,address)` interface.

- The **Trusted Agents**:

 1. A Trusted Agent can be any sort of application which typically requires users to escrow an ERC721 token.
 2. This can include features such as delegation, renting, staking, or others.
 3. A Trusted Agent is the interface between the users and the Register of Deeds and handles the requests for deed tokens creation and destruction.
 4. A Trusted Agent must have an adapted logic to handle the transfer of deeds between users through
    the callback `onDeedTransferred(address,uint256,address,address)`. For example a staking contract would distribute outstanding interests to the previous owner before transfer, or a rental contract would handle outstanding payments to the prevous owner.

### Interfaces

```solidity
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
     * On reception of a safe token transfer operated by a trusted agent, creates a deed for the original token owner using the same `tokenId`.
     * @dev Reverts if the sender is not a registered underlying token.
     * @dev Reverts if `operator` and `from` are the same and `data` does not contain the abi-encoded original token owner.
     * @dev Emits a DeedCreated event.
     * @param operator the trusted agent requesting the deed creation.
     * @param from the trusted agent if it had the token ownership, otherwise the original token owner.
     * @param tokenId the token identifier.
     * @param data the abi-encoded original token owner if the trusted agent had the token ownership, otherwise unused.
     * @return the magic value `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);

    /**
     * Destroys a deed and gives back the underlying token ownership to the owner of the deed.
     * @dev Reverts if the sender is not the Trusted Agent which created the deed.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     */
    function destroyDeed(IERC721 underlyingToken, uint256 tokenId) external;

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
```

```solidity
interface IDeedToken {
    /**
     * Gets the underlying token contract for which these deeds represent ownership.
     * @return the underlying token contract for which these deeds represent ownership.
     */
    function underlyingToken() external view returns (IERC721);

    /**
     * Gets the register of deeds which deployed this contract.
     * @return the register of deeds which deployed this contract.
     */
    function registerOfDeeds() external view returns (IRegisterOfDeeds);

    /**
     * Mints a deed for owner.
     * @dev Reverts if the sender is not the register of deeds.
     */
    function create(address owner, uint256 tokenId) external;

    /**
     * Burns a deed.
     * @dev Reverts if the sender is not the register of deeds.
     */
    function destroy(uint256 tokenId) external;
}
```

```solidity
interface ITrustedAgent {
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
```

## Rationale

The management of deed tokens offers a solution for ownership tradability while underlying tokens are escrowed. The unicity of the Register of Deeds ensures that there is at most one deed token per underlying token in circulation at a given time.

## Backward compatibility

This standard is fully compatible with all existing ERC721 tokens. Escrowing **Trusted Agents** must be implemented with respect to this specification in order for deeds to be transferred.

In order to support deed tokens, a market place should display the origin of a deed token:

- The **Deed Token** contract deployer should be the canonical **Register of Deeds** of the network.
- The **Trusted Agent** should be checked by the acquirer to ensure it is trusted, for example by cross-referencing with a list of official trusted agents from the underlyingtoken publisher.

## Test Cases

Unit tests:

```bash
yarn test
```

Coverage:

```bash
yarn coverage
```

## Implementation

[Github Repository](https://github.com/animoca/erc721-deeds).

## Security Considerations

The **Register Of Deeds** is trustless.

Before acquiring a **Deed Token** from a third party, a user must ensure the following:

- the Deed Token contract has been deployed by the canonical Register of Deeds of the current network,
- the Trusted Agent (`RegisterOfDeeeds`.`trustedAgent(address,uint256)`) must be trusted (see `ITrustedAgent for details`).

There are several levels of trust involved with a **Trusted Agent**, which apply for both the original owner and a potential deed acquirer:

- since the underlying token is safe-transferred to the RegisterOfDeeds while marking you as the owner.
- as the original deed owner or acquirer, you must ensure the the un-escrowing of the underlying token is correclty implemented
  by calling `RegisterOfDeeds`.`destroyDeed(address,uint256)`. If not, the deed owner would not be able to become the underlying token owner.
- the Trusted Agent grants some level of access-control to the deed owner, in particular for un-escrowing,
- the Trusted Agent should work in a fashion that the handling of the deed transfer is fair for the previous owner. An example of an unfair
  logic would be that a staking contract locks up the interests for a long period: if the deed is transferred sometime near the end of the lockup period, the previous owner would get nothing and the new owner would be the beneficiary for some time where it was not yet the deed owner.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
