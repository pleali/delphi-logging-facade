{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Base;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Logger.Intf,
  Logger.Types,
  Logger.StackTrace,
  Logger.Factory;

type
  /// <summary>
  /// Abstract base class for all loggers implementing the Chain of Responsibility pattern.
  /// Each logger can have a "next" logger in the chain, allowing dynamic composition
  /// of logging destinations without the need for a separate composite class.
  ///
  /// This design provides:
  /// - Zero overhead for single loggers (no list management)
  /// - Dynamic extensibility (can always add more loggers to the chain)
  /// - Simple implementation (no separate composite class needed)
  /// - Thread-safe chain modifications
  ///
  /// Example usage:
  /// <code>
  ///   Logger1 := TConsoleLogger.Create('App');
  ///   Logger2 := TFileLogger.Create('app.log');
  ///   Logger1.AddToChain(Logger2);  // Now logs to both console and file
  /// </code>
  /// </summary>
  TBaseLogger = class abstract(TInterfacedObject, ILogger)
  private
    FNext: ILogger;
    FName: string;
    FMinLevel: TLogLevel;
    FChainLock: TCriticalSection;

    function IsLevelEnabled(ALevel: TLogLevel): Boolean; inline;
  protected
    /// <summary>
    /// Abstract method that derived classes must implement to perform actual logging.
    /// Called only when the message level is enabled.
    /// </summary>
    procedure DoLog(ALevel: TLogLevel; const AMessage: string); virtual; abstract;

    /// <summary>
    /// Format a message with optional exception information.
    /// </summary>
    function FormatMessage(const AMessage: string; AException: Exception = nil): string;

    /// <summary>
    /// Log to this logger and propagate to next in chain.
    /// </summary>
    procedure LogMessage(ALevel: TLogLevel; const AMessage: string); overload;
    procedure LogMessage(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const); overload;
    procedure LogMessage(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const; AException: Exception); overload;
  public
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo);
    destructor Destroy; override;

    // ILogger implementation - Logging methods
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;
    procedure Trace(const AMessage: string; AException: Exception); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    procedure Debug(const AMessage: string; AException: Exception); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    procedure Info(const AMessage: string; AException: Exception); overload;
    procedure Info(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;
    procedure Warn(const AMessage: string; AException: Exception); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;
    procedure Error(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    // ILogger implementation - Level checking
    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    // ILogger implementation - Configuration
    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
    function GetName: string;

    // Chain of Responsibility methods
    function GetNext: ILogger;
    procedure SetNext(ALogger: ILogger);
    function AddToChain(ALogger: ILogger): ILogger;
    function RemoveFromChain(ALogger: ILogger): Boolean;
    function GetChainCount: Integer;
    procedure ClearChain;
  end;

implementation

{ TBaseLogger }

constructor TBaseLogger.Create(const AName: string; AMinLevel: TLogLevel);
begin
  inherited Create;
  FName := AName;
  FMinLevel := AMinLevel;
  FNext := nil;
  FChainLock := TCriticalSection.Create;
end;

destructor TBaseLogger.Destroy;
begin
  FChainLock.Free;
  FNext := nil;
  inherited;
end;

function TBaseLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

function TBaseLogger.FormatMessage(const AMessage: string; AException: Exception): string;
begin
  if Assigned(AException) then
    Result := TStackTraceManager.FormatExceptionMessage(AMessage, AException)
  else
    Result := AMessage;
end;

procedure TBaseLogger.LogMessage(ALevel: TLogLevel; const AMessage: string);
begin
  // Opportunistic config check before logging
  TLoggerFactory.CheckConfigReload;

  // Log locally if level is enabled
  if IsLevelEnabled(ALevel) then
    DoLog(ALevel, AMessage);

  // Propagate to next logger in chain
  if FNext <> nil then
  begin
    case ALevel of
      llTrace: FNext.Trace(AMessage);
      llDebug: FNext.Debug(AMessage);
      llInfo:  FNext.Info(AMessage);
      llWarn:  FNext.Warn(AMessage);
      llError: FNext.Error(AMessage);
      llFatal: FNext.Fatal(AMessage);
    end;
  end;
end;

procedure TBaseLogger.LogMessage(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const);
begin
  LogMessage(ALevel, Format(AMessage, AArgs));
end;

procedure TBaseLogger.LogMessage(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const; AException: Exception);
var
  FormattedMsg: string;
begin
  FormattedMsg := Format(AMessage, AArgs);
  LogMessage(ALevel, FormatMessage(FormattedMsg, AException));
end;

// Trace methods
procedure TBaseLogger.Trace(const AMessage: string);
begin
  LogMessage(llTrace, AMessage);
end;

procedure TBaseLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llTrace, AMessage, AArgs);
end;

procedure TBaseLogger.Trace(const AMessage: string; AException: Exception);
begin
  LogMessage(llTrace, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Trace(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llTrace, AMessage, AArgs, AException);
end;

// Debug methods
procedure TBaseLogger.Debug(const AMessage: string);
begin
  LogMessage(llDebug, AMessage);
end;

procedure TBaseLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llDebug, AMessage, AArgs);
end;

procedure TBaseLogger.Debug(const AMessage: string; AException: Exception);
begin
  LogMessage(llDebug, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Debug(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llDebug, AMessage, AArgs, AException);
end;

// Info methods
procedure TBaseLogger.Info(const AMessage: string);
begin
  LogMessage(llInfo, AMessage);
end;

procedure TBaseLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llInfo, AMessage, AArgs);
end;

procedure TBaseLogger.Info(const AMessage: string; AException: Exception);
begin
  LogMessage(llInfo, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Info(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llInfo, AMessage, AArgs, AException);
end;

// Warn methods
procedure TBaseLogger.Warn(const AMessage: string);
begin
  LogMessage(llWarn, AMessage);
end;

procedure TBaseLogger.Warn(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llWarn, AMessage, AArgs);
end;

procedure TBaseLogger.Warn(const AMessage: string; AException: Exception);
begin
  LogMessage(llWarn, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Warn(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llWarn, AMessage, AArgs, AException);
end;

// Error methods
procedure TBaseLogger.Error(const AMessage: string);
begin
  LogMessage(llError, AMessage);
end;

procedure TBaseLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llError, AMessage, AArgs);
end;

procedure TBaseLogger.Error(const AMessage: string; AException: Exception);
begin
  LogMessage(llError, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Error(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llError, AMessage, AArgs, AException);
end;

// Fatal methods
procedure TBaseLogger.Fatal(const AMessage: string);
begin
  LogMessage(llFatal, AMessage);
end;

procedure TBaseLogger.Fatal(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llFatal, AMessage, AArgs);
end;

procedure TBaseLogger.Fatal(const AMessage: string; AException: Exception);
begin
  LogMessage(llFatal, FormatMessage(AMessage, AException));
end;

procedure TBaseLogger.Fatal(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  LogMessage(llFatal, AMessage, AArgs, AException);
end;

// Level checking methods
function TBaseLogger.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(llTrace);
end;

function TBaseLogger.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(llDebug);
end;

function TBaseLogger.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(llInfo);
end;

function TBaseLogger.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(llWarn);
end;

function TBaseLogger.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(llError);
end;

function TBaseLogger.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(llFatal);
end;

// Configuration methods
procedure TBaseLogger.SetLevel(ALevel: TLogLevel);
begin
  FChainLock.Enter;
  try
    FMinLevel := ALevel;
  finally
    FChainLock.Leave;
  end;
end;

function TBaseLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

function TBaseLogger.GetName: string;
begin
  Result := FName;
end;

// Chain of Responsibility methods
function TBaseLogger.GetNext: ILogger;
begin
  FChainLock.Enter;
  try
    Result := FNext;
  finally
    FChainLock.Leave;
  end;
end;

procedure TBaseLogger.SetNext(ALogger: ILogger);
begin
  FChainLock.Enter;
  try
    FNext := ALogger;
  finally
    FChainLock.Leave;
  end;
end;

function TBaseLogger.AddToChain(ALogger: ILogger): ILogger;
var
  Current: ILogger;
  NextLogger: ILogger;
begin
  if ALogger = nil then
    Exit(nil);

  FChainLock.Enter;
  try
    // Check if logger is already in chain (prevent cycles)
    Current := Self;
    while Current <> nil do
    begin
      if Current = ALogger then
        Exit(ALogger); // Already in chain, don't add again
      NextLogger := Current.GetNext;
      if NextLogger = nil then
        Break;
      Current := NextLogger;
    end;

    // Add to end of chain
    if Current <> nil then
      Current.SetNext(ALogger);

    Result := ALogger;
  finally
    FChainLock.Leave;
  end;
end;

function TBaseLogger.RemoveFromChain(ALogger: ILogger): Boolean;
var
  Current: ILogger;
  NextLogger: ILogger;
begin
  Result := False;
  if ALogger = nil then
    Exit;

  FChainLock.Enter;
  try
    // Check if it's the immediate next logger
    if FNext = ALogger then
    begin
      // Skip over the logger being removed
      FNext := ALogger.GetNext;
      ALogger.SetNext(nil);
      Result := True;
      Exit;
    end;

    // Search the chain
    Current := FNext;
    while Current <> nil do
    begin
      NextLogger := Current.GetNext;
      if NextLogger = ALogger then
      begin
        // Found it - remove from chain
        Current.SetNext(ALogger.GetNext);
        ALogger.SetNext(nil);
        Result := True;
        Break;
      end;
      Current := NextLogger;
    end;
  finally
    FChainLock.Leave;
  end;
end;

function TBaseLogger.GetChainCount: Integer;
var
  Current: ILogger;
begin
  Result := 1; // Count self

  FChainLock.Enter;
  try
    Current := FNext;
    while Current <> nil do
    begin
      Inc(Result);
      Current := Current.GetNext;
    end;
  finally
    FChainLock.Leave;
  end;
end;

procedure TBaseLogger.ClearChain;
begin
  FChainLock.Enter;
  try
    FNext := nil;
  finally
    FChainLock.Leave;
  end;
end;

end.