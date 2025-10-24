unit Logger.Default;

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
  /// Default logger implementation that writes to console and OutputDebugString.
  /// This is a simple, zero-dependency implementation suitable for console applications
  /// and debugging scenarios. Thread-safe for concurrent access.
  /// Supports named loggers with Spring Boot-style formatting.
  /// </summary>
  TConsoleLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FMinLevel: TLogLevel;
    FUseColors: Boolean;
    FLock: TCriticalSection;

    procedure LogMessage(ALevel: TLogLevel; const AMessage: string);
    function FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
    function FormatLoggerName: string;
    function IsLevelEnabled(ALevel: TLogLevel): Boolean;
    procedure WriteToConsole(ALevel: TLogLevel; const AMessage: string);
  public
    constructor Create(const AName: string = ''; AMinLevel: TLogLevel = llInfo; AUseColors: Boolean = True);
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

{ TConsoleLogger }

constructor TConsoleLogger.Create(const AName: string; AMinLevel: TLogLevel; AUseColors: Boolean);
begin
  inherited Create;
  FName := AName;
  FMinLevel := AMinLevel;
  FUseColors := AUseColors;
  FLock := TCriticalSection.Create;
end;

destructor TConsoleLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TConsoleLogger.IsLevelEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

function TConsoleLogger.FormatLoggerName: string;
var
  NameWidth: Integer;
  TruncatedName: string;
begin
  if FName = '' then
    Exit('');

  NameWidth := 40; // Default, can be retrieved from factory if needed

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

function TConsoleLogger.FormatMessage(ALevel: TLogLevel; const AMessage: string): string;
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

procedure TConsoleLogger.LogMessage(ALevel: TLogLevel; const AMessage: string);
var
  FormattedMessage: string;
begin
  if not IsLevelEnabled(ALevel) then
    Exit;

  FLock.Enter;
  try
    FormattedMessage := FormatMessage(ALevel, AMessage);

    // Write to console
    WriteToConsole(ALevel, FormattedMessage);

    // Write to debug output (visible in IDE debugger)
    {$IFDEF MSWINDOWS}
    OutputDebugString(PChar(FormattedMessage));
    {$ENDIF}
  finally
    FLock.Leave;
  end;
end;

procedure TConsoleLogger.Trace(const AMessage: string);
begin
  LogMessage(llTrace, AMessage);
end;

procedure TConsoleLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  LogMessage(llTrace, Format(AMessage, AArgs));
end;

procedure TConsoleLogger.Trace(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llTrace, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
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

procedure TConsoleLogger.Debug(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llDebug, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
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

procedure TConsoleLogger.Info(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llInfo, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
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

procedure TConsoleLogger.Warn(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llWarn, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
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
    LogMessage(llError, TStackTraceManager.FormatExceptionMessage(AMessage, AException))
  else
    LogMessage(llError, AMessage);
end;

procedure TConsoleLogger.Error(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llError, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llError, Format(AMessage, AArgs));
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
    LogMessage(llFatal, TStackTraceManager.FormatExceptionMessage(AMessage, AException))
  else
    LogMessage(llFatal, AMessage);
end;

procedure TConsoleLogger.Fatal(const AMessage: string; const AArgs: array of const; AException: Exception);
begin
  if AException <> nil then
    LogMessage(llFatal, TStackTraceManager.FormatExceptionMessage(Format(AMessage, AArgs), AException))
  else
    LogMessage(llFatal, Format(AMessage, AArgs));
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
  FLock.Enter;
  try
    FMinLevel := ALevel;
  finally
    FLock.Leave;
  end;
end;

function TConsoleLogger.GetLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

function TConsoleLogger.GetName: string;
begin
  Result := FName;
end;

end.
