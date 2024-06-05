## Egg Wars

Live at https://eggwars.xyz

```
WARNING: This is an unaudited barnyard experimental game. It has been reviewed but not officially audited. Use at your own risk.
This is a game for fun, not for financial gain or speculation! There are no plans for future development.
```

### Deployments

EggToken: https://basescan.org/address/0xD20f3D9229FA77898D69524526fA590DAbdFf701
Chicken: https://basescan.org/address/0x3Ecb4A5c42671379f7b287431dB9002A17EE7018

### Functionality

The game starts with 150 players, each of whom has a chicken, which is an ERC-721. Each chicken starts at level 1. The other game piece that players will get as they play are eggs, which are ERC-20s.

Players have four actions that they can take:

1. **They can have their chicken(s)** lay eggs. The number of eggs a chicken lays is equal to the level of the chicken (e.g. a level 10 chicken will lay 10 eggs). A chicken can only lay eggs once every 8 hours.

2. **They can feed their chicken eggs.** Each egg they feed their chicken increases the level of the chicken by 1 (e.g. if your chicken is level 1 and you feed it 5 eggs, the chicken will be level 6). Chickens have a max level of 20. When an egg is fed to a chicken, the egg is burned.

3. **They can throw their eggs at other players’ chickens.** For each egg thrown at a chicken, its level decreases by 1. A chicken’s level can never go below 1. Each egg that is thrown is burned.

4. **They can attempt to hatch a chicken from an egg.** The likelihood of success with hatching is 10%. If the hatching succeeds, the player receives a new ERC-721 of a chicken that starts at level 1. Whether the hatching succeeds or fails, the egg is burned.
