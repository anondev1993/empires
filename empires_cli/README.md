# Empires CLI

<p align="center">
<img src="imgs/knight.png" width="90%" height="90%" alt="Coding knight">
</p>

A CLI tool to interact with the Empire and Realms contracts.

This CLI tool is meant to be used on the starknet-devnet and was built to showcase the capabilities of the Empire contract. It could be extended to work on the testnet or mainnet.

## Install

```jsx
cd empires_cli/

// installs all necessary dependencies
npm install
```

## Quickstart

In order to facilitate the onboarding of anyone wanting to test the contracts, we have created a quickstart CLI which:

-   deploys and initalizes all the contracts necessary to play Realms
    -   NFT contract
    -   Lords ERC20
    -   Resources ERC1155
    -   Modules
-   deploys the Empire contract
-   Batch mints all resources for the Empire
-   Mints a Realms NFT for 3 users (id 1, 2, 3)
-   Have user 1 and 2 join the empire

Simply execute `node index.js quickstart`.

# Examples

The below are two examples which use the commands implemented by the CLI: the first example builds a fish trap, forwards the block time, harvests the $FISH and
displays the total resources (resources are at the number of 24, with the two last resources being the $WHEAT and the $FISH) of the Empire and the user.
The second example starts a vote change for an Empire with 3 Realms and performs a change of Emperor at the second "Yes" vote. Finally, the third example issues
a bounty on an enemy realm.

## Example 1: Harvest

```jsx
// build a fishing house on realm tokenid1
node index.js manage-empire -e create -c "[1,0,1,5]"
// advance time
node index.js advance-time -s 30000
// harvest
node index.js manage-empire -e harvest -c "[1,0,5]"
// get empire resources
node index.js resources -e
// get user resources
node index.js resources -u 1
```

## Example 2: Round table voting

```jsx
// add the third user to the empire (not done by quickstart deployment)
node index.js join-empire -u 3 -t 3
// user 1 proposes a new emperor
node index.js manage-empire -u 1 -e propose_emperor_change -c '["0x1de4ff17901f1f23acb13a89f916d8812e65be11fe70d6ae8b1f2ffb0e02fde", 1]'
// user 2 can vote for tokenid 1 proposal, with his tokenid 2 and yes
node index.js manage-empire -u 2 -e vote_emperor -c "[1, 2, 1]"
```

## Example 3: Bounty

```jsx
// mint tokens to put in the empires treasury
node index.js mint-lords 1000 -e
// issue bounty on realm token 4
node index.js manage-empire -e issue_bounty -c "[4, 10]"
// check the bounty in the storage
node index.js read-empire -e get_bounties -c "[4]"
```

# Commands

## Starknet-devnet

Show the users info. Starknet-devnet deploys 10 account contracts by default. The first one will be used as admin account, the 9 others are treated as other players.

**show-users**

```jsx
node index.js show-users
```

**show-admin**

```jsx
node index.js show-admin
```

**advance-time**

```jsx
node index.js advance-time -s <seconds>
//node index.js advance-time -s 604800 (1 week)
```

## Deploy contracts

**deploy-realms**

Deploys all the necessary contracts to play Realms

```jsx
// deploys all the necessary contracts to play realms
node index.js deploy-realms
```

**deploy-empire**

```jsx
// deploys the Empire contract with admin account as emperor
node index.js deploy-empire
```

## Mint resources

**mint-resources**

Batch Mint all ERC1155 resources and transfers them to the Empire contract, this will allow us to directly test the gaming mechanics.

```jsx
node index.js mint-resources <amount> -e
// example node index.js mint-resources 1000 -e
```

You can also Batch Mint all ERC1155 resources for a list of users:

```jsx
node index.js mint-resources <amount> -u <users...>
// example empires_cli mint-resources 1000 -u 1 2 3
```

## Mint realms NFTs

Mints a realm NFT with a defined tokenid for a defined user

**mint-realm**

```jsx
node index.js mint-realm -u <user> -t <tokenid>
//node index.js mint-realm -u 1 -t 1
```

## Join the Empire

Allows a user to join the empire with his realm

**join-empire**

```jsx
node index.js join-empire -u <user> -t <tokenid>
// example node index.js join-empire -u 1 -t 1
```

