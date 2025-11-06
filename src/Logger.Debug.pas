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

    function AbbreviateLoggerName(const AName: string; AWidth: Integer): string;
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

function TDebugLogger.AbbreviateLoggerName(const AName: string; AWidth: Integer): string;
var
  Segments: TArray<string>;
  NumSegments, i: Integer;
  ClassName: string;
  AbbreviatedLength: Integer;
  ClassNameMaxLength: Integer;
begin
  // Handle empty names
  if AName = '' then
    Exit('');

  // Split by '.' separator
  Segments := AName.Split(['.']);
  NumSegments := Length(Segments);

  // Single segment (no packages) - just handle length
  if NumSegments = 1 then
  begin
    if Length(AName) > AWidth then
      Exit(Copy(AName, 1, AWidth - 3) + '...')
    else
      Exit(AName);
  end;

  // Extract class name (last segment)
  ClassName := Segments[NumSegments - 1];

  // Calculate length with all packages abbreviated to single character
  // Format: "A.B.C.ClassName" = (NumPackages * 2) + Length(ClassName)
  AbbreviatedLength := (NumSegments - 1) * 2 + Length(ClassName);

  if AbbreviatedLength <= AWidth then
  begin
    // Build abbreviated form: all packages as single char, full class name
    Result := '';
    for i := 0 to NumSegments - 2 do
      Result := Result + Segments[i][1] + '.';
    Result := Result + ClassName;
  end
  else
  begin
    // Even with abbreviated packages, the class name is too long
    // Abbreviate packages and truncate class name
    ClassNameMaxLength := AWidth - ((NumSegments - 1) * 2);

    Result := '';
    for i := 0 to NumSegments - 2 do
      Result := Result + Segments[i][1] + '.';

    if ClassNameMaxLength > 3 then
      Result := Result + Copy(ClassName, 1, ClassNameMaxLength - 3) + '...'
    else
      Result := Result + '...';  // Extremely narrow width
  end;
end;

function TDebugLogger.FormatLoggerName: string;
var
  NameWidth: Integer;
  FormattedName: string;
begin
  if GetName = '' then
    Exit('');

  NameWidth := 40;

  // Use Spring Boot-style abbreviation if name exceeds width
  if Length(GetName) > NameWidth then
    FormattedName := AbbreviateLoggerName(GetName, NameWidth)
  else
    FormattedName := GetName;

  // Right-align the name within the specified width
  Result := Format('[%*s] ', [NameWidth, FormattedName]);
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
