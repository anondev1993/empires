import fs from "fs";
import { Account, Provider, ec, json, Contract } from "starknet";
import { modules } from "../config/modules.mjs";
import { deployNoConstructorContract } from "../utils/deployment.mjs";
import { getDeployedAddresses } from "../utils/getAddresses.mjs";
import { deployErc20Mintable } from "./deployERC.mjs";
import { pack_data } from "./utils.mjs";
import realm_data from "./realms_data.json" assert { type: "json" };
import { getAccount } from "../utils/account.mjs";
import { Module } from "module";
import {
    getDeployedContractAddress,
    updateDeployedContractAddress,
} from "../utils/deployedContracts.mjs";

// address of starknet-dev
const options = { sequencer: { baseUrl: "http://localhost:5050" } };
const provider = new Provider(options);

// @notion deploys all the realms contracts + additional contracts needed
// @params accountContracts List of addresses {address, private_key, public_key}
async function deployRealmsContracts(accountContracts, provider) {
    // new Account object using the address retrieved from starknet-devnet
    const adminAccount = getAccount(accountContracts[0], provider);

    // /**
    //  * Deploys the lords ERC20 contract
    //  */
    const erc20Address = await deployErc20Mintable(
        provider,
        adminAccount.address
    );
    updateDeployedContractAddress("erc20", erc20Address);

    // /**
    //  * Deploys the Realms ERC721
    //  */

    const erc721Address = await deployNoConstructorContract(
        "compiled/ERC721/RealmsERC721.json",
        provider
    );

    console.log("Initializing realms erc721 contract");
    await adminAccount.execute({
        entrypoint: "initializer",
        contractAddress: erc721Address,
        calldata: [
            "0x5265616c6d73455243373231",
            "0x7265616d6c73",
            adminAccount.address,
        ],
    });

    console.log("Minting a realm for the first 3 accounts");
    for (let i = 1; i < 4; i++) {
        await adminAccount.execute({
            entrypoint: "mint",
            contractAddress: erc721Address,
            calldata: [accountContracts[i].address, i, 0],
        });
        await adminAccount.execute({
            entrypoint: "set_realm_data",
            contractAddress: erc721Address,
            calldata: [i, 0, pack_data(realm_data[i - 1])],
        });
    }

    updateDeployedContractAddress("erc721", erc721Address);

    // /**
    //  * Deploys the Resource ERC1155
    //  */
    console.log("Deploying erc1155 contract");
    const erc1155Address = await deployNoConstructorContract(
        "compiled/ERC1155/realms_erc1155.json",
        provider
    );

    updateDeployedContractAddress("erc1155", erc1155Address);

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
            adminAccount.address,
            // lords address
            getDeployedContractAddress("erc20"),
            // resources address
            getDeployedContractAddress("erc1155"),
            // realms address
            getDeployedContractAddress("erc721"),
            // treasury address
            adminAccount.address,
            // _s_realms_address
            //TODO: deploy s erc721 realms
            getDeployedContractAddress("erc721"),
        ],
    });
    await provider.waitForTransaction(response.transaction_hash);
    const controllerAddress = response.contract_address;

    updateDeployedContractAddress("controller", controllerAddress);

    /**
     * Initialize the ERC1155 Contract
     */

    console.log("Initializing realms erc1155 contract");
    const initERC1155Response = await adminAccount.execute({
        entrypoint: "initializer",
        contractAddress: getDeployedContractAddress("erc1155"),
        calldata: [
            "0x72616e646f6d",
            adminAccount.address,
            getDeployedContractAddress("controller"),
        ],
    });

    await provider.waitForTransaction(initERC1155Response.transaction_hash);

    /**
     * Deploys each of the modules and then executes transaction to call initializer entrypoint
     */

    // deploy modules
    for (const module of Object.values(modules)) {
        // deploys modules that don't need arguments in their constructor
        const moduleAddress = await deployNoConstructorContract(
            module["path"],
            provider
        );
        // calls function initializer in each module contract
        const initalizerResponse = await adminAccount.execute({
            entrypoint: "initializer",
            contractAddress: moduleAddress,
            calldata: [
                getDeployedContractAddress("controller"),
                accountContracts[0].address,
            ],
        });
        await provider.waitForTransaction(initalizerResponse.transaction_hash);

        const moduleName = Object.keys(modules).find(
            (key) => modules[key]["path"] === module["path"]
        );
        updateDeployedContractAddress(moduleName, moduleAddress);

        const setModuleAddressResponse = await adminAccount.execute({
            entrypoint: "set_address_for_module_id",
            contractAddress: getDeployedContractAddress("controller"),
            calldata: [module["moduleId"], moduleAddress],
        });

        await provider.waitForTransaction(
            setModuleAddressResponse.transaction_hash
        );
    }

    /**
     * Add the owner address as a module to mint any amount of ressources
     */

    console.log("Setup the accesses for the erc1155 module and the admin");
    const ownerModuleId = 2000;
    const erc1155ModuleId = 1004;

    const setModuleAddressResponse1 = await adminAccount.execute({
        entrypoint: "set_address_for_module_id",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [erc1155ModuleId, getDeployedContractAddress("erc1155")],
    });

    await provider.waitForTransaction(
        setModuleAddressResponse1.transaction_hash
    );

    const setModuleAddressResponse2 = await adminAccount.execute({
        entrypoint: "set_address_for_module_id",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [ownerModuleId, adminAccount.address],
    });
    await provider.waitForTransaction(
        setModuleAddressResponse2.transaction_hash
    );

    await adminAccount.execute({
        entrypoint: "set_write_access",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [ownerModuleId, erc1155ModuleId],
    });
    await provider.waitForTransaction(setWriteAccessResponse.transaction_hash);

    console.log("Buidling a house for a user");
    const userAccount1 = getAccount(accountContracts[1], provider);
    await userAccount1.execute({
        entrypoint: "build",
        contractAddress: getDeployedContractAddress("buildings"),
        // tokenid 1 (uint256), buildingid 1 (house), quantity 1
        calldata: [1, 0, 1, 1],
    });
}