## Manage the Empire

Allows the emperor to call the Empires contract to manage the empire, for example, build a house on one of the Realms. If you don’t define the emperor, it will default to user 0. You need to specify the name of the function and the calldata as a stringified list.

**manage-empire**

```jsx
node index.js manage-empire -u [calling_user] -e <entrypoint> -c <calldata>
// example empires_cli manage-empire -e build -c "[1,0,1,1]"
// this will construct one house on realm token id 1.
```

Here are a few examples of functions that can be called by the emperor in order to manage his empire:

### Manage the Empire examples:

A non exhaustive list of some of the entrypoints that can be called through the manage-empire command.

**start release period**

```jsx
node index.js manage-empire -u 1 -e start_release_period -c "[1]"
// user 1 activates the start of the release period so now the emperor
// cannot build on it
```

**leave empire**

```jsx
node index.js manage-empire -u 1 -e leave_empire -c "[1]"
// user 1 is leaving the empire his realm tokenid 1,
// the NFT is transferred back to the owner,
// release period needs to be finished
```

**issue_bounty**

```jsx
node index.js manage-empire -e issue_bounty -c "[2, 10]"
// issue 10 $LORDS bounty on realm tokenid 2
```

**propose_emperor_change**

```jsx
node index.js manage-empire -u 1 -e propose_emperor_change -c '["0x71045846eb574df80194698334a9de8070c515c5358251822d4db091f27128c", 1]'
```

**vote_emperor**

```jsx
node index.js manage-empire -u 2 -e vote_emperor -c "[1, 2, 1]"
// user 2 votes with his realm tokenid 2 for emperor proposed
// by owner of realm token id 1
```

**propose_realm_acquisition**

```jsx
node index.js manage-empire -u 1 -e propose_realm_acquisition -c "[654, 1000000000000000000 1]"
// proposition from user 1 with his tokenid 1 to buy token id 654 with price 1 ether
```

**vote_acquisition**

```jsx
node index.js manage-empire -u 2 -e vote_acquisition -c "[1, 2, 1]"
// user 2 votes with his realm tokenid 2 for proposition of user 1
```

**build**

```jsx
node index.js manage-empire -e build -c "[1,0,1,1]"
```

**create**

Creates a farm or fishing village

_id of farm = 4, id of fishing village = 5_

```jsx
node index.js manage-empire -e create -c "[1,0,1,5]"
// creates a fishing village for tokenid 1
```

**harvest**

```jsx
node index.js manage-empire -e harvest -c "[1,0,5]"
// harvests the resources of fishing village (5) on tokenid 1
```

**convert_food_tokens_to_store**

converts the 2 possible food tokens (wheatId: 10000, fishId: 10001) to store

```jsx
node index.js manage-empire -e convert_food_tokens_to_store -c "[1,0,1,10001]"
// converts fish in store for user 1 and quantity 1
```

**claim_resources**

```jsx
node index.js manage-empire -e claim_resources -c "[1,0]"
// claims resources for realm token id 1
```

## Read the empire contract

You can also read the storage of the empire contract through the read-empire command

**read-empire**

```jsx
node index.js read-empire -e <entrypoint> -c <calldata>
```

### Read the Empire examples:

A non exhaustive list of some of the entrypoints that can be called through the manage-empire command.

**get_emperor**

Gets the current emperor of the Empire

```jsx
node index.js read-empire -e get_emperor -c "[]"
```

**get_realms_count**

Gets the number of realms inside the Empire

```jsx
node index.js read-empire -e get_realms_count -c "[]"
```

**get_bounties**

```jsx
node index.js read-empire -e get_bounties -c "[1]"
// gets bounties on realm token id 1
```

**get_emperor_candidate**

```jsx
node index.js read-empire -e get_emperor_candidate -c "[1]"
// gets the candidate proposed by realm id 1
```

**get_realm_data**

```jsx
node index.js read-empire -e get_realm_data -c "[1]"
// gets the realm data of realm id 1
```

## Get all resources balance

**resources**

For empire

```jsx
node index.js resources -e
// gets the all the resources balance for empire contrat
```

For user

```jsx
node index.js resources -u 1
// gets the all the resources balance for user 1
```
