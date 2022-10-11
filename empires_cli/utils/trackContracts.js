const fs = require("fs");

function updateDeployedContractAddress(name, address) {
    let addresses;
    try {
        addresses = fs.readFileSync("./data/addresses.json").toString("ascii");
        if (!addresses) {
            addresses = {};
        } else {
            addresses = JSON.parse(addresses);
        }
    } catch (e) {
        addresses = {};
    }
    const newAddresses = { ...addresses, [name]: address };
    fs.writeFileSync("./data/addresses.json", JSON.stringify(newAddresses));
}

function getDeployedContractAddress(name) {
    const addresses = JSON.parse(fs.readFileSync("./data/addresses.json"));
    return addresses[name];
}

module.exports = {
    updateDeployedContractAddress,
    getDeployedContractAddress,
};
