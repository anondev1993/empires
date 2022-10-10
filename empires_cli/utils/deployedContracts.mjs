import fs from "fs";

export function updateDeployedContractAddress(name, address) {
    let addresses;
    try {
        addresses = fs.readFileSync("./addresses.json").toString("ascii");
        if (!addresses) {
            addresses = {};
        } else {
            addresses = JSON.parse(addresses);
        }
    } catch (e) {
        addresses = {};
    }
    const newAddresses = { ...addresses, [name]: address };
    fs.writeFileSync("./addresses.json", JSON.stringify(newAddresses));
}

export function getDeployedContractAddress(name) {
    const addresses = JSON.parse(
        fs.readFileSync("./addresses.json").toString("ascii")
    );
    return addresses[name];
}
