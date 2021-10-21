const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;

let fixture = undefined;

module.exports = function (deployer, owner, tokenId) {
  return (
    fixture ||
    ((fixture = async function () {
      this.registerOfDeeds = await artifacts.require('RegisterOfDeeds').new({from: deployer});

      this.forwarderRegistry = await artifacts.require('ForwarderRegistry').new({from: deployer});
      this.underlyingToken = await artifacts.require('ERC721Mock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await this.underlyingToken.mint(owner, tokenId, {from: deployer});

      await this.registerOfDeeds.registerUnderlyingToken(this.underlyingToken.address);
      this.deedToken = await artifacts.require('DeedToken').at(await this.registerOfDeeds.deedToken(this.underlyingToken.address));

      this.trustedAgent = await artifacts
        .require('TrustedAgentMock')
        .new(this.underlyingToken.address, this.registerOfDeeds.address, {from: deployer});

      this.underlyingNoMetadataToken = await artifacts.require('ERC721SimpleMock').new(this.forwarderRegistry.address, ZeroAddress, {from: deployer});
      await this.underlyingNoMetadataToken.mint(owner, tokenId, {from: deployer});

      await this.registerOfDeeds.registerUnderlyingToken(this.underlyingNoMetadataToken.address);
      this.deedNoMetadataToken = await artifacts
        .require('DeedToken')
        .at(await this.registerOfDeeds.deedToken(this.underlyingNoMetadataToken.address));

      this.noMetadataTrustedAgent = await artifacts
        .require('TrustedAgentMock')
        .new(this.underlyingNoMetadataToken.address, this.registerOfDeeds.address, true, {from: deployer});
    }),
    fixture)
  );
};
