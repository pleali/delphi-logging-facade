{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Factory;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  System.IOUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  Logger.Intf,
  Logger.Types,
  Logger.Config;

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
    class var FConfig: TLoggerConfig;
    class var FConfigLoaded: Boolean;

    class constructor Create;
    class destructor Destroy;

    class function CreateDefaultLoggerChain(const AName: string): ILogger; static;
    class function GetDefaultLogger: ILogger; static;
    class function GetDefaultNamedLogger(const AName: string): ILogger; static;
    class procedure LoadConfigIfNeeded; static;
    class function FindConfigFile: string; static;
    class function IsDebuggerAttached: Boolean; static;
    class function IsConsoleApplication: Boolean; static;
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

    /// <summary>
    /// Loads logger configuration from a .properties file.
    /// If no file is specified, automatically loads based on build configuration:
    /// - DEBUG: logging-debug.properties
    /// - RELEASE: logging.properties
    /// Thread-safe.
    /// </summary>
    /// <param name="AFileName">Optional config file path</param>
    class procedure LoadConfig(const AFileName: string = ''); static;

    /// <summary>
    /// Reloads the current configuration file.
    /// Thread-safe.
    /// </summary>
    class procedure ReloadConfig; static;

    /// <summary>
    /// Sets a logger level at runtime.
    /// Supports exact names ('mqtt.transport') and wildcards ('mqtt.*').
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name or pattern</param>
    /// <param name="ALevel">Log level to set</param>
    class procedure SetLoggerLevel(const ALoggerName: string; ALevel: TLogLevel); static;

    /// <summary>
    /// Gets the configured level for a logger name.
    /// Uses hierarchical resolution (most specific rule wins).
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name</param>
    /// <param name="ADefaultLevel">Default if no rule matches</param>
    class function GetConfiguredLevel(const ALoggerName: string;
                                       ADefaultLevel: TLogLevel = llInfo): TLogLevel; static;

    /// <summary>
    /// Clears all logger configuration.
    /// Thread-safe.
    /// </summary>
    class procedure ClearConfig; static;

    /// <summary>
    /// Checks if a logger instance has already been created.
    /// Returns false if no logger exists yet (without creating one).
    /// Thread-safe.
    /// </summary>
    class function HasLogger: Boolean; static;

    /// <summary>
    /// Adds a logger to the composite logger for the specified name.
    /// If the logger is already registered, it will not be added again.
    /// Creates the composite logger if it doesn't exist yet.
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name (empty string for root logger)</param>
    /// <param name="ALogger">Logger instance to add</param>
    /// <returns>The composite logger instance</returns>
    class function AddLogger(const ALoggerName: string; ALogger: ILogger): ILogger; static;

    /// <summary>
    /// Removes a logger from the composite logger for the specified name.
    /// The logger will be released if no other references exist.
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name (empty string for root logger)</param>
    /// <param name="ALogger">Logger instance to remove</param>
    class procedure RemoveLogger(const ALoggerName: string; ALogger: ILogger); static;
  end;

  /// <summary>
  /// Convenience function to get the global logger.
  /// Equivalent to TLoggerFactory.GetLogger.
  /// </summary>
  function Log: ILogger;

implementation

uses
  Logger.Console,
  Logger.Null,
  Logger.Debug,
  Logger.StackTrace;

{ TLoggerFactory }

class constructor TLoggerFactory.Create;
begin
  FLock := TCriticalSection.Create;
  FNamedLoggers := TDictionary<string, ILogger>.Create;
  FConfig := TLoggerConfig.Create;
  FRootLogger := nil;
  FFactoryFunc := nil;
  FNamedFactoryFunc := nil;
  FLoggerNameWidth := 40; // Default width inspired by Spring Boot
  FConfigLoaded := False;
end;

class destructor TLoggerFactory.Destroy;
begin
  FreeAndNil(FConfig);
  FreeAndNil(FNamedLoggers);
  FreeAndNil(FLock);
  FRootLogger := nil;
  FFactoryFunc := nil;
  FNamedFactoryFunc := nil;
end;

class function TLoggerFactory.FindConfigFile: string;
var
  LConfigName: string;
  LSearchPaths: TArray<string>;
  LPath: string;
begin
  // Determine config file name based on build configuration
  {$IFDEF DEBUG}
  LConfigName := 'logging-debug.properties';
  {$ELSE}
  LConfigName := 'logging.properties';
  {$ENDIF}

  // Search in multiple locations
  LSearchPaths := [
    // Current directory
    TPath.Combine(TDirectory.GetCurrentDirectory, LConfigName),
    // Executable directory
    TPath.Combine(ExtractFilePath(ParamStr(0)), LConfigName),
    // Parent directory
    TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)), '..'), LConfigName)
  ];

  for LPath in LSearchPaths do
  begin
    if TFile.Exists(LPath) then
      Exit(LPath);
  end;

  // Not found
  Result := '';
