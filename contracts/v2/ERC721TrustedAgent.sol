// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721TrustedAgent} from "./interfaces/IERC721TrustedAgent.sol";
import {IERC721RegisterOfDeeds} from "./interfaces/IERC721RegisterOfDeeds.sol";
import {IERC721DeedToken} from "./interfaces/IERC721DeedToken.sol";

/**
 * @title Trusted Agent base implemetation.
 * See documentation at {IERC721TrustedAgent}.
 * @dev The function `onDeedTransferred(address,uint256,address,address)` needs to be implemented by a child contract.
 */
abstract contract ERC721TrustedAgent is IERC165, IERC721TrustedAgent {
    IERC721RegisterOfDeeds public immutable registerOfDeeds;

    constructor(IERC721RegisterOfDeeds registerOfDeeds_) {
        registerOfDeeds = registerOfDeeds_;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721TrustedAgent).interfaceId;
    }

    //==================================================== Trusted Agent ====================================================//

    /// @inheritdoc IERC721TrustedAgent
    function onDeedTransferred(
        IERC721 underlyingToken,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) public virtual override returns (bytes4) {
        IERC721DeedToken deedToken = registerOfDeeds.deedToken(underlyingToken, IERC721TrustedAgent(address(this)));
        require(msg.sender == address(deedToken), "TrustedAgent: wrong sender");
        _onDeedTransferred(underlyingToken, deedToken, tokenId, previousOwner, newOwner);
        return IERC721TrustedAgent.onDeedTransferred.selector;
    }

    /// @dev to be overriden with agent-specific logic
    function _onDeedTransferred(
        IERC721, // underlyingToken,
        IERC721DeedToken, // deedToken,
        uint256, // tokenId,
        address, // previousOwner,
        address // newOwner
    ) internal virtual {}
}
