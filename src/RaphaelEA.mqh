//+------------------------------------------------------------------+
//| RaphaelEA.mqh                                                    |
//| Main header file for RaphaelEA - Complete Implementation        |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

#include "RaphaelEA.constants.mqh"
#include "modules/Logger.mqh"
#include "modules/RiskManager.mqh"
#include "modules/TradeManager.mqh"
#include "modules/Utils.mqh"

//+------------------------------------------------------------------+
//| RaphaelEA Class - Complete Implementation                       |
//+------------------------------------------------------------------+
class CRaphaelEA
{
private:
   // Core components
   CLogger*         m_logger;
   CRiskManager*    m_riskManager;
   CTradeManager*   m_tradeManager;
   CUtils*          m_utils;
   
   // Trading variables
   ulong            m_buyPosition;
   ulong            m_sellPosition;
   int              m_totalBars;
   double           m_initialBalance;
   double           m_baseLotSize;
   
   // Configuration
   bool             m_useBalanceScaling;
   bool             m_useExponentialGrowth;
   double           m_aggressiveMultiplier;
   double           m_growthPower;
   int              m_magicNumber;
   double           m_riskPercent;
   
   // Trading parameters
   int              m_orderDistancePoints;
   int              m_takeProfitPoints;
   int              m_stopLossPoints;
   int              m_trailingStopPoints;
   int              m_trailingTriggerPoints;
   int              m_expirationHours;
   int              m_barsLookback;
   ENUM_TIMEFRAMES  m_timeframe;
   
   // State variables
   bool             m_initialized;
   datetime         m_lastTradeTime;
   
public:
   // Constructor and destructor
   CRaphaelEA();
   ~CRaphaelEA();
   
   // Initialization methods
   bool             Initialize(void);
   void             Deinitialize(void);
   
   // Main processing methods
   void             OnTick(void);
   void             OnTradeTransaction(const MqlTradeTransaction& trans,
                                     const MqlTradeRequest& request,
                                     const MqlTradeResult& result);
   
   // Configuration methods
   void             SetBalanceScaling(bool use_scaling) { m_useBalanceScaling = use_scaling; }
   void             SetExponentialGrowth(bool use_exponential) { m_useExponentialGrowth = use_exponential; }
   void             SetAggressiveMultiplier(double multiplier) { m_aggressiveMultiplier = multiplier; }
   void             SetGrowthPower(double power) { m_growthPower = power; }
   void             SetMagicNumber(int magic) { m_magicNumber = magic; }
   void             SetRiskPercent(double risk) { m_riskPercent = risk; }
   void             SetBaseLotSize(double lots) { m_baseLotSize = lots; }
   void             SetTradingParameters(int order_dist, int tp, int sl, int tsl, int tsl_trigger);
   void             SetTimeframe(ENUM_TIMEFRAMES tf) { m_timeframe = tf; }
   void             SetBarsLookback(int bars) { m_barsLookback = bars; }
   void             SetExpirationHours(int hours) { m_expirationHours = hours; }
   
   // Getter methods
   bool             IsBalanceScalingEnabled(void) const { return m_useBalanceScaling; }
   bool             IsExponentialGrowthEnabled(void) const { return m_useExponentialGrowth; }
   double           GetAggressiveMultiplier(void) const { return m_aggressiveMultiplier; }
   double           GetGrowthPower(void) const { return m_growthPower; }
   int              GetMagicNumber(void) const { return m_magicNumber; }
   bool             IsInitialized(void) const { return m_initialized; }
   
   // Balance and lot size methods
   double           GetInitialBalance(void) const { return m_initialBalance; }
   double           GetCurrentBalance(void) const;
   double           GetBalanceRatio(void) const;
   double           CalculateScaledLotSize(void);
   
   // Trading methods
   bool             ExecuteBuyOrder(double entry_price);
   bool             ExecuteSellOrder(double entry_price);
   void             ProcessPosition(ulong& position_ticket);
   
   // Signal detection methods
   double           FindSwingHigh(void);
   double           FindSwingLow(void);
   
