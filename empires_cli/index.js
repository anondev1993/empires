#!/usr/bin/env node
const { program } = require("commander");
const { deployRealmsContracts, deployEmpire } = require("./cli/deploy");
const {
    batchMintResourcesEmpire,
    batchMintResourcesUsers,
    mintingRealm,
} = require("./cli/mint");
const { ownerOf } = require("./cli/read");
const { joinEmpire, manageEmpire } = require("./cli/write");
const { advanceTime } = require("./utils/advanceTime");
const { getUserAccounts, getAdminAccount } = require("./utils/getAccount");

program
    .command("deploy-realms")
    .description("Deploys all the necessary contracts to play Realms")
    .action(() => {
        console.log("Deploying realms contract");
        deployRealmsContracts();
    });

program
    .command("deploy-empire")
    .description(
        "Deploys the Empire contract using the Realms contract addresses"
    )
    .action(() => {
        console.log("Deploying empire contract");
        deployEmpire();
    });

program
    .command("advance-time")
    .description("advances the time of the devnet by an amount of seconds")
    .requiredOption(
        "-s, --seconds <seconds>",
        "the number of seconds to advance"
    )
    .action((options) => {
        console.log(`Advancing the time by ${options.seconds}`);
        advanceTime(options.seconds);
    });

program
    .command("show-users")
    .description("Shows the users accounts")
    .action(() => {
        console.log("Showing all the users: ");
        getUserAccounts();
    });

program
    .command("show-admin")
    .description("Shows the admin account")
    .action(() => {
        console.log("Showing the admin account: ");
        getAdminAccount();
    });

program
    .command("mint-resources")
    .option("-e, --empire", "if you want to mint batch for the empire")
    .option("-u, --users <users...>", "if you want to mint batch for the users")
    .argument("<amount>", "an amount of resources to mint (in 10**18)")
    .description(
        "Minting amount of all Realms resources for empire or defined users"
    )
    .action((amount, options) => {
        if (options.empire) {
            console.log(`Minting ${amount} of all resources for empire`);
            batchMintResourcesEmpire();
        } else {
            if (options.users) {
                console.log(
                    `Minting ${amount} of all resources for users ${options["users"]}`
                );
                batchMintResourcesUsers(options["users"]);
            }
        }
    });

program
    .command("mint-realm")
    .requiredOption(
        "-u, --user <user>",
        "user that will receive the minted realm"
    )
    .requiredOption("-t, --tokenid <tokenid>", "the token id of the realm")
    .description("Minting 1 Realms NFT with token id for one user")
    .action((options) => {
        console.log(
            `Minting Realms NFTS for user ${options.user} with tokenid ${options.tokenid}`
        );
        mintingRealm(options.user, options.tokenid);
    });

program
    .command("join-empire")
    .requiredOption("-u, --user <user>", "user that wants to join the empire")
    .requiredOption(
        "-t, --tokenid <tokenid>",
        "token if of the realm that joins empires"
    )
    .description("Joins the empire by transferring realms nft")
    .action((options) => {
        console.log(
            `User ${options.user} with token id ${options.tokenid} joins the empire`
        );
        joinEmpire(options.user, options.tokenid);
    });

program
    .command("owner")
    .requiredOption("-t, --tokenid <tokenid>", "the id of the token")
    .action((options) => {
        ownerOf(options.tokenid);
    });

program
    .command("manage-empire")
    .option(
        "-u, --user [user]",
        "Specify which user is the emperor, by default user 0"
    )
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
        if (!options.user)
            manageEmpire(0, options.entrypoint, JSON.parse(options.calldata));
        else
            manageEmpire(
                options.user,
                options.entrypoint,
                JSON.parse(options.calldata)
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
