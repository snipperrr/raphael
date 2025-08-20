//+------------------------------------------------------------------+
//| RiskManager.mqh                                                 |
//| Risk management module for RaphaelEA                           |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

//+------------------------------------------------------------------+
//| CRiskManager Class                                               |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   double           m_riskPercent;
   double           m_maxRiskPercent;
   double           m_baseLotSize;
   double           m_initialBalance;
   double           m_maxLotSize;
   double           m_minLotSize;
   bool             m_useBalanceScaling;
   double           m_aggressiveMultiplier;
   bool             m_useExponentialGrowth;
   double           m_growthPower;
   
public:
   // Constructor
   CRiskManager();
   ~CRiskManager();
   
   // Initialization
   bool             Initialize(void);
   
   // Configuration methods
   void             SetRiskPercent(double risk_percent) { m_riskPercent = MathMax(MIN_RISK_PERCENT, MathMin(MAX_RISK_PERCENT, risk_percent)); }
   void             SetBaseLotSize(double lot_size) { m_baseLotSize = NormalizeLotSize(lot_size); }
   void             SetInitialBalance(double balance) { m_initialBalance = balance; }
   void             SetBalanceScaling(bool use_scaling) { m_useBalanceScaling = use_scaling; }
   void             SetAggressiveMultiplier(double multiplier) { m_aggressiveMultiplier = MathMax(MIN_MULTIPLIER, MathMin(MAX_MULTIPLIER, multiplier)); }
   void             SetExponentialGrowth(bool use_exponential) { m_useExponentialGrowth = use_exponential; }
   void             SetGrowthPower(double power) { m_growthPower = MathMax(MIN_GROWTH_POWER, MathMin(MAX_GROWTH_POWER, power)); }
   
   // Getter methods
   double           GetRiskPercent(void) const { return m_riskPercent; }
   double           GetBaseLotSize(void) const { return m_baseLotSize; }
   double           GetInitialBalance(void) const { return m_initialBalance; }
   bool             IsBalanceScalingEnabled(void) const { return m_useBalanceScaling; }
   double           GetAggressiveMultiplier(void) const { return m_aggressiveMultiplier; }
   bool             IsExponentialGrowthEnabled(void) const { return m_useExponentialGrowth; }
   double           GetGrowthPower(void) const { return m_growthPower; }
   
   // Lot size calculation methods
   double           CalculateLotSize(double stop_loss_points);
   double           CalculateScaledLotSize(void);
   double           CalculateRiskBasedLotSize(double stop_loss_points);
   double           NormalizeLotSize(double lot_size);
   
   // Risk validation methods
   bool             ValidateRisk(double lot_size, double stop_loss_points);
   bool             ValidateLotSize(double lot_size);
   double           GetMaxAllowedLotSize(void);
   double           GetMinAllowedLotSize(void);
   
   // Balance and equity methods
   double           GetCurrentBalance(void);
   double           GetCurrentEquity(void);
   double           GetBalanceRatio(void);
   double           GetDrawdownPercent(void);
   
   // Utility methods
   void             PrintRiskInfo(string operation, double lot_size, double stop_loss_points);
   
