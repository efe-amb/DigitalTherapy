# DigitalTherapy Smart Contract

A comprehensive synthetic assets smart contract for tracking digital therapeutics and app-based medical treatments on the Stacks blockchain.

## Description

DigitalTherapy is a Clarity smart contract that manages digital therapeutic assets, tracks treatment efficacy, and enables synthetic asset creation for digital health interventions. The contract provides a decentralized platform for healthcare providers to register digital therapies, patients to track their treatments, and investors to create synthetic positions based on therapy performance.

## Features

### Core Functionality
- **Digital Therapy Registry**: Create and manage digital therapeutic programs
- **Treatment Tracking**: Record patient treatments with outcomes and efficacy metrics
- **Synthetic Asset Positions**: Create financial instruments based on therapy efficacy rates
- **Therapy Credits**: SIP-010 compliant fungible token system for platform incentives
- **Authorization System**: Role-based access control for therapy creators
- **Real-time Efficacy Calculation**: Automatic updates of therapy success rates

### Key Capabilities
- Therapy creation with name, category, and initial efficacy rate
- Patient treatment lifecycle management (start, complete, abandon)
- Automatic efficacy rate recalculation based on treatment outcomes
- Synthetic position creation with collateral requirements
- Position settlement based on efficacy performance changes
- Comprehensive treatment history and analytics

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Token Standard**: SIP-010 (Fungible Token)
- **Clarity Version**: 2
- **Epoch**: 2.5

### Contract Architecture
- **Main Contract**: `DigitalTherapy.clar`
- **Token**: `therapy-credits` (fungible token)
- **Maps**: 5 primary data structures for therapies, treatments, positions, and authorization
- **Constants**: 6 error codes and validation parameters

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- Node.js 16+ and npm
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd DigitalTherapy
   ```

2. **Navigate to contract directory**
   ```bash
   cd DigitalTherapy_contract
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Run tests**
   ```bash
   npm test
   ```

5. **Run tests with coverage**
   ```bash
   npm run test:report
   ```

6. **Watch mode for development**
   ```bash
   npm run test:watch
   ```

## Usage Examples

### Initialize the Contract
```clarity
;; Only contract owner can initialize
(contract-call? .DigitalTherapy initialize)
```

### Authorize a Therapy Creator
```clarity
;; Owner authorizes a healthcare provider
(contract-call? .DigitalTherapy authorize-creator 'SP1HEALTHCARE_PROVIDER)
```

### Create a Digital Therapy
```clarity
;; Create a new therapy program
(contract-call? .DigitalTherapy create-therapy
  "Mindfulness App"
  "Mental Health"
  u7500) ;; 75% initial efficacy rate
```

### Start a Treatment
```clarity
;; Patient starts treatment for therapy ID 1
(contract-call? .DigitalTherapy start-treatment u1)
```

### Complete a Treatment
```clarity
;; Complete treatment with successful outcome
(contract-call? .DigitalTherapy complete-treatment
  u1 ;; therapy-id
  u1 ;; treatment-id
  true ;; successful
  (some "Significant improvement in anxiety levels"))
```

### Create Synthetic Position
```clarity
;; Create position on therapy efficacy
(contract-call? .DigitalTherapy create-synthetic-position
  u1 ;; therapy-id
  u10) ;; position size (costs 100 therapy credits)
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions
- `initialize()` - Initialize contract and mint initial credits (owner only)
- `authorize-creator(principal)` - Authorize therapy creators (owner only)

#### Therapy Management
- `create-therapy(name, category, initial-efficacy)` - Register new digital therapy
- `start-treatment(therapy-id)` - Begin patient treatment
- `complete-treatment(therapy-id, treatment-id, successful, notes)` - Finish treatment with outcome

#### Synthetic Assets
- `create-synthetic-position(therapy-id, position-size)` - Create leveraged position
- `close-synthetic-position(therapy-id)` - Settle and close position

### Read-Only Functions

#### Data Retrieval
- `get-therapy(therapy-id)` - Retrieve therapy information
- `get-treatment(patient, therapy-id, treatment-id)` - Get treatment record
- `get-synthetic-position(holder, therapy-id)` - View position details
- `get-therapy-credits-balance(account)` - Check token balance
- `get-contract-stats()` - Overall contract statistics
- `is-authorized-creator(creator)` - Check creator authorization
- `get-therapy-efficacy(therapy-id)` - Get current efficacy rate

### Error Codes
- `u100` - ERR_UNAUTHORIZED: Insufficient permissions
- `u101` - ERR_NOT_FOUND: Resource does not exist
- `u102` - ERR_ALREADY_EXISTS: Resource already exists
- `u103` - ERR_INVALID_PARAMS: Invalid parameters provided
- `u104` - ERR_INSUFFICIENT_BALANCE: Insufficient token balance
- `u105` - ERR_THERAPY_INACTIVE: Therapy is not active

## Deployment Guide

### Local Development (Devnet)
```bash
clarinet integrate
```

### Testnet Deployment
1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
   ```bash
   clarinet deploy --testnet
   ```

### Mainnet Deployment
1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy to mainnet:
   ```bash
   clarinet deploy --mainnet
   ```

### Post-Deployment Steps
1. Call `initialize()` function
2. Authorize initial therapy creators
3. Verify all functions work correctly
4. Monitor initial therapy registrations

## Security Notes

### Access Control
- Contract owner has exclusive initialization and authorization rights
- Only authorized creators can register new therapies
- Patients can only manage their own treatments
- Position holders can only close their own positions

### Validation Mechanisms
- String length validation for therapy names and categories
- Efficacy rate bounds checking (0-10000 basis points)
- Treatment status validation before completion
- Sufficient balance checks for synthetic positions

### Economic Security
- Collateral requirements for synthetic positions (10 credits per unit)
- Automatic efficacy recalculation prevents manipulation
- Treatment rewards incentivize honest reporting
- Position settlement based on actual performance data

### Recommendations
- Regular auditing of therapy efficacy calculations
- Monitoring for unusual trading patterns in synthetic positions
- Verification of treatment outcome authenticity
- Implementation of additional oracle data for validation

## Token Economics

### Therapy Credits Distribution
- Initial mint: 1,000,000 credits to contract owner
- Creator rewards: 1,000 credits per therapy creation
- Treatment completion: 100 credits (successful), 50 credits (unsuccessful)
- Synthetic positions: 10 credits collateral per unit

### Incentive Structure
- Therapy creators incentivized through credit rewards
- Patients rewarded for treatment completion
- Successful outcomes receive higher rewards
- Synthetic positions provide market-based efficacy discovery

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write comprehensive tests
4. Ensure all tests pass
5. Submit a pull request with detailed description

## License

This project is licensed under the ISC License.

## Support

For technical support or questions about the DigitalTherapy smart contract, please create an issue in the repository or contact the development team.