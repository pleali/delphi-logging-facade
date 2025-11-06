{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Console;

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
  /// Console logger implementation that writes to standard output.
  /// This is a simple, zero-dependency implementation suitable for console applications.
  /// Thread-safe for concurrent access with optional colored output.
  /// Supports named loggers with Spring Boot-style formatting.
  /// Now inherits from TBaseLogger for Chain of Responsibility support.
  /// </summary>
  TConsoleLogger = class(TBaseLogger)
  private
    FUseColors: Boolean;
    FConsoleLock: TCriticalSection;

    function FormatLogMessage(ALevel: TLogLevel; const AMessage: string): string;
    function FormatLoggerName: string;
    procedure WriteToConsole(ALevel: TLogLevel; const AMessage: string);
  protected
    /// <summary>
    /// Implements the actual console output.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: TLogLevel; const AMessage: string); override;
  public
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo; AUseColors: Boolean = True);
    destructor Destroy; override;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.DateUtils,
  Logger.StackTrace,
  Logger.Name.Formatter;

{ TConsoleLogger }

constructor TConsoleLogger.Create(const AName: string; AMinLevel: TLogLevel; AUseColors: Boolean);
begin
  inherited Create(AName, AMinLevel);
  FUseColors := AUseColors;
  FConsoleLock := TCriticalSection.Create;
end;

destructor TConsoleLogger.Destroy;
begin
  FConsoleLock.Free;
  inherited;
end;

function TConsoleLogger.FormatLoggerName: string;
var
  NameWidth: Integer;
  FormattedName: string;
begin
  if GetName = '' then
    Exit('');

  NameWidth := 40; // Default, can be retrieved from factory if needed

  // Use Spring Boot-style abbreviation if name exceeds width
  if Length(GetName) > NameWidth then
    FormattedName := TLoggerNameFormatter.Abbreviate(GetName, NameWidth)
  else
    FormattedName := GetName;

  // Right-align the name within the specified width
  Result := Format('[%*s] ', [NameWidth, FormattedName]);
end;

function TConsoleLogger.FormatLogMessage(ALevel: TLogLevel; const AMessage: string): string;
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

procedure TConsoleLogger.WriteToConsole(ALevel: TLogLevel; const AMessage: string);
{$IFDEF MSWINDOWS}
var
  ConsoleHandle: THandle;
  OriginalAttrs: WORD;
  ConsoleInfo: TConsoleScreenBufferInfo;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if FUseColors then
  begin
    ConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
    if GetConsoleScreenBufferInfo(ConsoleHandle, ConsoleInfo) then
    begin
      OriginalAttrs := ConsoleInfo.wAttributes;
      try
        case ALevel of
          llTrace: SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_INTENSITY);
          llDebug: SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_BLUE or FOREGROUND_GREEN or FOREGROUND_INTENSITY);
          llInfo:  SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_GREEN or FOREGROUND_INTENSITY);
          llWarn:  SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_INTENSITY);
          llError: SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_RED or FOREGROUND_INTENSITY);
          llFatal: SetConsoleTextAttribute(ConsoleHandle, FOREGROUND_RED or BACKGROUND_RED or FOREGROUND_INTENSITY);
        end;
        Writeln(AMessage);
      finally
        SetConsoleTextAttribute(ConsoleHandle, OriginalAttrs);
      end;
    end
    else
      Writeln(AMessage);
  end
  else
  {$ENDIF}
    Writeln(AMessage);
end;

procedure TConsoleLogger.DoLog(ALevel: TLogLevel; const AMessage: string);
var
  FormattedMessage: string;
begin
  FConsoleLock.Enter;
  try
    FormattedMessage := FormatLogMessage(ALevel, AMessage);
    WriteToConsole(ALevel, FormattedMessage);
  finally
    FConsoleLock.Leave;
  end;
end;

end.
