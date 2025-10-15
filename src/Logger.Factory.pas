unit Logger.Factory;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  Logger.Intf,
  Logger.Types;

type
  /// <summary>
  /// Factory function type for creating logger instances.
  /// This allows custom logger implementations to be registered with the factory.
  /// </summary>
  TLoggerFactoryFunc = reference to function: ILogger;

  /// <summary>
  /// Factory function type for creating named logger instances.
  /// </summary>
  TNamedLoggerFactoryFunc = reference to function(const AName: string): ILogger;

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
    class var FRootLogger: ILogger;
    class var FNamedLoggers: TDictionary<string, ILogger>;
    class var FFactoryFunc: TLoggerFactoryFunc;
    class var FNamedFactoryFunc: TNamedLoggerFactoryFunc;
    class var FLock: TCriticalSection;
    class var FLoggerNameWidth: Integer;

    class constructor Create;
    class destructor Destroy;

    class function GetDefaultLogger: ILogger; static;
    class function GetDefaultNamedLogger(const AName: string): ILogger; static;
  public
    /// <summary>
    /// Gets a logger instance. If AName is empty, returns the root logger.
    /// If AName is provided, returns a cached named logger instance.
    /// If no logger has been configured, returns the default console logger.
    /// Thread-safe.
    /// </summary>
    /// <param name="AName">Optional logger name (e.g., 'MqttRpc.Registry')</param>
    class function GetLogger(const AName: string = ''): ILogger; static;

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

    /// <summary>
    /// Sets the width for logger name formatting in log output.
    /// Default is 40 characters (inspired by Spring Boot).
    /// </summary>
    /// <param name="AWidth">Width in characters for logger name field</param>
    class procedure SetLoggerNameWidth(AWidth: Integer); static;

    /// <summary>
    /// Gets the current logger name width.
    /// </summary>
    class function GetLoggerNameWidth: Integer; static;

    /// <summary>
    /// Sets a custom factory function for creating named loggers.
    /// This allows adapters to create their own named logger instances.
    /// </summary>
    class procedure SetNamedLoggerFactory(AFactoryFunc: TNamedLoggerFactoryFunc); static;
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
  FNamedLoggers := TDictionary<string, ILogger>.Create;
  FRootLogger := nil;
  FFactoryFunc := nil;
  FNamedFactoryFunc := nil;
  FLoggerNameWidth := 40; // Default width inspired by Spring Boot
end;

class destructor TLoggerFactory.Destroy;
begin
  FreeAndNil(FNamedLoggers);
  FreeAndNil(FLock);
  FRootLogger := nil;
  FFactoryFunc := nil;
  FNamedFactoryFunc := nil;
end;

class function TLoggerFactory.GetDefaultLogger: ILogger;
begin
  Result := TConsoleLogger.Create('', llInfo, True);
end;

class function TLoggerFactory.GetDefaultNamedLogger(const AName: string): ILogger;
begin
  Result := TConsoleLogger.Create(AName, llInfo, True);
end;

class function TLoggerFactory.GetLogger(const AName: string): ILogger;
begin
  // Fast path for root logger (no name) - no lock needed for read
  if AName = '' then
  begin
    if FRootLogger = nil then
    begin
      FLock.Enter;
      try
        if FRootLogger = nil then // Double-check inside lock
        begin
          if Assigned(FFactoryFunc) then
            FRootLogger := FFactoryFunc()
          else
            FRootLogger := GetDefaultLogger;
        end;
      finally
        FLock.Leave;
      end;
    end;
    Result := FRootLogger;
    Exit;
  end;

  // Named logger path - check cache first
  FLock.Enter;
  try
    if not FNamedLoggers.TryGetValue(AName, Result) then
    begin
      // Create new named logger
      if Assigned(FNamedFactoryFunc) then
        Result := FNamedFactoryFunc(AName)
      else
        Result := GetDefaultNamedLogger(AName);

      FNamedLoggers.Add(AName, Result);
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc);
begin
  FLock.Enter;
  try
    FFactoryFunc := AFactoryFunc;
    FRootLogger := nil; // Force recreation on next GetLogger call
    FNamedLoggers.Clear; // Clear named logger cache
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
    FRootLogger := ALogger;
    FFactoryFunc := nil;
    FNamedLoggers.Clear; // Clear named logger cache
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.Reset;
begin
  FLock.Enter;
  try
    FRootLogger := nil;
    FFactoryFunc := nil;
    FNamedFactoryFunc := nil;
    FNamedLoggers.Clear;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.UseConsoleLogger(AMinLevel: TLogLevel; AUseColors: Boolean);
begin
  SetLoggerFactory(
    function: ILogger
    begin
      Result := TConsoleLogger.Create('', AMinLevel, AUseColors);
    end
  );
  SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TConsoleLogger.Create(AName, AMinLevel, AUseColors);
    end
  );
end;

class procedure TLoggerFactory.UseNullLogger;
begin
  SetLoggerFactory(
    function: ILogger
    begin
      Result := TNullLogger.Create('');
    end
  );
  SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TNullLogger.Create(AName);
    end
  );
end;

class procedure TLoggerFactory.SetLoggerNameWidth(AWidth: Integer);
begin
  if AWidth < 10 then
    raise EArgumentException.Create('Logger name width must be at least 10 characters');

  FLock.Enter;
  try
    FLoggerNameWidth := AWidth;
  finally
    FLock.Leave;
  end;
end;

class function TLoggerFactory.GetLoggerNameWidth: Integer;
begin
  Result := FLoggerNameWidth;
end;

class procedure TLoggerFactory.SetNamedLoggerFactory(AFactoryFunc: TNamedLoggerFactoryFunc);
begin
  FLock.Enter;
  try
    FNamedFactoryFunc := AFactoryFunc;
    FNamedLoggers.Clear; // Clear cache when factory changes
  finally
    FLock.Leave;
  end;
end;

{ Global function }

function Log: ILogger;
begin
  Result := TLoggerFactory.GetLogger('');
end;

end.
