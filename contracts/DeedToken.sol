// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {AddressIsContract} from "@animoca/ethereum-contracts-core/contracts/utils/types/AddressIsContract.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Metadata} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Metadata.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {ERC721Simple} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/ERC721Simple.sol";
import {IDeedToken} from "./interfaces/IDeedToken.sol";
import {ITrustedAgent} from "./interfaces/ITrustedAgent.sol";
import {IRegisterOfDeeds} from "./interfaces/IRegisterOfDeeds.sol";

// todo enable universal forwarding ?
/**
 * @title Non-Fungible Deed Token.
 * See documentation at {IDeedToken}.
 */
contract DeedToken is ERC721Simple, IERC721Metadata, IDeedToken {
    using AddressIsContract for address;

    /// @inheritdoc IDeedToken
    IRegisterOfDeeds public immutable override registerOfDeeds;

    /// @inheritdoc IDeedToken
    IERC721 public immutable override underlyingToken;

    bytes4 internal constant _DEED_TRANSFER_NOTIFICATION_RECEIVED = ITrustedAgent.onDeedTransferred.selector;

    constructor(IERC721 underlyingToken_) {
        registerOfDeeds = IRegisterOfDeeds(msg.sender);
        underlyingToken = underlyingToken_;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        if (interfaceId == type(IERC721Metadata).interfaceId) {
            return IERC165(address(underlyingToken)).supportsInterface(interfaceId);
        }
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId || interfaceId == type(IDeedToken).interfaceId;
    }

    //=================================================== ERC721Metadata ====================================================//

    /// @inheritdoc IERC721Metadata
    /// @dev Reverts is the underlying asset does not support the ERC721Metadata interface
    function name() external view override returns (string memory) {
        require(IERC165(address(underlyingToken)).supportsInterface(type(IERC721Metadata).interfaceId), "Deed: Metadata not supported");
        return IERC721Metadata(address(underlyingToken)).name();
    }

    /// @inheritdoc IERC721Metadata
    /// @dev Reverts is the underlying asset does not support the ERC721Metadata interface
    function symbol() external view override returns (string memory) {
        require(IERC165(address(underlyingToken)).supportsInterface(type(IERC721Metadata).interfaceId), "Deed: Metadata not supported");
        return IERC721Metadata(address(underlyingToken)).symbol();
    }

    /// @inheritdoc IERC721Metadata
    /// @dev Reverts is the underlying asset does not support the ERC721Metadata interface
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(IERC165(address(underlyingToken)).supportsInterface(type(IERC721Metadata).interfaceId), "Deed: Metadata not supported");
        return IERC721Metadata(address(underlyingToken)).tokenURI(tokenId);
    }

    //====================================================== DeedToken ======================================================//

    /// @inheritdoc IDeedToken
    function create(address owner, uint256 tokenId) external override {
        require(msg.sender == address(registerOfDeeds), "Deed: not the register of deeds");
        _mint(owner, tokenId);
    }

    /// @inheritdoc IDeedToken
    function destroy(uint256 tokenId) external override {
        require(msg.sender == address(registerOfDeeds), "Deed: not the register of deeds");
        _burn(tokenId);
    }

    //============================================ High-level Internal Functions ============================================//

    /**
     * Safely or unsafely transfers some token.
     * @dev For `safe` transfer, see {IERC721-transferFrom(address,address,uint256)}.
     * @dev For un`safe` transfer, see {IERC721-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data,
        bool safe
    ) internal override {
        require(to != address(0), "ERC721: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 owner = _owners[tokenId];
        require(from == address(uint160(owner)), "ERC721: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[tokenId], "ERC721: non-approved sender");
        }
        _owners[tokenId] = uint256(uint160(to));

        if (from != to) {
            // cannot underflow as balance is verified through ownership
            --_nftBalances[from];
            //  cannot overflow as supply cannot overflow
            ++_nftBalances[to];
        }

        emit Transfer(from, to, tokenId);

        ITrustedAgent agent = registerOfDeeds.trustedAgent(underlyingToken, tokenId);
        require(agent.onDeedTransferred(underlyingToken, tokenId, from, to) == _DEED_TRANSFER_NOTIFICATION_RECEIVED, "Deed: agent callback failed");

        if (safe && to.isContract()) {
            require(IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) == _ERC721_RECEIVED, "ERC721: transfer refused");
        }
    }
}
