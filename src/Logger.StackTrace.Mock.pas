unit Logger.StackTrace.Mock;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.StackTrace;

type
  /// <summary>
  /// Mock stack trace provider for testing without external dependencies.
  /// This provider generates simulated stack traces for testing purposes.
  /// Use this when JCL or other stack trace libraries are not available.
  /// </summary>
  TMockStackTraceProvider = class(TInterfacedObject, IStackTraceProvider)
  public
    /// <summary>
    /// Gets a simulated stack trace for an exception.
    /// </summary>
    function GetStackTrace(AException: Exception): string;

    /// <summary>
    /// Gets a simulated current stack trace.
    /// </summary>
    function GetCurrentStackTrace: string;

    /// <summary>
    /// Mock provider is always available.
    /// </summary>
    function IsAvailable: Boolean;
  end;

implementation

{ TMockStackTraceProvider }

function TMockStackTraceProvider.IsAvailable: Boolean;
begin
  Result := True;
end;

function TMockStackTraceProvider.GetStackTrace(AException: Exception): string;
begin
  // Generate a mock stack trace
  Result := '';

  if AException = nil then
    Exit;

  Result := Format(
    '  [00401234] MockUnit.ThrowException (Line 42)' + sLineBreak +
    '  [00401567] MockUnit.CallFunction (Line 89)' + sLineBreak +
    '  [00401890] MockApp.Execute (Line 156)' + sLineBreak +
    '  [00402123] MockApp.Main (Line 23)',
    []
  );
end;

function TMockStackTraceProvider.GetCurrentStackTrace: string;
begin
  // Generate a mock current stack trace
  Result := Format(
    '  [00501234] TMockStackTraceProvider.GetCurrentStackTrace (Line %d)' + sLineBreak +
    '  [00501567] MockUnit.SomeFunction (Line 78)' + sLineBreak +
    '  [00501890] MockApp.Process (Line 134)',
    [0]  // Line number placeholder
  );
end;

end.
