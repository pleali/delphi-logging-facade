{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.MainThread;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  Logger.Intf,
  Logger.Types;

type
  /// <summary>
  /// Logger implementation that synchronizes all log events to the main thread.
  /// Uses TThread.Queue for non-blocking asynchronous delivery to main thread.
  /// Provides event-driven logging for VCL/FMX applications.
  /// Thread-safe for concurrent access from multiple threads.
  /// </summary>
  TMainThreadLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FMinLevel: TLogLevel;
    FLock: TCriticalSection;
    FOnTrace: TLogEvent;
    FOnDebug: TLogEvent;
    FOnInfo: TLogEvent;
    FOnWarn: TLogEvent;
    FOnError: TLogEvent;
    FOnFatal: TLogEvent;
    FOnMessage: TLogEvent;

    function IsLevelEnabled(ALevel: TLogLevel): Boolean;
    procedure DoFireEvent(const EventData: TLogEventData);
    procedure QueueEvent(const EventData: TLogEventData);
  public
    /// <summary>
    /// Creates a new main thread logger with the specified name and minimum log level.
    /// </summary>
    /// <param name="AName">The name of the logger (can be empty for root logger)</param>
    /// <param name="AMinLevel">The minimum log level (default: llTrace)</param>
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llTrace);

    /// <summary>
    /// Destroys the logger and releases resources.
    /// </summary>
    destructor Destroy; override;

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

    // Event properties
    property OnTrace: TLogEvent read FOnTrace write FOnTrace;
    property OnDebug: TLogEvent read FOnDebug write FOnDebug;
    property OnInfo: TLogEvent read FOnInfo write FOnInfo;
    property OnWarn: TLogEvent read FOnWarn write FOnWarn;
    property OnError: TLogEvent read FOnError write FOnError;
    property OnFatal: TLogEvent read FOnFatal write FOnFatal;
    property OnMessage: TLogEvent read FOnMessage write FOnMessage;
  end;

implementation

{ TMainThreadLogger }

constructor TMainThreadLogger.Create(const AName: string; AMinLevel: TLogLevel);
begin
  inherited Create;
  FName := AName;
  FMinLevel := AMinLevel;
  FLock := TCriticalSection.Create;
end;

destructor TMainThreadLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TMainThreadLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TMainThreadLogger.QueueEvent(const EventData: TLogEventData);
begin
  // Queue event to main thread asynchronously
  TThread.Queue(nil,
    procedure
    begin
      DoFireEvent(EventData);
    end);
end;

procedure TMainThreadLogger.DoFireEvent(const EventData: TLogEventData);
var
  Handler: TLogEvent;
begin
  FLock.Enter;
  try
    // Select the appropriate event handler
    Handler := nil;

    case EventData.Level of
      llTrace: Handler := FOnTrace;
      llDebug: Handler := FOnDebug;
      llInfo:  Handler := FOnInfo;
      llWarn:  Handler := FOnWarn;
      llError: Handler := FOnError;
      llFatal: Handler := FOnFatal;
    end;

    // If specific handler not assigned, fall back to OnMessage
    if not Assigned(Handler) then
      Handler := FOnMessage;
  finally
    FLock.Leave;
  end;

  // Fire the event if assigned (outside lock to prevent deadlocks)
  if Assigned(Handler) then
  begin
    try
      Handler(Self, EventData);
    except
      // Silently catch exceptions in event handlers to prevent crashes
    end;
  end;
end;

// Trace methods

procedure TMainThreadLogger.Trace(const AMessage: string);
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  QueueEvent(TLogEventData.Create(llTrace, AMessage));
end;

procedure TMainThreadLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  QueueEvent(TLogEventData.Create(llTrace, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Trace(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llTrace) then
    Exit;

  QueueEvent(TLogEventData.Create(llTrace, Format(AMessage, AArgs), AException));
end;

// Debug methods

procedure TMainThreadLogger.Debug(const AMessage: string);
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  QueueEvent(TLogEventData.Create(llDebug, AMessage));
end;

procedure TMainThreadLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  QueueEvent(TLogEventData.Create(llDebug, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Debug(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llDebug) then
    Exit;

  QueueEvent(TLogEventData.Create(llDebug, Format(AMessage, AArgs), AException));
end;

// Info methods

procedure TMainThreadLogger.Info(const AMessage: string);
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  QueueEvent(TLogEventData.Create(llInfo, AMessage));
end;

procedure TMainThreadLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  QueueEvent(TLogEventData.Create(llInfo, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Info(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llInfo) then
    Exit;

  QueueEvent(TLogEventData.Create(llInfo, Format(AMessage, AArgs), AException));
end;

// Warn methods

procedure TMainThreadLogger.Warn(const AMessage: string);
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  QueueEvent(TLogEventData.Create(llWarn, AMessage));
end;

procedure TMainThreadLogger.Warn(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  QueueEvent(TLogEventData.Create(llWarn, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Warn(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llWarn) then
    Exit;

  QueueEvent(TLogEventData.Create(llWarn, Format(AMessage, AArgs), AException));
end;

// Error methods

procedure TMainThreadLogger.Error(const AMessage: string);
begin
  if not IsLevelEnabled(llError) then
    Exit;

  QueueEvent(TLogEventData.Create(llError, AMessage));
end;

procedure TMainThreadLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llError) then
    Exit;

  QueueEvent(TLogEventData.Create(llError, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Error(const AMessage: string; AException: Exception);
begin
  if not IsLevelEnabled(llError) then
    Exit;

  QueueEvent(TLogEventData.Create(llError, AMessage, AException));
end;

procedure TMainThreadLogger.Error(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llError) then
    Exit;

  QueueEvent(TLogEventData.Create(llError, Format(AMessage, AArgs), AException));
end;

// Fatal methods

procedure TMainThreadLogger.Fatal(const AMessage: string);
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  QueueEvent(TLogEventData.Create(llFatal, AMessage));
end;

procedure TMainThreadLogger.Fatal(const AMessage: string; const AArgs: array of const);
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  QueueEvent(TLogEventData.Create(llFatal, Format(AMessage, AArgs)));
end;

procedure TMainThreadLogger.Fatal(const AMessage: string; AException: Exception);
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  QueueEvent(TLogEventData.Create(llFatal, AMessage, AException));
end;

procedure TMainThreadLogger.Fatal(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if not IsLevelEnabled(llFatal) then
    Exit;

  QueueEvent(TLogEventData.Create(llFatal, Format(AMessage, AArgs), AException));
end;

// Level checking methods

function TMainThreadLogger.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(llTrace);
end;

function TMainThreadLogger.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(llDebug);
end;

function TMainThreadLogger.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(llInfo);
end;

function TMainThreadLogger.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(llWarn);
end;

function TMainThreadLogger.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(llError);
end;

function TMainThreadLogger.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(llFatal);
end;

// Configuration methods

procedure TMainThreadLogger.SetLevel(ALevel: TLogLevel);
begin
  FLock.Enter;
  try
    FMinLevel := ALevel;
  finally
    FLock.Leave;
  end;
end;

function TMainThreadLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

function TMainThreadLogger.GetName: string;
begin
  Result := FName;
end;

end.
