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
  Logger.Types;

type
  /// <summary>
  /// Record containing log event data passed to event handlers.
  /// </summary>
  TLogEventData = record
    Level: TLogLevel;
    Message: string;
    TimeStamp: TDateTime;
    ThreadId: TThreadID;
    ExceptionMessage: string;
    ExceptionClass: string;

    constructor Create(ALevel: TLogLevel; const AMessage: string;
      AException: Exception = nil);
  end;

  /// <summary>
  /// Event handler type for log events.
  /// </summary>
  TLogEvent = procedure(Sender: TObject; const EventData: TLogEventData) of object;

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
    FAsyncEvents: Boolean;
    FLoggerName: string;

    procedure DoFireEvent(const EventData: TLogEventData);
    procedure SyncFireEvent(const EventData: TLogEventData);
  protected
    /// <summary>
    /// Fires the appropriate event based on log level.
    /// Falls back to OnMessage if specific event is not assigned.
    /// </summary>
    procedure FireEvent(const EventData: TLogEventData);
  public
    constructor Create(AOwner: TComponent); override;

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
    /// If True, events are fired asynchronously using TThread.Queue (non-blocking).
    /// If False, events are fired synchronously using TThread.Synchronize (blocking).
    /// Default: True.
    /// </summary>
    property AsyncEvents: Boolean read FAsyncEvents write FAsyncEvents default True;

    /// <summary>
    /// Logger name for identification purposes.
    /// </summary>
    property LoggerName: string read FLoggerName write FLoggerName;
  end;

implementation

uses
  System.SyncObjs;

{ TLogEventData }

constructor TLogEventData.Create(ALevel: TLogLevel; const AMessage: string;
  AException: Exception);
begin
  Level := ALevel;
  Message := AMessage;
  TimeStamp := Now;
  ThreadId := TThread.Current.ThreadID;

  if Assigned(AException) then
  begin
    ExceptionMessage := AException.Message;
    ExceptionClass := AException.ClassName;
  end
  else
  begin
    ExceptionMessage := '';
    ExceptionClass := '';
  end;
end;

{ TLoggerComponent }

constructor TLoggerComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinLevel := llTrace;
  FAsyncEvents := True;
  FLoggerName := '';
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
  if FAsyncEvents then
  begin
    // Non-blocking: queue event to main thread
    TThread.Queue(nil,
      procedure
      begin
        DoFireEvent(EventData);
      end);
  end
  else
  begin
    // Blocking: synchronize with main thread
    SyncFireEvent(EventData);
  end;
end;

procedure TLoggerComponent.SyncFireEvent(const EventData: TLogEventData);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      DoFireEvent(EventData);
    end);
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
