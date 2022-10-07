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

// @notice Deploys a smart contract without constructor
// @param provider Provider
export async function deployNoConstructorContract(path, provider) {
  const compiled = json.parse(fs.readFileSync(path).toString("ascii"));
  const response = await provider.deployContract({
    contract: compiled,
  });
  console.log(
    `Waiting for Tx to be Accepted on Starknet - ${path} Deployment...`
  );
  await provider.waitForTransaction(response.transaction_hash);

  const address = response.contract_address;
  console.log("address of the contract: ", address);
  return address;
}
