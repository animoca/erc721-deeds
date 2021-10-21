# ERC721 Deeds

[![Coverage Status](https://codecov.io/gh/animoca/erc721-deeds/graph/badge.svg)](https://codecov.io/gh/animoca/erc721-deeds)

## Overview

Todo

### Installation

Install as a module dependency in your host NodeJS project:

```bash
npm install --save-dev @animoca/erc721-deeds
```

or

```bash
yarn add -D @animoca/erc721-deeds
```

### Usage

#### Solidity Contracts

This project contains... <!-- todo -->
Import dependency contracts into your Solidity contracts and derive as needed:

```solidity
import "@animoca/erc721-deeds/contracts/{{Contract Group}}/{{Contract}}.sol"
```

#### Javascript Modules

A set of Javascript modules are also provided.

Require the NodeJS module dependency in your test and migration scripts as needed:

```javascript
const {constants, interfaces, abis} = require("@animoca/erc721-deeds");
```

- `constants`: project-specific constants.
- `interfaces`: ERC165 interfaces for supported standards.
- `abis`: the ABIs for the supported interfaces.
