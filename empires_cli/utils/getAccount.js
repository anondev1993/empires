const { Account, ec } = require("starknet");
const { getDeployedAddresses } = require("./getAddresses");

function getAccount(accountContract, provider) {
    const starkKeyPair = ec.getKeyPair(accountContract.private_key);
    const account = new Account(
        provider,
        accountContract.address,
        starkKeyPair
    );
    return account;
}

async function getUserAccounts() {
    const accountContracts = await getDeployedAddresses();
    const userAccounts = [];
    accountContracts.forEach((user, index) => {
        if (index != 0) {
            userAccounts.push({ ...user, number: index });
        }
    });

    console.log(userAccounts);
}

async function getAdminAccount() {
    const accountContracts = await getDeployedAddresses();
    const adminAccount = { ...accountContracts[0], number: 0 };
    console.log(adminAccount);
}

module.exports = { getAccount, getUserAccounts, getAdminAccount };
