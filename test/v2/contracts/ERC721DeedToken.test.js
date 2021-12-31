const {artifacts, accounts, web3} = require('hardhat');
const {AbiCoder} = require('ethers/utils');
const {BN, expectRevert} = require('@openzeppelin/test-helpers');
const interfaces = require('../../../src/interfaces/ERC165/Deeds');
const {ERC721, ERC721Metadata} = require('@animoca/ethereum-contracts-assets/src/interfaces/ERC165/ERC721');
const {behaviors, constants, interfaces: interfaces165} = require('@animoca/ethereum-contracts-core');
const {EmptyByte, ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {shouldBehaveLikeERC721} = require('@animoca/ethereum-contracts-assets/test/contracts/token/ERC721/behaviors/ERC721.behavior');
const fixture = require('../ERC721Fixture');

const [deployer, owner1, owner2] = accounts;
const abi = new AbiCoder();
const encodedOwner = abi.encode(['address'], [owner1]);

const tokenId = '1';

describe('ERC721 Deed Token (ERC721 behaviour)', function () {
  shouldBehaveLikeERC721({
    contractName: 'ERC721DeedToken',
    nfMaskLength: 32,
    name: 'ERC721Mock',
    symbol: 'E721',
    revertMessages: {
      // ERC721
      NonApproved: 'ERC721: non-approved sender',
      SelfApproval: 'ERC721: self-approval',
      SelfApprovalForAll: 'ERC721: self-approval',
      ZeroAddress: 'ERC721: zero address',
      TransferToZero: 'ERC721: transfer to zero',
      MintToZero: 'ERC721: mint to zero',
      TransferRejected: 'ERC721: transfer refused',
      NonExistingNFT: 'ERC721: non-existing NFT',
      NonOwnedNFT: 'ERC721: non-owned NFT',
      ExistingOrBurntNFT: 'ERC721: existing NFT',
    },
    interfaces: {ERC721: true, ERC721Metadata: true},
    features: {},
    methods: {},
    deploy: async function (deployer) {
      const forwarderRegistry = await artifacts.require('ForwarderRegistry').new({from: deployer});
      const underlyingToken = await artifacts.require('ERC721Mock').new(forwarderRegistry.address, ZeroAddress, {from: deployer});
      const registerOfDeeds = await artifacts.require('ERC721RegisterOfDeeds').new();
      const trustedAgent = await artifacts.require('ERC721TrustedAgentMock').new(underlyingToken.address, registerOfDeeds.address, true);
      await registerOfDeeds.registerTrustedAgent(underlyingToken.address, trustedAgent.address);
      return artifacts.require('ERC721DeedToken').at(await registerOfDeeds.deedToken(underlyingToken.address, trustedAgent.address));
    },
    mint: async function (contract, to, id, _value, overrides) {
      const underlyingToken = await artifacts.require('ERC721Mock').at(await contract.underlyingToken());
      const trustedAgent = await contract.trustedAgent();
      // const trustedAgent = await artifacts.require('ERC721TrustedAgentMock').new(underlyingToken.address, registerOfDeeds, true);
      await underlyingToken.mint(to, id, overrides);
      return underlyingToken.methods['safeTransferFrom(address,address,uint256)'](to, trustedAgent, id, {from: to});
    },
  });
});

describe('ERC721 Deed Token', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);

  beforeEach(async function () {
    await fixtureLoader(fixture(deployer, owner1, tokenId), this);
  });

  context('Underlying is ERC721Metadata', function () {
    describe('name()', function () {
      it('returns the same value as the underlying contract', async function () {
        (await this.deedToken.name()).should.be.equal(await this.underlyingToken.name());
      });
    });

    describe('symbol()', function () {
      it('returns the same value as the underlying contract', async function () {
        (await this.deedToken.symbol()).should.be.equal(await this.underlyingToken.symbol());
      });
    });

    describe('tokenURI(uint256)', function () {
      it('returns the same value as the underlying contract', async function () {
        (await this.deedToken.tokenURI(tokenId)).should.be.equal(await this.underlyingToken.tokenURI(tokenId));
      });
    });

    it('supports the ERC165 interface ERC721Metadata', async function () {
      (await this.deedToken.supportsInterface(ERC721Metadata.id)).should.be.equal(true);
    });
  });

  context('Underlying is not ERC721Metadata', function () {
    describe('name()', function () {
      it('reverts', async function () {
        await expectRevert(this.deedNoMetadataToken.name(), 'Deed: Metadata not supported');
      });
    });

    describe('symbol()', function () {
      it('reverts', async function () {
        await expectRevert(this.deedNoMetadataToken.symbol(), 'Deed: Metadata not supported');
      });
    });

    describe('tokenURI(uint256)', function () {
      it('reverts', async function () {
        await expectRevert(this.deedNoMetadataToken.tokenURI(tokenId), 'Deed: Metadata not supported');
      });
    });

    it('does not support the ERC165 interface ERC721Metadata', async function () {
      (await this.deedNoMetadataToken.supportsInterface(ERC721Metadata.id)).should.be.equal(false);
    });
  });

  describe('mint(address,uint256)', function () {
    it('reverts if not sent by the register of deeds', async function () {
      await expectRevert(this.deedToken.mint(owner1, tokenId, {from: owner1}), 'Deed: not the register of deeds');
    });
  });

  describe('burn(uint256)', function () {
    it('reverts if not sent by the register of deeds', async function () {
      await expectRevert(this.deedToken.burn(tokenId, {from: owner1}), 'Deed: not the register of deeds');
    });
  });

  describe('transfers', function () {
    it('reverts if the trusted agent is not a contract', async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256,bytes)'](
        owner1,
        this.registerOfDeeds.address,
        tokenId,
        encodedOwner,
        {from: owner1}
      );
      // await this.registerOfDeeds.createDeed(this.underlyingToken.address, token2, owner1, {from: owner1});
      await expectRevert.unspecified(this.deedToken.transferFrom(owner1, owner2, tokenId, {from: owner1}));
      await expectRevert.unspecified(this.deedToken.methods['safeTransferFrom(address,address,uint256)'](owner1, owner2, tokenId, {from: owner1}));
      await expectRevert.unspecified(
        this.deedToken.methods['safeTransferFrom(address,address,uint256,bytes)'](owner1, owner2, tokenId, EmptyByte, {from: owner1})
      );
    });

    it('reverts if the trusted agent returns a wrong value', async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.refusingTrustedAgent.address, tokenId, {
        from: owner1,
      });
      await expectRevert(this.refusingDeedToken.transferFrom(owner1, owner2, tokenId, {from: owner1}), 'Deed: agent callback failed');
      await expectRevert(
        this.refusingDeedToken.methods['safeTransferFrom(address,address,uint256)'](owner1, owner2, tokenId, {from: owner1}),
        'Deed: agent callback failed'
      );
      await expectRevert(
        this.refusingDeedToken.methods['safeTransferFrom(address,address,uint256,bytes)'](owner1, owner2, tokenId, EmptyByte, {from: owner1}),
        'Deed: agent callback failed'
      );
    });

    it('reverts if the trusted agent contract does not implement the callback interface', async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256)'](owner1, this.wrongTrustedAgent.address, tokenId, {
        from: owner1,
      });
      await expectRevert.unspecified(this.wrongDeedToken.transferFrom(owner1, owner2, tokenId, {from: owner1}));
      await expectRevert.unspecified(
        this.wrongDeedToken.methods['safeTransferFrom(address,address,uint256)'](owner1, owner2, tokenId, {from: owner1})
      );
      await expectRevert.unspecified(
        this.wrongDeedToken.methods['safeTransferFrom(address,address,uint256,bytes)'](owner1, owner2, tokenId, EmptyByte, {from: owner1})
      );
    });

    it('reverts if the trusted agent is an EOA', async function () {
      await this.underlyingToken.methods['safeTransferFrom(address,address,uint256,bytes)'](
        owner1,
        this.registerOfDeeds.address,
        tokenId,
        encodedOwner,
        {
          from: owner1,
        }
      );

      const deedToken = await artifacts.require('ERC721DeedToken').at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, owner1));
      await expectRevert.unspecified(deedToken.transferFrom(owner1, owner2, tokenId, {from: owner1}));
      await expectRevert.unspecified(deedToken.methods['safeTransferFrom(address,address,uint256)'](owner1, owner2, tokenId, {from: owner1}));
      await expectRevert.unspecified(
        deedToken.methods['safeTransferFrom(address,address,uint256,bytes)'](owner1, owner2, tokenId, EmptyByte, {from: owner1})
      );
    });
  });

  describe('ERC165 interfaces', function () {
    beforeEach(async function () {
      this.contract = this.deedToken;
    });
    behaviors.shouldSupportInterfaces([interfaces165.ERC165.ERC165, ERC721, interfaces.ERC721DeedToken]);
  });
});
