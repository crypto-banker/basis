## Basis

Basis is a system of smart contracts designed to automatically manage the issuance of a sovereign/reserve currency-style ERC20 token, called basis.
The Issuer contract is the primary point of interaction for users, controlling issuance of the underlying basis token and all of its bond tokens. Bonds are themselves ERC20 tokens, redeemable through the Issuer contract at (or after!) their expiration for an equal amount of the underlying basis token. The Issuer contract sells new bonds via a Dutch auction mechanism, where the yield on new bonds increases until they are all sold.

Basis uses the [Foundry framework](https://www.getfoundry.sh/) for compilation, tests, and deployment.

See below for development-related commands.

### Installation

Install foundry

```shell
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

Install dependencies

```shell
forge install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
