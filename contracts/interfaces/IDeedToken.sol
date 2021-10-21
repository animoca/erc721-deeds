// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IRegisterOfDeeds} from "./IRegisterOfDeeds.sol";

/**
 * @title ERCXXXX Deeds Standard, Deed Token.
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
