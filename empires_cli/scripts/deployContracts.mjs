import fs from "fs";
import { Account, Provider, ec, json } from "starknet";
import { modules } from "../config/modules.mjs";
import { deployNoConstructorContract } from "../utils/deployment.mjs";
import { getDeployedAddresses } from "../utils/getAddresses.mjs";
import { deployErc20Mintable } from "./deployERC.mjs";
import { pack_data } from "./utils.mjs";
import realm_data from "./realms_data.json" assert { type: "json" };

// address of starknet-dev
const options = { sequencer: { baseUrl: "http://localhost:5050" } };
const provider = new Provider(options);

// @notion deploys all the realms contracts + additional contracts needed
// @params accountContracts List of addresses {address, private_key, public_key}
async function deployRealmsContracts(accountContracts, provider) {
    // new Account object using the address retrieved from starknet-devnet
    const owner = accountContracts[0];
    const starkKeyPair = ec.getKeyPair(owner.private_key);
    const account = new Account(provider, owner.address, starkKeyPair);
    /**
     * Deploys the lords ERC20 contract
     */
    const erc20Address = await deployErc20Mintable(provider, account.address);

    /**
     * Deploys the Realms ERC721
     */
    const erc721Address = await deployNoConstructorContract(
        "compiled/ERC721/RealmsERC721.json",
        provider
    );
    console.log("Initializing realms erc721 contract");
    await account.execute({
        entrypoint: "initializer",
        contractAddress: erc721Address,
        calldata: [
            "0x5265616c6d73455243373231",
            "0x7265616d6c73",
            owner.address,
        ],
    });

    console.log("Minting a realm for the first 3 accounts");
    for (let i = 1; i < 4; i++) {
        await account.execute({
            entrypoint: "mint",
            contractAddress: erc721Address,
            calldata: [accountContracts[i].address, i, 0],
        });
        await account.execute({
            entrypoint: "set_realm_data",
            contractAddress: erc721Address,
            calldata: [i, 0, pack_data(realm_data[i - 1])],
        });
    }
    console.log("Done minting and setting data");

    /**
     * Deploys the Resource ERC1155
     */
    const erc1155Address = await deployNoConstructorContract(
        "compiled/ERC1155/Resources_ERC1155_Mintable_Burnable.json",
        provider
    );
    console.log("Initializing realms erc1155 contract");
    await account.execute({
        entrypoint: "initializer",
        contractAddress: erc1155Address,
        calldata: ["0x72616e646f6d", owner.address],
    });

    // TODO this will not work for now as when mintBatch is called,
    // it needs to be called by an approved module by the controller.
    // Move this block below the controller deployment and call set_write_access
    // for the account, which will allow it to call erc1155Address and mintBatch
    console.log("Batch minting resources for all three accounts");
    for (let i = 1; i < 4; i++) {
        let _ids = Array.from(Array(44), (_, index) =>
            index % 2 == 0 ? index / 2 + 1 : 0
        );
        let ids = _ids.concat([10000, 0, 10001, 0]);
        let amounts = Array.from(Array(48), (_, index) =>
            index % 2 == 0 ? 100000 : 0
        );
        let t = ids.concat([24], amounts, [1, 0]);
        let calldata = [accountContracts[i].address, 24].concat(t);
        await account.execute({
            entrypoint: "mintBatch",
            contractAddress: erc1155Address,
            calldata: calldata,
        });
    }

    /**
     * Deploys the S_RealmERC721
     */
    //TODO: check if it is need: yes, needed, can go look at Combat.cairo
    //TODO: if yes, need to compile it first: compiled, located in compiled/S_ERC721
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
