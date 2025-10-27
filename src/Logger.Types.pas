{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Types;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Classes,
  System.SysUtils;

type
  /// <summary>
  /// Enumeration of logging levels, ordered from most verbose to most severe.
  /// </summary>
  TLogLevel = (
    llTrace,   // Most verbose level - detailed trace information
    llDebug,   // Debug information for developers
    llInfo,    // General informational messages
    llWarn,    // Warning messages - potentially harmful situations
    llError,   // Error messages - error events that might still allow the app to continue
    llFatal    // Fatal messages - severe error events that will lead the app to abort
  );

  /// <summary>
  /// Helper record for TLogLevel to provide utility methods.
  /// </summary>
  TLogLevelHelper = record helper for TLogLevel
    /// <summary>
    /// Converts log level to string representation.
    /// </summary>
    function ToString: string;

    /// <summary>
    /// Converts string to log level.
    /// </summary>
    class function FromString(const AValue: string): TLogLevel; static;
  end;

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

implementation

{ TLogLevelHelper }

function TLogLevelHelper.ToString: string;
begin
  case Self of
    llTrace: Result := 'TRACE';
    llDebug: Result := 'DEBUG';
    llInfo:  Result := 'INFO';
    llWarn:  Result := 'WARN';
    llError: Result := 'ERROR';
    llFatal: Result := 'FATAL';
  else
    Result := 'UNKNOWN';
  end;
end;

class function TLogLevelHelper.FromString(const AValue: string): TLogLevel;
var
  LUpperValue: string;
begin
  LUpperValue := UpperCase(AValue);

  if LUpperValue = 'TRACE' then
    Result := llTrace
  else if LUpperValue = 'DEBUG' then
    Result := llDebug
  else if LUpperValue = 'INFO' then
    Result := llInfo
  else if LUpperValue = 'WARN' then
    Result := llWarn
  else if LUpperValue = 'ERROR' then
    Result := llError
  else if LUpperValue = 'FATAL' then
    Result := llFatal
  else
    Result := llInfo; // Default to Info if unknown
end;

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

end.
