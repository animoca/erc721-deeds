// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IRegisterOfDeeds} from "./IRegisterOfDeeds.sol";

/**
 * @title ERCXXXX Deeds Standard, Deed Token.
 * A Deed Token contract in an ERC721 deployed by the Register of Deeds for a specific underlying ERC721 contract.
 * A Deed Token contract mimics its underlying contract-level metadata (`name()`, `symbol()`) if provided (ERC721Metadata).
 * Deed tokens, as long as they exist, represent the ultimate ownership of the underlying tokens while these are escrowed by the Register of Deeds.
 * Deed tokens mimic the token identifier of the underlying tokens, as well as the token metadata (`tokenURI(uint256)`) if provided (ERC721Metadata).
 * Deed tokens can be created and destroyed only by the Register of Deeds when fulfilling requests coming from a Trusted Agent.
 * Deed tokens can be transferred only if the Trusted Agent correctly implements the `onDeedTransferred(address,uint256,address,address)` interface.
 * WARNING: For security, before acquiring a Deed Token from a third party, a user must ensure the following:
 *  - the Deed Token contract has been deployed by the canonical Register of Deeds of the current network,
 *  - the Trusted Agent (`RegisterOfDeeeds`.`trustedAgent(address,uint256)`) must be trusted (see `ITrustedAgent for details`).
 * @dev See https://eips.ethereum.org/EIPS/eip-XXXX
 * @dev Note: The ERC-165 identifier for this interface is 0xd780ad31.
 */
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
