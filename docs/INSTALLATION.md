#define VERSION "2.1"
#property version VERSION

#define PROJECT_NAME MQLInfoString(MQL_PROGRAM_NAME)

#include <Trade/Trade.mqh>

input double Lots = 0.1;
input double RiskPercent = 2.0; //RiskPercent (0 = Fix)
input bool UseBalanceScaling = true; // Scale lot size based on balance growth
input double InitialBalance = 0; // Initial balance reference (0 = auto-detect)
input double AggressiveMultiplier = 2.0; // Aggressive scaling multiplier (2.0 = double growth effect)
input bool UseExponentialGrowth = true; // Use exponential growth formula
input double GrowthPower = 1.5; // Power for exponential growth (1.0=linear, 2.0=quadratic)

input int OrderDistPoints = 200;
input int TpPoints = 200;
input int SlPoints = 200;
input int TslPoints = 5;
input int TslTriggerPoints = 5;

input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int BarsN = 5;
input int ExpirationHours = 50;

input int Magic = 111;

CTrade trade;

ulong buyPos, sellPos;
int totalBars;
double initialBalance;
double baseLotSize;

int OnInit(){
   trade.SetExpertMagicNumber(Magic);
   if(!trade.SetTypeFillingBySymbol(_Symbol)){
      trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }

   // Initialize balance and lot size variables
   baseLotSize = Lots;
   
   // Set initial balance
   if(InitialBalance > 0){
      initialBalance = InitialBalance;
   } else {
      // Load from global variable or use current balance
      string balanceVarName = _Symbol + "_" + IntegerToString(Magic) + "_InitialBalance";
      if(GlobalVariableCheck(balanceVarName)){
         initialBalance = GlobalVariableGet(balanceVarName);
         Print(__FUNCTION__," > Loaded initial balance from storage: ",DoubleToString(initialBalance,2));
      } else {
         initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         GlobalVariableSet(balanceVarName, initialBalance);
         Print(__FUNCTION__," > Set initial balance: ",DoubleToString(initialBalance,2));
      }
   }

   static bool isInit = false;
   if(!isInit){
      isInit = true;
      Print(__FUNCTION__," > EA (re)start...");
      Print(__FUNCTION__," > EA version ",VERSION,"...");
      Print(__FUNCTION__," > Base lot size: ",baseLotSize);
      Print(__FUNCTION__," > Aggressive multiplier: ",AggressiveMultiplier);
      Print(__FUNCTION__," > Exponential growth: ", UseExponentialGrowth ? "Enabled" : "Disabled");
      if(UseExponentialGrowth) Print(__FUNCTION__," > Growth power: ",GrowthPower);
      Print(__FUNCTION__," > Initial balance: ",DoubleToString(initialBalance,2));
      Print(__FUNCTION__," > Current balance: ",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
      Print(__FUNCTION__," > Balance scaling: ", UseBalanceScaling ? "Enabled" : "Disabled");
       
      for(int i = PositionsTotal()-1; i >= 0; i--){
         CPositionInfo pos;
         if(pos.SelectByIndex(i)){
            if(pos.Magic() != Magic) continue;
            if(pos.Symbol() != _Symbol) continue;

            Print(__FUNCTION__," > Found open position with ticket #",pos.Ticket(),"...");
            if(pos.PositionType() == POSITION_TYPE_BUY) buyPos = pos.Ticket();
            if(pos.PositionType() == POSITION_TYPE_SELL) sellPos = pos.Ticket();
         }
      }

      for(int i = OrdersTotal()-1; i >= 0; i--){
         COrderInfo order;
         if(order.SelectByIndex(i)){
            if(order.Magic() != Magic) continue;
            if(order.Symbol() != _Symbol) continue;

            Print(__FUNCTION__," > Found pending order with ticket #",order.Ticket(),"...");
            if(order.OrderType() == ORDER_TYPE_BUY_STOP) buyPos = order.Ticket();
            if(order.OrderType() == ORDER_TYPE_SELL_STOP) sellPos = order.Ticket();
         }
      }
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   // Save initial balance for future reference
   string balanceVarName = _Symbol + "_" + IntegerToString(Magic) + "_InitialBalance";
   GlobalVariableSet(balanceVarName, initialBalance);
}

void OnTick(){
   processPos(buyPos);
   processPos(sellPos);

   int bars = iBars(_Symbol,Timeframe);
   if(totalBars != bars){
      totalBars = bars;
      
      if(buyPos <= 0){
         double high = findHigh();
         if(high > 0){
            executeBuy(high);
         }
      }
      
      if(sellPos <= 0){
         double low = findLow();
         if(low > 0){
            executeSell(low);
         }
      }
   }
}

void OnTradeTransaction(
   const MqlTradeTransaction&    trans,
   const MqlTradeRequest&        request,
   const MqlTradeResult&         result
   ){
   
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD){
      COrderInfo order;
      if(order.Select(trans.order)){
         if(order.Magic() == Magic){
            if(order.OrderType() == ORDER_TYPE_BUY_STOP){
               buyPos = order.Ticket();
            }else if(order.OrderType() == ORDER_TYPE_SELL_STOP){
               sellPos = order.Ticket();
            }
         }
      }
   }
   
   // Handle position close events for balance tracking
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD){
      CDealInfo deal;
      if(deal.SelectByIndex(HistoryDealsTotal()-1)){
         if(deal.Magic() == Magic && deal.Symbol() == _Symbol){
            if(deal.Entry() == DEAL_ENTRY_OUT){
               // Position was closed - log balance change
               double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
               double balanceRatio = currentBalance / initialBalance;
               Print(__FUNCTION__," > Trade closed. Balance: ",DoubleToString(currentBalance,2),
                     ", Ratio: ",DoubleToString(balanceRatio,3));
            }
         }
      }
   }
}

