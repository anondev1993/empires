import fs from "fs";
import { Account, Provider, ec, json } from "starknet";
import { modules } from "../config/modules.mjs";
import { deployNoConstructorContract } from "../utils/deployment.mjs";
import { getDeployedAddresses } from "../utils/getAddresses.mjs";
import { deployErc20Mintable } from "./deployERC.mjs";

// address of starknet-dev
const options = { sequencer: { baseUrl: "http://localhost:5050" } };
const provider = new Provider(options);

// @notion deploys all the realms contracts + additional contracts needed
// @params accountContracts List of addresses {address, private_key, public_key}
async function deployRealmsContracts(accountContracts, provider) {
    /**
     * Deploys the lords ERC20 contract
     */
    //TODO: check the arguments given inside the functions
    const erc20Address = await deployErc20Mintable(provider);

    /**
     * Deploys the Realms ERC721
     */
    // TODO: deploy the Realms ERC721 tokens (no constructor args)
    const erc721Address = await deployNoConstructorContract(
        "compiled/ERC721/RealmsERC721.json",
        provider
    );
    // TODO: initialize the contract: name, symbol, proxy_admin
    // TODO: call the mint function
    // TODO: set realm data (set_realm_data)
    // TODO: could for loop to make it for 3 users

    /**
     * Deploys the Resource ERC1155
     */
    const erc1155Address = await deployNoConstructorContract(
        "compiled/ERC1155/Resources_ERC1155_Mintable_Burnable.json",
        provider
    );
    // TODO: initialize the contract: uri: felt, proxy_admin: felt (uri can be random?)
    // TODO: mintBatch to mint all ressources at once?

    /**
     * Deploys the S_RealmERC721
     */
    //TODO: check if it is need
    //TODO: if yes, need to compile it first
    //lib/realms_contracts_git/contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo

    /**
     * Deploys the Module controller
     */

    const compiled = json.parse(
        fs
            .readFileSync("compiled/Realms/ModuleController.json")
            .toString("ascii")
    );
    const response = await provider.deployContract({
        contract: compiled,
        constructorCalldata: [
            // arbiter_address
            accountContracts[0].address,
            // lords address
            //TODO: deploy erc20
            accountContracts[0].address,
            // resources address
            //TODO: deploy erc1155
            accountContracts[0].address,
            // realms address
            //TODO: deploy erc721 realms
            accountContracts[0].address,
            // treasury address
            // TODO: check if we need that, don't think something like Buildings needs it so put aside for now
            accountContracts[0].address,
            // _s_realms_address
            //TODO: deploy erc721 realms
            accountContracts[0].address,
        ],
    });
    console.log(
        `Waiting for Tx to be Accepted on Starknet - ModulesController Deployment...`
    );
    await provider.waitForTransaction(response.transaction_hash);

    const controllerAddress = response.contract_address;
    console.log(
        "address of the module controller contract: ",
        controllerAddress
    );

    /**
     * Deploys each of the modules and then executes transaction to call initializer entrypoint
     */

    // new Account object using the address retrieved from starknet-devnet
    const starkKeyPair = ec.getKeyPair(accountContracts[0].private_key);
    const account = new Account(
        provider,
        accountContracts[0].address,
        starkKeyPair
    );

    // deploy modules
    const moduleAddresses = {};
    for (const modulePath of Object.values(modules)) {
        // deploys modules that don't need arguments in their constructor
        const moduleAddress = await deployNoConstructorContract(
            modulePath,
            provider
        );
        // calls function initializer in each module contract
        const initalizerResponse = await account.execute({
            entrypoint: "initializer",
            contractAddress: moduleAddress,
            calldata: [controllerAddress, accountContracts[0].address],
        });
        await provider.waitForTransaction(initalizerResponse.transaction_hash);
        console.log(
            `Contract ${modulePath} has been initialized with transaction_hash ${initalizerResponse.transaction_hash}`
        );
        // populates moduleAddresses as (module, address) pair
        moduleAddresses[
            Object.keys(modules).find((key) => modules[key] === modulePath)
        ] = moduleAddress;
    }

    return moduleAddresses;
}

async function main() {
    const userAddresses = await getDeployedAddresses();
    const moduleAddresses = await deployRealmsContracts(
        userAddresses,
        provider
    );
    //TODO: deploy the Empire contract using all of the previous addresses
    /**
  emperor: felt,
  realm_contract_address: felt
  building_module_: felt,
  food_module_: felt,
  goblin_town_module_: felt,
  resource_module_: felt,
  travel_module_: felt,
  combat_module_: felt,
  lords_contract_address: felt,
  eth_contract_address: felt, => not needed if we don't do the acquire_realm function
  router_contract_address: felt, => not needed if we don't do the acquire_realm function
  l1_empire_contract_address: felt, => not needed if we don't do the acquire_realm function
  token_bridge_contract_address: felt, => not needed if we don't do the acquire_realm function
  producer_taxes_: felt,
  attacker_taxes_: felt,
  goblin_taxes_: felt,
   */
}

main();
