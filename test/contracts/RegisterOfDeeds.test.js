const {artifacts, accounts, web3} = require('hardhat');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const interfaces = require('../../src/interfaces/ERC165/Deeds');
const {ERC721Receiver} = require('@animoca/ethereum-contracts-assets/src/interfaces/ERC165/ERC721');
const {behaviors, constants, interfaces: interfaces165} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const fixture = require('../fixture');

const [deployer, owner1, owner2] = accounts;

const tokenId = '1';
const nonExistingToken = '2';

describe('Register of Deeds', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);

  beforeEach(async function () {
    await fixtureLoader(fixture(deployer, owner1, tokenId), this);
  });

  describe('registerUnderlyingToken()', function () {
    it('reverts if the underlying has already been registered', async function () {
      await expectRevert(this.registerOfDeeds.registerUnderlyingToken(this.underlyingToken.address), 'Underlying already registered');
    });

    it('reverts if trying to register a deeds contract', async function () {
      await expectRevert(this.registerOfDeeds.registerUnderlyingToken(this.deedToken.address), 'Underlying cannot be a deed');
    });

    it('emits an UnderlyingTokenRegistered event', async function () {
      const otherToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      const receipt = await this.registerOfDeeds.registerUnderlyingToken(otherToken.address);
      expectEvent(receipt, 'UnderlyingTokenRegistered', {
        underlyingToken: otherToken.address,
        deedToken: await this.registerOfDeeds.deedToken(otherToken.address),
      });
    });
  });

  describe('onERC721Received(address,address,uint256,bytes) (create a deed)', function () {
    it('reverts for a non-registered underlying', async function () {
      const otherToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await otherToken.mint(owner1, tokenId, {from: deployer});
      await expectRevert(
        otherToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.registerOfDeeds.address, tokenId, {
          from: owner1,
        }),
        'Underlying not registered'
      );
    });

    it('reverts if the owner is not properly set', async function () {
      await expectRevert.unspecified(
        this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.registerOfDeeds.address, tokenId, {
          from: owner1,
        })
      );
    });
  });

  // describe('createDeed(address,uint256,address)', function () {
  //   it('reverts for a non-registered underlying', async function () {
  //     const otherToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
  //     await otherToken.mint(owner1, tokenId, {from: deployer});
  //     await expectRevert(
  //       otherToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.registerOfDeeds.address, tokenId, {
  //         from: owner1,
  //       }),
  //       'Underlying not registered'
  //     );
  //   });

  //   it('reverts if the owner is not properly set', async function () {
  //     await expectRevert.unspecified(
  //       this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.registerOfDeeds.address, tokenId, {
  //         from: owner1,
  //       })
  //     );
  //   });
  // });

  describe('destroyDeed(address,uint256)', function () {
    it('reverts if not sent by the agent which created the deed', async function () {
      await expectRevert(this.registerOfDeeds.destroyDeed(this.underlyingToken.address, tokenId, {from: owner1}), 'Not the trusted agent');
    });
  });

  describe('ownerOf(address,uint256)', function () {
    it('reverts for a non-existing token', async function () {
      await expectRevert(this.registerOfDeeds.ownerOf(this.underlyingToken.address, nonExistingToken), 'ERC721: non-existing NFT');
    });

    it('returns the canonical owner when there is no deed', async function () {
      (await this.registerOfDeeds.ownerOf(this.underlyingToken.address, tokenId)).should.be.equal(owner1);
    });

    it('returns the deed owner when there is a deed', async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.trustedAgent.address, tokenId, {
        from: owner1,
      });
      (await this.registerOfDeeds.ownerOf(this.underlyingToken.address, tokenId)).should.be.equal(owner1);
      await this.deedToken.transferFrom(owner1, owner2, tokenId, {from: owner1});
      (await this.registerOfDeeds.ownerOf(this.underlyingToken.address, tokenId)).should.be.equal(owner2);
    });
  });

  describe('ERC165 interfaces', function () {
    beforeEach(async function () {
      this.contract = this.registerOfDeeds;
    });
    behaviors.shouldSupportInterfaces([interfaces165.ERC165.ERC165, interfaces.RegisterOfDeeds, ERC721Receiver]);
  });
});