async function batchMintResourcesUsers(accountContracts, userList) {
    console.log("Batch minting resources for all three accounts");
    for (const i of userList) {
        let _ids = Array.from(Array(44), (_, index) =>
            index % 2 == 0 ? index / 2 + 1 : 0
        );
        let ids = _ids.concat([10000, 0, 10001, 0]);
        let amounts = Array.from(Array(48), (_, index) =>
            index % 2 == 0 ? BigInt(100000 * 10 ** 18) : BigInt(0)
        );
        let t = ids.concat([24], amounts, [1, 0]);
        let calldata = [accountContracts[i].address, 24].concat(t);
        await adminAccount.execute({
            entrypoint: "mintBatch",
            contractAddress: getDeployedContractAddress("erc1155"),
            calldata: calldata,
        });
    }
}

async function deployEmpire(accountContracts) {
    console.log("Deploying Empires contract");
    const compiled = json.parse(
        fs.readFileSync("compiled/Empire.json").toString("ascii")
    );

    const callData = {
        emperor: accountContracts[0].address,
        realm_contract_address: getDeployedContractAddress("erc721"),
        stacked_realm_contract_address: getDeployedContractAddress("erc721"),
        erc1155_contract_address: getDeployedContractAddress("erc1155"),
        building_module_: getDeployedContractAddress("buildings"),
        food_module_: getDeployedContractAddress("food"),
        goblin_town_module_: getDeployedContractAddress("goblintown"),
        resource_module: getDeployedContractAddress("resources"),
        travel_module_: getDeployedContractAddress("travel"),
        combat_module_: getDeployedContractAddress("combat"),
        lords_contract_address: getDeployedContractAddress("erc20"),
        eth_contract_address: 0,
        router_contract_address: 0,
        l1_empire_contract_address: 0,
        token_bridge_contract_address: 0,
        producer_taxes_: 50,
        attacker_taxes_: 50,
        goblin_taxes_: 50,
    };

    const response = await provider.deployContract({
        contract: compiled,
        constructorCalldata: Object.values(callData),
    });

    await provider.waitForTransaction(response.transaction_hash);

    updateDeployedContractAddress("empire", response.contract_address);
}

async function batchMintResourcesEmpire(accountContracts) {
    const adminAccount = getAccount(accountContracts[0], provider);

    let _ids = Array.from(Array(44), (_, index) =>
        index % 2 == 0 ? index / 2 + 1 : 0
    );
    let ids = _ids.concat([10000, 0, 10001, 0]);
    let amounts = Array.from(Array(48), (_, index) =>
        index % 2 == 0 ? BigInt(100000 * 10 ** 18) : BigInt(0)
    );
    let t = ids.concat([24], amounts, [1, 0]);
    let calldata = [getDeployedContractAddress("empire"), 24].concat(t);
    await adminAccount.execute({
        entrypoint: "mintBatch",
        contractAddress: getDeployedContractAddress("erc1155"),
        calldata: calldata,
    });
}

async function joinTheEmpire(accountContracts, user, tokenId) {
    const userAccount = getAccount(accountContracts[user], provider);

    await userAccount.execute([
        {
            entrypoint: "approve",
            contractAddress: getDeployedContractAddress("erc721"),
            calldata: [getDeployedContractAddress("empire"), tokenId, 0],
        },
        {
            entrypoint: "delegate",
            contractAddress: getDeployedContractAddress("empire"),
            calldata: [tokenId],
        },
    ]);
}

async function manageEmpire(userAddresses, entrypoint, calldata) {
    const adminAccount = getAccount(userAddresses[0], provider);

    await adminAccount.execute({
        entrypoint: entrypoint,
        contractAddress: getDeployedContractAddress("empire"),
        calldata: calldata,
    });
}

async function readRealms(module, entrypoint, calldata) {
    const compiled = json.parse(
        fs.readFileSync(modules[module]["path"]).toString("ascii")
    );

    const contract = new Contract(
        compiled.abi,
        getDeployedContractAddress(module),
        provider
    );

    const response = await contract.call(entrypoint, calldata);

    console.log(response);
}

async function main() {
    const userAddresses = await getDeployedAddresses();
    // await deployRealmsContracts(userAddresses, provider);
    // await batchMintResourcesUsers(userAddresses, [1, 2, 3]);
    // await deployEmpire(userAddresses);
    // await batchMintResourcesEmpire(userAddresses);
    // await joinTheEmpire(userAddresses);
    // await manageEmpire(userAddresses, "build", [1, 0, 1, 1]);
    // await readRealms("buildings", "get_effective_population_buildings", [
    //     [1, 0],
    // ]);
}

main();
