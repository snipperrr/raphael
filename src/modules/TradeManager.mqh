//+------------------------------------------------------------------+
//| TradeManager.mqh                                                |
//| Trade execution and management module for RaphaelEA            |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"



//+------------------------------------------------------------------+
//| CTradeManager Class                                              |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   CTrade           m_trade;
   int              m_magicNumber;
   int              m_orderDistancePoints;
   int              m_takeProfitPoints;
   int              m_stopLossPoints;
   int              m_trailingStopPoints;
   int              m_trailingTriggerPoints;
   int              m_expirationHours;
   ENUM_TIMEFRAMES  m_timeframe;
   ulong            m_lastResultOrder; // To store the last order ticket
   
public:
   // Constructor
   CTradeManager();
   ~CTradeManager();
   
   // Initialization
   bool             Initialize(int magic_number);
   
   // Configuration methods
   void             SetMagicNumber(int magic) { m_magicNumber = magic; m_trade.SetExpertMagicNumber(magic); }
   void             SetOrderDistance(int points) { m_orderDistancePoints = points; }
   void             SetTakeProfit(int points) { m_takeProfitPoints = points; }
   void             SetStopLoss(int points) { m_stopLossPoints = points; }
   void             SetTrailingStop(int points) { m_trailingStopPoints = points; }
   void             SetTrailingTrigger(int points) { m_trailingTriggerPoints = points; }
   void             SetExpiration(int hours) { m_expirationHours = hours; }
   void             SetTimeframe(ENUM_TIMEFRAMES tf) { m_timeframe = tf; }
   
   // Getter methods
   int              GetMagicNumber(void) const { return m_magicNumber; }
   ulong            GetLastResultOrder(void) const { return m_lastResultOrder; }
   
   // Order execution methods
   bool             ExecuteBuyStopOrder(double entry_price, double lot_size);
   bool             ExecuteSellStopOrder(double entry_price, double lot_size);
   
   // Position management methods
   void             ProcessPosition(ulong position_ticket);
   bool             ModifyPosition(ulong ticket, double stop_loss, double take_profit);
   bool             ClosePosition(ulong ticket);

private:
   void             SetupTradeFilling(void);
   bool             ValidateTradeRequest(double entry_price, double lot_size, bool is_buy);
   void             LogTradeOperation(string operation, double price, double lot_size);
   datetime         CalculateExpiration(void);
   double           CalculateTakeProfit(double entry_price, bool is_buy);
   double           CalculateStopLoss(double entry_price, bool is_buy);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager(void)
{
   m_magicNumber = DEFAULT_MAGIC_NUMBER;
   m_orderDistancePoints = DEFAULT_ORDER_DIST_POINTS;
   m_takeProfitPoints = DEFAULT_TP_POINTS;
   m_stopLossPoints = DEFAULT_SL_POINTS;
   m_trailingStopPoints = DEFAULT_TSL_POINTS;
   m_trailingTriggerPoints = DEFAULT_TSL_TRIGGER_POINTS;
   m_expirationHours = DEFAULT_EXPIRATION_HOURS;
   m_timeframe = PERIOD_H1;
   m_lastResultOrder = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager(void)
{
}

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(int magic_number)
{
   m_magicNumber = magic_number;
   m_trade.SetExpertMagicNumber(m_magicNumber);
   SetupTradeFilling();
   return true;
}

//+------------------------------------------------------------------+
//| Execute buy stop order                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteBuyStopOrder(double entry_price, double lot_size)
{
   m_lastResultOrder = 0;
   if(!ValidateTradeRequest(entry_price, lot_size, true))
      return false;
   
   entry_price = NormalizeDouble(entry_price, _Digits);
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry_price - m_orderDistancePoints * _Point)
      return false;
   
   double take_profit = CalculateTakeProfit(entry_price, true);
   double stop_loss = CalculateStopLoss(entry_price, true);
   datetime expiration = CalculateExpiration();
   
   LogTradeOperation("BUY STOP", entry_price, lot_size);
   
   bool result = m_trade.BuyStop(lot_size, entry_price, _Symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, expiration);
   if(result)
   {
      m_lastResultOrder = m_trade.ResultOrder();
   }
   return result;
}

