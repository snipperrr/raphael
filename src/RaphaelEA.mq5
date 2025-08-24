//+------------------------------------------------------------------+
//| RaphaelEA.mq5                                                    |
//| Advanced MT5 Expert Advisor with Dynamic Balance Scaling        |
//+------------------------------------------------------------------+

#define VERSION "2.1"
#property version VERSION
#property copyright "Copyright 2025, RaphaelEA"
#property link      "https://github.com/RaphaelEA/RaphaelEA"
#property description "Advanced MetaTrader 5 Expert Advisor featuring intelligent lot sizing, balance scaling, and automated trading"

#include <Trade/Trade.mqh>
#include <Object.mqh>
#include "RaphaelEA.includes.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== LOT SIZE & RISK MANAGEMENT ==="
input double Lots = 0.1;                              // Base lot size
input double RiskPercent = 2.0;                       // Risk percentage (0 = Fixed lots)
input bool UseBalanceScaling = true;                  // Enable dynamic balance scaling
input double InitialBalance = 0;                      // Initial balance reference (0 = auto-detect)
input double AggressiveMultiplier = 2.0;              // Aggressive scaling multiplier
input bool UseExponentialGrowth = true;               // Use exponential growth formula
input double GrowthPower = 1.5;                       // Power for exponential growth (1.0=linear, 2.0=quadratic)

input group "=== TRADING PARAMETERS ==="
input int OrderDistPoints = 200;                      // Minimum distance for pending orders (points)
input int TpPoints = 200;                             // Take profit distance (points)
input int SlPoints = 200;                             // Stop loss distance (points)
input int TslPoints = 5;                              // Trailing stop distance (points)
input int TslTriggerPoints = 5;                       // Trailing stop trigger distance (points)

input group "=== STRATEGY SETTINGS ==="
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;          // Analysis timeframe
input int BarsN = 5;                                  // Bars lookback for swing detection
input int ExpirationHours = 50;                      // Pending order expiration (hours)

input group "=== SYSTEM SETTINGS ==="
input int Magic = 111;                                // Magic number for trade identification
input bool EnableLogging = true;                     // Enable detailed logging
input bool ShowTradeInfo = true;                     // Show trade information in comments

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CRaphaelEA* g_ea = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create EA instance
   g_ea = new CRaphaelEA();
   if(!g_ea)
   {
      Print(__FUNCTION__, " > Error: Failed to create EA instance");
      return INIT_FAILED;
   }

   // Configure EA
   g_ea.SetMagicNumber(Magic);
   g_ea.SetBalanceScaling(UseBalanceScaling);
   g_ea.SetExponentialGrowth(UseExponentialGrowth);
   g_ea.SetAggressiveMultiplier(AggressiveMultiplier);
   g_ea.SetGrowthPower(GrowthPower);
   g_ea.SetRiskPercent(RiskPercent);
   g_ea.SetBaseLotSize(Lots);
   g_ea.SetTradingParameters(OrderDistPoints, TpPoints, SlPoints, TslPoints, TslTriggerPoints);
   g_ea.SetTimeframe(Timeframe);
   g_ea.SetBarsLookback(BarsN);
   g_ea.SetExpirationHours(ExpirationHours);
   g_ea.SetShowTradeInfo(ShowTradeInfo);
   g_ea.SetInitialBalance(InitialBalance);

   // Initialize EA
   if(!g_ea.Initialize())
   {
      Print(__FUNCTION__, " > Error: EA initialization failed");
      delete g_ea;
      g_ea = NULL;
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup EA instance
   if(g_ea)
   {
      g_ea.Deinitialize();
      delete g_ea;
      g_ea = NULL;
   }

   Print(__FUNCTION__, " > EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_ea && CheckPointer(g_ea) == POINTER_VALID)
   {
      g_ea.OnTick();
   }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(
   const MqlTradeTransaction&    trans,
   const MqlTradeRequest&        request,
   const MqlTradeResult&         result
   )
{
   if(g_ea && CheckPointer(g_ea) == POINTER_VALID)
   {
      g_ea.OnTradeTransaction(trans, request, result);
   }
}
