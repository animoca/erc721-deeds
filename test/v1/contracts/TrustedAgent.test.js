const {artifacts, accounts, web3} = require('hardhat');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const interfaces = require('../../../src/interfaces/ERC165/Deeds');
const {ERC721Receiver} = require('@animoca/ethereum-contracts-assets/src/interfaces/ERC165/ERC721');
const {behaviors, constants, interfaces: interfaces165} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const fixture = require('../fixture');

const [deployer, owner1, owner2] = accounts;

const tokenId = '1';

describe('Trusted Agent', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);

  beforeEach(async function () {
    await fixtureLoader(fixture(deployer, owner1, tokenId), this);
  });

  describe('onERC71Received (create a deed)', function () {
    it('reverts if the NFT contract is incorrect', async function () {
      const otherToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await otherToken.mint(owner1, tokenId, {from: deployer});
      await expectRevert(
        otherToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.trustedAgent.address, tokenId, {
          from: owner1,
        }),
        'ERC721Receiver: wrong contract'
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        this.receipt = await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.trustedAgent.address, tokenId, {
          from: owner1,
        });
      });

      it('escrows the token in the Register of Deeds', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.underlyingToken, 'Transfer', {
          _from: this.trustedAgent.address,
          _to: this.registerOfDeeds.address,
          _tokenId: tokenId,
        });
      });

      it('mints a deed token to the owner', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.deedToken, 'Transfer', {
          _from: ZeroAddress,
          _to: owner1,
          _tokenId: tokenId,
        });
      });

      it('emits a DeedCreated event', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.registerOfDeeds, 'DeedCreated', {
          underlyingToken: this.underlyingToken.address,
          tokenId: tokenId,
          owner: owner1,
          trustedAgent: this.trustedAgent.address,
        });
      });
    });
  });

  describe('createDeed(uint256)', function () {
    beforeEach(async function () {
      await this.underlyingToken.approve(this.trustedAgent.address, tokenId, {from: owner1});
      this.receipt = await this.trustedAgent.createDeed(tokenId, {from: owner1});
    });

    it('escrows the token in the Register of Deeds', async function () {
      await expectEvent.inTransaction(this.receipt.tx, this.underlyingToken, 'Transfer', {
        _from: owner1,
        _to: this.registerOfDeeds.address,
        _tokenId: tokenId,
      });
    });

    it('mints a deed token to the owner', async function () {
      await expectEvent.inTransaction(this.receipt.tx, this.deedToken, 'Transfer', {
        _from: ZeroAddress,
        _to: owner1,
        _tokenId: tokenId,
      });
    });

    it('emits a DeedCreated event', async function () {
      await expectEvent.inTransaction(this.receipt.tx, this.registerOfDeeds, 'DeedCreated', {
        underlyingToken: this.underlyingToken.address,
        tokenId: tokenId,
        owner: owner1,
        trustedAgent: this.trustedAgent.address,
      });
    });
  });

  describe('destroyDeed()', function () {
    function behaveLikeDeedDestruction(deedOwner, otherAccount) {
      it('reverts if the sender is not the deed owner', async function () {
        await expectRevert(this.trustedAgent.destroyDeed(tokenId, {from: otherAccount}), 'TrustedAgent: not token owner');
      });

      context('when successful', function () {
        beforeEach(async function () {
          this.receipt = await this.trustedAgent.destroyDeed(tokenId, {from: deedOwner});
        });

        it('burns the deed token', async function () {
          await expectEvent.inTransaction(this.receipt.tx, this.deedToken, 'Transfer', {
            _from: deedOwner,
            _to: ZeroAddress,
            _tokenId: tokenId,
          });
        });

        it('gives back the token to the deed owner', async function () {
          await expectEvent.inTransaction(this.receipt.tx, this.underlyingToken, 'Transfer', {
            _from: this.registerOfDeeds.address,
            _to: deedOwner,
            _tokenId: tokenId,
          });
        });
      });
    }

    beforeEach(async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.trustedAgent.address, tokenId, {
        from: owner1,
      });
    });

    context('from the original owner', function () {
      behaveLikeDeedDestruction(owner1, owner2);
    });

    context('from the another owner after deed transfer', function () {
      beforeEach(async function () {
        await this.deedToken.transferFrom(owner1, owner2, tokenId, {from: owner1});
      });
      behaveLikeDeedDestruction(owner2, owner1);
    });
  });

  describe('onDeedTransferred(address,uint256,address,address)', function () {
    it('reverts if the sender is not the deed token contract', async function () {
      await expectRevert(
        this.trustedAgent.onDeedTransferred(this.underlyingToken.address, tokenId, owner1, owner2, {from: owner1}),
        'TrustedAgent: wrong sender'
      );
    });
  });

  describe('ERC165 interfaces', function () {
    beforeEach(async function () {
      this.contract = this.trustedAgent;
    });
    behaviors.shouldSupportInterfaces([interfaces165.ERC165.ERC165, interfaces.TrustedAgent, ERC721Receiver]);
  });
});
