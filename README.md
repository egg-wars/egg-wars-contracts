## Egg Wars

### Review scope

Please review all the files in `./src/`, as well as the deploy script in `./script` along with the release plan detailed below

This is a game created from a hackathon and being released on a L2 (Base). Not looking for minor gas improvements, but interested in any possible exploits or unintended behavior.

Acknowledged issues:

- I know ERC721Enumerable is gas heavy but it makes it easier for the frontend to work without an indexer
- I know that the owner() of Chicken.sol has powerful authority, but we expect to renounce this after a few days of gameplay

### Functionality

The game starts with 150 players, each of whom has a chicken, which is an ERC-721. Each chicken starts at level 1. The other game piece that players will get as they play are eggs, which are ERC-20s.

Players have four actions that they can take:

1. **They can have their chicken(s)** lay eggs. The number of eggs a chicken lays is equal to the level of the chicken (e.g. a level 10 chicken will lay 10 eggs). A chicken can only lay eggs once every 8 hours.

2. **They can feed their chicken eggs.** Each egg they feed their chicken increases the level of the chicken by 1 (e.g. if your chicken is level 1 and you feed it 5 eggs, the chicken will be level 6). Chickens have a max level of 20. When an egg is fed to a chicken, the egg is burned.

3. **They can throw their eggs at other players’ chickens.** For each egg thrown at a chicken, its level decreases by 1. A chicken’s level can never go below 1. Each egg that is thrown is burned.

4. **They can attempt to hatch a chicken from an egg.** The likelihood of success with hatching is 10%. If the hatching succeeds, the player receives a new ERC-721 of a chicken that starts at level 1. Whether the hatching succeeds or fails, the egg is burned.

The original 150 players contributed 0.015 ETH each, for a total of 2.25 ETH. This ETH could be used to start a liquidity pool on Uniswap with 60,000 eggs. Existing players can buy or sell eggs to support their game strategy. New players can buy eggs to attempt to hatch new chickens and join the game.

### Deploying

Set up `.env` (cp `.env.sample .env`)

Run `./deploy/deploy_testnet.sh` or `./deploy/deploy_base.sh`

Run `yarn generate_sponsor` and paste in the Chicken smart contract address

Call `setSponsorWallet` with the output

Send ETH to Sponsor Wallet address

### Base release plan

- [ ] Pass proposal to send ETH to deployer address
- [ ] Deploy EggToken & Chicken contracts via Deployment plan above
- [ ] Airdrop 1 chicken to st3ve.eth
- [ ] Have st3ve.eth test `attemptHatch`
- [ ] Consider proposing that Party LPs the EGG token with the ETH in the party
- [ ] Call `Chicken.airdrop()`, have params include 1 chicken for every party membership (https://basescan.org/token/0x8138f468D235fFA0C6B32ae70aA799555a91ee74#balances)
- [ ] Call `Chicken.closeAirdrop()` to disable any more chickens being produced
- [ ] Change owner of Chicken to the party address (`0x8138f468D235fFA0C6B32ae70aA799555a91ee74`)
- [ ] After a few days of gameplay, have prty renounce ownership of Chicken contract
