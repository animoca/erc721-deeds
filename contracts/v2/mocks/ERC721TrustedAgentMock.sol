// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {IERC721RegisterOfDeeds} from "../interfaces/IERC721RegisterOfDeeds.sol";
import {IERC721TrustedAgent} from "../interfaces/IERC721TrustedAgent.sol";
import {IERC721DeedToken} from "../interfaces/IERC721DeedToken.sol";
import {ERC721TrustedAgent} from "../ERC721TrustedAgent.sol";

contract ERC721TrustedAgentMock is ERC721TrustedAgent, IERC721Receiver {
    event DeedTransferred();

    IERC721 public immutable underlyingToken;
    bool internal immutable acceptCallback;

    constructor(
        IERC721 underlyingToken_,
        IERC721RegisterOfDeeds registerOfDeeds_,
        bool acceptCallback_
    ) ERC721TrustedAgent(registerOfDeeds_) {
        underlyingToken = underlyingToken_;
        acceptCallback = acceptCallback_;
        underlyingToken_.setApprovalForAll(address(registerOfDeeds_), true);
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return ERC721TrustedAgent.supportsInterface(interfaceId) || interfaceId == type(IERC721Receiver).interfaceId;
    }

    //=================================================== ERC721Receiver ====================================================//

    /// @inheritdoc IERC721Receiver
    /// @dev Reverts if the sender is not the supported ERC721 contract.
    function onERC721Received(
        address, /* operator*/
        address from,
        uint256 tokenId,
        bytes memory /*data*/
    ) public virtual override returns (bytes4) {
        require(address(underlyingToken) == msg.sender, "ERC721Receiver: wrong contract");
        underlyingToken.safeTransferFrom(address(this), address(registerOfDeeds), tokenId, abi.encode(from));
        return IERC721Receiver.onERC721Received.selector;
    }

    //==================================================== Trusted Agent ====================================================//

    /// @inheritdoc IERC721TrustedAgent
    function onDeedTransferred(
        IERC721 underlyingToken_,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) public virtual override returns (bytes4) {
        if (!acceptCallback) {
            return 0xffffffff;
        }
        return super.onDeedTransferred(underlyingToken_, tokenId, previousOwner, newOwner);
    }

    //================================================== Public Functions ===================================================//

    function wrapWithSafeTransfer(uint256 tokenId) external {
        underlyingToken.safeTransferFrom(msg.sender, address(registerOfDeeds), tokenId);
    }

    function wrapWithFunctionCall(uint256 tokenId) external {
        underlyingToken.transferFrom(msg.sender, address(this), tokenId);
        registerOfDeeds.wrap(underlyingToken, tokenId, msg.sender);
    }

    function unwrap(uint256 tokenId) external {
        IERC721 deed = IERC721(address(registerOfDeeds.deedToken(underlyingToken, IERC721TrustedAgent(address(this)))));
        require(msg.sender == deed.ownerOf(tokenId), "TrustedAgent: not deed owner");
        registerOfDeeds.unwrap(underlyingToken, tokenId);
    }
}
