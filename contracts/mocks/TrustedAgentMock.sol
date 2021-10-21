// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {IRegisterOfDeeds} from "../interfaces/IRegisterOfDeeds.sol";
import {ITrustedAgent} from "../interfaces/ITrustedAgent.sol";
import {IDeedToken} from "../interfaces/IDeedToken.sol";
import {TrustedAgent} from "../TrustedAgent.sol";

contract TrustedAgentMock is TrustedAgent, IERC721Receiver {
    IERC721 public immutable nftContract;

    bool internal immutable acceptCallback;
    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;

    constructor(
        IERC721 nftContract_,
        IRegisterOfDeeds registerOfDeeds_,
        bool acceptCallback_
    ) TrustedAgent(registerOfDeeds_) {
        nftContract = nftContract_;
        acceptCallback = acceptCallback_;
        nftContract_.setApprovalForAll(address(registerOfDeeds_), true);
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return TrustedAgent.supportsInterface(interfaceId) || interfaceId == type(IERC721Receiver).interfaceId;
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
        IERC721 underlyingToken = IERC721(msg.sender);
        require(address(underlyingToken) == address(nftContract), "ERC721Receiver: wrong contract");
        underlyingToken.safeTransferFrom(address(this), address(registerOfDeeds), tokenId, abi.encode(from));
        return _ERC721_RECEIVED;
    }

    //==================================================== Trusted Agent ====================================================//

    /// @inheritdoc ITrustedAgent
    function onDeedTransferred(
        IERC721 underlyingToken,
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) public virtual override returns (bytes4) {
        if (!acceptCallback) {
            return 0xffffffff;
        }
        return super.onDeedTransferred(underlyingToken, tokenId, previousOwner, newOwner);
    }

    function _onDeedTransferred(
        IERC721, /*underlyingToken*/
        IDeedToken, /*deedToken*/
        uint256, /*tokenId*/
        address, /*previousOwner*/
        address /*newOwner*/
    ) internal virtual override {}

    //================================================== Public Functions ===================================================//

    function createDeed(uint256 tokenId) external {
        nftContract.safeTransferFrom(msg.sender, address(registerOfDeeds), tokenId);
    }

    function destroyDeed(uint256 tokenId) external {
        address sender = msg.sender;
        _requireTokenOwnership(sender, nftContract, tokenId);
        registerOfDeeds.destroyDeed(nftContract, tokenId);
    }
}