   // Utility methods
   void             PrintStatus(void);
   void             SaveSettings(void);
   bool             LoadSettings(void);
   string           GetAccountStats(void);
   bool             IsTradingAllowed(void);
   int              GetPositionCount(void);
   int              GetOrderCount(void);
   double           GetTotalProfit(void);
   void             EmergencyCloseAll(void);
   
private:
   // Internal helper methods
   void             InitializeComponents(void);
   void             CleanupComponents(void);
   bool             ValidateConfiguration(void);
   void             LogInitialization(void);
   void             ScanExistingPositions(void);
   void             ScanExistingOrders(void);
   double           CalculateLotSize(double stop_loss_points);
   double           NormalizeLotSize(double lot_size);
   bool             IsNewBar(void);
   void             UpdateChartComment(void);
   string           GetGlobalVariableName(string suffix);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRaphaelEA::CRaphaelEA(void)
{
   m_logger = NULL;
   m_riskManager = NULL;
   m_tradeManager = NULL;
   m_utils = NULL;
   
   m_buyPosition = 0;
   m_sellPosition = 0;
   m_totalBars = 0;
   m_initialBalance = 0;
   m_baseLotSize = DEFAULT_LOTS;
   
   m_useBalanceScaling = true;
   m_useExponentialGrowth = true;
   m_aggressiveMultiplier = DEFAULT_AGGRESSIVE_MULTIPLIER;
   m_growthPower = DEFAULT_GROWTH_POWER;
   m_magicNumber = DEFAULT_MAGIC_NUMBER;
   m_riskPercent = DEFAULT_RISK_PERCENT;
   
   m_orderDistancePoints = DEFAULT_ORDER_DIST_POINTS;
   m_takeProfitPoints = DEFAULT_TP_POINTS;
   m_stopLossPoints = DEFAULT_SL_POINTS;
   m_trailingStopPoints = DEFAULT_TSL_POINTS;
   m_trailingTriggerPoints = DEFAULT_TSL_TRIGGER_POINTS;
   m_expirationHours = DEFAULT_EXPIRATION_HOURS;
   m_barsLookback = DEFAULT_BARS_N;
   m_timeframe = PERIOD_H1;
   
   m_initialized = false;
   m_lastTradeTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRaphaelEA::~CRaphaelEA(void)
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize the EA                                                |
//+------------------------------------------------------------------+
bool CRaphaelEA::Initialize(void)
{
   if(m_initialized)
      return true;
      
   InitializeComponents();
   
   if(!ValidateConfiguration())
   {
      if(m_logger) m_logger.Error("Configuration validation failed");
      return false;
   }
   
   // Set initial balance
   if(m_initialBalance <= 0)
   {
      string balanceVarName = GetGlobalVariableName(GV_INITIAL_BALANCE);
      if(GlobalVariableCheck(balanceVarName))
      {
         m_initialBalance = GlobalVariableGet(balanceVarName);
         if(m_logger) m_logger.Info("Loaded initial balance from storage: " + DoubleToString(m_initialBalance, 2));
      }
      else
      {
         m_initialBalance = GetCurrentBalance();
         GlobalVariableSet(balanceVarName, m_initialBalance);
         if(m_logger) m_logger.Info("Set initial balance: " + DoubleToString(m_initialBalance, 2));
      }
   }
   
   // Configure components
   if(m_riskManager)
   {
      m_riskManager.SetRiskPercent(m_riskPercent);
      m_riskManager.SetBaseLotSize(m_baseLotSize);
      m_riskManager.SetInitialBalance(m_initialBalance);
      m_riskManager.SetBalanceScaling(m_useBalanceScaling);
      m_riskManager.SetAggressiveMultiplier(m_aggressiveMultiplier);
      m_riskManager.SetExponentialGrowth(m_useExponentialGrowth);
      m_riskManager.SetGrowthPower(m_growthPower);
   }
   
   if(m_tradeManager)
   {
      m_tradeManager.SetMagicNumber(m_magicNumber);
      m_tradeManager.SetOrderDistance(m_orderDistancePoints);
      m_tradeManager.SetTakeProfit(m_takeProfitPoints);
      m_tradeManager.SetStopLoss(m_stopLossPoints);
      m_tradeManager.SetTrailingStop(m_trailingStopPoints);
      m_tradeManager.SetTrailingTrigger(m_trailingTriggerPoints);
      m_tradeManager.SetExpiration(m_expirationHours);
      m_tradeManager.SetTimeframe(m_timeframe);
   }
   
   if(m_utils)
   {
      m_utils.SetTimeframe(m_timeframe);
      m_utils.SetBarsLookback(m_barsLookback);
   }
   
   LogInitialization();
   ScanExistingPositions();
   ScanExistingOrders();
   
   m_totalBars = iBars(_Symbol, m_timeframe);
   m_initialized = true;
   
   if(m_logger) m_logger.Info("EA initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the EA                                              |
//+------------------------------------------------------------------+
void CRaphaelEA::Deinitialize(void)
{
   if(!m_initialized)
      return;
      
   SaveSettings();
   
   if(m_logger) m_logger.Info("EA deinitialized");
   
   CleanupComponents();
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Main tick processing                                             |
//+------------------------------------------------------------------+
void CRaphaelEA::OnTick(void)
{
   if(!m_initialized)
      return;
      
   // Process positions with trailing stop
   ProcessPosition(m_buyPosition);
   ProcessPosition(m_sellPosition);
   
   // Check for new bar
   if(IsNewBar())
   {
      // Look for buy signals
      if(m_buyPosition <= 0)
      {
         double high = FindSwingHigh();
         if(high > 0)
         {
            ExecuteBuyOrder(high);
         }
      }
      
      // Look for sell signals
      if(m_sellPosition <= 0)
      {
         double low = FindSwingLow();
         if(low > 0)
         {
            ExecuteSellOrder(low);
         }
      }
   }
   
   UpdateChartComment();
}

//+------------------------------------------------------------------+
//| Handle trade transactions                                        |
//+------------------------------------------------------------------+
void CRaphaelEA::OnTradeTransaction(const MqlTradeTransaction& trans,
                                  const MqlTradeRequest& request,
                                  const MqlTradeResult& result)
{
   if(!m_initialized)
      return;
      
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD)
   {
      COrderInfo order;
      if(order.Select(trans.order))
      {
         if(order.Magic() == m_magicNumber && order.Symbol() == _Symbol)
         {
            if(order.OrderType() == ORDER_TYPE_BUY_STOP)
            {
               m_buyPosition = order.Ticket();
               if(m_logger) m_logger.Trade("Buy stop order placed: #" + IntegerToString((int)order.Ticket()));
            }
            else if(order.OrderType() == ORDER_TYPE_SELL_STOP)
            {
               m_sellPosition = order.Ticket();
               if(m_logger) m_logger.Trade("Sell stop order placed: #" + IntegerToString((int)order.Ticket()));
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
         if(deal.Magic() == m_magicNumber && deal.Symbol() == _Symbol)
         {
            if(deal.Entry() == DEAL_ENTRY_OUT)
            {
               double currentBalance = GetCurrentBalance();
               double balanceRatio = GetBalanceRatio();
               if(m_logger) m_logger.Trade("Trade closed. Balance: " + DoubleToString(currentBalance, 2) +
                                         ", Ratio: " + DoubleToString(balanceRatio, 3));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get current balance                                              |
//+------------------------------------------------------------------+
double CRaphaelEA::GetCurrentBalance(void) const
{
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Get balance ratio                                                |
//+------------------------------------------------------------------+
double CRaphaelEA::GetBalanceRatio(void) const
{
   if(m_initialBalance <= 0)
      return 1.0;
   
   return GetCurrentBalance() / m_initialBalance;
}

//+------------------------------------------------------------------+
//| Calculate scaled lot size                                        |
//+------------------------------------------------------------------+
double CRaphaelEA::CalculateScaledLotSize(void)
{
   if(m_riskManager)
   {
      return m_riskManager.CalculateScaledLotSize();
   }
   
   // Fallback implementation
   if(!m_useBalanceScaling || m_initialBalance <= 0)
   {
      return m_baseLotSize;
   }
   
   double balanceRatio = GetBalanceRatio();
   double scaledLots;
   
   if(m_useExponentialGrowth)
   {
      double exponentialRatio = MathPow(balanceRatio, m_growthPower);
      scaledLots = m_baseLotSize * exponentialRatio * m_aggressiveMultiplier;
   }
   else
   {
      scaledLots = m_baseLotSize * balanceRatio * m_aggressiveMultiplier;
   }
   
   return NormalizeLotSize(scaledLots);
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
bool CRaphaelEA::ExecuteBuyOrder(double entry_price)
{
   if(!m_initialized || m_buyPosition > 0)
      return false;
      
   entry_price = NormalizeDouble(entry_price, _Digits);
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry_price - m_orderDistancePoints * _Point)
      return false;
      
   double lots = CalculateLotSize(m_stopLossPoints * _Point);
   
   if(m_tradeManager)
   {
      bool result = m_tradeManager.ExecuteBuyStopOrder(entry_price, lots);
      if(result)
      {
         if(m_logger)
         {
            m_logger.Trade("Buy order executed: Price=" + DoubleToString(entry_price, _Digits) + 
                          ", Lots=" + DoubleToString(lots, 3));
         }
      }
      return result;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
bool CRaphaelEA::ExecuteSellOrder(double entry_price)
{
   if(!m_initialized || m_sellPosition > 0)
      return false;
      
   entry_price = NormalizeDouble(entry_price, _Digits);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry_price + m_orderDistancePoints * _Point)
      return false;
      
   double lots = CalculateLotSize(m_stopLossPoints * _Point);
   
   if(m_tradeManager)
   {
      bool result = m_tradeManager.ExecuteSellStopOrder(entry_price, lots);
      if(result)
      {
         if(m_logger)
         {
            m_logger.Trade("Sell order executed: Price=" + DoubleToString(entry_price, _Digits) + 
                          ", Lots=" + DoubleToString(lots, 3));
         }
      }
      return result;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Process position for trailing stop                              |
//+------------------------------------------------------------------+
void CRaphaelEA::ProcessPosition(ulong& position_ticket)
{
   if(position_ticket <= 0)
      return;
      
   if(m_tradeManager)
   {
      m_tradeManager.ProcessPosition(position_ticket);
   }
   else
   {
      // Fallback implementation
      if(OrderSelect(position_ticket))
         return; // It's a pending order
      
      CPositionInfo pos;
      if(!pos.SelectByTicket(position_ticket))
      {
         position_ticket = 0;
         return;
      }
      
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(bid > pos.PriceOpen() + m_trailingTriggerPoints * _Point)
         {
            double sl = bid - m_trailingStopPoints * _Point;
            sl = NormalizeDouble(sl, _Digits);
            if(sl > pos.StopLoss())
            {
               CTrade trade;
               trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
      else if(pos.PositionType() == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(ask < pos.PriceOpen() - m_trailingTriggerPoints * _Point)
         {
            double sl = ask + m_trailingStopPoints * _Point;
            sl = NormalizeDouble(sl, _Digits);
            if(sl < pos.StopLoss() || pos.StopLoss() == 0)
            {
               CTrade trade;
               trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Find swing high                                                  |
//+------------------------------------------------------------------+
double CRaphaelEA::FindSwingHigh(void)
{
   if(m_utils)
   {
      return m_utils.FindSwingHigh();
   }
   
   // Fallback implementation
   double highestHigh = 0;
   for(int i = 0; i < 200; i++)
   {
      double high = iHigh(_Symbol, m_timeframe, i);
      if(high <= 0) continue;
      
      if(i > m_barsLookback && iHighest(_Symbol, m_timeframe, MODE_HIGH, m_barsLookback*2+1, i-m_barsLookback) == i)
      {
         if(high > highestHigh)
            return high;
      }
      highestHigh = MathMax(high, highestHigh);
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Find swing low                                                   |
//+------------------------------------------------------------------+
double CRaphaelEA::FindSwingLow(void)
{
   if(m_utils)
   {
      return m_utils.FindSwingLow();
   }
   
   // Fallback implementation
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++)
   {
      double low = iLow(_Symbol, m_timeframe, i);
      if(low <= 0) continue;
      
      if(i > m_barsLookback && iLowest(_Symbol, m_timeframe, MODE_LOW, m_barsLookback*2+1, i-m_barsLookback) == i)
      {
         if(low < lowestLow)
            return low;
      }
      lowestLow = MathMin(low, lowestLow);
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Print EA status                                                  |
//+------------------------------------------------------------------+
void CRaphaelEA::PrintStatus(void)
{
   if(!m_logger)
   {
      Print("=== RaphaelEA Status ===");
      Print("Version: " + EA_VERSION);
      Print("Magic Number: " + IntegerToString(m_magicNumber));
      Print("Initial Balance: " + DoubleToString(m_initialBalance, 2));
      Print("Current Balance: " + DoubleToString(GetCurrentBalance(), 2));
      Print("Balance Ratio: " + DoubleToString(GetBalanceRatio(), 3));
      Print("Balance Scaling: " + (m_useBalanceScaling ? "Enabled" : "Disabled"));
      Print("Exponential Growth: " + (m_useExponentialGrowth ? "Enabled" : "Disabled"));
      Print("Aggressive Multiplier: " + DoubleToString(m_aggressiveMultiplier, 1));
      Print("Growth Power: " + DoubleToString(m_growthPower, 1));
      Print("Buy Position: " + IntegerToString((int)m_buyPosition));
      Print("Sell Position: " + IntegerToString((int)m_sellPosition));
      Print("======================");
      return;
   }
   
   m_logger.Info("=== RaphaelEA Status ===");
   m_logger.Info("Version: " + EA_VERSION);
   m_logger.Info("Magic Number: " + IntegerToString(m_magicNumber));
   m_logger.Info("Initial Balance: " + DoubleToString(m_initialBalance, 2));
   m_logger.Info("Current Balance: " + DoubleToString(GetCurrentBalance(), 2));
   m_logger.Info("Balance Ratio: " + DoubleToString(GetBalanceRatio(), 3));
   m_logger.Info("Balance Scaling: " + (m_useBalanceScaling ? "Enabled" : "Disabled"));
   m_logger.Info("Exponential Growth: " + (m_useExponentialGrowth ? "Enabled" : "Disabled"));
   m_logger.Info("Aggressive Multiplier: " + DoubleToString(m_aggressiveMultiplier, 1));
   m_logger.Info("Growth Power: " + DoubleToString(m_growthPower, 1));
   m_logger.Info("Buy Position: " + IntegerToString((int)m_buyPosition));
   m_logger.Info("Sell Position: " + IntegerToString((int)m_sellPosition));
   m_logger.Info("======================");
}

//+------------------------------------------------------------------+
//| Save settings to global variables                               |
//+------------------------------------------------------------------+
void CRaphaelEA::SaveSettings(void)
{
   GlobalVariableSet(GetGlobalVariableName(GV_INITIAL_BALANCE), m_initialBalance);
   
   if(m_logger) m_logger.Info("Settings saved");
}

//+------------------------------------------------------------------+
//| Load settings from global variables                             |
//+------------------------------------------------------------------+
bool CRaphaelEA::LoadSettings(void)
{
   string balanceVarName = GetGlobalVariableName(GV_INITIAL_BALANCE);
   if(GlobalVariableCheck(balanceVarName))
   {
      m_initialBalance = GlobalVariableGet(balanceVarName);
      if(m_logger) m_logger.Info("Settings loaded successfully");
      return true;
   }
   
   if(m_logger) m_logger.Warning("No saved settings found");
   return false;
}

//+------------------------------------------------------------------+
//| Initialize components                                            |
//+------------------------------------------------------------------+
void CRaphaelEA::InitializeComponents(void)
{
   CleanupComponents(); // Ensure clean state
   
   m_logger = new CLogger();
   m_riskManager = new CRiskManager();
   m_tradeManager = new CTradeManager();
   m_utils = new CUtils();
   
   if(m_logger) m_logger.Initialize();
   if(m_riskManager) m_riskManager.Initialize();
   if(m_tradeManager) m_tradeManager.Initialize(m_magicNumber);
   if(m_utils) m_utils.Initialize();
}

//+------------------------------------------------------------------+
//| Cleanup components                                               |
//+------------------------------------------------------------------+
void CRaphaelEA::CleanupComponents(void)
{
   if(m_logger) { delete m_logger; m_logger = NULL; }
   if(m_riskManager) { delete m_riskManager; m_riskManager = NULL; }
   if(m_tradeManager) { delete m_tradeManager; m_tradeManager = NULL; }
   if(m_utils) { delete m_utils; m_utils = NULL; }
}

//+------------------------------------------------------------------+
//| Validate configuration                                           |
//+------------------------------------------------------------------+
bool CRaphaelEA::ValidateConfiguration(void)
{
   if(m_baseLotSize <= 0)
   {
      if(m_logger) m_logger.Error("Invalid base lot size: " + DoubleToString(m_baseLotSize, 3));
      return false;
   }
   
   if(m_riskPercent < 0 || m_riskPercent > 50)
   {
      if(m_logger) m_logger.Error("Invalid risk percentage: " + DoubleToString(m_riskPercent, 1));
      return false;
   }
   
   if(m_aggressiveMultiplier <= 0 || m_aggressiveMultiplier > 10)
   {
      if(m_logger) m_logger.Error("Invalid aggressive multiplier: " + DoubleToString(m_aggressiveMultiplier, 1));
      return false;
   }
   
   if(m_growthPower <= 0 || m_growthPower > 5)
   {
      if(m_logger) m_logger.Error("Invalid growth power: " + DoubleToString(m_growthPower, 1));
      return false;
   }
   
   if(m_orderDistancePoints <= 0 || m_takeProfitPoints <= 0 || m_stopLossPoints <= 0)
   {
      if(m_logger) m_logger.Error("Invalid points parameters");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Log initialization                                               |
//+------------------------------------------------------------------+
void CRaphaelEA::LogInitialization(void)
{
   if(!m_logger)
      return;
      
   m_logger.Info("EA initialization started...");
   m_logger.Info("Version: " + EA_VERSION);
   m_logger.Info("Symbol: " + _Symbol);
   m_logger.Info("Magic Number: " + IntegerToString(m_magicNumber));
   m_logger.Info("Base Lot Size: " + DoubleToString(m_baseLotSize, 3));
   m_logger.Info("Risk Percent: " + DoubleToString(m_riskPercent, 1) + "%");
   m_logger.Info("Balance Scaling: " + (m_useBalanceScaling ? "Enabled" : "Disabled"));
   m_logger.Info("Exponential Growth: " + (m_useExponentialGrowth ? "Enabled" : "Disabled"));
   m_logger.Info("Aggressive Multiplier: " + DoubleToString(m_aggressiveMultiplier, 1));
   m_logger.Info("Growth Power: " + DoubleToString(m_growthPower, 1));
}

//+------------------------------------------------------------------+
//| Scan existing positions                                          |
//+------------------------------------------------------------------+
void CRaphaelEA::ScanExistingPositions(void)
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      CPositionInfo pos;
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() != m_magicNumber || pos.Symbol() != _Symbol)
            continue;

         if(m_logger) m_logger.Info("Found open position: #" + IntegerToString((int)pos.Ticket()));
         
         if(pos.PositionType() == POSITION_TYPE_BUY)
            m_buyPosition = pos.Ticket();
         else if(pos.PositionType() == POSITION_TYPE_SELL)
            m_sellPosition = pos.Ticket();
      }
   }
}

//+------------------------------------------------------------------+
//| Scan existing orders                                             |
//+------------------------------------------------------------------+
void CRaphaelEA::ScanExistingOrders(void)
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      COrderInfo order;
      if(order.SelectByIndex(i))
      {
         if(order.Magic() != m_magicNumber || order.Symbol() != _Symbol)
            continue;

         if(m_logger) m_logger.Info("Found pending order: #" + IntegerToString((int)order.Ticket()));
         
         if(order.OrderType() == ORDER_TYPE_BUY_STOP)
            m_buyPosition = order.Ticket();
         else if(order.OrderType() == ORDER_TYPE_SELL_STOP)
            m_sellPosition = order.Ticket();
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk and scaling                    |
//+------------------------------------------------------------------+
double CRaphaelEA::CalculateLotSize(double stop_loss_points)
{
   if(m_riskManager)
   {
      return m_riskManager.CalculateLotSize(stop_loss_points);
   }
   
   // Fallback implementation
   if(m_riskPercent > 0)
   {
      // Risk-based calculation with balance scaling
      double currentBalance = GetCurrentBalance();
      double risk = currentBalance * m_riskPercent / 100.0;
      
      if(m_useBalanceScaling)
      {
         double balanceRatio = GetBalanceRatio();
         double scaledRisk = (m_baseLotSize * balanceRatio) * stop_loss_points;
         double maxRisk = currentBalance * m_riskPercent / 100.0;
         risk = MathMin(scaledRisk, maxRisk);
      }
      
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      if(tickSize <= 0 || tickValue <= 0 || lotStep <= 0)
      {
         if(m_logger) m_logger.Error("Invalid symbol specifications");
         return CalculateScaledLotSize();
      }
      
      double moneyPerLotStep = stop_loss_points / tickSize * tickValue * lotStep;
      
      if(moneyPerLotStep <= 0)
      {
         if(m_logger) m_logger.Error("Invalid money per lot calculation");
         return CalculateScaledLotSize();
      }
      
      double lots = MathFloor(risk / moneyPerLotStep) * lotStep;
      
      // Ensure we don't go below the scaled lot size
      if(m_useBalanceScaling)
      {
         double minLots = CalculateScaledLotSize();
         lots = MathMax(lots, minLots);
      }
      
      return NormalizeLotSize(lots);
   }
   else
   {
      return CalculateScaledLotSize();
   }
}

//+------------------------------------------------------------------+
//| Normalize lot size according to broker specifications           |
//+------------------------------------------------------------------+
double CRaphaelEA::NormalizeLotSize(double lot_size)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(stepVol > 0)
      lot_size = MathRound(lot_size / stepVol) * stepVol;
   
   lot_size = MathMax(lot_size, minVol);
   lot_size = MathMin(lot_size, maxVol);
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Check if new bar appeared                                        |
//+------------------------------------------------------------------+
bool CRaphaelEA::IsNewBar(void)
{
   int bars = iBars(_Symbol, m_timeframe);
   if(m_totalBars != bars)
   {
      m_totalBars = bars;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update chart comment with trading information                   |
//+------------------------------------------------------------------+
void CRaphaelEA::UpdateChartComment(void)
{
   string comment = "";
   comment += "=== RaphaelEA v" + EA_VERSION + " ===\n";
   comment += "Symbol: " + _Symbol + "\n";
   comment += "Magic: " + IntegerToString(m_magicNumber) + "\n\n";
   
   // Balance information
   double currentBalance = GetCurrentBalance();
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balanceRatio = GetBalanceRatio();
   
   comment += "=== BALANCE INFO ===\n";
   comment += "Initial Balance: $" + DoubleToString(m_initialBalance, 2) + "\n";
   comment += "Current Balance: $" + DoubleToString(currentBalance, 2) + "\n";
   comment += "Current Equity: $" + DoubleToString(currentEquity, 2) + "\n";
   comment += "Balance Ratio: " + DoubleToString(balanceRatio, 3) + "\n\n";
   
   // Lot size information
   double scaledLots = CalculateScaledLotSize();
   comment += "=== LOT SIZE INFO ===\n";
   comment += "Base Lot Size: " + DoubleToString(m_baseLotSize, 3) + "\n";
   comment += "Scaled Lot Size: " + DoubleToString(scaledLots, 3) + "\n";
   comment += "Growth Factor: " + DoubleToString(scaledLots/m_baseLotSize, 2) + "x\n";
   comment += "Balance Scaling: " + (m_useBalanceScaling ? "ON" : "OFF") + "\n";
   comment += "Exponential Growth: " + (m_useExponentialGrowth ? "ON" : "OFF") + "\n\n";
   
   // Position information
   comment += "=== POSITION INFO ===\n";
   comment += "Buy Position: " + (m_buyPosition > 0 ? "#" + IntegerToString((int)m_buyPosition) : "None") + "\n";
   comment += "Sell Position: " + (m_sellPosition > 0 ? "#" + IntegerToString((int)m_sellPosition) : "None") + "\n";
   
   // Market information
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   comment += "\n=== MARKET INFO ===\n";
   comment += "Spread: " + DoubleToString((double)spread, 1) + " points\n";
   comment += "Bid: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "\n";
   comment += "Ask: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits) + "\n";
   
   // Trading state
   comment += "\n=== TRADING STATE ===\n";
   comment += "Initialized: " + (m_initialized ? "Yes" : "No") + "\n";
   comment += "Last Trade: " + (m_lastTradeTime > 0 ? TimeToString(m_lastTradeTime) : "Never") + "\n";
   
   Comment(comment);
}

//+------------------------------------------------------------------+
//| Get global variable name with prefix                            |
//+------------------------------------------------------------------+
string CRaphaelEA::GetGlobalVariableName(string suffix)
{
   return _Symbol + "_" + IntegerToString(m_magicNumber) + suffix;
}

//+------------------------------------------------------------------+
//| Set trading parameters                                           |
//+------------------------------------------------------------------+
void CRaphaelEA::SetTradingParameters(int order_dist, int tp, int sl, int tsl, int tsl_trigger)
{
   m_orderDistancePoints = order_dist;
   m_takeProfitPoints = tp;
   m_stopLossPoints = sl;
   m_trailingStopPoints = tsl;
   m_trailingTriggerPoints = tsl_trigger;
   
   if(m_tradeManager)
   {
      m_tradeManager.SetOrderDistance(order_dist);
      m_tradeManager.SetTakeProfit(tp);
      m_tradeManager.SetStopLoss(sl);
      m_tradeManager.SetTrailingStop(tsl);
      m_tradeManager.SetTrailingTrigger(tsl_trigger);
   }
}

//+------------------------------------------------------------------+
//| Get account statistics                                           |
//+------------------------------------------------------------------+
string CRaphaelEA::GetAccountStats(void)
{
   string stats = "";
   stats += "Account Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + "\n";
   stats += "Account Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + "\n";
   stats += "Free Margin: $" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + "\n";
   stats += "Margin Level: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + "%\n";
   return stats;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool CRaphaelEA::IsTradingAllowed(void)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      if(m_logger) m_logger.Warning("Trading is not allowed in terminal");
      return false;
   }
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      if(m_logger) m_logger.Warning("Automated trading is not allowed");
      return false;
   }
   
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
   {
      if(m_logger) m_logger.Warning("Expert trading is not allowed for this account");
      return false;
   }
   
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
   {
      if(m_logger) m_logger.Warning("Trading is disabled for symbol " + _Symbol);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get position count for this EA                                  |
//+------------------------------------------------------------------+
int CRaphaelEA::GetPositionCount(void)
{
   int count = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      CPositionInfo pos;
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == m_magicNumber && pos.Symbol() == _Symbol)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get pending order count for this EA                             |
//+------------------------------------------------------------------+
int CRaphaelEA::GetOrderCount(void)
{
   int count = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      COrderInfo order;
      if(order.SelectByIndex(i))
      {
         if(order.Magic() == m_magicNumber && order.Symbol() == _Symbol)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get total profit for this EA                                    |
//+------------------------------------------------------------------+
double CRaphaelEA::GetTotalProfit(void)
{
   double total_profit = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      CPositionInfo pos;
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == m_magicNumber && pos.Symbol() == _Symbol)
            total_profit += pos.Profit() + pos.Swap() + pos.Commission();
      }
   }
   return total_profit;
}

//+------------------------------------------------------------------+
//| Emergency close all positions and orders                        |
//+------------------------------------------------------------------+
void CRaphaelEA::EmergencyCloseAll(void)
{
   if(m_logger) m_logger.Warning("Emergency close all initiated");
   
   // Close all positions
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      CPositionInfo pos;
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == m_magicNumber && pos.Symbol() == _Symbol)
         {
            CTrade trade;
            trade.PositionClose(pos.Ticket());
         }
      }
   }
   
   // Delete all pending orders
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      COrderInfo order;
      if(order.SelectByIndex(i))
      {
         if(order.Magic() == m_magicNumber && order.Symbol() == _Symbol)
         {
            CTrade trade;
            trade.OrderDelete(order.Ticket());
         }
      }
   }
   
   m_buyPosition = 0;
   m_sellPosition = 0;
   
   if(m_logger) m_logger.Info("Emergency close all completed");
}