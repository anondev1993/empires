const fs = require("fs");
const { Provider, json, Contract } = require("starknet");
const { modules } = require("../data/modules.js");
const { getDeployedAddresses } = require("../utils/getAddresses.js");
const { packData } = require("../utils/packData.js");
const { getAccount } = require("../utils/getAccount.js");
const {
    getDeployedContractAddress,
    updateDeployedContractAddress,
} = require("../utils/trackContracts.js");
const { getProvider } = require("../utils/getProvider.js");

// @notion deploys all the realms contracts needed to play the game
// @param accountContracts List of addresses {address, private_key, public_key}
// @param provider A starknetjs provider object containing network info
async function deployRealmsContracts() {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    // new Account object using the address retrieved from starknet-devnet
    const adminAccount = getAccount(accountContracts[0], provider);

    // /**
    //  * Deploys the lords ERC20 contract
    //  */
    const erc20Address = await deployErc20Mintable();
    updateDeployedContractAddress("erc20", erc20Address);

    // /**
    //  * Deploys the Realms ERC721 Contract
    //  */
    const erc721Address = await deployNoConstructorContract(
        "compiled/ERC721/RealmsERC721.json"
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

    updateDeployedContractAddress("erc721", erc721Address);

    // /**
    //  * Deploys the Resource ERC1155
    //  */
    console.log("Deploying erc1155 contract");
    const erc1155Address = await deployNoConstructorContract(
        "compiled/ERC1155/realms_erc1155.json"
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
            getDeployedContractAddress("erc721"),
        ],
    });
    //TODO: verify if wait .waitForTransaction is useful or not in our case
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

    // erc1155ModuleId needed to give write access to each of the modules
    const erc1155ModuleId = 1004;

    console.log("Deploying and initializing all the needed modules contracts");
    // deploy modules
    for (const module of Object.values(modules)) {
        // deploys modules that don't need arguments in their constructor
        const moduleAddress = await deployNoConstructorContract(module["path"]);
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

        // set write access to all modules to the ERC1155 resource contract
        //TODO: test that it works
        await adminAccount.execute({
            entrypoint: "set_write_access",
            contractAddress: getDeployedContractAddress("controller"),
            calldata: [module["moduleId"], erc1155ModuleId],
        });
    }

    /**
     * Add the owner address as a module to mint any amount of ressources
     */

    console.log("Setup the access control for ERC1155 Resources");
    const ownerModuleId = 2000;

    await adminAccount.execute({
        entrypoint: "set_address_for_module_id",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [erc1155ModuleId, getDeployedContractAddress("erc1155")],
    });

    await adminAccount.execute({
        entrypoint: "set_address_for_module_id",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [ownerModuleId, adminAccount.address],
    });

    await adminAccount.execute({
        entrypoint: "set_write_access",
        contractAddress: getDeployedContractAddress("controller"),
        calldata: [ownerModuleId, erc1155ModuleId],
    });
}

async function deployEmpire() {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
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

async function deployErc20Mintable() {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const path = "./compiled/ERC20/ERC20Mintable.json";
    console.log(`Deploying ${path} Contract`);

    const compiled = json.parse(fs.readFileSync(path).toString("ascii"));

    const response = await provider.deployContract({
        contract: compiled,
        constructorCalldata: [
            //name
            "298305742194",
            // symbol
            "4543560",
            // decimals
            "18",
            // original supply
            "38411331902790913116538",
            "0",
            // recipient
            accountContracts[0].address,
            // owner
            accountContracts[0].address,
        ],
    });

    await provider.waitForTransaction(response.transaction_hash);

    const address = response.contract_address;
    return address;
}

// @notice Deploys a smart contract without constructor
// @param provider Provider
async function deployNoConstructorContract(path) {
    const provider = getProvider();
    console.log(`Deploying ${path} contract`);
    const compiled = json.parse(fs.readFileSync(path).toString("ascii"));
    const response = await provider.deployContract({
        contract: compiled,
    });
    await provider.waitForTransaction(response.transaction_hash);

    const address = response.contract_address;
    return address;
}

async function main() {
    // await deployRealmsContracts(userAddresses, provider);
    // await batchMintResourcesUsers(userAddresses, [1, 2, 3]);
    // await deployEmpire(userAddresses);
    // await batchMintResourcesEmpire(userAddresses);
    // await joinTheEmpire(userAddresses, 1, 1);
    // await manageEmpire(userAddresses, "build", [1, 0, 1, 1]);
    // await readRealms("buildings", "get_effective_population_buildings", [
    //     [1, 0],
    // ]);
}

main();

// console.log("Buidling a house for a user");
// const userAccount1 = getAccount(accountContracts[1], provider);
// await userAccount1.execute({
//     entrypoint: "build",
//     contractAddress: getDeployedContractAddress("buildings"),
//     // tokenid 1 (uint256), buildingid 1 (house), quantity 1
//     calldata: [1, 0, 1, 1],
// });

module.exports = { deployRealmsContracts, deployEmpire };
