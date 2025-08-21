//+------------------------------------------------------------------+
//| RaphaelEA.mq5                                                    |
//| Advanced MT5 Expert Advisor with Dynamic Balance Scaling        |
//+------------------------------------------------------------------+

#define VERSION "2.1"
#property version VERSION
#property copyright "Copyright 2025, RaphaelEA"
#property link      "https://github.com/RaphaelEA/RaphaelEA"
#property description "Advanced MetaTrader 5 Expert Advisor featuring intelligent lot sizing, balance scaling, and automated trading"

#define PROJECT_NAME MQLInfoString(MQL_PROGRAM_NAME)

#include <Trade/Trade.mqh>
#include "RaphaelEA.constants.mqh"
#include "RaphaelEA.mqh"

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
CTrade g_trade;

ulong buyPos, sellPos;
int totalBars;
double initialBalance;
double baseLotSize;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trade object
   g_trade.SetExpertMagicNumber(Magic);
   if(!g_trade.SetTypeFillingBySymbol(_Symbol))
   {
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }

   // Initialize balance and lot size variables
   baseLotSize = Lots;
   
   // Set initial balance
   if(InitialBalance > 0)
   {
      initialBalance = InitialBalance;
   } 
   else 
   {
      // Load from global variable or use current balance
      string balanceVarName = _Symbol + "_" + IntegerToString(Magic) + "_InitialBalance";
      if(GlobalVariableCheck(balanceVarName))
      {
         initialBalance = GlobalVariableGet(balanceVarName);
         Print(__FUNCTION__, " > Loaded initial balance from storage: ", DoubleToString(initialBalance, 2));
      } 
      else 
      {
         initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         GlobalVariableSet(balanceVarName, initialBalance);
         Print(__FUNCTION__, " > Set initial balance: ", DoubleToString(initialBalance, 2));
      }
   }

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
   g_ea.SetBaseLotSize(baseLotSize);
   g_ea.SetTradingParameters(OrderDistPoints, TpPoints, SlPoints, TslPoints, TslTriggerPoints);
   g_ea.SetTimeframe(Timeframe);
   g_ea.SetBarsLookback(BarsN);
   g_ea.SetExpirationHours(ExpirationHours);

   // Initialize EA
   if(!g_ea.Initialize())
   {
      Print(__FUNCTION__, " > Error: EA initialization failed");
      delete g_ea;
      g_ea = NULL;
      return INIT_FAILED;
   }

   // Log initialization
   static bool isInit = false;
   if(!isInit)
   {
      isInit = true;
      Print(__FUNCTION__, " > EA (re)start...");
      Print(__FUNCTION__, " > EA version ", VERSION, "...");
      Print(__FUNCTION__, " > Base lot size: ", baseLotSize);
      Print(__FUNCTION__, " > Aggressive multiplier: ", AggressiveMultiplier);
      Print(__FUNCTION__, " > Exponential growth: ", UseExponentialGrowth ? "Enabled" : "Disabled");
      if(UseExponentialGrowth) Print(__FUNCTION__, " > Growth power: ", GrowthPower);
      Print(__FUNCTION__, " > Initial balance: ", DoubleToString(initialBalance, 2));
      Print(__FUNCTION__, " > Current balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      Print(__FUNCTION__, " > Balance scaling: ", UseBalanceScaling ? "Enabled" : "Disabled");
       
      // Scan existing positions and orders
      ScanExistingPositions();
      ScanExistingOrders();
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Save initial balance for future reference
   string balanceVarName = _Symbol + "_" + IntegerToString(Magic) + "_InitialBalance";
   GlobalVariableSet(balanceVarName, initialBalance);

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
   if(g_ea && CheckPointer(g_ea))
   {
      g_ea.OnTick();
      return;
   }
   
   // Fallback implementation if EA class is not available
   // Process positions with trailing stop
   processPos(buyPos);
   processPos(sellPos);

   // Check for new bar
   int bars = iBars(_Symbol, Timeframe);
   if(totalBars != bars)
   {
      totalBars = bars;
      
      // Look for buy signals
      if(buyPos <= 0)
      {
         double high = findHigh();
         if(high > 0)
         {
            executeBuy(high);
         }
      }
      
      // Look for sell signals
      if(sellPos <= 0)
      {
         double low = findLow();
         if(low > 0)
         {
            executeSell(low);
         }
      }
   }

   // Update chart comment with trade info
   if(ShowTradeInfo)
   {
      UpdateChartComment();
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
   if(g_ea && CheckPointer(g_ea))
   {
      g_ea.OnTradeTransaction(trans, request, result);
      return;
   }
   
   // Fallback implementation
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD)
   {
      COrderInfo order;
      if(order.Select(trans.order))
      {
         if(order.Magic() == Magic)
         {
            if(order.OrderType() == ORDER_TYPE_BUY_STOP)
            {
               buyPos = order.Ticket();
            }
            else if(order.OrderType() == ORDER_TYPE_SELL_STOP)
            {
               sellPos = order.Ticket();
            }
         }
      }
   }
   
   // Handle position close events for balance tracking
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      CDealInfo deal;
      if(deal.SelectByIndex(HistoryDealsTotal()-1))
      {
         if(deal.Magic() == Magic && deal.Symbol() == _Symbol)
         {
            if(deal.Entry() == DEAL_ENTRY_OUT)
            {
               // Position was closed - log balance change
               double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
               double balanceRatio = currentBalance / initialBalance;
               Print(__FUNCTION__, " > Trade closed. Balance: ", DoubleToString(currentBalance, 2),
                     ", Ratio: ", DoubleToString(balanceRatio, 3));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate scaled lot size based on balance growth               |
//+------------------------------------------------------------------+
double calculateScaledLotSize()
{
   if(!UseBalanceScaling || initialBalance <= 0)
   {
      return baseLotSize;
   }
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   
   double scaledLots;
   
   if(UseExponentialGrowth)
   {
      // Exponential growth formula: BaseLots * (Ratio^Power) * Multiplier
      double exponentialRatio = MathPow(balanceRatio, GrowthPower);
      scaledLots = baseLotSize * exponentialRatio * AggressiveMultiplier;
   } 
   else 
   {
      // Linear aggressive scaling: BaseLots * Ratio * Multiplier
      scaledLots = baseLotSize * balanceRatio * AggressiveMultiplier;
   }
   
   // Normalize volume according to broker specifications
   scaledLots = normalizeVolume(scaledLots);
   
   return scaledLots;
}

//+------------------------------------------------------------------+
//| Normalize volume according to broker specifications             |
//+------------------------------------------------------------------+
double normalizeVolume(double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(stepVol > 0)
   {
      volume = MathRound(volume / stepVol) * stepVol;
   }
   
   volume = MathMax(volume, minVol);
   volume = MathMin(volume, maxVol);
   
   return volume;
}

//+------------------------------------------------------------------+
//| Process position for trailing stop                              |
//+------------------------------------------------------------------+
void processPos(ulong &posTicket)
{
   if(posTicket <= 0) return;
   if(OrderSelect(posTicket)) return; // It's a pending order
   
   CPositionInfo pos;
   if(!pos.SelectByTicket(posTicket))
   {
      posTicket = 0;
      return;
   }
   else
   {
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         
         if(bid > pos.PriceOpen() + TslTriggerPoints * _Point)
         {
            double sl = bid - TslPoints * _Point;
            sl = NormalizeDouble(sl, _Digits);
            
            if(sl > pos.StopLoss())
            {
               g_trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
      else if(pos.PositionType() == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         
         if(ask < pos.PriceOpen() - TslTriggerPoints * _Point)
         {
            double sl = ask + TslPoints * _Point;
            sl = NormalizeDouble(sl, _Digits);
            
            if(sl < pos.StopLoss() || pos.StopLoss() == 0)
            {
               g_trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void executeBuy(double entry)
{
   entry = NormalizeDouble(entry, _Digits);
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry - OrderDistPoints * _Point) return;
   
   double tp = entry + TpPoints * _Point;
   tp = NormalizeDouble(tp, _Digits);
   
   double sl = entry - SlPoints * _Point;
   sl = NormalizeDouble(sl, _Digits);

   double lots;
   if(RiskPercent > 0) 
   {
      lots = calcLots(entry - sl);
   } 
   else 
   {
      lots = calculateScaledLotSize();
   }
   
   lots = normalizeVolume(lots);
   
   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationHours * PeriodSeconds(PERIOD_H1);

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   double scaledLots = calculateScaledLotSize();
   
   Print(__FUNCTION__, " > Placing BUY order");
   Print("   Entry Price: ", DoubleToString(entry, _Digits));
   Print("   Current Balance: ", DoubleToString(currentBalance, 2));
   Print("   Balance Ratio: ", DoubleToString(balanceRatio, 3));
   Print("   Scaled Lot Size: ", DoubleToString(scaledLots, 3), " (Base: ", DoubleToString(baseLotSize, 2), ")");
   Print("   Final Lot Size: ", DoubleToString(lots, 3));
   Print("   Growth Factor: ", DoubleToString(lots/baseLotSize, 2), "x");
   
   g_trade.BuyStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
   
   buyPos = g_trade.ResultOrder();
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
void executeSell(double entry)
{
   entry = NormalizeDouble(entry, _Digits);  

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry + OrderDistPoints * _Point) return;

   double tp = entry - TpPoints * _Point;
   tp = NormalizeDouble(tp, _Digits);
   
   double sl = entry + SlPoints * _Point;
   sl = NormalizeDouble(sl, _Digits);
   
   double lots;
   if(RiskPercent > 0) 
   {
      lots = calcLots(sl - entry);
   } 
   else 
   {
      lots = calculateScaledLotSize();
   }
   
   lots = normalizeVolume(lots);
  
   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationHours * PeriodSeconds(PERIOD_H1);

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   double scaledLots = calculateScaledLotSize();
   
   Print(__FUNCTION__, " > Placing SELL order");
   Print("   Entry Price: ", DoubleToString(entry, _Digits));
   Print("   Current Balance: ", DoubleToString(currentBalance, 2));
   Print("   Balance Ratio: ", DoubleToString(balanceRatio, 3));
   Print("   Scaled Lot Size: ", DoubleToString(scaledLots, 3), " (Base: ", DoubleToString(baseLotSize, 2), ")");
   Print("   Final Lot Size: ", DoubleToString(lots, 3));
   Print("   Growth Factor: ", DoubleToString(lots/baseLotSize, 2), "x");

   g_trade.SellStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
   
   sellPos = g_trade.ResultOrder();
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double calcLots(double slPoints)
{
   if(!UseBalanceScaling)
   {
      // Original risk-based calculation
      double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
      
      double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      if(ticksize <= 0 || tickvalue <= 0 || lotstep <= 0)
      {
         Print(__FUNCTION__, " > Error: Invalid symbol specifications");
         return normalizeVolume(baseLotSize);
      }
      
      double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;   
      
      if(moneyPerLotstep <= 0)
      {
         Print(__FUNCTION__, " > Error: Invalid money per lot calculation");
         return normalizeVolume(baseLotSize);
      }
      
      double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
      return normalizeVolume(lots);
   } 
   else 
   {
      // Balance-scaled risk calculation
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double balanceRatio = currentBalance / initialBalance;
      
      // Scale the risk based on balance growth
      double scaledRisk = (baseLotSize * balanceRatio) * slPoints;
      double maxRisk = currentBalance * RiskPercent / 100;
      
      // Use the smaller of scaled risk or percentage risk
      double risk = MathMin(scaledRisk, maxRisk);
      
      double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      if(ticksize <= 0 || tickvalue <= 0 || lotstep <= 0)
      {
         Print(__FUNCTION__, " > Error: Invalid symbol specifications");
         return calculateScaledLotSize();
      }
      
      double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;   
      
      if(moneyPerLotstep <= 0)
      {
         Print(__FUNCTION__, " > Error: Invalid money per lot calculation");
         return calculateScaledLotSize();
      }
      
      double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
      
      // Ensure we don't go below the scaled lot size
      double minLots = calculateScaledLotSize();
      lots = MathMax(lots, minLots);
      
      return normalizeVolume(lots);
   }
}

//+------------------------------------------------------------------+
//| Find swing high for breakout entry                              |
//+------------------------------------------------------------------+
double findHigh()
{
   double highestHigh = 0;
   for(int i = 0; i < 200; i++)
   {
      double high = iHigh(_Symbol, Timeframe, i);
      if(high <= 0) continue; // Skip invalid data
      
      if(i > BarsN && iHighest(_Symbol, Timeframe, MODE_HIGH, BarsN*2+1, i-BarsN) == i)
      {
         if(high > highestHigh)
         {
            return high;
         }
      }
      highestHigh = MathMax(high, highestHigh);
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Find swing low for breakout entry                               |
//+------------------------------------------------------------------+
double findLow()
{
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++)
   {
      double low = iLow(_Symbol, Timeframe, i);
      if(low <= 0) continue; // Skip invalid data
      
      if(i > BarsN && iLowest(_Symbol, Timeframe, MODE_LOW, BarsN*2+1, i-BarsN) == i)
      {
         if(low < lowestLow)
         {
            return low;
         }
      }   
      lowestLow = MathMin(low, lowestLow);
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Scan existing positions on startup                              |
//+------------------------------------------------------------------+
void ScanExistingPositions()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      CPositionInfo pos;
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() != Magic) continue;
         if(pos.Symbol() != _Symbol) continue;

         Print(__FUNCTION__, " > Found open position with ticket #", IntegerToString(pos.Ticket()), "...");
         if(pos.PositionType() == POSITION_TYPE_BUY) buyPos = pos.Ticket();
         if(pos.PositionType() == POSITION_TYPE_SELL) sellPos = pos.Ticket();
      }
   }
}

//+------------------------------------------------------------------+
//| Scan existing orders on startup                                 |
//+------------------------------------------------------------------+
void ScanExistingOrders()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      COrderInfo order;
      if(order.SelectByIndex(i))
      {
         if(order.Magic() != Magic) continue;
         if(order.Symbol() != _Symbol) continue;

         Print(__FUNCTION__, " > Found pending order with ticket #", IntegerToString(order.Ticket()), "...");
         if(order.OrderType() == ORDER_TYPE_BUY_STOP) buyPos = order.Ticket();
         if(order.OrderType() == ORDER_TYPE_SELL_STOP) sellPos = order.Ticket();
      }
   }
}

//+------------------------------------------------------------------+
//| Update chart comment with trade information                     |
//+------------------------------------------------------------------+
void UpdateChartComment()
{
   string comment = "";
   comment += "=== RaphaelEA v" + VERSION + " ===\n";
   comment += "Symbol: " + _Symbol + "\n";
   comment += "Magic: " + IntegerToString(Magic) + "\n\n";
   
   // Balance information
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balanceRatio = initialBalance > 0 ? currentBalance / initialBalance : 1.0;
   
   comment += "=== BALANCE INFO ===\n";
   comment += "Initial Balance: $" + DoubleToString(initialBalance, 2) + "\n";
   comment += "Current Balance: $" + DoubleToString(currentBalance, 2) + "\n";
   comment += "Current Equity: $" + DoubleToString(currentEquity, 2) + "\n";
   comment += "Balance Ratio: " + DoubleToString(balanceRatio, 3) + "\n\n";
   
   // Lot size information
   double scaledLots = calculateScaledLotSize();
   comment += "=== LOT SIZE INFO ===\n";
   comment += "Base Lot Size: " + DoubleToString(baseLotSize, 3) + "\n";
   comment += "Scaled Lot Size: " + DoubleToString(scaledLots, 3) + "\n";
   comment += "Growth Factor: " + DoubleToString(scaledLots/baseLotSize, 2) + "x\n";
   comment += "Balance Scaling: " + (UseBalanceScaling ? "ON" : "OFF") + "\n";
   comment += "Exponential Growth: " + (UseExponentialGrowth ? "ON" : "OFF") + "\n\n";
   
   // Position information
   comment += "=== POSITION INFO ===\n";
   comment += "Buy Position: " + (buyPos > 0 ? "#" + IntegerToString((int)buyPos) : "None") + "\n";
   comment += "Sell Position: " + (sellPos > 0 ? "#" + IntegerToString((int)sellPos) : "None") + "\n";
   
   // Market information
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   comment += "\n=== MARKET INFO ===\n";
   comment += "Spread: " + DoubleToString(spread, 1) + " points\n";
   comment += "Bid: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "\n";
   comment += "Ask: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits) + "\n";
   
   Comment(comment);
}

//+------------------------------------------------------------------+
//| Get account statistics                                           |
//+------------------------------------------------------------------+
string GetAccountStats()
{
   string stats = "";
   stats += "Account Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
   stats += "Account Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
   stats += "Free Margin: $" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + "\n";
   stats += "Margin Level: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + "%\n";
   
   return stats;
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   // Check if trading is allowed in general
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print(__FUNCTION__, " > Trading is not allowed in terminal");
      return false;
   }
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print(__FUNCTION__, " > Automated trading is not allowed");
      return false;
   }
   
   // Check account permissions
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
   {
      Print(__FUNCTION__, " > Expert trading is not allowed for this account");
      return false;
   }
   
   // Check symbol trading
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
   {
      Print(__FUNCTION__, " > Trading is disabled for symbol ", _Symbol);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate EA parameters                                           |
//+------------------------------------------------------------------+
bool ValidateParameters()
{
   // Validate lot size
   if(Lots <= 0)
   {
      Print(__FUNCTION__, " > Error: Invalid lot size: ", Lots);
      return false;
   }
   
   // Validate risk percentage
   if(RiskPercent < 0 || RiskPercent > 50)
   {
      Print(__FUNCTION__, " > Error: Invalid risk percentage: ", RiskPercent);
      return false;
   }
   
   // Validate aggressive multiplier
   if(AggressiveMultiplier <= 0 || AggressiveMultiplier > 10)
   {
      Print(__FUNCTION__, " > Error: Invalid aggressive multiplier: ", AggressiveMultiplier);
      return false;
   }
   
   // Validate growth power
   if(GrowthPower <= 0 || GrowthPower > 5)
   {
      Print(__FUNCTION__, " > Error: Invalid growth power: ", GrowthPower);
      return false;
   }
   
   // Validate points parameters
   if(OrderDistPoints <= 0 || TpPoints <= 0 || SlPoints <= 0)
   {
      Print(__FUNCTION__, " > Error: Invalid points parameters");
      return false;
   }
   
   return true;
}