double calculateScaledLotSize(){
   if(!UseBalanceScaling || initialBalance <= 0){
      return baseLotSize;
   }
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   
   double scaledLots;
   
   if(UseExponentialGrowth){
      // Exponential growth formula: BaseLots * (Ratio^Power) * Multiplier
      double exponentialRatio = MathPow(balanceRatio, GrowthPower);
      scaledLots = baseLotSize * exponentialRatio * AggressiveMultiplier;
   } else {
      // Linear aggressive scaling: BaseLots * Ratio * Multiplier
      scaledLots = baseLotSize * balanceRatio * AggressiveMultiplier;
   }
   
   // Normalize volume according to broker specifications
   scaledLots = normalizeVolume(scaledLots);
   
   return scaledLots;
}

double normalizeVolume(double volume){
   double minVol = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   if(stepVol > 0){
      volume = MathRound(volume / stepVol) * stepVol;
   }
   
   volume = MathMax(volume, minVol);
   volume = MathMin(volume, maxVol);
   
   return volume;
}

void processPos(ulong &posTicket){
   if(posTicket <= 0) return;
   if(OrderSelect(posTicket)) return;
   
   CPositionInfo pos;
   if(!pos.SelectByTicket(posTicket)){
      posTicket = 0;
      return;
   }else{
      if(pos.PositionType() == POSITION_TYPE_BUY){
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         
         if(bid > pos.PriceOpen() + TslTriggerPoints * _Point){
            double sl = bid - TslPoints * _Point;
            sl = NormalizeDouble(sl,_Digits);
            
            if(sl > pos.StopLoss()){
               trade.PositionModify(pos.Ticket(),sl,pos.TakeProfit());
            }
         }
      }else if(pos.PositionType() == POSITION_TYPE_SELL){
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         
         if(ask < pos.PriceOpen() - TslTriggerPoints * _Point){
            double sl = ask + TslPoints * _Point;
            sl = NormalizeDouble(sl,_Digits);
            
            if(sl < pos.StopLoss() || pos.StopLoss() == 0){
               trade.PositionModify(pos.Ticket(),sl,pos.TakeProfit());
            }
         }
      }
   }
}

void executeBuy(double entry){
   entry = NormalizeDouble(entry,_Digits);
   
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(ask > entry - OrderDistPoints * _Point) return;
   
   double tp = entry + TpPoints * _Point;
   tp = NormalizeDouble(tp,_Digits);
   
   double sl = entry - SlPoints * _Point;
   sl = NormalizeDouble(sl,_Digits);

   double lots;
   if(RiskPercent > 0) {
      lots = calcLots(entry-sl);
   } else {
      lots = calculateScaledLotSize();
   }
   
   lots = normalizeVolume(lots);
   
   datetime expiration = iTime(_Symbol,Timeframe,0) + ExpirationHours * PeriodSeconds(PERIOD_H1);

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   double scaledLots = calculateScaledLotSize();
   
   Print(__FUNCTION__," > Placing BUY order");
   Print("   Current Balance: ",DoubleToString(currentBalance,2));
   Print("   Balance Ratio: ",DoubleToString(balanceRatio,3));
   Print("   Scaled Lot Size: ",DoubleToString(scaledLots,3)," (Base: ",DoubleToString(baseLotSize,2),")");
   Print("   Growth Factor: ",DoubleToString(scaledLots/baseLotSize,2),"x");
   
   trade.BuyStop(lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration);
   
   buyPos = trade.ResultOrder();
}

