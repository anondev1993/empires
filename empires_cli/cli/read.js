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

module.exports = { readRealms, ownerOf };
