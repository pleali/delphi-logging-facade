{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Composite;

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
  /// Composite logger implementation that broadcasts log messages to multiple registered loggers.
  /// This implementation follows the Composite design pattern, allowing you to treat
  /// a group of loggers as a single logger.
  ///
  /// Use case: When you need to log to multiple destinations simultaneously
  /// (e.g., console, file, remote service) without coupling your code to specific implementations.
  ///
  /// Thread-safe for concurrent access.
  /// </summary>
  /// <remarks>
  /// Level Management:
  /// The composite logger is the single point of filtering. When loggers are added,
  /// they are automatically set to TRACE level so they don't filter messages.
  /// The composite's SetLevel() only affects the composite itself, not the sub-loggers.
  /// This ensures efficient single-point filtering and consistent behavior.
  ///
  /// Example usage:
  /// <code>
  ///   var
  ///     CompositeLogger: ILogger;
  ///     ConsoleLogger: ILogger;
  ///     FileLogger: ILogger;
  ///   begin
  ///     CompositeLogger := TCompositeLogger.Create('MyApp');
  ///     ConsoleLogger := TConsoleLogger.Create;
  ///     FileLogger := TFileLogger.Create('app.log');
  ///
  ///     TCompositeLogger(CompositeLogger).AddLogger(ConsoleLogger);
  ///     TCompositeLogger(CompositeLogger).AddLogger(FileLogger);
  ///
  ///     // This message will be sent to both console and file
  ///     CompositeLogger.Info('Application started');
  ///   end;
  /// </code>
  /// </remarks>
  TCompositeLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FMinLevel: TLogLevel;
    FLoggers: TList<ILogger>;
    FLock: TCriticalSection;

    function IsLevelEnabled(ALevel: TLogLevel): Boolean;
    procedure ConfigureSubLoggerLevel(ALogger: ILogger);
  public
    /// <summary>
    /// Creates a new composite logger with the specified name and minimum log level.
    /// </summary>
    /// <param name="AName">The name of the logger (can be empty for root logger)</param>
    /// <param name="AMinLevel">The minimum log level (default: llInfo)</param>
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo);

    /// <summary>
    /// Destroys the composite logger and releases all registered loggers.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Adds a logger to the composite. The logger will receive all subsequent log messages.
    /// The logger's level will be automatically set to TRACE to ensure the composite
    /// is the single point of filtering.
    /// </summary>
    /// <param name="ALogger">The logger to add (not const to ensure reference is held)</param>
    /// <remarks>
    /// If the logger is already registered, it will not be added again.
    /// The logger's level is set to TRACE so it doesn't filter messages -
    /// the composite logger handles all filtering.
    /// Note: Parameter is not const to ensure a reference is acquired on entry,
    /// preventing premature destruction during method execution.
    /// </remarks>
    procedure AddLogger(ALogger: ILogger);

    /// <summary>
    /// Removes a logger from the composite. The logger will no longer receive log messages.
    /// </summary>
    /// <param name="ALogger">The logger to remove</param>
    /// <returns>True if the logger was found and removed, False otherwise</returns>
    function RemoveLogger(const ALogger: ILogger): Boolean;

    /// <summary>
    /// Removes all registered loggers from the composite.
    /// </summary>
    procedure ClearLoggers;

    /// <summary>
    /// Returns the number of loggers currently registered.
    /// </summary>
    function GetLoggerCount: Integer;

    // ILogger implementation
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    procedure Info(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;
    procedure Error(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;

    function GetName: string;
  end;

implementation

{ TCompositeLogger }

constructor TCompositeLogger.Create(const AName: string; AMinLevel: TLogLevel);
begin
  inherited Create;
  FName := AName;
  FMinLevel := AMinLevel;
  FLoggers := TList<ILogger>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TCompositeLogger.Destroy;
begin
  FLock.Free;
  FLoggers.Free;
  inherited;
end;

// Note: No const on ALogger parameter - ensures reference is held during method execution
// to prevent premature destruction when calling ConfigureSubLoggerLevel
procedure TCompositeLogger.AddLogger(ALogger: ILogger);
begin
  if ALogger = nil then
    Exit;

  FLock.Enter;
  try
    // Avoid adding the same logger twice
    if not FLoggers.Contains(ALogger) then
    begin
      // Configure sub-logger to not filter messages
      ConfigureSubLoggerLevel(ALogger);
      FLoggers.Add(ALogger);
    end;
  finally
    FLock.Leave;
  end;
end;

function TCompositeLogger.RemoveLogger(const ALogger: ILogger): Boolean;
begin
  if ALogger = nil then
    Exit(False);

  FLock.Enter;
  try
    Result := FLoggers.Remove(ALogger) >= 0;
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.ClearLoggers;
begin
  FLock.Enter;
  try
    FLoggers.Clear;
  finally
    FLock.Leave;
  end;
end;

function TCompositeLogger.GetLoggerCount: Integer;
begin
  FLock.Enter;
  try
    Result := FLoggers.Count;
  finally
    FLock.Leave;
  end;
end;

function TCompositeLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TCompositeLogger.ConfigureSubLoggerLevel(ALogger: ILogger);
begin
  // Set sub-logger to TRACE level so it doesn't filter messages
  // The composite logger is the single point of filtering
  ALogger.SetLevel(llTrace);
end;

procedure TCompositeLogger.Trace(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Trace(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Trace(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Trace(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Trace(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Trace(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Debug(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Debug(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Debug(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Debug(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Debug(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Debug(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Info(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Info(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Info(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Info(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Info(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Info(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Warn(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Warn(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Warn(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Warn(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Warn(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Warn(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Error(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llError) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Error(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Error(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llError) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Error(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Error(const AMessage: string; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llError) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Error(AMessage, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Error(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llError) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Error(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Fatal(const AMessage: string);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Fatal(AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Fatal(const AMessage: string; const AArgs: array of const);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Fatal(AMessage, AArgs);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Fatal(const AMessage: string; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Fatal(AMessage, AException);
  finally
    FLock.Leave;
  end;
end;

procedure TCompositeLogger.Fatal(const AMessage: string; const AArgs: array of const; AException: Exception);
var
  Logger: ILogger;
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  FLock.Enter;
  try
    for Logger in FLoggers do
      Logger.Fatal(AMessage, AArgs, AException);
  finally
    FLock.Leave;
  end;
end;

function TCompositeLogger.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(llTrace);
end;

function TCompositeLogger.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(llDebug);
end;

function TCompositeLogger.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(llInfo);
end;

function TCompositeLogger.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(llWarn);
end;

function TCompositeLogger.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(llError);
end;

function TCompositeLogger.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(llFatal);
end;

procedure TCompositeLogger.SetLevel(ALevel: TLogLevel);
begin
  FLock.Enter;
  try
    FMinLevel := ALevel;
  finally
    FLock.Leave;
  end;
end;

function TCompositeLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

function TCompositeLogger.GetName: string;
begin
  Result := FName;
end;

end.
