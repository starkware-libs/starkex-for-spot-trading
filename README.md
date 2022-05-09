# StarkEx Cairo Code Repository
​
## Overview
​
This repository contains the Cairo code (and some of the cryptographic primitives) used by StarkEx,
StarkWare's scalability solution for spot ERC-20 and ERC-721 trading.
If you are not familiar with StarkEx, you can read more about it [here](https://docs.starkware.co/starkex-v3/).
​

Note: The Cairo code that proves perpetual trading, can be found [in another repo](https://github.com/starkware-libs/stark-perpetual).
​

If you are not familiar with the Cairo language, you can find more details about it [here](https://www.cairo-lang.org/).

​
The Cairo code is published to allow a permissionless audit of StarkEx business logic,
as enforced by the StarkEx smart-contract


## Repository Contents
​
**src/starkware/cairo/dex**, **src/services/exchange/cairo**
The full Cairo program that StarkEx, StarkWare's scaling solution,  executes.
It includes a Python file, *generate_program_hash_test.py*, that calculates the hash of the
Cairo code and compares it to the pre-calculated value found at *program_hash.json*
​

**src/starkware/crypto/starkware/crypto/signature**: The Python implementation of the
cryptographic primitives used by StarkEx, namely the Pedersen hash functions and the ECDSA signature.
These implementations, or equivalent implementations in other languages such as JS, are used by StarEx user's wallets in order to generate and sign on orders.


**src/starkware/python**: additional utility scripts the scripts at *src/starkware/cairo/dex* need.

## How to Use the Repo
​
### Prerequisites:
​
[Docker](https://docs.docker.com/get-docker/) (Ubuntu install via: `apt install -y docker.io`)
​
### Usage:
​
1. Run the test to verify that the Cairo program hash is indeed the one saved in the file
*src/starkware/cairo/dex/program_hash.json* by running the command:\
    `docker build .`

2. Verify that the same hash is used by StarkEx on Mainnet by running the script
*src/services/extract_cairo_hash.py* in the following way:\
    `./src/services/exchange/extract_cairo_hash.py --main_address <checksummed_main_address> --node_endpoint <your_node_endpoint> `
​

You can find the relevant addresses and current versions for the
different StarkEx deployments [here](https://docs.starkware.co/starkex-v3/deployments-addresses).

When comparing the hash, please make sure you checkout the tag that corresponds to the
deployed version from this repo.
