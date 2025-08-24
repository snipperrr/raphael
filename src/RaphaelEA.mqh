//+------------------------------------------------------------------+
//| RaphaelEA.mqh                                                    |
//| Main header file for RaphaelEA - Complete Implementation        |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

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
   ulong            m_buyTicket;
   ulong            m_sellTicket;
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
   bool             m_showTradeInfo;
   
   // State variables
   bool             m_initialized;
   
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
   void             SetShowTradeInfo(bool show) { m_showTradeInfo = show; }
   void             SetInitialBalance(double balance) { m_initialBalance = balance; }

private:
   // Internal helper methods
   void             InitializeComponents(void);
   void             CleanupComponents(void);
   bool             ValidateParameters(void);
   void             LogInitialization(void);
   void             ScanExistingPositions(void);
   void             ScanExistingOrders(void);
   bool             IsNewBar(void);
   void             UpdateChartComment(void);
   string           GetGlobalVariableName(string suffix);
   void             LoadPreset(void);
   void             ApplyPresetValue(string key, string value);

   // Trading Logic
   void             ExecuteBuy(double entry);
   void             ExecuteSell(double entry);
   void             ProcessPosition(ulong &posTicket);
   double           CalculateLotSize(double slPoints);
   double           FindHigh(void);
   double           FindLow(void);
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
   
   m_buyTicket = 0;
   m_sellTicket = 0;
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
   m_showTradeInfo = true;
   
   m_initialized = false;
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

   // Load preset settings first
   LoadPreset();
      
   InitializeComponents();
   
   if(!ValidateParameters())
   {
      if(m_logger) m_logger->Error("Configuration validation failed");
      return false;
   }
   
   // Set initial balance
   if(m_initialBalance <= 0)
   {
      string balanceVarName = GetGlobalVariableName(GV_INITIAL_BALANCE);
      if(GlobalVariableCheck(balanceVarName))
      {
         m_initialBalance = GlobalVariableGet(balanceVarName);
         if(m_logger) m_logger->Info("Loaded initial balance from storage: " + DoubleToString(m_initialBalance, 2));
      }
      else
      {
         m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         GlobalVariableSet(balanceVarName, m_initialBalance);
         if(m_logger) m_logger->Info("Set initial balance: " + DoubleToString(m_initialBalance, 2));
      }
   }
   
   // Configure components with potentially updated parameters
   if(m_riskManager)
   {
      m_riskManager->SetRiskPercent(m_riskPercent);
      m_riskManager->SetBaseLotSize(m_baseLotSize);
      m_riskManager->SetInitialBalance(m_initialBalance);
      m_riskManager->SetBalanceScaling(m_useBalanceScaling);
      m_riskManager->SetAggressiveMultiplier(m_aggressiveMultiplier);
      m_riskManager->SetExponentialGrowth(m_useExponentialGrowth);
      m_riskManager->SetGrowthPower(m_growthPower);
   }
   
   if(m_tradeManager)
   {
      m_tradeManager->SetMagicNumber(m_magicNumber);
      m_tradeManager->SetOrderDistance(m_orderDistancePoints);
      m_tradeManager->SetTakeProfit(m_takeProfitPoints);
      m_tradeManager->SetStopLoss(m_stopLossPoints);
      m_tradeManager->SetTrailingStop(m_trailingStopPoints);
      m_tradeManager->SetTrailingTrigger(m_trailingTriggerPoints);
      m_tradeManager->SetExpiration(m_expirationHours);
      m_tradeManager->SetTimeframe(m_timeframe);
   }
   
   if(m_utils)
   {
      m_utils->SetTimeframe(m_timeframe);
      m_utils->SetBarsLookback(m_barsLookback);
   }
   
   LogInitialization();
   ScanExistingPositions();
   ScanExistingOrders();
   
   m_totalBars = iBars(_Symbol, m_timeframe);
   m_initialized = true;
   
   if(m_logger) m_logger->Info("EA initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the EA                                              |
//+------------------------------------------------------------------+
void CRaphaelEA::Deinitialize(void)
{
   if(!m_initialized)
      return;
      
   // Save initial balance for future reference
   string balanceVarName = GetGlobalVariableName(GV_INITIAL_BALANCE);
   GlobalVariableSet(balanceVarName, m_initialBalance);
   
   if(m_logger) m_logger->Info("EA deinitialized");
   
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
   ProcessPosition(m_buyTicket);
   ProcessPosition(m_sellTicket);
   
   // Check for new bar
   if(IsNewBar())
   {
      // Look for buy signals
      if(m_buyTicket <= 0)
      {
         double high = FindHigh();
         if(high > 0)
         {
            ExecuteBuy(high);
         }
      }
      
      // Look for sell signals
      if(m_sellTicket <= 0)
      {
         double low = FindLow();
         if(low > 0)
         {
            ExecuteSell(low);
         }
      }
   }
   
   if(m_showTradeInfo)
   {
      UpdateChartComment();
   }
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
               m_buyTicket = order.Ticket();
               if(m_logger) m_logger->Trade("Buy stop order placed: #" + IntegerToString((int)order.Ticket()));
            }
            else if(order.OrderType() == ORDER_TYPE_SELL_STOP)
            {
               m_sellTicket = order.Ticket();
               if(m_logger) m_logger->Trade("Sell stop order placed: #" + IntegerToString((int)order.Ticket()));
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
               double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
               double balanceRatio = (m_initialBalance > 0) ? currentBalance / m_initialBalance : 1.0;
               if(m_logger) m_logger->Trade("Trade closed. Balance: " + DoubleToString(currentBalance, 2) +
                                         ", Ratio: " + DoubleToString(balanceRatio, 3));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void CRaphaelEA::ExecuteBuy(double entry)
{
   entry = NormalizeDouble(entry, _Digits);
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry - m_orderDistancePoints * _Point) return;
   
   double lots = CalculateLotSize(m_stopLossPoints * _Point);
   
   if(m_tradeManager)
   {
      bool res = m_tradeManager->ExecuteBuyStopOrder(entry, lots);
      if(res)
      {
         m_buyTicket = m_tradeManager->GetLastResultOrder();
      }
   }
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
void CRaphaelEA::ExecuteSell(double entry)
{
   entry = NormalizeDouble(entry, _Digits);  

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry + m_orderDistancePoints * _Point) return;

   double lots = CalculateLotSize(m_stopLossPoints * _Point);
   
   if(m_tradeManager)
   {
      bool res = m_tradeManager->ExecuteSellStopOrder(entry, lots);
      if(res)
      {
         m_sellTicket = m_tradeManager->GetLastResultOrder();
      }
   }
}

//+------------------------------------------------------------------+
//| Process position for trailing stop                              |
//+------------------------------------------------------------------+
void CRaphaelEA::ProcessPosition(ulong& posTicket)
{
   if(posTicket <= 0) return;
   if(OrderSelect(posTicket)) return; // It's a pending order
   
   CPositionInfo pos;
   if(!pos.SelectByTicket(posTicket))
   {
      posTicket = 0;
      return;
   }
   
   if(m_tradeManager)
   {
      m_tradeManager->ProcessPosition(pos.Ticket());
   }
}

//+------------------------------------------------------------------+
//| Find swing high                                                  |
//+------------------------------------------------------------------+
double CRaphaelEA::FindHigh(void)
{
   if(m_utils)
   {
      return m_utils->FindSwingHigh();
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Find swing low                                                   |
//+------------------------------------------------------------------+
double CRaphaelEA::FindLow(void)
{
   if(m_utils)
   {
      return m_utils->FindSwingLow();
   }
   return -1;
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
   
   if(m_logger) m_logger->Initialize();
   if(m_riskManager) m_riskManager->Initialize();
   if(m_tradeManager) m_tradeManager->Initialize(m_magicNumber);
   if(m_utils) m_utils->Initialize();
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
bool CRaphaelEA::ValidateParameters(void)
{
   if(m_baseLotSize <= 0)
   {
      if(m_logger) m_logger->Error("Invalid base lot size: " + DoubleToString(m_baseLotSize, 3));
      return false;
   }
   
   if(m_riskPercent < 0 || m_riskPercent > 50)
   {
      if(m_logger) m_logger->Error("Invalid risk percentage: " + DoubleToString(m_riskPercent, 1));
      return false;
   }
   
   if(m_aggressiveMultiplier <= 0 || m_aggressiveMultiplier > 10)
   {
      if(m_logger) m_logger->Error("Invalid aggressive multiplier: " + DoubleToString(m_aggressiveMultiplier, 1));
      return false;
   }
   
   if(m_growthPower <= 0 || m_growthPower > 5)
   {
      if(m_logger) m_logger->Error("Invalid growth power: " + DoubleToString(m_growthPower, 1));
      return false;
   }
   
   if(m_orderDistancePoints <= 0 || m_takeProfitPoints <= 0 || m_stopLossPoints <= 0)
   {
      if(m_logger) m_logger->Error("Invalid points parameters");
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
      
   m_logger->Info("EA initialization started...\n");
   m_logger->Info("Version: " + EA_VERSION + "\n");
   m_logger->Info("Symbol: " + _Symbol + "\n");
   m_logger->Info("Magic Number: " + IntegerToString(m_magicNumber) + "\n");
   m_logger->Info("Base Lot Size: " + DoubleToString(m_baseLotSize, 3) + "\n");
   m_logger->Info("Risk Percent: " + DoubleToString(m_riskPercent, 1) + "%\n");
   m_logger->Info("Balance Scaling: " + (m_useBalanceScaling ? "Enabled" : "Disabled") + "\n");
   m_logger->Info("Exponential Growth: " + (m_useExponentialGrowth ? "Enabled" : "Disabled") + "\n");
   m_logger->Info("Aggressive Multiplier: " + DoubleToString(m_aggressiveMultiplier, 1) + "\n");
   m_logger->Info("Growth Power: " + DoubleToString(m_growthPower, 1) + "\n");
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

         if(m_logger) m_logger->Info("Found open position: #" + IntegerToString((int)pos.Ticket()) + "\n");
         
         if(pos.PositionType() == POSITION_TYPE_BUY)
            m_buyTicket = pos.Ticket();
         else if(pos.PositionType() == POSITION_TYPE_SELL)
            m_sellTicket = pos.Ticket();
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

         if(m_logger) m_logger->Info("Found pending order: #" + IntegerToString((int)order.Ticket()) + "\n");
         
         if(order.OrderType() == ORDER_TYPE_BUY_STOP)
            m_buyTicket = order.Ticket();
         else if(order.OrderType() == ORDER_TYPE_SELL_STOP)
            m_sellTicket = order.Ticket();
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk and scaling                    |
//+------------------------------------------------------------------+
double CRaphaelEA::CalculateLotSize(double slPoints)
{
   if(m_riskManager)
   {
      return m_riskManager->CalculateLotSize(slPoints);
   }
   return m_baseLotSize;
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
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balanceRatio = m_initialBalance > 0 ? currentBalance / m_initialBalance : 1.0;
   
   comment += "=== BALANCE INFO ===\n";
   comment += "Initial Balance: $" + DoubleToString(m_initialBalance, 2) + "\n";
   comment += "Current Balance: $" + DoubleToString(currentBalance, 2) + "\n";
   comment += "Current Equity: $" + DoubleToString(currentEquity, 2) + "\n";
   comment += "Balance Ratio: " + DoubleToString(balanceRatio, 3) + "\n\n";
   
   // Lot size information
   double scaledLots = m_riskManager ? m_riskManager->CalculateScaledLotSize() : m_baseLotSize;
   comment += "=== LOT SIZE INFO ===\n";
   comment += "Base Lot Size: " + DoubleToString(m_baseLotSize, 3) + "\n";
   comment += "Scaled Lot Size: " + DoubleToString(scaledLots, 3) + "\n";
   comment += "Growth Factor: " + DoubleToString(m_baseLotSize > 0 ? scaledLots/m_baseLotSize : 0, 2) + "x\n";
   comment += "Balance Scaling: " + (m_useBalanceScaling ? "ON" : "OFF") + "\n";
   comment += "Exponential Growth: " + (m_useExponentialGrowth ? "ON" : "OFF") + "\n\n";
   
   // Position information
   comment += "=== POSITION INFO ===\n";
   comment += "Buy Ticket: " + (m_buyTicket > 0 ? "#" + IntegerToString((int)m_buyTicket) : "None") + "\n";
   comment += "Sell Ticket: " + (m_sellTicket > 0 ? "#" + IntegerToString((int)m_sellTicket) : "None") + "\n";
   
   // Market information
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   comment += "\n=== MARKET INFO ===\n";
   comment += "Spread: " + DoubleToString((double)spread, 1) + " points\n";
   comment += "Bid: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "\n";
   comment += "Ask: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits) + "\n";
   
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
      m_tradeManager->SetOrderDistance(order_dist);
      m_tradeManager->SetTakeProfit(tp);
      m_tradeManager->SetStopLoss(sl);
      m_tradeManager->SetTrailingStop(tsl);
      m_tradeManager->SetTrailingTrigger(tsl_trigger);
   }
}

//+------------------------------------------------------------------+
//| Load preset file for the current symbol                         |
//+------------------------------------------------------------------+
void CRaphaelEA::LoadPreset(void)
{
   string symbol = _Symbol;
   string preset_path = "";
   
   string search_path = "presets" + PATH_SEPARATOR + "*";
   long handle = FileFindFirst(search_path, preset_path);
   
   if(handle != INVALID_HANDLE)
   {
      do
      {
         // Check if it's a directory
         if(FileIsDirectory(preset_path))
         {
            string file_path = preset_path + PATH_SEPARATOR + symbol + ".set";
            if(FileIsExist(file_path, FILE_COMMON))
            {
               preset_path = file_path;
               break;
            }
         }
      }
      while(FileFindNext(handle, preset_path));
      
      FileFindClose(handle);
   }

   if(preset_path == "" || !FileIsExist(preset_path, FILE_COMMON))
   {
      if(m_logger) m_logger->Info("No preset file found for symbol " + symbol + ". Using default parameters.\n");
      return;
   }

   int file_handle = FileOpen(preset_path, FILE_READ|FILE_TXT|FILE_ANSI);
   if(file_handle == INVALID_HANDLE)
   {
      if(m_logger) m_logger->Error("Failed to open preset file: " + preset_path + "\n");
      return;
   }

   if(m_logger) m_logger->Info("Loading preset file: " + preset_path + "\n");

   while(!FileIsEnding(file_handle))
   {
      string line = FileReadString(file_handle);
      StringTrimRight(line);
      StringTrimLeft(line);

      if(StringSubstr(line, 0, 1) == "#" || StringSubstr(line, 0, 2) == "//" || line == "")
         continue;

      int separator_pos = StringFind(line, "=");
      if(separator_pos > 0)
      {
         string key = StringSubstr(line, 0, separator_pos);
         string value = StringSubstr(line, separator_pos + 1);
         ApplyPresetValue(key, value);
      }
   }

   FileClose(file_handle);
}


//+------------------------------------------------------------------+
//| Apply a single value from the preset file                       |
//+------------------------------------------------------------------+
void CRaphaelEA::ApplyPresetValue(string key, string value)
{
   if(key == "Lots") m_baseLotSize = (double)StringToDouble(value);
   else if(key == "RiskPercent") m_riskPercent = (double)StringToDouble(value);
   else if(key == "UseBalanceScaling") m_useBalanceScaling = (bool)StringToBool(value);
   else if(key == "InitialBalance") m_initialBalance = (double)StringToDouble(value);
   else if(key == "AggressiveMultiplier") m_aggressiveMultiplier = (double)StringToDouble(value);
   else if(key == "UseExponentialGrowth") m_useExponentialGrowth = (bool)StringToBool(value);
   else if(key == "GrowthPower") m_growthPower = (double)StringToDouble(value);
   else if(key == "OrderDistPoints") m_orderDistancePoints = (int)StringToInteger(value);
   else if(key == "TpPoints") m_takeProfitPoints = (int)StringToInteger(value);
   else if(key == "SlPoints") m_stopLossPoints = (int)StringToInteger(value);
   else if(key == "TslPoints") m_trailingStopPoints = (int)StringToInteger(value);
   else if(key == "TslTriggerPoints") m_trailingTriggerPoints = (int)StringToInteger(value);
   else if(key == "BarsN") m_barsLookback = (int)StringToInteger(value);
   else if(key == "ExpirationHours") m_expirationHours = (int)StringToInteger(value);
   else if(key == "Timeframe")
   {
      int tf_minutes = (int)StringToInteger(value);
      switch(tf_minutes)
      {
         case 1: m_timeframe = PERIOD_M1; break;
         case 5: m_timeframe = PERIOD_M5; break;
         case 15: m_timeframe = PERIOD_M15; break;
         case 30: m_timeframe = PERIOD_M30; break;
         case 60: m_timeframe = PERIOD_H1; break;
         case 240: m_timeframe = PERIOD_H4; break;
         case 1440: m_timeframe = PERIOD_D1; break;
         case 10080: m_timeframe = PERIOD_W1; break;
         case 43200: m_timeframe = PERIOD_MN1; break;
         default: m_timeframe = PERIOD_H1;
      }
   }
}
