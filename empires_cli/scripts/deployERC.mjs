import fs from "fs";
import { json } from "starknet";

export async function deployERC721Realms(provider) {
    const compiled = json.parse(
        fs.readFileSync("./compiled/ERC20/ERC20Mintable.json").toString("ascii")
    );
}

export async function deployErc20Mintable(provider, owner_address) {
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
            // recipient
            owner_address,
            // owner
            owner_address,
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
