import { Account, ec } from "starknet";

// deploy a new Account smart contract
async function deployAccount(accountPubKey) {
    const compiledAccount = json.parse(
        fs.readFileSync("compiled/Account.json").toString("ascii")
    );

    const accountResponse = await provider.deployContract({
        contract: compiledAccount,
        constructorCalldata: [accountPubKey],
        addressSalt: accountPubKey,
    });

    await provider.waitForTransaction(accountResponse.transaction_hash);
    console.log(
        "Account contract deployed at address: ",
        accountResponse.contract_address
    );

    return accountResponse.address;
}

export function getAccount(accountContract, provider) {
    const starkKeyPair = ec.getKeyPair(accountContract.private_key);
    const account = new Account(
        provider,
        accountContract.address,
        starkKeyPair
    );
    return account;
}
