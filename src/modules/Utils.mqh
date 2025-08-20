//+------------------------------------------------------------------+
//| Utils.mqh                                                        |
//| Utility functions for RaphaelEA                                 |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

//+------------------------------------------------------------------+
//| CUtils Class                                                     |
//+------------------------------------------------------------------+
class CUtils
{
private:
   ENUM_TIMEFRAMES  m_timeframe;
   int              m_barsLookback;
   
public:
   // Constructor
   CUtils();
   ~CUtils();
   
   // Initialization
   bool             Initialize(void);
   
   // Configuration
   void             SetTimeframe(ENUM_TIMEFRAMES tf) { m_timeframe = tf; }
   void             SetBarsLookback(int bars) { m_barsLookback = bars; }
   
   // Technical analysis methods
   double           FindSwingHigh(void);
   double           FindSwingLow(void);
   bool             IsSwingHigh(int bar_index);
   bool             IsSwingLow(int bar_index);
   
   // Price utility methods
   double           GetHighest(int bars, int start_bar = 0);
   double           GetLowest(int bars, int start_bar = 0);
   double           GetRange(int bars, int start_bar = 0);
   double           GetAverageRange(int bars, int start_bar = 0);
   
   // Time utility methods
   bool             IsNewBar(void);
   datetime         GetBarTime(int bar_index = 0);
   int              GetBarIndex(datetime time);
   
   // Symbol information methods
   double           GetPointValue(void);
   double           GetTickValue(void);
   double           GetSpread(void);
   string           GetSymbolDescription(void);
   
   // Market state methods
   bool             IsMarketOpen(void);
   bool             IsTradingAllowed(void);
   double           GetMarketDistance(bool is_buy);
   
   // String utility methods
   string           DoubleToStringOptimal(double value, int digits = -1);
   string           TimeToStringOptimal(datetime time);
   string           BoolToString(bool value);
   
   // Math utility methods
   double           NormalizePrice(double price);
   double           CalculateDistance(double price1, double price2);
   bool             IsWithinRange(double value, double min_val, double max_val);
   
   // Global variable methods
   bool             SaveGlobalVariable(string name, double value);
   double           LoadGlobalVariable(string name, double default_value = 0);
   bool             DeleteGlobalVariable(string name);
   
private:
   int              m_lastBarTime;
   void             UpdateLastBarTime(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CUtils::CUtils(void)
{
   m_timeframe = PERIOD_H1;
   m_barsLookback = DEFAULT_BARS_N;
   m_lastBarTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CUtils::~CUtils(void)
{
}

//+------------------------------------------------------------------+
//| Initialize utils                                                 |
//+------------------------------------------------------------------+
bool CUtils::Initialize(void)
{
   UpdateLastBarTime();
   return true;
}

//+------------------------------------------------------------------+
//| Find swing high                                                  |
//+------------------------------------------------------------------+
double CUtils::FindSwingHigh(void)
{
   double highestHigh = 0;
   
   for(int i = 0; i < 200; i++)
   {
      double high = iHigh(_Symbol, m_timeframe, i);
      if(high <= 0) 
         continue; // Skip invalid data
      
      if(i > m_barsLookback && IsSwingHigh(i))
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
//| Find swing low                                                   |
//+------------------------------------------------------------------+
double CUtils::FindSwingLow(void)
{
   double lowestLow = DBL_MAX;
   
   for(int i = 0; i < 200; i++)
   {
      double low = iLow(_Symbol, m_timeframe, i);
      if(low <= 0) 
         continue; // Skip invalid data
      
      if(i > m_barsLookback && IsSwingLow(i))
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
//| Check if bar is swing high                                       |
//+------------------------------------------------------------------+
bool CUtils::IsSwingHigh(int bar_index)
{
   int highest_index = iHighest(_Symbol, m_timeframe, MODE_HIGH, m_barsLookback * 2 + 1, bar_index - m_barsLookback);
   return highest_index == bar_index;
}

//+------------------------------------------------------------------+
//| Check if bar is swing low                                        |
//+------------------------------------------------------------------+
bool CUtils::IsSwingLow(int bar_index)
{
   int lowest_index = iLowest(_Symbol, m_timeframe, MODE_LOW, m_barsLookback * 2 + 1, bar_index - m_barsLookback);
   return lowest_index == bar_index;
}

//+------------------------------------------------------------------+
//| Get highest price                                                |
//+------------------------------------------------------------------+
double CUtils::GetHighest(int bars, int start_bar = 0)
{
   return iHigh(_Symbol, m_timeframe, iHighest(_Symbol, m_timeframe, MODE_HIGH, bars, start_bar));
}

//+------------------------------------------------------------------+
//| Get lowest price                                                 |
//+------------------------------------------------------------------+
double CUtils::GetLowest(int bars, int start_bar = 0)
{
   return iLow(_Symbol, m_timeframe, iLowest(_Symbol, m_timeframe, MODE_LOW, bars, start_bar));
}

//+------------------------------------------------------------------+
//| Get range                                                        |
//+------------------------------------------------------------------+
double CUtils::GetRange(int bars, int start_bar = 0)
{
   return GetHighest(bars, start_bar) - GetLowest(bars, start_bar);
}

//+------------------------------------------------------------------+
//| Check if new bar                                                 |
//+------------------------------------------------------------------+
bool CUtils::IsNewBar(void)
{
   int current_time = (int)iTime(_Symbol, m_timeframe, 0);
   
   if(current_time != m_lastBarTime)
   {
      m_lastBarTime = current_time;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get bar time                                                     |
//+------------------------------------------------------------------+
datetime CUtils::GetBarTime(int bar_index = 0)
{
   return iTime(_Symbol, m_timeframe, bar_index);
}

//+------------------------------------------------------------------+
//| Get point value                                                  |
//+------------------------------------------------------------------+
double CUtils::GetPointValue(void)
{
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Get tick value                                                   |
//+------------------------------------------------------------------+
double CUtils::GetTickValue(void)
{
   return SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
}

//+------------------------------------------------------------------+
//| Get spread                                                       |
//+------------------------------------------------------------------+
double CUtils::GetSpread(void)
{
   return SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
}

//+------------------------------------------------------------------+
//| Check if market is open                                          |
//+------------------------------------------------------------------+
bool CUtils::IsMarketOpen(void)
{
   return SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool CUtils::IsTradingAllowed(void)
{
   return TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && 
          MQLInfoInteger(MQL_TRADE_ALLOWED) && 
          AccountInfoInteger(ACCOUNT_TRADE_EXPERT) &&
          IsMarketOpen();
}

//+------------------------------------------------------------------+
//| Normalize price                                                  |
//+------------------------------------------------------------------+
double CUtils::NormalizePrice(double price)
{
   return NormalizeDouble(price, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate distance                                               |
//+------------------------------------------------------------------+
double CUtils::CalculateDistance(double price1, double price2)
{
   return MathAbs(price1 - price2) / _Point;
}

//+------------------------------------------------------------------+
//| Double to string optimal                                         |
//+------------------------------------------------------------------+
string CUtils::DoubleToStringOptimal(double value, int digits = -1)
{
   if(digits < 0)
      digits = _Digits;
   
   return DoubleToString(value, digits);
}

//+------------------------------------------------------------------+
//| Time to string optimal                                           |
//+------------------------------------------------------------------+
string CUtils::TimeToStringOptimal(datetime time)
{
   return TimeToString(time, TIME_DATE | TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Bool to string                                                   |
//+------------------------------------------------------------------+
string CUtils::BoolToString(bool value)
{
   return value