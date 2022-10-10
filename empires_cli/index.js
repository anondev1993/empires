#!/usr/bin/env node
const { program } = require("commander");

program
    .command("deploy-realms")
    .description("Deploys all the necessary contracts to play Realms")
    .action(() => console.log("deploying realms contract"));

program
    .command("deploy-empire")
    .description(
        "Deploys the Empire contract using the Realms contract addresses"
    )
    .action(() => console.log("deploying empire contract"));

program
    .command("show-users")
    .description("Shows the users accounts")
    .action(() => console.log("Showing the users"));

program
    .command("show-admin")
    .description("Shows the admin account")
    .action(() => console.log("Showing the admin account"));

program
    .command("mint-resources")
    .option("-e, --empire", "if you want to mint batch for the empire")
    .option("-u, --users <users...>", "if you want to mint batch for the users")
    .argument("<amount>", "an amount of resources to mint")
    .description(
        "Minting amount of all Realms resources for empire or defined users"
    )
    .action((amount, options) => {
        if (options.empire) {
            console.log(`Minting ${amount} ressources for empire`);
        } else {
            if (options.users) {
                console.log(
                    `Minting ${amount} ressources for users ${options["users"]}`
                );
            }
        }
    });

program
    .command("mint-realms")
    .requiredOption(
        "-u, --users <users...>",
        "users that will receive the minted realms"
    )
    .description("Minting 1 Realms NFT per defined user")
    .action((options) => {
        console.log(`Minting Realms NFTS for users ${options.users}`);
    });

program
    .command("join-empire")
    .requiredOption("-u, --user <user>", "user that wants to join the empire")
    .requiredOption(
        "-t, -tokenid <tokenid>",
        "token if of the realm that joins empires"
    )
    .description("Joins the empire by transferring realms nft")
    .action(({ user, Tokenid }) => {
        // console.log(options);
        console.log(`User ${user} with token id ${Tokenid} joins the empire`);
    });

program
    .command("manage-empire")
    .requiredOption(
        "-e, --entrypoint <entrypoint>",
        "The Empire function to call"
    )
    .option(
        "-c, --calldata <calldata>",
        "The arguments of the function as a string of a list (no space between elements)"
    )
    .description("calls the functions from the empire contract")
    .action((options) => {
        console.log(
            `Calls the function ${
                options.entrypoint
            } with calldata ${JSON.parse(options.calldata)}`
        );
    });

program
    .command("read-realms")
    .requiredOption(
        "-m, --module <module>",
        "the name of one of the realms modules"
    )
    .requiredOption(
        "-e, --entrypoint <entrypoint>",
        "The Empire function to call"
    )
    .option(
        "-c, --calldata <calldata>",
        "The arguments of the function as a string of a list (no space between elements)"
    )
    .action(({ module, entrypoint, calldata }) => {
        console.log(module);
        console.log(entrypoint);
        console.log(JSON.parse(calldata));
    });

program.parse(process.argv);