end;

class procedure TLoggerFactory.LoadConfigIfNeeded;
var
  LConfigFile: string;
begin
  if FConfigLoaded then
    Exit;

  FLock.Enter;
  try
    if FConfigLoaded then
      Exit;

    LConfigFile := FindConfigFile;
    if LConfigFile <> '' then
    begin
      try
        FConfig.LoadFromFile(LConfigFile);
      except
        // Silently ignore config file errors, use defaults
      end;
    end;

    FConfigLoaded := True;
  finally
    FLock.Leave;
  end;
end;

class function TLoggerFactory.IsDebuggerAttached: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := IsDebuggerPresent;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

class function TLoggerFactory.IsConsoleApplication: Boolean;
{$IFDEF MSWINDOWS}
var
  ModuleHandle: HMODULE;
  DosHeader: PImageDosHeader;
  NtHeaders: PImageNtHeaders;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  // Check if the executable subsystem is console
  ModuleHandle := GetModuleHandle(nil);
  if ModuleHandle <> 0 then
  begin
    DosHeader := PImageDosHeader(ModuleHandle);
    if (DosHeader.e_magic = IMAGE_DOS_SIGNATURE) then
    begin
      NtHeaders := PImageNtHeaders(NativeUInt(DosHeader) + NativeUInt(DosHeader._lfanew));
      if (NtHeaders.Signature = IMAGE_NT_SIGNATURE) then
      begin
        Result := NtHeaders.OptionalHeader.Subsystem = IMAGE_SUBSYSTEM_WINDOWS_CUI;
        Exit;
      end;
    end;
  end;
  Result := False;
  {$ELSE}
  // For non-Windows, default to False for GUI apps
  Result := False;
  {$ENDIF}
end;

class function TLoggerFactory.CreateDefaultLoggerChain(const AName: string): ILogger;
var
  LLevel: TLogLevel;
  LFirstLogger: ILogger;
begin
  LoadConfigIfNeeded;
  LLevel := FConfig.GetLevelForLogger(AName, llInfo);

  // Create initial logger based on environment
  LFirstLogger := nil;

  // Add TDebugLogger if debugger is attached
  if IsDebuggerAttached then
    LFirstLogger := TDebugLogger.Create(AName, LLevel);

  // Add TConsoleLogger if this is a console application
  if IsConsoleApplication then
  begin
    if LFirstLogger = nil then
      LFirstLogger := TConsoleLogger.Create(AName, LLevel, True)
    else
      LFirstLogger.AddToChain(TConsoleLogger.Create(AName, LLevel, True));
  end;

  // If no logger was created, use a null logger
  if LFirstLogger = nil then
    LFirstLogger := TNullLogger.Create(AName);

  // Auto-enable stack trace if available
  TStackTraceManager.TryEnableIfAvailable;

  Result := LFirstLogger;
end;

class function TLoggerFactory.GetDefaultLogger: ILogger;
begin
  Result := CreateDefaultLoggerChain('');
end;

class function TLoggerFactory.GetDefaultNamedLogger(const AName: string): ILogger;
begin
  Result := CreateDefaultLoggerChain(AName);
end;

class function TLoggerFactory.GetLogger(const AName: string): ILogger;
var
  LFullName: string;
