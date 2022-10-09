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
