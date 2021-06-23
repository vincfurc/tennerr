# tennerr
hackaton - hackmoney2021

## Prerequisites

Please install or have installed the following:

- [nodejs and npm](https://nodejs.org/en/download/)
- [python](https://www.python.org/downloads/)
## Installation

1. [Install Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html), if you haven't already. Here is a simple way to install brownie.


```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
# restart your terminal
pipx install eth-brownie
```
Or, if that doesn't work, via pip
```bash
pip install eth-brownie
```
## Local Development

For local testing [install ganache-cli](https://www.npmjs.com/package/ganache-cli)
```bash
npm install -g ganache-cli
```
or
```bash
yarn add global ganache-cli
```

## Testnet Development
If you want to be able to deploy to testnets, do the following.

Set your `WEB3_INFURA_PROJECT_ID`, and `ETHERSCAN_TOKEN`.

You can get a `WEB3_INFURA_PROJECT_ID` by getting a free trial of [Infura](https://infura.io/). At the moment, it does need to be infura with brownie. If you get lost, you can [follow this guide](https://ethereumico.io/knowledge-base/infura-api-key-guide/) to getting a project key. 
You can get a `ETHERSCAN_TOKEN` by registering at [Etherscan](etherscan.io/).
You could also set your `PRIVATE_KEY`, which you can find from your ethereum wallet like [metamask](https://metamask.io/).

1. Run Tests in Development network: 
`brownie test --network development`
or
Run Tests on Polygon network:
`brownie test --network polygon-fork`

2. Run in console:
`brownie console --network polygon-fork`


