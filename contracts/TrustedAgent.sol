// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {ITrustedAgent} from "./interfaces/ITrustedAgent.sol";
import {IRegisterOfDeeds} from "./interfaces/IRegisterOfDeeds.sol";
import {IDeedToken} from "./interfaces/IDeedToken.sol";

/**
 * @title Trusted Agent base implemetation.
 * See documentation at {ITrustedAgent}.
 * @dev The function `onDeedTransferred(address,uint256,address,address)` needs to be implemented by a child contract.
 */
abstract contract TrustedAgent is IERC165, ITrustedAgent {
    IRegisterOfDeeds public immutable registerOfDeeds;

    bytes4 internal constant _DEED_TRANSFER_NOTIFICATION_RECEIVED = ITrustedAgent.onDeedTransferred.selector;

    constructor(IRegisterOfDeeds registerOfDeeds_) {
        registerOfDeeds = registerOfDeeds_;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ITrustedAgent).interfaceId;
    }

    //==================================================== Trusted Agent ====================================================//

    /// @inheritdoc ITrustedAgent
    function onDeedTransferred(
        IERC721 underlyingToken,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) public virtual override returns (bytes4) {
        IDeedToken deedToken = registerOfDeeds.deedToken(underlyingToken);
        require(msg.sender == address(deedToken), "TrustedAgent: wrong sender");
        _onDeedTransferred(underlyingToken, deedToken, tokenId, previousOwner, newOwner);
        return _DEED_TRANSFER_NOTIFICATION_RECEIVED;
    }

    function _onDeedTransferred(
        IERC721 underlyingToken,
        IDeedToken deedToken,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) internal virtual;

    //============================================== Internal Helper Functions ==============================================//

    /**
     * Access-control function to be used for verification of the ultimate token ownership.
     * @dev Reverts if `sender` is not either the deed owner (if it exists), or the underlying token owner.
     * @param sender the message sender.
     * @param underlyingToken the underlying asset contract.
     * @param tokenId the token identifier.
     */
    function _requireTokenOwnership(
        address sender,
        IERC721 underlyingToken,
        uint256 tokenId
    ) internal {
        require(sender == registerOfDeeds.ownerOf(underlyingToken, tokenId), "TrustedAgent: not token owner");
    }
}
