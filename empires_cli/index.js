#!/usr/bin/env node
const { program } = require("commander");
const { deployRealmsContracts, deployEmpire } = require("./cli/deploy");
const {
    batchMintResourcesEmpire,
    batchMintResourcesUsers,
    mintingRealm,
    mintLordsUser,
    mintLordsEmpire,
} = require("./cli/mint");
const {
    ownerOf,
    readEmpire,
    readRealms,
    balanceOfBatch,
} = require("./cli/read");
const { joinEmpire, manageEmpire } = require("./cli/write");
const { advanceTime } = require("./utils/advanceTime");
const { getUserAccounts, getAdminAccount } = require("./utils/getAccount");
const { getDeployedAddresses } = require("./utils/getAddresses.js");
const { getDeployedContractAddress } = require("./utils/trackContracts.js");

program
    .command("quickstart")
    .description(
        "deploy a quick start version of all contracts for Realm and Empire, including minting of 3 tokens."
    )
    .action(async () => {
        console.log("Deploying realms contract");
        await deployRealmsContracts();
        console.log("Deploying empire contract");
        await deployEmpire();
        console.log("Minting 1000 resources for the Empires");
        await batchMintResourcesEmpire(1000);
        console.log(
            "Minting Realms NFTS for user 1 with tokenid 1 and joining empire"
        );
        await mintingRealm(1, 1);
        await joinEmpire(1, 1);
        console.log(
            "Minting Realms NFTS for user 2 with tokenid 2 and joining empire"
        );
        await mintingRealm(2, 2);
        await joinEmpire(2, 2);
        console.log("Minting Realms NFTS for user 3 with tokenid 3");
        await mintingRealm(3, 3);
    });

program
    .command("deploy-realms")
    .description("deploy all the necessary contracts to play Realms")
    .action(() => {
        console.log("Deploying realms contract");
        deployRealmsContracts();
    });

program
    .command("deploy-empire")
    .description(
        "deploy the Empire contract using the Realms contract addresses"
    )
    .action(() => {
        console.log("Deploying empire contract");
        deployEmpire();
    });

program
    .command("advance-time")
    .description("advance the time of the devnet by an amount of seconds")
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
    .description("show the users accounts")
    .action(() => {
        console.log("Showing all the users: ");
        getUserAccounts();
    });

program
    .command("show-admin")
    .description("show the admin account")
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
        "mint amount of all Realms resources for empire or defined users"
    )
    .action((amount, options) => {
        if (options.empire) {
            console.log(`Minting ${amount} of all resources for empire`);
            batchMintResourcesEmpire(amount);
        } else {
            if (options.users) {
                console.log(
                    `Minting ${amount} of all resources for users ${options["users"]}`
                );
                batchMintResourcesUsers(options["users"], amount);
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
    .description("mint 1 Realms NFT with token id for one user")
    .action((options) => {
        console.log(
            `Minting Realms NFTS for user ${options.user} with tokenid ${options.tokenid}`
        );
        mintingRealm(options.user, options.tokenid);
    });

program
    .command("mint-lords")
    .argument("<amount>", "an amount of lords to mint (in 10**18)")
    .option("-e, --empire", "if you want to mint lords for the empire")
    .option("-u, --user <user>", "if you want to mint lords for one user")
    .description("mint an amount of $LORDS for the user")
    .action((amount, options) => {
        if (options.empire) {
            console.log(`Minting ${amount} of LORDS for empire`);
            mintLordsEmpire(amount);
        } else {
            if (options.user) {
                console.log(
                    `Minting ${amount} of LORDS for users ${options["user"]}`
                );
                mintLordsUser(amount, options["user"]);
            }
        }
    });

program
    .command("join-empire")
    .requiredOption("-u, --user <user>", "user that wants to join the empire")
    .requiredOption(
        "-t, --tokenid <tokenid>",
        "token if of the realm that joins empires"
    )
    .description("join the empire by transferring realms nft")
    .action((options) => {
        console.log(
            `User ${options.user} with token id ${options.tokenid} joins the empire`
        );
        joinEmpire(options.user, options.tokenid);
    });

program
    .command("owner")
    .requiredOption("-t, --tokenid <tokenid>", "the id of the token")
    .description("query the owner of the token")
    .action((options) => {
        ownerOf(options.tokenid);
    });

program
    .command("resources")
    .option("-u, --user <user>", "if you want to check the resources of a user")
    .option("-e, --empire", "if you want to check the resources of the empire")
    .description("query the current resources of the user")
    .action(async (options) => {
        if (options.empire) {
            console.log("Querying the empires' resources");
            const empireAddress = getDeployedContractAddress("empire");
            balanceOfBatch(empireAddress);
        } else {
            if (options.user) {
                console.log(`Querying user ${options.user}'s resources`);
                const accountContracts = await getDeployedAddresses();
                const index = parseInt(options.user, 10);
                balanceOfBatch(accountContracts[index].address);
            }
        }
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
    .description("call the functions from the empire contract")
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
    .command("read-empire")
    .requiredOption(
        "-e, --entrypoint <entrypoint>",
        "The Empire function to call"
    )
    .option(
        "-c, --calldata <calldata>",
        "The arguments of the function as a string of a list (no space between elements)"
    )
    .description("query the storage of the Empire")
    .action(({ entrypoint, calldata }) => {
        readEmpire(entrypoint, JSON.parse(calldata));
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
    .description("query the storage of the Realm module")
    .action(({ module, entrypoint, calldata }) => {
        readRealms(module, entrypoint, JSON.parse(calldata));
    });

program.parse(process.argv);
