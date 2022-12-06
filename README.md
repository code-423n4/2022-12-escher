# Escher.xyz contest details
- Total Prize Pool: $36,500 USDC
  - HM awards: $25,500 USDC 
  - QA report awards: $3,000 USDC 
  - Gas report awards: $1,500 USDC 
  - Judge + presort awards: $6,000 USDC 
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2022-12-escher-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts December 06, 2022 20:00 UTC
- Ends December 09, 2022 20:00 UTC

## C4udit / Publicly Known Issues

The C4audit output for the contest can be found [here](https://gist.github.com/Picodes/cd4ff52d400a1d060dcbd3d85b08b10f).

*Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards.*

# Overview

Escher
Escher is a decentralized curated marketplace for editioned artwork

Contracts
For Escher721, Sale contracts, and URI delegates, we inherit from the openzeppelen-contracts-upgradeable version of OpenZeppelin's libraries to keep deploy costs low, and the contracts aren't actually upgradeable

### Escher.sol
This is a minimal curated registry of onchain addresses which are the creators onboarded to Escher. Users can be added as a `Curator` or a `Creator`. Curators are able to onboard creators to the smart contract system. All assigned roles are ERC1155 soulbound tokens.

### Escher Editions

#### URIs
Each contract must declare a URI delegate which handles all token metadata.

#### Escher721.sol
This is the core creator contract implementation for Escher. It is built on top the OpenZepplin ERC721 contracts. Each contract is **fully owned by the creators**. Escher must be careful to not lose their keys or to add backup admins.

#### Escher721Factory.sol
This is the factory contract where all onboarded artists are able to mint their own `Escher Edition` contract. Each contract is a minimal proxy to keep is cheap and easy to make your own contract. While the Factory uses proxies, nothing in it is upgradeable.

### Fixed Price Sales

#### FixedPriceSaleFactory.sol
This is the factory contract where fixed price sale proxies are created. The protocol controls a `feeReceiver` variable which is the address that receives 5% of all sales. The other function is creating the proxy. Variables and how the creation flow works will be covered below in [Sales Patterns](#sales-patterns)

#### FixedPriceSale.sol
This is the core contract for fixed price and fixed supply sales. Inside this contract there are two public functions. One to cancel the sale which is controlled by the creator and the other to purchase an edition.

### Open Edition Sale

#### OpenEditionFactory.sol
This is the factory contract where open edition sale proxies are created. The protocol controls a `feeReceiver` variable which is the address that receives 5% of all sales. The other function is creating the proxy. Variables and how the creation flow works will be covered below in [Sales Patterns](#sales-patterns)

#### OpenEdition.sol
This is the core contract for fixed price and uncapped supply sales. Inside this contract there are two public functions.

### Last Price Dutch Auction Sale (LPDA)

#### LPDAFactory.sol
This is the factory contract where LPDA sale proxies are created. The protocol controls a `feeReceiver` variable which is the address that receives 5% of all sales. The other function is creating the proxy. Variables and how the creation flow works will be covered below in [Sales Patterns](#sales-patterns)

#### LPDA.sol
This is the core contract for LPDA sales. Each contract is a proxy to the implementation of LPDAs. 

# Scope

### Files in scope
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (12)_|
|[src/uris/Unique.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/uris/Unique.sol)|[9](#nowhere "(nSLOC:9, SLOC:9, Lines:13)")|Metadata Contract, &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:1)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/uris/Base.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/uris/Base.sol)|[15](#nowhere "(nSLOC:15, SLOC:15, Lines:21)")|Metadata Contract, &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:3)")| [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/)|
|[src/uris/Generative.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/uris/Generative.sol) [🧮](#nowhere "Uses Hash-Functions")|[20](#nowhere "(nSLOC:20, SLOC:20, Lines:31)")|Metadata Contract, &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:8)")||
|[src/Escher721Factory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721Factory.sol) [🌀](#nowhere "create/create2")|[28](#nowhere "(nSLOC:24, SLOC:28, Lines:42)")|Token Factory, &nbsp;&nbsp;[0.00%](#nowhere "(Hit:0 / Total:6)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/minters/FixedPriceFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPriceFactory.sol) [🌀](#nowhere "create/create2")|[31](#nowhere "(nSLOC:31, SLOC:31, Lines:45)")|Sale Factory, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:7 / Total:7)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/minters/OpenEditionFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEditionFactory.sol) [🌀](#nowhere "create/create2")|[31](#nowhere "(nSLOC:31, SLOC:31, Lines:45)")|Sale Factory, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:7 / Total:7)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/minters/LPDAFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDAFactory.sol) [🌀](#nowhere "create/create2")|[35](#nowhere "(nSLOC:35, SLOC:35, Lines:49)")|Sale Factory, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:11 / Total:11)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/Escher.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher.sol) [🧮](#nowhere "Uses Hash-Functions")|[48](#nowhere "(nSLOC:34, SLOC:48, Lines:59)")|Manages roles, &nbsp;&nbsp;[80.00%](#nowhere "(Hit:8 / Total:10)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/Escher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721.sol) [🧮](#nowhere "Uses Hash-Functions")|[64](#nowhere "(nSLOC:47, SLOC:64, Lines:95)")|ERC721 Token, &nbsp;&nbsp;[15.38%](#nowhere "(Hit:2 / Total:13)")| [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/)|
|[src/minters/FixedPrice.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPrice.sol) [💰](#nowhere "Payable Functions") [💣](#nowhere "Destroyable Contract") [📤](#nowhere "Initiates ETH Value Transfer")|[66](#nowhere "(nSLOC:66, SLOC:66, Lines:112)")|Sale Contract, &nbsp;&nbsp;[82.61%](#nowhere "(Hit:19 / Total:23)")| [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/)|
|[src/minters/OpenEdition.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEdition.sol) [💰](#nowhere "Payable Functions") [💣](#nowhere "Destroyable Contract") [📤](#nowhere "Initiates ETH Value Transfer")|[81](#nowhere "(nSLOC:81, SLOC:81, Lines:124)")|Sale Contract, &nbsp;&nbsp;[81.48%](#nowhere "(Hit:22 / Total:27)")| [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/)|
|[src/minters/LPDA.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDA.sol) [💰](#nowhere "Payable Functions") [📤](#nowhere "Initiates ETH Value Transfer")|[106](#nowhere "(nSLOC:106, SLOC:106, Lines:149)")|Sale Contract, &nbsp;&nbsp;[91.11%](#nowhere "(Hit:41 / Total:45)")| [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/)|
|Total (over 12 files):| [534](#nowhere "(nSLOC:499, SLOC:534, Lines:785)") |[72.67%](#nowhere "Hit:117 / Total:161")|


### All other source contracts (not in scope)
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Interfaces (4)_|
|[src/interfaces/ISaleFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/ISaleFactory.sol)|[4](#nowhere "(nSLOC:4, SLOC:4, Lines:6)")|-||
|[src/interfaces/ITokenUriDelegate.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/ITokenUriDelegate.sol)|[6](#nowhere "(nSLOC:6, SLOC:6, Lines:10)")|-||
|[src/interfaces/ISale.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/ISale.sol) [💰](#nowhere "Payable Functions")|[8](#nowhere "(nSLOC:8, SLOC:8, Lines:14)")|-||
|[src/interfaces/IEscher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/IEscher721.sol)|[10](#nowhere "(nSLOC:10, SLOC:10, Lines:17)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|Total (over 4 files):| [28](#nowhere "(nSLOC:28, SLOC:28, Lines:47)") |-|

### External Imports
* **openzeppelin-upgradeable/access/AccessControlUpgradeable.sol**
  * [src/Escher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721.sol)
* **openzeppelin-upgradeable/access/OwnableUpgradeable.sol**
  * [src/minters/FixedPrice.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPrice.sol)
  * [src/minters/LPDA.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDA.sol)
  * [src/minters/OpenEdition.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEdition.sol)
  * [src/uris/Base.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/uris/Base.sol)
* **openzeppelin-upgradeable/proxy/utils/Initializable.sol**
  * [src/Escher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721.sol)
  * [src/minters/FixedPrice.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPrice.sol)
  * [src/minters/LPDA.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDA.sol)
  * [src/minters/OpenEdition.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEdition.sol)
* **openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol**
  * [src/Escher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721.sol)
* **openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol**
  * [src/Escher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721.sol)
* **openzeppelin/access/AccessControl.sol**
  * [src/Escher.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher.sol)
  * ~~[src/interfaces/IEscher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/IEscher721.sol)~~
* **openzeppelin/access/Ownable.sol**
  * [src/minters/FixedPriceFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPriceFactory.sol)
  * [src/minters/LPDAFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDAFactory.sol)
  * [src/minters/OpenEditionFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEditionFactory.sol)
* **openzeppelin/proxy/Clones.sol**
  * [src/Escher721Factory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher721Factory.sol)
  * [src/minters/FixedPriceFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/FixedPriceFactory.sol)
  * [src/minters/LPDAFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/LPDAFactory.sol)
  * [src/minters/OpenEditionFactory.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/minters/OpenEditionFactory.sol)
* **openzeppelin/token/ERC1155/ERC1155.sol**
  * [src/Escher.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/Escher.sol)
* **openzeppelin/token/ERC721/IERC721.sol**
  * ~~[src/interfaces/IEscher721.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/interfaces/IEscher721.sol)~~
* **openzeppelin/utils/Strings.sol**
  * [src/uris/Unique.sol](https://github.com/code-423n4/2022-12-escher/blob/main/src/uris/Unique.sol)

# Additional Context

## Sales Patterns
Here we will cover the flow from start to finish for both fixed price and open edition sales. Sales require that the default royalties for a contract has been set at minimum. This is how we decide where payments go.
### Fixed Price
1. Set up the token URI by calling `setTokenURI` with the token ID and the URI (arweave recommended)
2. If the artist would like sales and royalties to go somewhere other than the default royalty receiver, they must call `setTokenRoyalty` with the following variables:
  - `id`: the token ID of the sale
  - `receiver`: the address to receive paymnts
  - `feeNumerator`: the desired royalty %
3. Call `createFixedSale` in the `FixedPriceSaleFactory` contract. This will create the proxy sale contract. The artist must provide the following variables:
  - `edition`: the contract address of their Escher Edition proxy
  - `id`: the id of the token to sell
  - `price`: the price in ether of each edition
  - `saleTime`: the starting time in unix of the sale
  - `amount`: the amount of editions to sell
4. Call `grantRole` in the creators Escher Edition contract. This will allow the proxy contract to mint the tokens. The following variables must be provided:
  - `role`: the bytes32 `MINTER_ROLE` which can be found in the artist contract
  - `account`: the address of the sale proxy contract


### Open Edition
1. Set up the token URI by calling `setTokenURI` with the token ID and the URI (arweave recommended)
2. If the artist would like sales and royalties to go somewhere other than the default royalty receiver, they must call `setTokenRoyalty` with the following variables:
  - `id`: the token ID of the sale
  - `receiver`: the address to receive paymnts
  - `feeNumerator`: the desired royalty %
3. Call `createOpenEdition` in the `OpenEditionSaleFactory` contract. This will create the proxy sale contract. The artist must provide the following variables:
  - `edition`: the contract address of their Escher Edition proxy
  - `id`: the id of the token to sell
  - `price`: the price in ether of each edition
  - `saleTime`: the starting time in unix of the sale
  - `endTime`: the ending time in unix of the sale
4. Call `grantRole` in the creators Escher Edition contract. This will allow the proxy contract to mint the tokens. The following variables must be provided:
  - `role`: the bytes32 `MINTER_ROLE` which can be found in the artist contract
  - `account`: the address of the sale proxy contract
5. Once the sale has ended, the artist must call `finalize` to get their Ethereum.

### Last Price Dutch Auction (LPDA)
1. Set up the token URI by calling `setTokenURI` with the token ID and the URI (arweave recommended)
2. If the artist would like sales and royalties to go somewhere other than the default royalty receiver, they must call `setTokenRoyalty` with the following variables:
  - `id`: the token ID of the sale
  - `receiver`: the address to receive paymnts
  - `feeNumerator`: the desired royalty %
3. Call `createLPDASale` in the `LPDAFactory` contract. This will create the proxy sale contract. The artist must provide the following variables:
  - `currentId`: the starting id of the token to sell
  - `finalId`: the ending id of the token to sell
  - `edition`: the contract address of their Escher Edition proxy
  - `startPrice`: the starting price of the LDPA
  - `finalPrice`: the ending price of the LDPA
  - `dropPerSecond`: price decrease per second
  - `endTime`: the ending time in unix of the sale
  - `saleReceiver`: the account to send proceeds from the sale to
  - `startTime`: the starting time in unix of the sale
4. Call `grantRole` in the creators Escher Edition contract. This will allow the proxy contract to mint the tokens. The following variables must be provided:
  - `role`: the bytes32 `MINTER_ROLE` which can be found in the artist contract
  - `account`: the address of the sale proxy contract
5. Once the sale has ended, the users must call `refund` to get their Ether refunds based on their purchase price and lowest sale price.




*Describe any novel or unique curve logic or mathematical models implemented in the contracts*

*Sponsor, please confirm/edit the information below.*

## Scoping Details 
```
- If you have a public code repo, please share it here:  
- How many contracts are in scope?:   13
- Total SLoC for these contracts?:  525
- How many external imports are there?: 10 
- How many separate interfaces and struct definitions are there for the contracts within scope?:  5
- Does most of your code generally use composition or inheritance?:   composition
- How many external calls?:   0
- What is the overall line coverage percentage provided by your tests?:  100%
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:   false
- Please describe required context:   
- Does it use an oracle?:  false
- Does the token conform to the ERC20 standard?:  No token
- Are there any novel or unique curve logic or mathematical models?: No
- Does it use a timelock function?:  No
- Is it an NFT?: ERC721 are part of it
- Does it have an AMM?:   No
- Is it a fork of a popular project?:   false
- Does it use rollups?:   false
- Is it multi-chain?:  false
- Does it use a side-chain?: false
```

# Quickstart

In one command

```
rm -Rf 2022-12-escher || true && git clone https://github.com/code-423n4/2022-12-escher.git && cd 2022-12-escher && npm ci && git submodule update --init --recursive && foundryup && forge test --gas-report
```

# Tests

Install linting and formatting

```
npm ci
```

Install git submodules

```
git submodule update --init --recursive
```

Run tests

```
forge test
```

Run Slither

Make sure you're running the latest version of slither v0.9.1
```
slither .
```
