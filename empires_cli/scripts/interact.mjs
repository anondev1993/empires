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

async function main() {
  const options = { sequencer: { baseUrl: "http://localhost:5050" } };
  const provider = new Provider(options);
  //TODO: no error even if i put wrong value, check why
  const starkKeyPair = ec.getKeyPair("0xc10f889ddaf9b2039b447ea2fa835285");
  const account = new Account(
    provider,
    "0x14bd9618b34b1cb5c57feefbfcaa0acb9812e6ca7e3cf5a1cd86e1ad6c737b8",
    starkKeyPair
  );

  const erc20Address =
    "0x04e83a6355d3e5dee0a5cec76cb634c558906828a61b4f8f81b449b5061766b6";

  // TODO: how to get balance?
  // const response = await account.execute({
  //   entrypoint: "balanceOf",
  //   contractAddress: erc20Address,
  //   calldata: [
  //     "586326687173811284770377415536409798911599066310948070382172496299953698744",
  //   ],
  // });
  const response = await account.execute({
    entrypoint: "transfer",
    contractAddress: erc20Address,
    calldata: [
      // my argent account 2
      "2724239328133579815326317010668104112468424150014954275070058048198289066157",
      BigInt(1 * 10 ** 18),
      0,
    ],
  });

  await provider.waitForTransaction(response.transaction_hash);

  console.log(response);
}

main();
