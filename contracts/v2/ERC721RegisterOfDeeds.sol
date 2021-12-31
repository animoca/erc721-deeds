// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {IERC721DeedToken} from "./interfaces/IERC721DeedToken.sol";
import {IERC721TrustedAgent} from "./interfaces/IERC721TrustedAgent.sol";
import {IERC721RegisterOfDeeds} from "./interfaces/IERC721RegisterOfDeeds.sol";
import {ERC721DeedToken} from "./ERC721DeedToken.sol";

/**
 * @title Register of Deeds.
 * See documentation at {IRegisterOfDeeds}.
 */
// contract RegisterOfDeeds is IERC165, IRegisterOfDeeds, IERC721Receiver {
contract ERC721RegisterOfDeeds is IERC165, IERC721RegisterOfDeeds, IERC721Receiver {
    /// @inheritdoc IERC721RegisterOfDeeds
    mapping(IERC721 => mapping(IERC721TrustedAgent => IERC721DeedToken)) public override deedToken;

    /// @inheritdoc IERC721RegisterOfDeeds
    mapping(IERC721 => mapping(uint256 => IERC721TrustedAgent)) public override trustedAgent;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721RegisterOfDeeds).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    //=================================================== RegisterOfDeeds ===================================================//

    function registerTrustedAgent(IERC721 underlyingToken, IERC721TrustedAgent trustedAgent_) public override returns (IERC721DeedToken) {
        IERC721DeedToken deed = deedToken[underlyingToken][trustedAgent_];
        if (deed == IERC721DeedToken(0)) {
            require(!IERC165(address(underlyingToken)).supportsInterface(type(IERC721DeedToken).interfaceId), "Underlying cannot be a deed");
            deed = new ERC721DeedToken(underlyingToken, trustedAgent_);
            deedToken[underlyingToken][trustedAgent_] = deed;
            emit TrustedAgentRegistered(underlyingToken, trustedAgent_, deed);
        }
        return deed;
    }

    /// @inheritdoc IERC721RegisterOfDeeds
    function wrap(
        IERC721 underlyingToken,
        uint256 tokenId,
        address owner
    ) external override {
        IERC721TrustedAgent agent = IERC721TrustedAgent(msg.sender);
        IERC721DeedToken deed = registerTrustedAgent(underlyingToken, agent);

        trustedAgent[underlyingToken][tokenId] = agent;

        underlyingToken.transferFrom(address(agent), address(this), tokenId);
        deed.mint(owner, tokenId);

        // emit DeedCreated(underlyingToken, tokenId, owner, agent);
    }

    /// @inheritdoc IERC721RegisterOfDeeds
    function unwrap(IERC721 underlyingToken, uint256 tokenId) external override {
        IERC721TrustedAgent agent = trustedAgent[underlyingToken][tokenId];
        require(msg.sender == address(agent), "Not the trusted agent");
        // trustedAgent[underlyingToken][tokenId] = IERC721TrustedAgent(0);

        IERC721DeedToken deed = deedToken[underlyingToken][agent];
        address owner = IERC721(address(deed)).ownerOf(tokenId);
        underlyingToken.transferFrom(address(this), owner, tokenId);
        deed.burn(tokenId);
    }

    /**
     * On reception of a safe token transfer operated by a trusted agent, mints a deed for the original token owner using the same `tokenId`.
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
    ) public virtual override returns (bytes4) {
        IERC721 underlyingToken = IERC721(msg.sender);
        IERC721TrustedAgent agent = IERC721TrustedAgent(operator);
        IERC721DeedToken deed = registerTrustedAgent(underlyingToken, agent);

        trustedAgent[underlyingToken][tokenId] = agent;

        address owner = (operator == from) ? abi.decode(data, (address)) : from;

        deed.mint(owner, tokenId);

        // emit DeedCreated(underlyingToken, tokenId, owner, agent);

        return IERC721Receiver.onERC721Received.selector;
    }
}
