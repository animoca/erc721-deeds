// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721.sol";
import {IERC721Receiver} from "@animoca/ethereum-contracts-assets/contracts/token/ERC721/interfaces/IERC721Receiver.sol";
import {IERC721RegisterOfDeeds} from "../interfaces/IERC721RegisterOfDeeds.sol";
import {IERC721TrustedAgent} from "../interfaces/IERC721TrustedAgent.sol";
import {IERC721DeedToken} from "../interfaces/IERC721DeedToken.sol";

contract ERC721WrongTrustedAgentMock is IERC721Receiver {
    event DeedTransferred();

    IERC721RegisterOfDeeds public immutable registerOfDeeds;
    IERC721 public immutable underlyingToken;

    constructor(IERC721 underlyingToken_, IERC721RegisterOfDeeds registerOfDeeds_) {
        registerOfDeeds = registerOfDeeds_;
        underlyingToken = underlyingToken_;
        underlyingToken_.setApprovalForAll(address(registerOfDeeds_), true);
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
        // require(address(underlyingToken) == msg.sender, "ERC721Receiver: wrong contract");
        underlyingToken.safeTransferFrom(address(this), address(registerOfDeeds), tokenId, abi.encode(from));
        return IERC721Receiver.onERC721Received.selector;
    }
}
