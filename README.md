# RaphaelEA - Advanced MT5 Expert Advisor

An advanced MetaTrader 5 Expert Advisor featuring intelligent lot sizing, balance scaling, and automated trading with support for multiple asset classes.

## Features

- ✅ **Dynamic Balance Scaling**: Automatically adjusts position sizes based on account balance growth
- ✅ **Exponential Growth Formula**: Optional exponential scaling for aggressive growth strategies
- ✅ **Risk Management**: Fixed lot size or percentage-based risk calculation
- ✅ **Trailing Stop Loss**: Automatic profit protection with customizable trailing distance
- ✅ **Multiple Asset Support**: Forex, Metals, and Cryptocurrency pairs
- ✅ **Pending Order Strategy**: Buy/Sell stop orders based on technical analysis
- ✅ **Configurable Parameters**: Extensive customization options for different markets

## Quick Start

1. Copy the EA files to your MetaTrader 5 data folder
2. Compile the source code or use the pre-compiled .ex5 file
3. Load appropriate preset settings for your chosen instrument
4. Attach to chart and configure parameters
5. Enable automated trading

## Configuration

### Basic Settings

- **Lots**: Base lot size (0.1 standard)
- **RiskPercent**: Risk percentage per trade (2.0% recommended)
- **UseBalanceScaling**: Enable dynamic lot scaling based on account growth
- **AggressiveMultiplier**: Scaling multiplier for aggressive growth (2.0 = double effect)

### Advanced Settings

- **OrderDistPoints**: Minimum distance for pending orders (200 points)
- **TpPoints**: Take profit distance (200 points)
- **SlPoints**: Stop loss distance (200 points)
- **TslPoints**: Trailing stop distance (5 points)
- **ExpirationHours**: Pending order expiration time (50 hours)

## Asset Class Support

### Forex Pairs
- Major pairs: EUR/USD, GBP/USD, USD/JPY, AUD/USD
- Minor pairs: EUR/GBP, AUD/JPY, GBP/CHF
- Exotic pairs: USD/SGD, EUR/TRY, GBP/ZAR

### Precious Metals
- Gold: XAU/USD, XAU/EUR, XAU/GBP
- Silver: XAG/USD
- Platinum: XPT/USD
- Palladium: XPD/USD

### Cryptocurrencies
- Bitcoin: BTC/USD
- Ethereum: ETH/USD
- Major altcoins: LTC/USD, XRP/USD, ADA/USD

## Strategy Overview

The EA employs a breakout strategy based on swing highs and lows:

1. **Signal Detection**: Identifies significant highs and lows using configurable lookback periods
2. **Order Placement**: Places pending orders at breakout levels
3. **Risk Management**: Applies stop loss and take profit levels
4. **Position Management**: Implements trailing stop loss for profit protection

## Risk Management

### Balance Scaling Algorithm

The EA features an innovative balance scaling system:

- **Linear Scaling**: `NewLots = BaseLots × (CurrentBalance / InitialBalance) × Multiplier`
- **Exponential Scaling**: `NewLots = BaseLots × (Ratio^Power) × Multiplier`

### Position Sizing Options

1. **Fixed Lot Size**: Use predetermined lot sizes
2. **Percentage Risk**: Calculate lots based on account risk percentage
3. **Dynamic Scaling**: Adjust position sizes based on account growth

## Installation

See [INSTALLATION.md](docs/INSTALLATION.md) for detailed setup instructions.

## Documentation

- [Strategy Details](docs/STRATEGY.md)
- [Installation Guide](docs/INSTALLATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [FAQ](docs/FAQ.md)

## Version History

Current Version: **2.1**

See [CHANGELOG.md](docs/CHANGELOG.md) for complete version history.

## Support

For support and questions, please check the documentation first. Common issues are covered in the [FAQ](docs/FAQ.md) and [Troubleshooting](docs/TROUBLESHOOTING.md) guides.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Disclaimer

**Trading Risk Warning**: Forex, cryptocurrency, and derivatives trading involves substantial risk of loss and is not suitable for all investors. Past performance is not indicative of future results. Only trade with money you can afford to lose.