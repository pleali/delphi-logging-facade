unit Logger.Default;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types;

type
  /// <summary>
  /// Default logger implementation that writes to console and OutputDebugString.
  /// This is a simple, zero-dependency implementation suitable for console applications
  /// and debugging scenarios.
  /// </summary>
  TConsoleLogger = class(TInterfacedObject, ILogger)
  private
    FMinLevel: TLogLevel;
    FUseColors: Boolean;

    procedure LogMessage(ALevel: TLogLevel; const AMessage: string);
    function FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
    function IsLevelEnabled(ALevel: TLogLevel): Boolean;
    procedure WriteToConsole(ALevel: TLogLevel; const AMessage: string);
  public
    constructor Create(AMinLevel: TLogLevel = llInfo; AUseColors: Boolean = True);

    // ILogger implementation
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;

    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.DateUtils;

{ TConsoleLogger }

constructor TConsoleLogger.Create(AMinLevel: TLogLevel; AUseColors: Boolean);
begin
  inherited Create;
  FMinLevel := AMinLevel;
  FUseColors := AUseColors;
end;

function TConsoleLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

function TConsoleLogger.FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
begin
  Result := Format('[%s] [%s] %s',
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

procedure TConsoleLogger.LogMessage(ALevel: TLogLevel; const AMessage: string);
var
  FormattedMessage: string;
begin
  if not IsLevelEnabled(ALevel) then
    Exit;

  FormattedMessage := FormatMessage(ALevel, AMessage);

  // Write to console
  WriteToConsole(ALevel, FormattedMessage);

  // Write to debug output (visible in IDE debugger)
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar(FormattedMessage));
  {$ENDIF}
end;

procedure TConsoleLogger.Trace(const AMessage: string);
begin
  LogMessage(llTrace, AMessage);
end;

procedure TConsoleLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llTrace, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Debug(const AMessage: string);
begin
  LogMessage(llDebug, AMessage);
end;

procedure TConsoleLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llDebug, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Info(const AMessage: string);
begin
  LogMessage(llInfo, AMessage);
end;

procedure TConsoleLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llInfo, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Warn(const AMessage: string);
begin
  LogMessage(llWarn, AMessage);
end;

procedure TConsoleLogger.Warn(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llWarn, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Error(const AMessage: string);
begin
  LogMessage(llError, AMessage);
end;

procedure TConsoleLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llError, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Error(const AMessage: string; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llError, Format('%s - Exception: %s: %s',
      [AMessage, AException.ClassName, AException.Message]))
  else
    LogMessage(llError, AMessage);
end;

procedure TConsoleLogger.Fatal(const AMessage: string);
begin
  LogMessage(llFatal, AMessage);
end;

procedure TConsoleLogger.Fatal(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llFatal, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Fatal(const AMessage: string; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llFatal, Format('%s - Exception: %s: %s',
      [AMessage, AException.ClassName, AException.Message]))
  else
    LogMessage(llFatal, AMessage);
end;

function TConsoleLogger.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(llTrace);
end;

function TConsoleLogger.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(llDebug);
end;

function TConsoleLogger.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(llInfo);
end;

function TConsoleLogger.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(llWarn);
end;

function TConsoleLogger.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(llError);
end;

function TConsoleLogger.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(llFatal);
end;

procedure TConsoleLogger.SetLevel(ALevel: TLogLevel);
begin
  FMinLevel := ALevel;
end;

function TConsoleLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

end.
