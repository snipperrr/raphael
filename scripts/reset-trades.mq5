//+------------------------------------------------------------------+
//| reset-trades.mq5                                                 |
//| Script to close all positions and delete all pending orders      |
//| associated with a specific Magic Number for RaphaelEA.           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"
#property script_show_inputs

#include "../src/RaphaelEA.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input int Magic = 111; // Magic number of the EA whose trades to reset

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnInit()
{
   Print("Reset Trades Script: Starting...");

   // Create a temporary CRaphaelEA instance
   CRaphaelEA* temp_ea = new CRaphaelEA();
   if(temp_ea == NULL)
   {
      Print("Reset Trades Script: Failed to create CRaphaelEA instance.");
      return;
   }

   // Set the Magic Number for the temporary EA instance
   temp_ea->SetMagicNumber(Magic);

   // Call the EmergencyCloseAll method to close positions and delete orders
   temp_ea->EmergencyCloseAll();

   // Clean up the temporary EA instance
   delete temp_ea;
   temp_ea = NULL;

   Print("Reset Trades Script: Finished. Check Experts tab for details.");
}

//+------------------------------------------------------------------+
//| Script deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Reset Trades Script: Deinitialized. Reason: ", reason);
}
