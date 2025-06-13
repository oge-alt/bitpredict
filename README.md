# BitPredict Protocol

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546FF?style=flat-square)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Smart%20Contract-Clarity-orange?style=flat-square)](https://clarity-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square)](https://github.com/bitpredict/protocol)

A trustless, decentralized prediction market protocol built on Stacks, enabling users to stake STX tokens on asset price movements and earn proportional rewards for accurate predictions.

## 🎯 Overview

BitPredict leverages Stacks' secure smart contract capabilities to create transparent, automated prediction markets. The protocol eliminates intermediaries while ensuring fair reward distribution through mathematical precision and blockchain transparency.

### Key Features

- **Trustless Operations**: No intermediaries, automated payouts
- **Proportional Rewards**: Winners share the total pool based on stake weight
- **Oracle Integration**: Reliable price feeds for accurate market resolution
- **Flexible Market Creation**: Customizable timeframes and assets
- **Built-in Governance**: Administrative controls for protocol evolution
- **Emergency Controls**: Pause mechanism for security

## 🏗️ System Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Market Layer  │    │  Oracle Layer   │    │  Reward Layer   │
│                 │    │                 │    │                 │
│ • Market CRUD   │    │ • Price Feeds   │    │ • Calculations  │
│ • Validation    │    │ • Resolution    │    │ • Distribution  │
│ • State Mgmt    │    │ • Verification  │    │ • Fee Handling  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Core Protocol  │
                    │                 │
                    │ • STX Transfers │
                    │ • State Storage │
                    │ • Access Control│
                    │ • Event Logging │
                    └─────────────────┘
```

### Contract Architecture

The BitPredict protocol is structured around five main architectural layers:

#### 1. **Storage Layer**

- **Markets Map**: Stores market metadata, stakes, and resolution data
- **Predictions Map**: Tracks user predictions and claim status
- **Statistics Map**: Maintains user and platform analytics
- **Configuration Variables**: Protocol parameters and settings

#### 2. **Business Logic Layer**

- **Market Management**: Creation, validation, and lifecycle management
- **Prediction Handling**: Stake processing and validation
- **Resolution Engine**: Oracle-based market resolution
- **Reward Calculator**: Proportional payout calculations

#### 3. **Security Layer**

- **Access Control**: Owner-only functions and oracle authorization
- **Validation Engine**: Parameter validation and business rule enforcement
- **Emergency Controls**: Protocol pause and recovery mechanisms
- **Balance Verification**: Ensures sufficient funds for operations

#### 4. **Interface Layer**

- **Public Functions**: User-facing market interactions
- **Read-Only Functions**: Data queries and analytics
- **Administrative Functions**: Protocol governance and maintenance

#### 5. **Integration Layer**

- **Oracle Interface**: External price feed integration
- **STX Transfer Protocol**: Native token transfer handling
- **Event System**: Transaction logging and monitoring

## 🔄 Data Flow

### Market Creation Flow

```
Owner → create-market() → Validation → Storage → Market ID
  ↓
Parameters: asset-name, start-price, timeframe
  ↓
Validation: timeframe, price > 0, authorized caller
  ↓
Storage: markets map, increment counter
```

### Prediction Flow

```
User → make-prediction() → Validation → STX Transfer → Storage Update
  ↓
Parameters: market-id, prediction (up/down), stake amount
  ↓
Validation: market active, sufficient balance, minimum stake
  ↓
Transfer: STX from user to contract
  ↓
Storage: update predictions map, market totals, statistics
```

### Resolution & Payout Flow

```
Oracle → resolve-market() → Price Update → User Claims → Calculations → Payouts
  ↓
Price Resolution: end-price, market status update
  ↓
User Claims: claim-winnings() for winners
  ↓
Calculations: proportional rewards, platform fees
  ↓
Payouts: STX transfer to winners, fees to protocol
```

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks CLI tools
- Node.js (for testing scripts)

### Installation

```bash
# Clone the repository
git clone https://github.com/oge-alt/bitpredict.git
cd bitpredict

# Check contract syntax
clarinet check

# Run tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

### Basic Usage

```clarity
;; Create a new market (owner only)
(contract-call? .bitpredict create-market 
    "BTC-USD" 
    u50000000000 ;; $50,000 start price
    u1000        ;; start block
    u2000)       ;; end block

;; Make a prediction
(contract-call? .bitpredict make-prediction 
    u0           ;; market ID
    "up"         ;; prediction
    u5000000)    ;; 5 STX stake

;; Claim winnings after resolution
(contract-call? .bitpredict claim-winnings u0)
```

## 📊 Protocol Mechanics

### Reward Calculation

Winners receive rewards proportional to their stake in the winning pool:

```
User Reward = (User Stake × Total Pool) ÷ Winning Pool - Platform Fee
```

### Fee Structure

- **Platform Fee**: 2% of winnings (configurable, max 10%)
- **Minimum Stake**: 1 STX (configurable)
- **No Entry Fees**: Users only pay when they win

### Market States

1. **Pending**: Created but not yet active
2. **Active**: Accepting predictions
3. **Closed**: No longer accepting predictions, awaiting resolution
4. **Resolved**: Oracle has provided final price, payouts available

## 🔧 Configuration

### Administrative Functions

```clarity
;; Update oracle address
(set-oracle-address new-address)

;; Adjust minimum stake
(set-minimum-stake u2000000) ;; 2 STX

;; Modify platform fee
(set-platform-fee u3) ;; 3%

;; Emergency pause
(toggle-protocol-pause)
```

### Oracle Integration

The protocol supports external oracle integration for price feeds:

- **Oracle Authorization**: Only authorized oracles can resolve markets
- **Price Validation**: Ensures positive price values
- **Resolution Timing**: Markets can only be resolved after end block

## 📈 Analytics & Monitoring

### Platform Statistics

```clarity
;; Get platform overview
(get-platform-stats)
;; Returns: total-markets, total-volume, total-fees, contract-balance

;; Get user statistics
(get-user-stats user-principal)
;; Returns: total-predictions, total-winnings, total-losses
```

### Market Analytics

```clarity
;; Get detailed market information
(get-market-details market-id)
;; Returns: market data + calculated fields (total-pool, percentages)
```

## 🛡️ Security Features

### Access Control

- **Owner-Only Functions**: Critical operations restricted to contract owner
- **Oracle Authorization**: Only designated oracle can resolve markets
- **Parameter Validation**: Comprehensive input validation

### Emergency Mechanisms

- **Protocol Pause**: Ability to halt operations during emergencies
- **Fee Caps**: Platform fee cannot exceed 10%
- **Balance Checks**: Ensures contract has sufficient funds for payouts

### Audit Considerations

- **No Reentrancy**: Functions designed to prevent reentrancy attacks
- **Integer Overflow Protection**: Safe arithmetic operations
- **State Consistency**: Atomic operations maintain contract state integrity

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/bitpredict_test.ts

# Check contract coverage
clarinet test --coverage
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