begin
  // Load config on first call
  LoadConfigIfNeeded;

  // Normalize logger name (lowercase, trimmed)
  LFullName := LowerCase(Trim(AName));

  // Fast path for root logger (no name) - no lock needed for read
  if LFullName = '' then
  begin
    if FRootLogger = nil then
    begin
      FLock.Enter;
      try
        if FRootLogger = nil then // Double-check inside lock
        begin
          // Get default logger (already a composite)
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
    if not FNamedLoggers.TryGetValue(LFullName, Result) then
    begin
      // Get default named logger (already a composite)
      if Assigned(FNamedFactoryFunc) then
        Result := FNamedFactoryFunc(LFullName)
      else
        Result := GetDefaultNamedLogger(LFullName);

      FNamedLoggers.Add(LFullName, Result);
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

class procedure TLoggerFactory.LoadConfig(const AFileName: string);
var
  LConfigFile: string;
begin
  FLock.Enter;
  try
    if AFileName <> '' then
      LConfigFile := AFileName
    else
      LConfigFile := FindConfigFile;

    if LConfigFile = '' then
      raise Exception.Create('Configuration file not found');

    FConfig.LoadFromFile(LConfigFile);
    FConfigLoaded := True;

    // Clear logger cache to apply new configuration
    FRootLogger := nil;
    FNamedLoggers.Clear;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.ReloadConfig;
begin
  FLock.Enter;
  try
    FConfig.Reload;

    // Clear logger cache to apply reloaded configuration
    FRootLogger := nil;
    FNamedLoggers.Clear;
  finally
    FLock.Leave;
  end;
end;

class procedure TLoggerFactory.SetLoggerLevel(const ALoggerName: string; ALevel: TLogLevel);
var
  LLogger: ILogger;
  LFullName: string;
begin
  FLock.Enter;
  try
    // Update configuration
    FConfig.SetLoggerLevel(ALoggerName, ALevel);

    // Update existing logger instances if they're already created
    LFullName := LowerCase(Trim(ALoggerName));

    // Update root logger
    if (LFullName = '') and (FRootLogger <> nil) then
      FRootLogger.SetLevel(ALevel);

    // Update named logger if it exists in cache
    if (LFullName <> '') and FNamedLoggers.TryGetValue(LFullName, LLogger) then
      LLogger.SetLevel(ALevel);
  finally
    FLock.Leave;
  end;
end;

class function TLoggerFactory.GetConfiguredLevel(const ALoggerName: string;
                                                   ADefaultLevel: TLogLevel): TLogLevel;
begin
  LoadConfigIfNeeded;
  Result := FConfig.GetLevelForLogger(ALoggerName, ADefaultLevel);
end;

class procedure TLoggerFactory.ClearConfig;
begin
  FLock.Enter;
  try
    FConfig.Clear;
    FConfigLoaded := False;

    // Clear logger cache
    FRootLogger := nil;
    FNamedLoggers.Clear;
  finally
    FLock.Leave;
  end;
end;

class function TLoggerFactory.HasLogger: Boolean;
begin
  Result := FRootLogger <> nil;
end;

class function TLoggerFactory.AddLogger(const ALoggerName: string; ALogger: ILogger): ILogger;
var
  LFullName: string;
  LRootLogger: ILogger;
begin
  if ALogger = nil then
    raise EArgumentNilException.Create('Logger instance cannot be nil');

  // Normalize logger name
  LFullName := LowerCase(Trim(ALoggerName));

  // Get or create the logger
  LRootLogger := GetLogger(LFullName);

  // Add logger to the chain
  Result := LRootLogger.AddToChain(ALogger);
end;

class procedure TLoggerFactory.RemoveLogger(const ALoggerName: string; ALogger: ILogger);
var
  LFullName: string;
  LLogger: ILogger;
begin
  if ALogger = nil then
    Exit;

  // Normalize logger name
  LFullName := LowerCase(Trim(ALoggerName));

  FLock.Enter;
  try
    // Get logger from cache (root or named)
    if LFullName = '' then
      LLogger := FRootLogger
    else
      FNamedLoggers.TryGetValue(LFullName, LLogger);

    // Remove from chain if found
    if LLogger <> nil then
      LLogger.RemoveFromChain(ALogger);
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
