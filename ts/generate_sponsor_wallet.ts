import * as api3 from "@api3/airnode-admin";
import { createInterface } from "readline";

const readline = createInterface({
  input: process.stdin,
  output: process.stdout,
});

// request url from user in command prompt
const asyncPrompt = (question: string) => {
  return new Promise<string>((resolve, reject) => {
    readline.question(question, async (response) => {
      resolve(response);
    });
  });
};

const go = async () => {
  const contractAddress = await asyncPrompt("Enter contract address: ");
  const confirmation = await asyncPrompt(
    `Got contract address ${contractAddress}. Press Y to confirm: `
  );
  if (confirmation !== "Y") {
    throw new Error("did not confirm");
  }

  const network = await asyncPrompt("What network do you want to use?");
  let XPUB;
  let AIRNODE;
  if (network === "base") {
    // https://docs.api3.org/reference/qrng/providers.html
    XPUB =
      "xpub6CyZcaXvbnbqGfqqZWvWNUbGvdd5PAJRrBeAhy9rz1bbnFmpVLg2wPj1h6TyndFrWLUG3kHWBYpwacgCTGWAHFTbUrXEg6LdLxoEBny2YDz";
    AIRNODE = "0x224e030f03Cd3440D88BD78C9BF5Ed36458A1A25";
  } else if (network == "base_sepolia") {
    // https://docs.api3.org/reference/qrng/providers.html
    XPUB =
      "xpub6CuDdF9zdWTRuGybJPuZUGnU4suZowMmgu15bjFZT2o6PUtk4Lo78KGJUGBobz3pPKRaN9sLxzj21CMe6StP3zUsd8tWEJPgZBesYBMY7Wo";
    AIRNODE = "0x6238772544f029ecaBfDED4300f13A3c4FE84E1D";
  }

  if (!XPUB || !AIRNODE) {
    throw new Error("network not found");
  }

  const sponsorWalletAddress = await api3.deriveSponsorWalletAddress(
    XPUB,
    AIRNODE,
    contractAddress
  );
  console.log({ sponsorWalletAddress, contractAddress });
  console.log("Your sponsor address is", sponsorWalletAddress, ".");
  console.log("Next step: fund the sponsor address with ETH.");
};

go().then(() => {
  process.exit();
});
