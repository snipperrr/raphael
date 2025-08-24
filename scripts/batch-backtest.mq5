//+------------------------------------------------------------------+
//| batch-backtest.mq5                                               |
//| Script to prepare batch backtest configurations for RaphaelEA.   |
//| Generates .set files for various scenarios.                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"
#property script_show_inputs

#include "../src/RaphaelEA.mqh" // For constants and potential future use of CRaphaelEA methods

//+------------------------------------------------------------------+
//| Input Parameters (for script configuration)                      |
//+------------------------------------------------------------------+
input string SymbolsToTest = "EURUSD,GBPUSD,USDJPY"; // Comma-separated list of symbols
input string TimeframesToTest = "60,240";           // Comma-separated list of timeframes (in minutes: 60=H1, 240=H4)
input string RiskPercentsToTest = "1.0,2.0,3.0";    // Comma-separated list of RiskPercent values

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnInit()
{
   Print("Batch Backtest Preparer Script: Starting...");

   string symbols[];
   StringSplit(SymbolsToTest, ',', symbols);

   string timeframes_str[];
   StringSplit(TimeframesToTest, ',', timeframes_str);
   ENUM_TIMEFRAMES timeframes[ArraySize(timeframes_str)];
   for(int i = 0; i < ArraySize(timeframes_str); i++)
   {
      int tf_minutes = (int)StringToInteger(timeframes_str[i]);
      switch(tf_minutes)
      {
         case 1: timeframes[i] = PERIOD_M1; break;
         case 5: timeframes[i] = PERIOD_M5; break;
         case 15: timeframes[i] = PERIOD_M15; break;
         case 30: timeframes[i] = PERIOD_M30; break;
         case 60: timeframes[i] = PERIOD_H1; break;
         case 240: timeframes[i] = PERIOD_H4; break;
         case 1440: timeframes[i] = PERIOD_D1; break;
         case 10080: timeframes[i] = PERIOD_W1; break;
         case 43200: timeframes[i] = PERIOD_MN1; break;
         default: timeframes[i] = PERIOD_H1; // Default to H1 if unknown
      }
   }

   string risk_percents_str[];
   StringSplit(RiskPercentsToTest, ',', risk_percents_str);
   double risk_percents[ArraySize(risk_percents_str)];
   for(int i = 0; i < ArraySize(risk_percents_str); i++)
   {
      risk_percents[i] = StringToDouble(risk_percents_str[i]);
   }

   string common_settings = "Lots=0.1\nUseBalanceScaling=true\nInitialBalance=0\nAggressiveMultiplier=2.0\nUseExponentialGrowth=true\nGrowthPower=1.5\nOrderDistPoints=200\nTpPoints=400\nSlPoints=200\nTslPoints=50\nTslTriggerPoints=100\nBarsN=5\nExpirationHours=50\n";

   int counter = 0;
   for(int s = 0; s < ArraySize(symbols); s++)
   {
      for(int tf = 0; tf < ArraySize(timeframes); tf++)
      {
         for(int rp = 0; rp < ArraySize(risk_percents); rp++)
         {
            counter++;
            string filename = "Backtest_" + symbols[s] + "_" + TimeframeToString(timeframes[tf]) + "_Risk" + DoubleToString(risk_percents[rp], 1) + ".set";
            string filepath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filename;

            int file_handle = FileOpen(filepath, FILE_WRITE|FILE_TXT|FILE_ANSI);
            if(file_handle != INVALID_HANDLE)
            {
               FileWriteString(file_handle, common_settings);
               FileWriteString(file_handle, "RiskPercent=" + DoubleToString(risk_percents[rp], 1) + "\n");
               FileWriteString(file_handle, "Timeframe=" + IntegerToString(timeframes[tf]) + "\n"); // Write timeframe as integer for parsing
               FileClose(file_handle);
               Print("Prepared backtest scenario ", counter, ": ", symbols[s], " ", TimeframeToString(timeframes[tf]), " Risk ", DoubleToString(risk_percents[rp], 1), "%");
               Print("   Load this preset in Strategy Tester: ", filepath);
            }
            else
            {
               Print("Error: Could not create file ", filepath);
            }
         }
      }
   }

   Print("Batch Backtest Preparer Script: Finished. Total scenarios prepared: ", counter);
   Print("Instructions: Go to Strategy Tester, select RaphaelEA, then 'Open' and load one of the generated .set files.");
   Print("Remember to set the correct symbol and timeframe in the Strategy Tester before starting each test.");
}

//+------------------------------------------------------------------+
//| Script deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Batch Backtest Preparer Script: Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Helper function to convert ENUM_TIMEFRAMES to string             |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      case PERIOD_MN1: return "MN1";
      default: return "Unknown";
   }
}
