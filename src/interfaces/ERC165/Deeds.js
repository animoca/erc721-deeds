const {makeInterfaceId} = require('@openzeppelin/test-helpers');

const RegisterOfDeeds_Functions = [
  'registerUnderlyingToken(address)',
  'destroyDeed(address,uint256)',
  'ownerOf(address,uint256)',
  'deedToken(address)',
  'trustedAgent(address,uint256)',
];

const TrustedAgent_Functions = ['onDeedTransferred(address,uint256,address,address)'];

const DeedToken_Functions = ['underlyingToken()', 'registerOfDeeds()', 'create(address,uint256)', 'destroy(uint256)'];

module.exports = {
  RegisterOfDeeds: {
    name: 'RegisterOfDeeds',
    functions: RegisterOfDeeds_Functions,
    id: makeInterfaceId.ERC165(RegisterOfDeeds_Functions),
  }, // '0xfbd461f9'
  TrustedAgent: {
    name: 'TrustedAgent',
    functions: TrustedAgent_Functions,
    id: makeInterfaceId.ERC165(TrustedAgent_Functions),
  }, // '0x58d179a5'
  DeedToken: {
    name: 'DeedToken',
    functions: DeedToken_Functions,
    id: makeInterfaceId.ERC165(DeedToken_Functions),
  }, // '0xd780ad31'
};
