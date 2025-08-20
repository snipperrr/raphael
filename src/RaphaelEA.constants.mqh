//+------------------------------------------------------------------+
//| RaphaelEA.constants.mqh                                          |
//| Constants and enumerations for RaphaelEA                        |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

//+------------------------------------------------------------------+
//| EA Constants                                                     |
//+------------------------------------------------------------------+
#define EA_VERSION "2.1"
#define EA_NAME "RaphaelEA"
#define EA_DESCRIPTION "Advanced MT5 Expert Advisor with Dynamic Balance Scaling"

//+------------------------------------------------------------------+
//| Default Parameters                                               |
//+------------------------------------------------------------------+
#define DEFAULT_LOTS 0.1
#define DEFAULT_RISK_PERCENT 2.0
#define DEFAULT_AGGRESSIVE_MULTIPLIER 2.0
#define DEFAULT_GROWTH_POWER 1.5

#define DEFAULT_ORDER_DIST_POINTS 200
#define DEFAULT_TP_POINTS 200
#define DEFAULT_SL_POINTS 200
#define DEFAULT_TSL_POINTS 5
#define DEFAULT_TSL_TRIGGER_POINTS 5

#define DEFAULT_BARS_N 5
#define DEFAULT_EXPIRATION_HOURS 50
#define DEFAULT_MAGIC_NUMBER 111

//+------------------------------------------------------------------+
//| Risk Management Constants                                        |
//+------------------------------------------------------------------+
#define MIN_LOT_SIZE 0.01
#define MAX_LOT_SIZE 100.0
#define MIN_RISK_PERCENT 0.1
#define MAX_RISK_PERCENT 50.0

//+------------------------------------------------------------------+
//| Trading Constants                                                |
//+------------------------------------------------------------------+
#define MIN_POINTS_DISTANCE 10
#define MAX_POINTS_DISTANCE 10000
#define MIN_BARS_LOOKBACK 1
#define MAX_BARS_LOOKBACK 50

//+------------------------------------------------------------------+
//| Balance Scaling Constants                                        |
//+------------------------------------------------------------------+
#define MIN_BALANCE_RATIO 0.1
#define MAX_BALANCE_RATIO 100.0
#define MIN_GROWTH_POWER 0.5
#define MAX_GROWTH_POWER 5.0
#define MIN_MULTIPLIER 0.1
#define MAX_MULTIPLIER 10.0

//+------------------------------------------------------------------+
//| Error Codes                                                      |
//+------------------------------------------------------------------+
#define ERR_INVALID_SYMBOL_SPECS 4001
#define ERR_INVALID_LOT_CALCULATION 4002
#define ERR_INSUFFICIENT_FUNDS 4003
#define ERR_INVALID_PRICE_DATA 4004

//+------------------------------------------------------------------+
//| Trading States                                                   |
//+------------------------------------------------------------------+
enum ENUM_TRADING_STATE
{
   TRADING_STATE_IDLE,
   TRADING_STATE_PENDING_BUY,
   TRADING_STATE_PENDING_SELL,
   TRADING_STATE_POSITION_BUY,
   TRADING_STATE_POSITION_SELL
};

//+------------------------------------------------------------------+
//| Scaling Methods                                                  |
//+------------------------------------------------------------------+
enum ENUM_SCALING_METHOD
{
   SCALING_METHOD_FIXED,
   SCALING_METHOD_LINEAR,
   SCALING_METHOD_EXPONENTIAL
};

//+------------------------------------------------------------------+
//| Asset Classes                                                    |
//+------------------------------------------------------------------+
enum ENUM_ASSET_CLASS
{
   ASSET_CLASS_FOREX,
   ASSET_CLASS_METALS,
   ASSET_CLASS_CRYPTO,
   ASSET_CLASS_INDICES,
   ASSET_CLASS_COMMODITIES
};

//+------------------------------------------------------------------+
//| Message Types                                                    |
//+------------------------------------------------------------------+
enum ENUM_MESSAGE_TYPE
{
   MSG_TYPE_INFO,
   MSG_TYPE_WARNING,
   MSG_TYPE_ERROR,
   MSG_TYPE_DEBUG
};

//+------------------------------------------------------------------+
//| Global Variable Names                                            |
//+------------------------------------------------------------------+
#define GV_INITIAL_BALANCE "_InitialBalance"
#define GV_TRADE_COUNT "_TradeCount"
#define GV_LAST_TRADE_TIME "_LastTradeTime"
#define GV_TOTAL_PROFIT "_TotalProfit"