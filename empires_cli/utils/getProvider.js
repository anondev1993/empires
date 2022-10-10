require("dotenv").config();
const { Provider } = require("starknet");

function getProvider() {
    // address of starknet-dev
    const options = { sequencer: { baseUrl: process.env.PROVIDER_URL } };
    const provider = new Provider(options);

    return provider;
}

module.exports = { getProvider };
