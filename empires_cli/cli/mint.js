const fs = require("fs");
const { getAccount } = require("../utils/getAccount.js");
const { getDeployedAddresses } = require("../utils/getAddresses.js");
const { getProvider } = require("../utils/getProvider.js");
const { packData } = require("../utils/packData.js");
const { getDeployedContractAddress } = require("../utils/trackContracts.js");

async function batchMintResourcesUsers(userList, amount) {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const adminAccount = getAccount(accountContracts[0], provider);
    for (const i of userList) {
        let _ids = Array.from(Array(44), (_, index) =>
            index % 2 == 0 ? index / 2 + 1 : 0
        );
        let ids = _ids.concat([10000, 0, 10001, 0]);
        let amounts = Array.from(Array(48), (_, index) =>
            index % 2 == 0 ? BigInt(amount * 10 ** 18) : BigInt(0)
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

async function mintingRealm(user, tokenid) {
    // console.log(`Minting a realm for user ${user}`);
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const adminAccount = getAccount(accountContracts[0], provider);
    const realm_data = JSON.parse(fs.readFileSync("./data/realms_data.json"));
    const rand = Math.floor(Math.random() * (2 + 1));
    const erc721Address = getDeployedContractAddress("erc721");
    await adminAccount.execute({
        entrypoint: "mint",
        contractAddress: erc721Address,
        calldata: [accountContracts[user].address, tokenid, 0],
    });
    await adminAccount.execute({
        entrypoint: "set_realm_data",
        contractAddress: erc721Address,
        calldata: [tokenid, 0, packData(realm_data[rand])],
    });
}

async function batchMintResourcesEmpire(amount) {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const adminAccount = getAccount(accountContracts[0], provider);

    let _ids = Array.from(Array(44), (_, index) =>
        index % 2 == 0 ? index / 2 + 1 : 0
    );
    let ids = _ids.concat([10000, 0, 10001, 0]);
    let amounts = Array.from(Array(48), (_, index) =>
        index % 2 == 0 ? BigInt(amount * 10 ** 18) : BigInt(0)
    );
    let t = ids.concat([24], amounts, [1, 0]);
    let calldata = [getDeployedContractAddress("empire"), 24].concat(t);
    await adminAccount.execute({
        entrypoint: "mintBatch",
        contractAddress: getDeployedContractAddress("erc1155"),
        calldata: calldata,
    });
}

async function mintLordsUser(amount, user) {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const adminAccount = getAccount(accountContracts[0], provider);
    const calldata = [
        accountContracts[user].address,
        BigInt(amount * 10 ** 18),
        0,
    ];
    await adminAccount.execute({
        entrypoint: "mint",
        contractAddress: getDeployedContractAddress("erc20"),
        calldata: calldata,
    });
}
async function mintLordsEmpire(amount) {
    const provider = getProvider();
    const accountContracts = await getDeployedAddresses();
    const adminAccount = getAccount(accountContracts[0], provider);
    const empireAddress = getDeployedContractAddress("empire");
    const calldata = [empireAddress, BigInt(amount * 10 ** 18), 0];
    await adminAccount.execute({
        entrypoint: "mint",
        contractAddress: getDeployedContractAddress("erc20"),
        calldata: calldata,
    });
}

module.exports = {
    batchMintResourcesEmpire,
    batchMintResourcesUsers,
    mintingRealm,
    mintLordsEmpire,
    mintLordsUser,
};
