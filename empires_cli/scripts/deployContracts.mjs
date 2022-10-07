import fs from "fs";
import {
  Account,
  Contract,
  Provider,
  defaultProvider,
  ec,
  json,
  number,
  Signer,
} from "starknet";
import { modules } from "../utils/modules.mjs";
import { deployNoConstructorContract } from "../utils/deployment.mjs";

const options = { sequencer: { baseUrl: "http://localhost:5050" } };
const provider = new Provider(options);
console.log(provider);
//TODO: no error even if i put wrong value, check why
const starkKeyPair = ec.getKeyPair("0xc10f889ddaf9b2039b447ea2fa835285");
const account = new Account(
  provider,
  "0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8",
  starkKeyPair
);

async function initalizeRealmsModules(address, controllerAddress) {
  const response = await account.execute({
    entrypoint: "initializer",
    contractAddress: address,
    calldata: [
      // modules controller
      controllerAddress,
      // admin adddrss
      "0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8",
    ],
  });
  await provider.waitForTransaction(response.transaction_hash);
  console.log(
    "Initializer transaction confirmed with tx hash: ",
    response.transaction_hash
  );
}

async function deployRealmsContracts(provider) {
  // deploy controller

  // deploy modules
  for (const modulePath of Object.values(modules)) {
    await deployNoConstructorContract(modulePath, provider);
  }
}

async function deployErc20Mintable(provider) {
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
      "586326687173811284770377415536409798911599066310948070382172496299953698744",
      // owner 0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8
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

async function main(provider) {
  // const erc20MintableAddress = await deployErc20Mintable(provider);
  const buildingAddress = await deployRealmsContracts(provider);
}

main(provider);