void executeSell(double entry){
   entry = NormalizeDouble(entry,_Digits);  

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(bid < entry + OrderDistPoints * _Point) return;

   double tp = entry - TpPoints * _Point;
   tp = NormalizeDouble(tp,_Digits);
   
   double sl = entry + SlPoints * _Point;
   sl = NormalizeDouble(sl,_Digits);
   
   double lots;
   if(RiskPercent > 0) {
      lots = calcLots(sl-entry);
   } else {
      lots = calculateScaledLotSize();
   }
   
   lots = normalizeVolume(lots);
  
   datetime expiration = iTime(_Symbol,Timeframe,0) + ExpirationHours * PeriodSeconds(PERIOD_H1);

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double balanceRatio = currentBalance / initialBalance;
   double scaledLots = calculateScaledLotSize();
   
   Print(__FUNCTION__," > Placing SELL order");
   Print("   Current Balance: ",DoubleToString(currentBalance,2));
   Print("   Balance Ratio: ",DoubleToString(balanceRatio,3));
   Print("   Scaled Lot Size: ",DoubleToString(scaledLots,3)," (Base: ",DoubleToString(baseLotSize,2),")");
   Print("   Growth Factor: ",DoubleToString(scaledLots/baseLotSize,2),"x");

   trade.SellStop(lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration);
   
   sellPos = trade.ResultOrder();
}

double calcLots(double slPoints){
   if(!UseBalanceScaling){
      // Original risk-based calculation
      double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
      
      double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double lotstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
      
      if(ticksize <= 0 || tickvalue <= 0 || lotstep <= 0){
         Print(__FUNCTION__," > Error: Invalid symbol specifications");
         return normalizeVolume(baseLotSize);
      }
      
      double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;   
      
      if(moneyPerLotstep <= 0){
         Print(__FUNCTION__," > Error: Invalid money per lot calculation");
         return normalizeVolume(baseLotSize);
      }
      
      double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
      return normalizeVolume(lots);
   } else {
      // Balance-scaled risk calculation
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double balanceRatio = currentBalance / initialBalance;
      
      // Scale the risk based on balance growth
      double scaledRisk = (baseLotSize * balanceRatio) * slPoints;
      double maxRisk = currentBalance * RiskPercent / 100;
      
      // Use the smaller of scaled risk or percentage risk
      double risk = MathMin(scaledRisk, maxRisk);
      
      double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double lotstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
      
      if(ticksize <= 0 || tickvalue <= 0 || lotstep <= 0){
         Print(__FUNCTION__," > Error: Invalid symbol specifications");
         return calculateScaledLotSize();
      }
      
      double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;   
      
      if(moneyPerLotstep <= 0){
         Print(__FUNCTION__," > Error: Invalid money per lot calculation");
         return calculateScaledLotSize();
      }
      
      double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
      
      // Ensure we don't go below the scaled lot size
      double minLots = calculateScaledLotSize();
      lots = MathMax(lots, minLots);
      
      return normalizeVolume(lots);
   }
}

double findHigh(){
   double highestHigh = 0;
   for(int i = 0; i < 200; i++){
      double high = iHigh(_Symbol,Timeframe,i);
      if(high <= 0) continue; // Skip invalid data
      
      if(i > BarsN && iHighest(_Symbol,Timeframe,MODE_HIGH,BarsN*2+1,i-BarsN) == i){
         if(high > highestHigh){
            return high;
         }
      }
      highestHigh = MathMax(high,highestHigh);
   }
   return -1;
}

double findLow(){
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++){
      double low = iLow(_Symbol,Timeframe,i);
      if(low <= 0) continue; // Skip invalid data
      
      if(i > BarsN && iLowest(_Symbol,Timeframe,MODE_LOW,BarsN*2+1,i-BarsN) == i){
         if(low < lowestLow){
            return low;
         }
      }   
      lowestLow = MathMin(low,lowestLow);
   }
   return -1;
}