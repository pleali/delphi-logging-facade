unit Logger.Types;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

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

implementation

uses
  System.SysUtils;

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

end.
