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
  Logger.Types;

type
  /// <summary>
  /// Debug logger implementation that writes only to OutputDebugString.
  /// Perfect for GUI applications (VCL/FMX) when running under a debugger.
  /// Thread-safe for concurrent access. Lightweight with no console dependencies.
  /// </summary>
  TDebugLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FMinLevel: TLogLevel;
    FLock: TCriticalSection;

    procedure LogMessage(ALevel: TLogLevel; const AMessage: string);
    function FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
    function FormatLoggerName: string;
    function IsLevelEnabled(ALevel: TLogLevel): Boolean;
    procedure WriteToDebugOutput(const AMessage: string);
  public
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo);
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
  inherited Create;
  FName := AName;
  FMinLevel := AMinLevel;
  FLock := TCriticalSection.Create;
end;

destructor TDebugLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TDebugLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

function TDebugLogger.FormatLoggerName: string;
var
  NameWidth: Integer;
  TruncatedName: string;
begin
  if FName = '' then
    Exit('');

  NameWidth := 40;

  // If name is longer than width, truncate and add ellipsis
  if Length(FName) > NameWidth then
  begin
    TruncatedName := Copy(FName, 1, NameWidth - 3) + '...';
    Result := Format('[%s] ', [TruncatedName]);
  end
  else
  begin
    // Right-align the name within the specified width
    Result := Format('[%*s] ', [NameWidth, FName]);
  end;
end;

function TDebugLogger.FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
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

procedure TDebugLogger.LogMessage(ALevel: TLogLevel; const AMessage: string);
var
  FormattedMessage: string;
begin
  if not IsLevelEnabled(ALevel) then
    Exit;

  FLock.Enter;
  try
    FormattedMessage := FormatMessage(ALevel, AMessage);
    WriteToDebugOutput(FormattedMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TDebugLogger.Trace(const AMessage: string);
begin
  LogMessage(llTrace, AMessage);
end;

procedure TDebugLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llTrace, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Trace(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llTrace, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llTrace, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Debug(const AMessage: string);
begin
  LogMessage(llDebug, AMessage);
end;

procedure TDebugLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llDebug, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Debug(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llDebug, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llDebug, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Info(const AMessage: string);
begin
  LogMessage(llInfo, AMessage);
end;

procedure TDebugLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llInfo, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Info(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llInfo, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llInfo, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Warn(const AMessage: string);
begin
  LogMessage(llWarn, AMessage);
end;

procedure TDebugLogger.Warn(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llWarn, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Warn(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llWarn, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llWarn, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Error(const AMessage: string);
begin
  LogMessage(llError, AMessage);
end;

procedure TDebugLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llError, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Error(const AMessage: string; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llError, TStackTraceManager.FormatExceptionMessage(AMessage, AException))
  else
    LogMessage(llError, AMessage);
end;

procedure TDebugLogger.Error(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llError, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llError, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Fatal(const AMessage: string);
begin
  LogMessage(llFatal, AMessage);
end;

procedure TDebugLogger.Fatal(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llFatal, Format(AMessage, AArgs));
end;

procedure TDebugLogger.Fatal(const AMessage: string; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llFatal, TStackTraceManager.FormatExceptionMessage(AMessage, AException))
  else
    LogMessage(llFatal, AMessage);
end;

procedure TDebugLogger.Fatal(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llFatal, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llFatal, Format(AMessage, AArgs));
end;

function TDebugLogger.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(llTrace);
end;

function TDebugLogger.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(llDebug);
end;

function TDebugLogger.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(llInfo);
end;

function TDebugLogger.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(llWarn);
end;

function TDebugLogger.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(llError);
end;

function TDebugLogger.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(llFatal);
end;

procedure TDebugLogger.SetLevel(ALevel: TLogLevel);
begin
  FLock.Enter;
  try
    FMinLevel := ALevel;
  finally
    FLock.Leave;
  end;
end;

function TDebugLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

function TDebugLogger.GetName: string;
begin
  Result := FName;
end;

end.
