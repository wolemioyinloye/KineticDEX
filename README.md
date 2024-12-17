# KineticDEX

KineticDEX is a decentralized exchange (DEX) built on the Stacks blockchain, enabling fast and efficient token swaps with automated market maker functionality.

## Features

- **Automated Market Maker (AMM)**: Utilizes a constant product formula for efficient token pricing
- **Liquidity Pools**: Users can create and manage liquidity pools for token pairs
- **Low Fees**: Competitive 0.3% fee structure for sustainable operations
- **Security First**: Built with robust security measures and fail-safes

## Smart Contract Architecture

The KineticDEX smart contract implements the following core functionality:

1. **Liquidity Pool Creation**
   - Users can create new pools for token pairs
   - Initial liquidity provider sets the initial price ratio

2. **Token Swapping**
   - Constant product formula (x * y = k)
   - Slippage protection with minimum output amount
   - Automatic fee collection

3. **Liquidity Provider Management**
   - Track liquidity provider shares
   - Fair distribution of trading fees

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks Wallet](https://www.hiro.so/wallet) for interacting with the DEX
- Basic understanding of Clarity and Stacks blockchain

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/kineticdex.git
cd kineticdex
```

2. Install dependencies:
```bash
clarinet requirements
```

3. Run tests:
```bash
clarinet test
```

### Deployment

1. Update the contract configurations in `Clarinet.toml`
2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## Usage

### Creating a Liquidity Pool

```clarity
(contract-call? .kineticdex create-pool 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-x
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-y
    u1000000
    u1000000)
```

### Swapping Tokens

```clarity
(contract-call? .kineticdex swap-exact-tokens
    u1
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-x
    u1000
    u990)
```

## Security

- Contract owner functionality is limited to emergency situations
- All mathematical operations include overflow checks
- Slippage protection built into swap functions
- Comprehensive test suite covering edge cases

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## Acknowledgments

- Stacks Foundation
- Clarity Language Documentation
- OpenZeppelin for security patterns