const { getDeployedAddresses } = require("../utils/getAddresses.js");
const { getAccount } = require("../utils/getAccount.js");
const {
    getDeployedContractAddress,
    updateDeployedContractAddress,
} = require("../utils/trackContracts.js");
const { getProvider } = require("../utils/getProvider.js");

async function joinEmpire(user, tokenId) {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
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

async function manageEmpire(emperor, entrypoint, calldata) {
    const userAddresses = await getDeployedAddresses();
    const provider = getProvider();
    const adminAccount = getAccount(userAddresses[emperor], provider);

    await adminAccount.execute({
        entrypoint: entrypoint,
        contractAddress: getDeployedContractAddress("empire"),
        calldata: calldata,
    });
}

module.exports = { joinEmpire, manageEmpire };
