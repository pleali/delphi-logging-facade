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
  Logger.Types,
  Logger.Base;

type
  /// <summary>
  /// Logger implementation that synchronizes all log events to the main thread.
  /// Uses TThread.Queue for non-blocking asynchronous delivery to main thread.
  /// Provides event-driven logging for VCL/FMX applications.
  /// Thread-safe for concurrent access from multiple threads.
  /// Inherits from TBaseLogger for Chain of Responsibility support.
  /// </summary>
  TMainThreadLogger = class(TBaseLogger)
  private
    FLock: TCriticalSection;
    FOnTrace: TLogEvent;
    FOnDebug: TLogEvent;
    FOnInfo: TLogEvent;
    FOnWarn: TLogEvent;
    FOnError: TLogEvent;
    FOnFatal: TLogEvent;
    FOnMessage: TLogEvent;

    procedure DoFireEvent(const EventData: TLogEventData);
    procedure QueueEvent(const EventData: TLogEventData);
  protected
    /// <summary>
    /// Implements main thread event firing via queue.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string); override;
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
  inherited Create(AName, AMinLevel);
  FLock := TCriticalSection.Create;
end;

destructor TMainThreadLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TMainThreadLogger.DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string);
var
  EventData: TLogEventData;
begin
  EventData := TLogEventData.Create(ALevel, AMessage);
  QueueEvent(EventData);
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

end.