private:
   void             UpdateSymbolSpecs(void);
   bool             ValidateSymbolSpecs(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(void)
{
   m_riskPercent = DEFAULT_RISK_PERCENT;
   m_maxRiskPercent = MAX_RISK_PERCENT;
   m_baseLotSize = DEFAULT_LOTS;
   m_initialBalance = 0;
   m_maxLotSize = MAX_LOT_SIZE;
   m_minLotSize = MIN_LOT_SIZE;
   m_useBalanceScaling = true;
   m_aggressiveMultiplier = DEFAULT_AGGRESSIVE_MULTIPLIER;
   m_useExponentialGrowth = true;
   m_growthPower = DEFAULT_GROWTH_POWER;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager(void)
{
}

//+------------------------------------------------------------------+
//| Initialize risk manager                                          |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(void)
{
   UpdateSymbolSpecs();
   
   if(!ValidateSymbolSpecs())
   {
      Print(__FUNCTION__, " > Error: Invalid symbol specifications");
      return false;
   }
   
   if(m_initialBalance <= 0)
   {
      m_initialBalance = GetCurrentBalance();
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double stop_loss_points)
{
   if(m_riskPercent > 0)
   {
      return CalculateRiskBasedLotSize(stop_loss_points);
   }
   else
   {
      return CalculateScaledLotSize();
   }
}

//+------------------------------------------------------------------+
//| Calculate scaled lot size                                        |
//+------------------------------------------------------------------+
double CRiskManager::CalculateScaledLotSize(void)
{
   if(!m_useBalanceScaling || m_initialBalance <= 0)
   {
      return NormalizeLotSize(m_baseLotSize);
   }
   
   double balanceRatio = GetBalanceRatio();
   double scaledLots;
   
   if(m_useExponentialGrowth)
   {
      // Exponential growth formula: BaseLots * (Ratio^Power) * Multiplier
      double exponentialRatio = MathPow(balanceRatio, m_growthPower);
      scaledLots = m_baseLotSize * exponentialRatio * m_aggressiveMultiplier;
   }
   else
   {
      // Linear aggressive scaling: BaseLots * Ratio * Multiplier
      scaledLots = m_baseLotSize * balanceRatio * m_aggressiveMultiplier;
   }
   
   return NormalizeLotSize(scaledLots);
}

//+------------------------------------------------------------------+
//| Calculate risk-based lot size                                    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskBasedLotSize(double stop_loss_points)
{
   double currentBalance = GetCurrentBalance();
   double risk = currentBalance * m_riskPercent / 100.0;
   
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(tickSize <= 0 || tickValue <= 0 || lotStep <= 0)
   {
      Print(__FUNCTION__, " > Error: Invalid symbol specifications");
      return NormalizeLotSize(m_baseLotSize);
   }
   
   double moneyPerLotStep = stop_loss_points / tickSize * tickValue * lotStep;
   
   if(moneyPerLotStep <= 0)
   {
      Print(__FUNCTION__, " > Error: Invalid money per lot calculation");
      return NormalizeLotSize(m_baseLotSize);
   }
   
   double lots = MathFloor(risk / moneyPerLotStep) * lotStep;
   
   if(m_useBalanceScaling)
   {
      // Ensure we don't go below the scaled lot size
      double minLots = CalculateScaledLotSize();
      lots = MathMax(lots, minLots);
   }
   
   return NormalizeLotSize(lots);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeLotSize(double lot_size)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(stepVol > 0)
   {
      lot_size = MathRound(lot_size / stepVol) * stepVol;
   }
   
   lot_size = MathMax(lot_size, minVol);
   lot_size = MathMin(lot_size, maxVol);
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Validate risk                                                    |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateRisk(double lot_size, double stop_loss_points)
{
   if(!ValidateLotSize(lot_size))
      return false;
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double maxRisk = GetCurrentBalance() * m_maxRiskPercent / 100.0;
   double currentRisk = lot_size * stop_loss_points * tickValue;
   
   return currentRisk <= maxRisk;
}

//+------------------------------------------------------------------+
//| Validate lot size                                                |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateLotSize(double lot_size)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   return lot_size >= minVol && lot_size <= maxVol;
}

//+------------------------------------------------------------------+
//| Get current balance                                              |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentBalance(void)
{
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Get current equity                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentEquity(void)
{
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

//+------------------------------------------------------------------+
//| Get balance ratio                                                |
//+------------------------------------------------------------------+
double CRiskManager::GetBalanceRatio(void)
{
   if(m_initialBalance <= 0)
      return 1.0;
   
   return GetCurrentBalance() / m_initialBalance;
}

//+------------------------------------------------------------------+
//| Get drawdown percent                                             |
//+------------------------------------------------------------------+
double CRiskManager::GetDrawdownPercent(void)
{
   double balance = GetCurrentBalance();
   double equity = GetCurrentEquity();
   
   if(balance <= 0)
      return 0.0;
   
   return (balance - equity) / balance * 100.0;
}

//+------------------------------------------------------------------+
//| Update symbol specifications                                     |
//+------------------------------------------------------------------+
void CRiskManager::UpdateSymbolSpecs(void)
{
   m_minLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   m_maxLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
}

//+------------------------------------------------------------------+
//| Validate symbol specifications                                   |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateSymbolSpecs(void)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   return tickSize > 0 && tickValue > 0 && lotStep > 0 && m_minLotSize > 0 && m_maxLotSize > 0;
}

//+------------------------------------------------------------------+
//| Print risk information                                           |
//+------------------------------------------------------------------+
void CRiskManager::PrintRiskInfo(string operation, double lot_size, double stop_loss_points)
{
   double currentBalance = GetCurrentBalance();
   double balanceRatio = GetBalanceRatio();
   double scaledLots = CalculateScaledLotSize();
   
   Print(__FUNCTION__, " > ", operation, " order risk info:");
   Print("   Current Balance: ", DoubleToString(currentBalance, 2));
   Print("   Balance Ratio: ", DoubleToString(balanceRatio, 3));
   Print("   Scaled Lot Size: ", DoubleToString(scaledLots, 3), " (Base: ", DoubleToString(m_baseLotSize, 2), ")");
   Print("   Growth Factor: ", DoubleToString(scaledLots/m_baseLotSize, 2), "x");
   Print("   Final Lot Size: ", DoubleToString(lot_size, 3));
   Print("   Stop Loss Points: ", DoubleToString(stop_loss_points, 1));
}