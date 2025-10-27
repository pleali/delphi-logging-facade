{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Component;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Classes,
  System.SysUtils,
  Logger.Types,
  Logger.Intf;

type
  /// <summary>
  /// Non-visual component that exposes logging through events.
  /// Events are synchronized with the main thread using TThread.Queue for non-blocking behavior.
  /// Falls back to OnMessage when specific level events are not assigned.
  /// </summary>
  TLoggerComponent = class(TComponent)
  private
    FOnTrace: TLogEvent;
    FOnDebug: TLogEvent;
    FOnInfo: TLogEvent;
    FOnWarn: TLogEvent;
    FOnError: TLogEvent;
    FOnFatal: TLogEvent;
    FOnMessage: TLogEvent;
    FMinLevel: TLogLevel;
    FLoggerName: string;
    FActive: Boolean;
    FMainThreadLogger: ILogger;

    procedure DoFireEvent(const EventData: TLogEventData);
    procedure SetActive(const Value: Boolean);
    procedure AttachMainThreadLoggerEvents;
    procedure DetachMainThreadLogger;
  protected
    /// <summary>
    /// Fires the appropriate event based on log level.
    /// Falls back to OnMessage if specific event is not assigned.
    /// </summary>
    procedure FireEvent(const EventData: TLogEventData);
  public
    constructor Create(AOwner: TComponent); override;

    /// <summary>
    /// Destroys the component and automatically unregisters from factory if active.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Logs a message at the specified level.
    /// </summary>
    procedure Log(ALevel: TLogLevel; const AMessage: string;
      AException: Exception = nil);

    /// <summary>
    /// Logs a TRACE level message.
    /// </summary>
    procedure Trace(const AMessage: string);

    /// <summary>
    /// Logs a DEBUG level message.
    /// </summary>
    procedure Debug(const AMessage: string);

    /// <summary>
    /// Logs an INFO level message.
    /// </summary>
    procedure Info(const AMessage: string);

    /// <summary>
    /// Logs a WARN level message.
    /// </summary>
    procedure Warn(const AMessage: string);

    /// <summary>
    /// Logs an ERROR level message.
    /// </summary>
    procedure Error(const AMessage: string; AException: Exception = nil);

    /// <summary>
    /// Logs a FATAL level message.
    /// </summary>
    procedure Fatal(const AMessage: string; AException: Exception = nil);
  published
    /// <summary>
    /// Event fired for TRACE level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnTrace: TLogEvent read FOnTrace write FOnTrace;

    /// <summary>
    /// Event fired for DEBUG level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnDebug: TLogEvent read FOnDebug write FOnDebug;

    /// <summary>
    /// Event fired for INFO level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnInfo: TLogEvent read FOnInfo write FOnInfo;

    /// <summary>
    /// Event fired for WARN level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnWarn: TLogEvent read FOnWarn write FOnWarn;

    /// <summary>
    /// Event fired for ERROR level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnError: TLogEvent read FOnError write FOnError;

    /// <summary>
    /// Event fired for FATAL level messages.
    /// If not assigned, falls back to OnMessage.
    /// </summary>
    property OnFatal: TLogEvent read FOnFatal write FOnFatal;

    /// <summary>
    /// Fallback event fired when specific level event is not assigned.
    /// </summary>
    property OnMessage: TLogEvent read FOnMessage write FOnMessage;

    /// <summary>
    /// Minimum log level. Messages below this level are ignored.
    /// Default: llTrace (log everything).
    /// </summary>
    property MinLevel: TLogLevel read FMinLevel write FMinLevel default llTrace;

    /// <summary>
    /// Logger name for identification purposes.
    /// </summary>
    property LoggerName: string read FLoggerName write FLoggerName;

    /// <summary>
    /// When True, creates a main thread logger and registers it with the factory.
    /// When False, unregisters and releases the main thread logger.
    /// Default: False.
    /// </summary>
    property Active: Boolean read FActive write SetActive default False;
  end;

implementation

uses
  System.SyncObjs,
  Logger.Factory,
  Logger.MainThread;

{ TLoggerComponent }

constructor TLoggerComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinLevel := llTrace;
  FLoggerName := '';
  FActive := False;
  FMainThreadLogger := nil;
end;

destructor TLoggerComponent.Destroy;
begin
  // Automatically deactivate to unregister from factory
  if FActive then
    Active := False;
  inherited;
end;

procedure TLoggerComponent.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;

  FActive := Value;

  if FActive then
    AttachMainThreadLoggerEvents
  else
    DetachMainThreadLogger;
end;

procedure TLoggerComponent.AttachMainThreadLoggerEvents;
var
  LMainThreadLogger: TMainThreadLogger;
begin
  if FLoggerName = '' then
    raise Exception.Create('LoggerName must be set before activating the component');

  // Create main thread logger
  LMainThreadLogger := TMainThreadLogger.Create(FLoggerName, FMinLevel);

  // Attach events
  LMainThreadLogger.OnTrace := FOnTrace;
  LMainThreadLogger.OnDebug := FOnDebug;
  LMainThreadLogger.OnInfo := FOnInfo;
  LMainThreadLogger.OnWarn := FOnWarn;
  LMainThreadLogger.OnError := FOnError;
  LMainThreadLogger.OnFatal := FOnFatal;
  LMainThreadLogger.OnMessage := FOnMessage;

  // Store reference
  FMainThreadLogger := LMainThreadLogger;

  // Register with factory
  TLoggerFactory.AddLogger(FLoggerName, FMainThreadLogger);
end;

procedure TLoggerComponent.DetachMainThreadLogger;
begin
  if FMainThreadLogger = nil then
    Exit;

  // Unregister from factory
  TLoggerFactory.RemoveLogger(FLoggerName, FMainThreadLogger);

  // Release reference
  FMainThreadLogger := nil;
end;

procedure TLoggerComponent.Log(ALevel: TLogLevel; const AMessage: string;
  AException: Exception);
var
  EventData: TLogEventData;
begin
  // Check minimum level
  if ALevel < FMinLevel then
    Exit;

  EventData := TLogEventData.Create(ALevel, AMessage, AException);
  FireEvent(EventData);
end;

procedure TLoggerComponent.FireEvent(const EventData: TLogEventData);
begin
  // Fire event directly (no synchronization)
  // If thread synchronization is needed, use TMainThreadLogger via Active property
  DoFireEvent(EventData);
end;

procedure TLoggerComponent.DoFireEvent(const EventData: TLogEventData);
var
  Handler: TLogEvent;
begin
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

  // Fire the event if assigned
  if Assigned(Handler) then
  begin
    try
      Handler(Self, EventData);
    except
      // Silently catch exceptions in event handlers to prevent crashes
      // In a real production scenario, you might want to log this somewhere
    end;
  end;
end;

procedure TLoggerComponent.Trace(const AMessage: string);
begin
  Log(llTrace, AMessage);
end;

procedure TLoggerComponent.Debug(const AMessage: string);
begin
  Log(llDebug, AMessage);
end;

procedure TLoggerComponent.Info(const AMessage: string);
begin
  Log(llInfo, AMessage);
end;

procedure TLoggerComponent.Warn(const AMessage: string);
begin
  Log(llWarn, AMessage);
end;

procedure TLoggerComponent.Error(const AMessage: string; AException: Exception);
begin
  Log(llError, AMessage, AException);
end;

procedure TLoggerComponent.Fatal(const AMessage: string; AException: Exception);
begin
  Log(llFatal, AMessage, AException);
end;

end.
