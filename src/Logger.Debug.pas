{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Debug;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Logger.Intf,
  Logger.Types,
  Logger.Base;

type
  /// <summary>
  /// Debug logger implementation that writes only to OutputDebugString.
  /// Perfect for GUI applications (VCL/FMX) when running under a debugger.
  /// Thread-safe for concurrent access. Lightweight with no console dependencies.
  /// Now inherits from TBaseLogger for Chain of Responsibility support.
  /// </summary>
  TDebugLogger = class(TBaseLogger)
  private
    FDebugLock: TCriticalSection;

    function FormatLogMessage(ALevel: TLogLevel; const AMessage: string): string;
    function FormatLoggerName: string;
    procedure WriteToDebugOutput(const AMessage: string);
  protected
    /// <summary>
    /// Implements the actual debug output via OutputDebugString.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: TLogLevel; const AMessage: string); override;
  public
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo);
    destructor Destroy; override;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.DateUtils,
  Logger.StackTrace;

{ TDebugLogger }

constructor TDebugLogger.Create(const AName: string; AMinLevel: TLogLevel);
begin
  inherited Create(AName, AMinLevel);
  FDebugLock := TCriticalSection.Create;
end;

destructor TDebugLogger.Destroy;
begin
  FDebugLock.Free;
  inherited;
end;

function TDebugLogger.FormatLoggerName: string;
var
  NameWidth: Integer;
  TruncatedName: string;
begin
  if GetName = '' then
    Exit('');

  NameWidth := 40;

  // If name is longer than width, truncate and add ellipsis
  if Length(GetName) > NameWidth then
  begin
    TruncatedName := Copy(GetName, 1, NameWidth - 3) + '...';
    Result := Format('[%s] ', [TruncatedName]);
  end
  else
  begin
    // Right-align the name within the specified width
    Result := Format('[%*s] ', [NameWidth, GetName]);
  end;
end;

function TDebugLogger.FormatLogMessage(ALevel: TLogLevel; const AMessage: string): string;
var
  LoggerNamePart: string;
begin
  LoggerNamePart := FormatLoggerName;

  if LoggerNamePart <> '' then
    Result := Format('%s %-5s %s: %s',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
       ALevel.ToString,
       LoggerNamePart,
       AMessage])
  else
    Result := Format('%s %-5s : %s',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
       ALevel.ToString,
       AMessage]);
end;

procedure TDebugLogger.WriteToDebugOutput(const AMessage: string);
begin
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar(AMessage));
  {$ENDIF}
  // For non-Windows platforms, could use platform-specific debug output
  // For now, Windows-only
end;

procedure TDebugLogger.DoLog(ALevel: TLogLevel; const AMessage: string);
var
  FormattedMessage: string;
begin
  FDebugLock.Enter;
  try
    FormattedMessage := FormatLogMessage(ALevel, AMessage);
    WriteToDebugOutput(FormattedMessage);
  finally
    FDebugLock.Leave;
  end;
end;

end.
