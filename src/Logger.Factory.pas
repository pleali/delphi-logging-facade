unit Logger.Factory;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Logger.Intf,
  Logger.Types;

type
  /// <summary>
  /// Factory function type for creating logger instances.
  /// This allows custom logger implementations to be registered with the factory.
  /// </summary>
  TLoggerFactoryFunc = reference to function: ILogger;

  /// <summary>
  /// Singleton factory for creating and managing logger instances.
  /// Inspired by SLF4J's LoggerFactory pattern.
  ///
  /// Usage:
  ///   - At application startup, call SetLoggerFactory to configure which logger to use
  ///   - Throughout the application, call GetLogger to retrieve the logger instance
  ///   - The factory maintains a single logger instance (singleton pattern)
  /// </summary>
  TLoggerFactory = class sealed
  private
    class var FInstance: ILogger;
    class var FFactoryFunc: TLoggerFactoryFunc;
    class var FLock: TCriticalSection;

    class constructor Create;
    class destructor Destroy;

    class function GetDefaultLogger: ILogger; static;
  public
    /// <summary>
    /// Gets the global logger instance.
    /// If no logger has been configured, returns the default console logger.
    /// Thread-safe.
    /// </summary>
    class function GetLogger: ILogger; static;

    /// <summary>
    /// Sets a custom factory function for creating loggers.
    /// This should be called once at application startup before any GetLogger calls.
    /// Thread-safe.
    /// </summary>
    /// <param name="AFactoryFunc">Function that creates and returns a logger instance</param>
    class procedure SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc); static;

    /// <summary>
    /// Sets a specific logger instance to be used globally.
    /// This is a convenience method - equivalent to SetLoggerFactory with a function
    /// that returns the provided instance.
    /// Thread-safe.
    /// </summary>
    /// <param name="ALogger">The logger instance to use</param>
    class procedure SetLogger(ALogger: ILogger); static;

    /// <summary>
    /// Resets the factory to use the default console logger.
    /// Useful for testing or resetting configuration.
    /// Thread-safe.
    /// </summary>
    class procedure Reset; static;

    /// <summary>
    /// Quick configuration methods for common scenarios.
    /// </summary>

    /// <summary>
    /// Configures the factory to use the default console logger.
    /// </summary>
    /// <param name="AMinLevel">Minimum log level (default: Info)</param>
    /// <param name="AUseColors">Enable colored console output (default: True)</param>
    class procedure UseConsoleLogger(AMinLevel: TLogLevel = llInfo; AUseColors: Boolean = True); static;

    /// <summary>
    /// Configures the factory to use the null logger (no output).
    /// Useful for testing or production environments where logging is not desired.
    /// </summary>
    class procedure UseNullLogger; static;
  end;

  /// <summary>
  /// Convenience function to get the global logger.
  /// Equivalent to TLoggerFactory.GetLogger.
  /// </summary>
  function Log: ILogger;

implementation

uses
  Logger.Default,
  Logger.Null;

{ TLoggerFactory }

class constructor TLoggerFactory.Create;
begin
  FLock := TCriticalSection.Create;
  FInstance := nil;
  FFactoryFunc := nil;
end;

class destructor TLoggerFactory.Destroy;
begin
  FreeAndNil(FLock);
  FInstance := nil;
  FFactoryFunc := nil;
end;

class function TLoggerFactory.GetDefaultLogger: ILogger;
begin
  Result := TConsoleLogger.Create(llInfo, True);
end;

class function TLoggerFactory.GetLogger: ILogger;
begin
  FLock.Enter;
  try
    if FInstance = nil then
    begin
      if Assigned(FFactoryFunc) then
        FInstance := FFactoryFunc()
      else
        FInstance := GetDefaultLogger;
    end;
    Result := FInstance;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc);
begin
  FLock.Enter;
  try
    FFactoryFunc := AFactoryFunc;
    FInstance := nil; // Force recreation on next GetLogger call
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.SetLogger(ALogger: ILogger);
begin
  if ALogger = nil then
    raise EArgumentNilException.Create('Logger instance cannot be nil');

  FLock.Enter;
  try
    FInstance := ALogger;
    FFactoryFunc := nil;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.Reset;
begin
  FLock.Enter;
  try
    FInstance := nil;
    FFactoryFunc := nil;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.UseConsoleLogger(AMinLevel: TLogLevel; AUseColors: Boolean);
begin
  SetLoggerFactory(
    function: ILogger
    begin
      Result := TConsoleLogger.Create(AMinLevel, AUseColors);
    end
  );
end;

class procedure TLoggerFactory.UseNullLogger;
begin
  SetLoggerFactory(
    function: ILogger
    begin
      Result := TNullLogger.Create;
    end
  );
end;

{ Global function }

function Log: ILogger;
begin
  Result := TLoggerFactory.GetLogger;
end;

end.
