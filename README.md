# lr_land_redeem_sol

## what
https://twitter.com/davidiola_/status/1520688640132800513

## tx 
https://etherscan.io/tx/0x62955836139fa34e8de69107b69e3f810373a188eb4d6d177f71d4bef7ae8f4d

## testing
```forge test --fork-url [rpc_url] --fork-block-number 14403948 -vvvv```

## Testing
- comment out lines 98 - 116 (ILandAirdrop) as land airdrop was not live during block used for testing.
- tests are mainly to validate LooksRare order taking logic + withdrawal NFT logic, leave as an exercise to reader to re-create above mainnet tx

```
forge test --fork-url [alchemy_url] --fork-block-number 14676636 -vvvv
```
