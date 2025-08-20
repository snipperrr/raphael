//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| Logging utility for RaphaelEA                                   |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, RaphaelEA"
#property version   "2.1"

//+------------------------------------------------------------------+
//| CLogger Class                                                    |
//+------------------------------------------------------------------+
class CLogger
{
private:
   string           m_logFile;
   bool             m_enableFileLogging;
   bool             m_enableConsoleLogging;
   int              m_logLevel;
   
public:
   // Constructor
   CLogger();
   ~CLogger();
   
   // Initialization
   bool             Initialize(string log_file = "");
   void             SetLogLevel(int level) { m_logLevel = level; }
   void             EnableFileLogging(bool enable) { m_enableFileLogging = enable; }
   void             EnableConsoleLogging(bool enable) { m_enableConsoleLogging = enable; }
   
   // Logging methods
   void             Info(string message);
   void             Warning(string message);
   void             Error(string message);
   void             Debug(string message);
   void             Trade(string message);
   
   // Utility methods
   void             LogHeader(void);
   void             LogSeparator(void);
   
private:
   void             WriteToFile(string message);
   void             WriteToConsole(string message);
   string           GetTimestamp(void);
   string           FormatMessage(string level, string message);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger(void)
{
   m_logFile = "";
   m_enableFileLogging = false;
   m_enableConsoleLogging = true;
   m_logLevel = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger(void)
{
}

//+------------------------------------------------------------------+
//| Initialize logger                                                |
//+------------------------------------------------------------------+
bool CLogger::Initialize(string log_file = "")
{
   if(log_file == "")
   {
      m_logFile = "logs/RaphaelEA_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
   }
   else
   {
      m_logFile = log_file;
   }
   
   m_enableFileLogging = true;
   m_enableConsoleLogging = true;
   
   LogHeader();
   Info("Logger initialized successfully");
   
   return true;
}

//+------------------------------------------------------------------+
//| Log info message                                                 |
//+------------------------------------------------------------------+
void CLogger::Info(string message)
{
   string formatted_msg = FormatMessage("INFO", message);
   
   if(m_enableConsoleLogging)
      WriteToConsole(formatted_msg);
   
   if(m_enableFileLogging)
      WriteToFile(formatted_msg);
}

//+------------------------------------------------------------------+
//| Log warning message                                              |
//+------------------------------------------------------------------+
void CLogger::Warning(string message)
{
   string formatted_msg = FormatMessage("WARN", message);
   
   if(m_enableConsoleLogging)
      WriteToConsole(formatted_msg);
   
   if(m_enableFileLogging)
      WriteToFile(formatted_msg);
}

//+------------------------------------------------------------------+
//| Log error message                                                |
//+------------------------------------------------------------------+
void CLogger::Error(string message)
{
   string formatted_msg = FormatMessage("ERROR", message);
   
   if(m_enableConsoleLogging)
      WriteToConsole(formatted_msg);
   
   if(m_enableFileLogging)
      WriteToFile(formatted_msg);
}

//+------------------------------------------------------------------+
//| Log debug message                                                |
//+------------------------------------------------------------------+
void CLogger::Debug(string message)
{
   if(m_logLevel < 1)
      return;
   
   string formatted_msg = FormatMessage("DEBUG", message);
   
   if(m_enableConsoleLogging)
      WriteToConsole(formatted_msg);
   
   if(m_enableFileLogging)
      WriteToFile(formatted_msg);
}

//+------------------------------------------------------------------+
//| Log trade message                                                |
//+------------------------------------------------------------------+
void CLogger::Trade(string message)
{
   string formatted_msg = FormatMessage("TRADE", message);
   
   if(m_enableConsoleLogging)
      WriteToConsole(formatted_msg);
   
   if(m_enableFileLogging)
      WriteToFile(formatted_msg);
}

//+------------------------------------------------------------------+
//| Write to console                                                 |
//+------------------------------------------------------------------+
void CLogger::WriteToConsole(string message)
{
   Print(message);
}

//+------------------------------------------------------------------+
//| Write to file                                                    |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(string message)
{
   int file_handle = FileOpen(m_logFile, FILE_WRITE|FILE_TXT|FILE_ANSI, '\t');
   
   if(file_handle != INVALID_HANDLE)
   {
      FileSeek(file_handle, 0, SEEK_END);
      FileWrite(file_handle, message);
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Get timestamp                                                    |
//+------------------------------------------------------------------+
string CLogger::GetTimestamp(void)
{
   return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Format message                                                   |
//+------------------------------------------------------------------+
string CLogger::FormatMessage(string level, string message)
{
   return GetTimestamp() + " [" + level + "] " + message;
}

//+------------------------------------------------------------------+
//| Log header                                                       |
//+------------------------------------------------------------------+
void CLogger::LogHeader(void)
{
   LogSeparator();
   Info("RaphaelEA v" + EA_VERSION + " - Advanced MT5 Expert Advisor");
   Info("Copyright 2025, RaphaelEA");
   Info("Session started: " + GetTimestamp());
   LogSeparator();
}

//+------------------------------------------------------------------+
//| Log separator                                                    |
//+------------------------------------------------------------------+
void CLogger::LogSeparator(void)
{
   string separator = "================================================";
   
   if(m_enableConsoleLogging)
      WriteToConsole(separator);
   
   if(m_enableFileLogging)
      WriteToFile(separator);
}