const {artifacts, accounts, web3} = require('hardhat');
const {AbiCoder} = require('ethers/utils');
const {BN, expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const interfaces = require('../../../src/interfaces/ERC165/Deeds');
const {ERC721Receiver} = require('@animoca/ethereum-contracts-assets/src/interfaces/ERC165/ERC721');
const {behaviors, constants, interfaces: interfaces165} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const fixture = require('../ERC721Fixture');

const abi = new AbiCoder();

const [deployer, owner1, owner2] = accounts;

const tokenId = '1';

describe('ERC721 Register of Deeds', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);

  beforeEach(async function () {
    await fixtureLoader(fixture(deployer, owner1, tokenId), this);
  });

  describe('registerTrustedAgent()', function () {
    it('reverts if trying to register a deeds contract', async function () {
      await expectRevert(this.registerOfDeeds.registerTrustedAgent(this.deedToken.address, ZeroAddress), 'Underlying cannot be a deed');
    });

    context('when successful', function () {
      const trustedAgent = ZeroAddress;

      beforeEach(async function () {
        this.receipt = await this.registerOfDeeds.registerTrustedAgent(this.underlyingToken.address, trustedAgent);
      });

      it('sets the deedToken', async function () {
        const deed = await artifacts.require('ERC721DeedToken').at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, trustedAgent));
        (await deed.trustedAgent()).should.be.equal(trustedAgent);
      });

      it('emits a TrustedAgentRegistered event', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.registerOfDeeds, 'TrustedAgentRegistered', {
          underlyingToken: this.underlyingToken.address,
          trustedAgent: trustedAgent,
          deedToken: await this.registerOfDeeds.deedToken(this.underlyingToken.address, trustedAgent),
        });
      });
    });
  });

  describe('onERC721Received(address,address,uint256,bytes) (create a deed)', function () {
    context('when the trusted agent has not been previously registered', function () {
      beforeEach(async function () {
        const encodedOwner = abi.encode(['address'], [owner1]);
        this.receipt = await this.underlyingToken.methods['safeTransferFrom(address,address,uint256,bytes)'](
          owner1,
          this.registerOfDeeds.address,
          tokenId,
          encodedOwner,
          {
            from: owner1,
          }
        );
      });

      it('registers the operator as trusted agent', async function () {
        const deed = await artifacts.require('ERC721DeedToken').at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, owner1));
        (await deed.trustedAgent()).should.be.equal(owner1);
      });

      it('emits a TrustedAgentRegistered event', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.registerOfDeeds, 'TrustedAgentRegistered', {
          underlyingToken: this.underlyingToken.address,
          trustedAgent: owner1,
          deedToken: await this.registerOfDeeds.deedToken(this.underlyingToken.address, owner1),
        });
      });
    });

    context('when the trusted agent has been previously registered', function () {
      beforeEach(async function () {
        this.receipt = await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.trustedAgent.address, tokenId, {
          from: owner1,
        });
      });

      it('does not emit a TrustedAgentRegistered', async function () {
        await expectEvent.not.inTransaction(this.receipt.tx, this.registerOfDeeds, 'TrustedAgentRegistered');
      });
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

  describe('unwrap(address,uint256)', function () {
    it('reverts if not sent by the agent which created the deed', async function () {
      await expectRevert(this.registerOfDeeds.unwrap(this.underlyingToken.address, tokenId, {from: owner1}), 'Not the trusted agent');
    });
  });

  describe('ERC165 interfaces', function () {
    beforeEach(async function () {
      this.contract = this.registerOfDeeds;
    });
    behaviors.shouldSupportInterfaces([interfaces165.ERC165.ERC165, interfaces.ERC721RegisterOfDeeds, ERC721Receiver]);
  });
});
