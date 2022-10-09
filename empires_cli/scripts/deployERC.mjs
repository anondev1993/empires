export async function deployERC721Realms(provider) {
    const compiled = json.parse(
        fs.readFileSync("./compiled/ERC20/ERC20Mintable.json").toString("ascii")
    );
}

export async function deployErc20Mintable(provider) {
    const compiled = json.parse(
        fs.readFileSync("./compiled/ERC20/ERC20Mintable.json").toString("ascii")
    );

    const response = await provider.deployContract({
        contract: compiled,
        constructorCalldata: [
            //name Ether
            "298305742194",
            // symbol ETH
            "4543560",
            // decimals
            "18",
            // original supply
            "38411331902790913116538",
            "0",
            // recipient 0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8
            //TODO: change that to new account
            "586326687173811284770377415536409798911599066310948070382172496299953698744",
            // owner 0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8
            //TODO: change that to new account
            "586326687173811284770377415536409798911599066310948070382172496299953698744",
        ],
    });
    console.log(
        "Waiting for Tx to be Accepted on Starknet - ERC20 Deployment..."
    );
    await provider.waitForTransaction(response.transaction_hash);

    const address = response.contract_address;
    console.log("address of the contract: ", address);
    return address;
}
