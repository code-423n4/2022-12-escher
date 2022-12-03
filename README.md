# ✨ So you want to sponsor a contest

This `README.md` contains a set of checklists for our contest collaboration.

Your contest will use two repos: 
- **a _contest_ repo** (this one), which is used for scoping your contest and for providing information to contestants (wardens)
- **a _findings_ repo**, where issues are submitted (shared with you after the contest) 

Ultimately, when we launch the contest, this contest repo will be made public and will contain the smart contracts to be reviewed and all the information needed for contest participants. The findings repo will be made public after the contest report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the contest sponsor (⭐️)**.

---

# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Provide a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Make sure your code is thoroughly commented using the [NatSpec format](https://docs.soliditylang.org/en/v0.5.10/natspec-format.html#natspec-format).
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 24 hours prior to contest start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the contest — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the contest. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)


---

## ⭐️ Sponsor: Edit this README

Under "SPONSORS ADD INFO HERE" heading below, include the following:

- [ ] Modify the bottom of this `README.md` file to describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the C4 Wardens should keep in mind when reviewing. ([Here's a well-constructed example.](https://github.com/code-423n4/2022-08-foundation#readme))
  - [ ] When linking, please provide all links as full absolute links versus relative links
  - [ ] All information should be provided in markdown format (HTML does not render on Code4rena.com)
- [ ] Under the "Scope" heading, provide the name of each contract and:
  - [ ] source lines of code (excluding blank lines and comments) in each
  - [ ] external contracts called in each
  - [ ] libraries used in each
- [ ] Describe any novel or unique curve logic or mathematical models implemented in the contracts
- [ ] Does the token conform to the ERC-20 standard? In what specific ways does it differ?
- [ ] Describe anything else that adds any special logic that makes your approach unique
- [ ] Identify any areas of specific concern in reviewing the code
- [ ] Optional / nice to have: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] Delete this checklist and all text above the line below when you're ready.

---

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

# Overview

Escher
Escher is a decentralized curated marketplace for editioned artwork

Contracts
For Escher721, Sale contracts, and URI delegates, we inherit from the openzeppelen-contracts-upgradeable version of OpenZeppelin's libraries to keep deploy costs low, and the contracts aren't actually upgradeable

### Escher.sol
This is a minimal curated registry of onchain addresses which are the creators onboarded to Escher. Users can be added as a `Curator` or a `Creator`. Curators are able to onboard creators to the smart contract system. All assigned roles are ERC1155 soulbound tokens.

### Escher Editions

#### URIs
Each contract must declare a URI delegate which handles all token metadata. More documentation to come here but for now use this goerli implementation of base URI delegate

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
This is the core contract for fixed price and fixed supply sales. Inside this contract there are two public functions.

### Last Price Dutch Auction Sale (LPDA)

#### LPDAFactory.sol
This is the factory contract where LPDA sale proxies are created. The protocol controls a `feeReceiver` variable which is the address that receives 5% of all sales. The other function is creating the proxy. Variables and how the creation flow works will be covered below in [Sales Patterns](#sales-patterns)

#### LPDA.sol
This is the core contract for LPDA sales. Each contract is a proxy to the implementation of LPDAs. 

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

# Scope

| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| src/Escher.sol | 59 | Manages roles | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/Escher721.sol | 95 | ERC721 Token | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/Escher721Factory | 42 | Token Factory | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/minters/FixedPriceSale.sol | 112 | Sale Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |
| src/minters/FixedPriceFactory.sol | 45 | Sale Factory | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/minters/OpenEdition.sol | 124 | Sale Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |
| src/minters/OpenEditionFactory.sol | 45 | Sale Factory | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/minters/LPDA.sol | 149 | Sale Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |
| src/minters/LPDAFactory.sol | 49 | Sale Factory | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| src/uris/Base.sol | 21 | Metadata Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |
| src/uris/Unique.sol | 13 | Metadata Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |
| src/uris/Generative.sol | 31 | Metadata Contract | [`@openzeppelin-upgradeable/*`](https://openzeppelin.com/contracts/) |

## Out of scope

*List any files/contracts that are out of scope for this audit.*

# Additional Context

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

# Tests

```
npm ci
```

```
git submodule update --init --recursive
```

```
forge test
```

