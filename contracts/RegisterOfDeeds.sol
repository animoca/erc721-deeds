// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {IDeedToken} from "./interfaces/IDeedToken.sol";
import {ITrustedAgent} from "./interfaces/ITrustedAgent.sol";
import {IRegisterOfDeeds} from "./interfaces/IRegisterOfDeeds.sol";
import {DeedToken} from "./DeedToken.sol";

contract RegisterOfDeeds is IERC165, IRegisterOfDeeds, IERC721Receiver {
    /// @inheritdoc IRegisterOfDeeds
    mapping(IERC721 => IDeedToken) public override deedToken;

    /// @inheritdoc IRegisterOfDeeds
    mapping(IERC721 => mapping(uint256 => ITrustedAgent)) public override trustedAgent;

    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IRegisterOfDeeds).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    //=================================================== RegisterOfDeeds ===================================================//

    /// @inheritdoc IRegisterOfDeeds
    function registerUnderlyingToken(IERC721 underlyingToken) external override {
        require(deedToken[underlyingToken] == IDeedToken(0), "Underlying already registered");
        require(!IERC165(address(underlyingToken)).supportsInterface(type(IDeedToken).interfaceId), "Underlying cannot be a deed");
        IDeedToken deed = new DeedToken(underlyingToken);
        deedToken[underlyingToken] = deed;
        emit UnderlyingTokenRegistered(underlyingToken, deed);
    }

    /// @inheritdoc IRegisterOfDeeds
    // function createDeed(
    //     IERC721 underlyingToken,
    //     uint256 tokenId,
    //     address owner
    // ) external override {
    //     IDeedToken deed = deedToken[underlyingToken];
    //     require(address(deed) != address(0), "Underlying not registered");

    //     ITrustedAgent agent = ITrustedAgent(msg.sender);
    //     trustedAgent[underlyingToken][tokenId] = agent;

    //     underlyingToken.transferFrom(address(agent), address(this), tokenId);
    //     deed.create(owner, tokenId);

    //     emit DeedCreated(underlyingToken, tokenId, owner, agent);
    // }

    /**
     * On reception of a safe token transfer operated by a trusted agent, creates a deed for the original token owner using the same `tokenId`.
     * @dev Reverts if the sender is not a registered underlying token.
     * @dev Reverts if `operator` and `from` are the same and `data` does not contain the abi-encoded original token owner.
     * @dev Emits a DeedCreated event.
     * @param operator the trusted agent requesting the deed creation.
     * @param from the trusted agent if it had the token ownership, otherwise the original token owner.
     * @param tokenId the token identifier.
     * @param data the abi-encoded original token owner if the trusted agent had the token ownership, otherwise unused.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        IERC721 underlyingToken = IERC721(msg.sender);
        IDeedToken deed = deedToken[underlyingToken];
        require(address(deed) != address(0), "Underlying not registered");

        ITrustedAgent agent = ITrustedAgent(operator);
        trustedAgent[underlyingToken][tokenId] = agent;

        address owner;
        if (operator == from) {
            owner = abi.decode(data, (address));
        } else {
            owner = from;
        }

        deed.create(owner, tokenId);

        emit DeedCreated(underlyingToken, tokenId, owner, agent);

        return _ERC721_RECEIVED;
    }

    /// @inheritdoc IRegisterOfDeeds
    function destroyDeed(IERC721 underlyingToken, uint256 tokenId) external override {
        ITrustedAgent agent = trustedAgent[underlyingToken][tokenId];
        require(msg.sender == address(agent), "Not the trusted agent");
        trustedAgent[underlyingToken][tokenId] = ITrustedAgent(0);

        IDeedToken deed = deedToken[underlyingToken];
        address owner = IERC721(address(deed)).ownerOf(tokenId);
        deed.destroy(tokenId);
        underlyingToken.transferFrom(address(this), owner, tokenId);
    }

    /// @inheritdoc IRegisterOfDeeds
    function ownerOf(IERC721 underlyingToken, uint256 tokenId) external view override returns (address) {
        ITrustedAgent agent = trustedAgent[underlyingToken][tokenId];
        if (agent == ITrustedAgent(0)) {
            return underlyingToken.ownerOf(tokenId);
        }
        return IERC721(address(deedToken[underlyingToken])).ownerOf(tokenId);
    }
}
