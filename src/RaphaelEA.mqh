//+------------------------------------------------------------------+
//| RaphaelEA.mqh                                                    |
//| Main header file for RaphaelEA                                  |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

#include "RaphaelEA.constants.mqh"
#include "modules/Logger.mqh"
#include "modules/RiskManager.mqh"
#include "modules/TradeManager.mqh"
#include "modules/Utils.mqh"

//+------------------------------------------------------------------+
//| RaphaelEA Class                                                  |
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
   
   // Getter methods
   bool             IsBalanceScalingEnabled(void) const { return m_useBalanceScaling; }
   bool             IsExponentialGrowthEnabled(void) const { return m_useExponentialGrowth; }
   double           GetAggressiveMultiplier(void) const { return m_aggressiveMultiplier; }
   double           GetGrowthPower(void) const { return m_growthPower; }
   int              GetMagicNumber(void) const { return m_magicNumber; }
   
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
   
private:
   // Internal helper methods
   void             InitializeComponents(void);
   void             CleanupComponents(void);
   bool             ValidateConfiguration(void);
   void             LogInitialization(void);
   void             ScanExistingPositions(void);
   void             ScanExistingOrders(void);
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
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRaphaelEA::~CRaphaelEA(void)
{
   CleanupComponents();
}

//+------------------------------------------------------------------+
//| Initialize the EA                                                |
//+------------------------------------------------------------------+
bool CRaphaelEA::Initialize(void)
{
   InitializeComponents();
   
   if(!ValidateConfiguration())
   {
      m_logger.Error("Configuration validation failed");
      return false;
   }
   
   LogInitialization();
   ScanExistingPositions();
   ScanExistingOrders();
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize components                                            |
//+------------------------------------------------------------------+
void CRaphaelEA::InitializeComponents(void)
{
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
//| Print EA status                                                  |
//+------------------------------------------------------------------+
void CRaphaelEA::PrintStatus(void)
{
   if(!m_logger)
      return;
   
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
   m_logger.Info("Buy Position: " + ULongToString(m_buyPosition));
   m_logger.Info("Sell Position: " + ULongToString(m_sellPosition));
   m_logger.Info("======================");
}