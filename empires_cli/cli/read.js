const fs = require("fs");
const { json, Contract } = require("starknet");
const { modules } = require("../data/modules.js");
const { getProvider } = require("../utils/getProvider.js");
const { getDeployedContractAddress } = require("../utils/trackContracts.js");

async function readRealms(module, entrypoint, calldata) {
    const provider = getProvider();
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

async function readEmpire(entrypoint, calldata) {
    const provider = getProvider();
    const compiled = json.parse(
        fs.readFileSync("compiled/Empire.json").toString("ascii")
    );

    const contract = new Contract(
        compiled.abi,
        getDeployedContractAddress("empire"),
        provider
    );

    const response = await contract.call(entrypoint, calldata);

    console.log(response);
}

async function ownerOf(tokenId) {
    const provider = getProvider();
    const compiled = json.parse(
        fs.readFileSync("compiled/ERC721/RealmsERC721.json").toString("ascii")
    );

    const contract = new Contract(
        compiled.abi,
        getDeployedContractAddress("erc721"),
        provider
    );

    const response = await contract.ownerOf([tokenId, 0]);
    console.log(response);
}

async function balanceOfBatch(owner) {
    const provider = getProvider();
    const compiled = json.parse(
        fs
            .readFileSync("compiled/ERC1155/realms_erc1155.json")
            .toString("ascii")
    );

    const contract = new Contract(
        compiled.abi,
        getDeployedContractAddress("erc1155"),
        provider
    );

    const owners = Array(24).fill(owner);
    const _ids = Array.from(Array(22), (_, index) => [index + 1, 0]);
    const ids = _ids.concat([
        [10000, 0],
        [10001, 0],
    ]);
    const response = await contract.balanceOfBatch(owners, ids);

    console.log(response[0]);
}

module.exports = { readRealms, readEmpire, ownerOf, balanceOfBatch };
