const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;

let fixture = undefined;

module.exports = function (deployer, owner, tokenId) {
  return (
    fixture ||
    ((fixture = async function () {
      this.registerOfDeeds = await artifacts.require('ERC721RegisterOfDeeds').new({from: deployer});

      this.forwarderRegistry = await artifacts.require('ForwarderRegistry').new({from: deployer});
      this.underlyingToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await this.underlyingToken.mint(owner, tokenId, {from: deployer});

      this.trustedAgent = await artifacts
        .require('ERC721TrustedAgentMock')
        .new(this.underlyingToken.address, this.registerOfDeeds.address, true, {from: deployer});

      await this.registerOfDeeds.registerTrustedAgent(this.underlyingToken.address, this.trustedAgent.address);
      this.deedToken = await artifacts
        .require('ERC721DeedToken')
        .at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, this.trustedAgent.address));

      this.refusingTrustedAgent = await artifacts
        .require('ERC721TrustedAgentMock')
        .new(this.underlyingToken.address, this.registerOfDeeds.address, false, {from: deployer});
      await this.registerOfDeeds.registerTrustedAgent(this.underlyingToken.address, this.refusingTrustedAgent.address);
      this.refusingDeedToken = await artifacts
        .require('ERC721DeedToken')
        .at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, this.refusingTrustedAgent.address));

      this.wrongTrustedAgent = await artifacts
        .require('ERC721WrongTrustedAgentMock')
        .new(this.underlyingToken.address, this.registerOfDeeds.address, {from: deployer});
      await this.registerOfDeeds.registerTrustedAgent(this.underlyingToken.address, this.wrongTrustedAgent.address);
      this.wrongDeedToken = await artifacts
        .require('ERC721DeedToken')
        .at(await this.registerOfDeeds.deedToken(this.underlyingToken.address, this.wrongTrustedAgent.address));

      this.underlyingNoMetadataToken = await artifacts.require('ERC721SimpleMock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await this.underlyingNoMetadataToken.mint(owner, tokenId, {from: deployer});

      this.noMetadataTrustedAgent = await artifacts
        .require('ERC721TrustedAgentMock')
        .new(this.underlyingNoMetadataToken.address, this.registerOfDeeds.address, true, {from: deployer});

      await this.registerOfDeeds.registerTrustedAgent(this.underlyingNoMetadataToken.address, this.noMetadataTrustedAgent.address);
      this.deedNoMetadataToken = await artifacts
        .require('ERC721DeedToken')
        .at(await this.registerOfDeeds.deedToken(this.underlyingNoMetadataToken.address, this.noMetadataTrustedAgent.address));
    }),
    fixture)
  );
};
