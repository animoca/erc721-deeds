const {makeInterfaceId} = require('@openzeppelin/test-helpers');

const ERC721RegisterOfDeeds_Functions = [
  'deedToken(address,address)',
  'trustedAgent(address,uint256)',
  'registerTrustedAgent(address,address)',
  'wrap(address,uint256,address)',
  'unwrap(address,uint256)',
];

const RegisterOfDeeds_Functions = [
  'registerUnderlyingToken(address)',
  'destroyDeed(address,uint256)',
  'ownerOf(address,uint256)',
  'deedToken(address)',
  'trustedAgent(address,uint256)',
];

const TrustedAgent_Functions = ['onDeedTransferred(address,uint256,address,address)'];

const ERC721TrustedAgent_Functions = ['onDeedTransferred(address,uint256,address,address)'];

const DeedToken_Functions = ['underlyingToken()', 'registerOfDeeds()', 'create(address,uint256)', 'destroy(uint256)'];

const ERC721DeedToken_Functions = ['underlyingToken()', 'registerOfDeeds()', 'trustedAgent()', 'mint(address,uint256)', 'burn(uint256)'];

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

  ERC721RegisterOfDeeds: {
    name: 'ERC721RegisterOfDeeds',
    functions: ERC721RegisterOfDeeds_Functions,
    id: makeInterfaceId.ERC165(ERC721RegisterOfDeeds_Functions),
  }, // '0xtodo'
  ERC721TrustedAgent: {
    name: 'ERC721TrustedAgent',
    functions: ERC721TrustedAgent_Functions,
    id: makeInterfaceId.ERC165(ERC721TrustedAgent_Functions),
  }, // '0xtodo'
  ERC721DeedToken: {
    name: 'ERC721DeedToken',
    functions: ERC721DeedToken_Functions,
    id: makeInterfaceId.ERC165(ERC721DeedToken_Functions),
  }, // '0xtodo'
};