//+------------------------------------------------------------------+
//| Execute sell stop order                                          |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteSellStopOrder(double entry_price, double lot_size)
{
   m_lastResultOrder = 0;
   if(!ValidateTradeRequest(entry_price, lot_size, false))
      return false;
   
   entry_price = NormalizeDouble(entry_price, _Digits);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid < entry_price + m_orderDistancePoints * _Point)
      return false;
   
   double take_profit = CalculateTakeProfit(entry_price, false);
   double stop_loss = CalculateStopLoss(entry_price, false);
   datetime expiration = CalculateExpiration();
   
   LogTradeOperation("SELL STOP", entry_price, lot_size);
   
   bool result = m_trade.SellStop(lot_size, entry_price, _Symbol, stop_loss, take_profit, ORDER_TIME_SPECIFIED, expiration);
   if(result)
   {
      m_lastResultOrder = m_trade.ResultOrder();
   }
   return result;
}

//+------------------------------------------------------------------+
//| Process position for trailing stop                              |
//+------------------------------------------------------------------+
void CTradeManager::ProcessPosition(ulong position_ticket)
{
   if(position_ticket <= 0)
      return;
      
   if(OrderSelect(position_ticket))
      return; // It's a pending order, not a position
   
   CPositionInfo pos;
   if(!pos.SelectByTicket(position_ticket))
      return;
   
   if(pos.PositionType() == POSITION_TYPE_BUY)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      if(bid > pos.PriceOpen() + m_trailingTriggerPoints * _Point)
      {
         double new_sl = bid - m_trailingStopPoints * _Point;
         new_sl = NormalizeDouble(new_sl, _Digits);
         
         if(new_sl > pos.StopLoss())
         {
            ModifyPosition(pos.Ticket(), new_sl, pos.TakeProfit());
         }
      }
   }
   else if(pos.PositionType() == POSITION_TYPE_SELL)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(ask < pos.PriceOpen() - m_trailingTriggerPoints * _Point)
      {
         double new_sl = ask + m_trailingStopPoints * _Point;
         new_sl = NormalizeDouble(new_sl, _Digits);
         
         if(new_sl < pos.StopLoss() || pos.StopLoss() == 0)
         {
            ModifyPosition(pos.Ticket(), new_sl, pos.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Modify position                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double stop_loss, double take_profit)
{
   return m_trade.PositionModify(ticket, stop_loss, take_profit);
}

//+------------------------------------------------------------------+
//| Close position                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket)
{
   return m_trade.PositionClose(ticket);
}

//+------------------------------------------------------------------+
//| Calculate expiration time                                        |
//+------------------------------------------------------------------+
datetime CTradeManager::CalculateExpiration(void)
{
   return iTime(_Symbol, m_timeframe, 0) + m_expirationHours * PeriodSeconds(PERIOD_H1);
}

//+------------------------------------------------------------------+
//| Calculate take profit                                            |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTakeProfit(double entry_price, bool is_buy)
{
   double tp;
   
   if(is_buy)
      tp = entry_price + m_takeProfitPoints * _Point;
   else
      tp = entry_price - m_takeProfitPoints * _Point;
   
   return NormalizeDouble(tp, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                              |
//+------------------------------------------------------------------+
double CTradeManager::CalculateStopLoss(double entry_price, bool is_buy)
{
   double sl;
   
   if(is_buy)
      sl = entry_price - m_stopLossPoints * _Point;
   else
      sl = entry_price + m_stopLossPoints * _Point;
   
   return NormalizeDouble(sl, _Digits);
}

//+------------------------------------------------------------------+
//| Setup trade filling                                              |
//+------------------------------------------------------------------+
void CTradeManager::SetupTradeFilling(void)
{
   if(!m_trade.SetTypeFillingBySymbol(_Symbol))
   {
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }
}

//+------------------------------------------------------------------+
//| Validate trade request                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateTradeRequest(double entry_price, double lot_size, bool is_buy)
{
   if(entry_price <= 0 || lot_size <= 0)
      return false;
   
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   return lot_size >= min_lot && lot_size <= max_lot;
}

//+------------------------------------------------------------------+
//| Log trade operation                                              |
//+------------------------------------------------------------------+
void CTradeManager::LogTradeOperation(string operation, double price, double lot_size)
{
   Print(__FUNCTION__, " > Placing ", operation, " order");
   Print("   Entry Price: ", DoubleToString(price, _Digits));
   Print("   Lot Size: ", DoubleToString(lot_size, 3));
   Print("   Take Profit: ", DoubleToString(CalculateTakeProfit(price, StringFind(operation, "BUY") >= 0), _Digits));
   Print("   Stop Loss: ", DoubleToString(CalculateStopLoss(price, StringFind(operation, "BUY") >= 0), _Digits));
}
