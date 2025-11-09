unit Logger;

{$I Logger.Config.inc}

interface

uses
  Logger.Types,
  Logger.Intf,
  Logger.Factory;

type
  // Re-export core types from Logger.Types
  TLogLevel = Logger.Types.TLogLevel;
  TLogLevelHelper = Logger.Types.TLogLevelHelper;
  TLogEventData = Logger.Types.TLogEventData;
  TLogEvent = Logger.Types.TLogEvent;

  // Re-export interface from Logger.Intf
  ILogger = Logger.Intf.ILogger;

  // Re-export factory from Logger.Factory
  TLoggerFactory = Logger.Factory.TLoggerFactory;
  TLoggerFactoryFunc = Logger.Factory.TLoggerFactoryFunc;
  TNamedLoggerFactoryFunc = Logger.Factory.TNamedLoggerFactoryFunc;

// Re-export convenience function from Logger.Factory
function Log: ILogger;

implementation

function Log: ILogger;
begin
  Result := Logger.Factory.Log;
end;

end.
