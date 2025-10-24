unit Logger.StackTrace;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  /// <summary>
  /// Interface for stack trace providers.
  /// Implementations can use different libraries (JclDebug, madExcept, EurekaLog, etc.)
  /// </summary>
  IStackTraceProvider = interface
    ['{F3A1B5C2-8D4E-4F1A-9B2C-6E7D8F9A0B1C}']

    /// <summary>
    /// Gets the stack trace for an exception as a formatted string.
    /// </summary>
    /// <param name="AException">The exception to get the stack trace for</param>
    /// <returns>Formatted stack trace string, or empty if not available</returns>
    function GetStackTrace(AException: Exception): string;

    /// <summary>
    /// Gets the current call stack as a formatted string.
    /// Useful for logging the call stack at any point in code.
    /// </summary>
    /// <returns>Formatted stack trace string</returns>
    function GetCurrentStackTrace: string;

    /// <summary>
    /// Checks if stack trace capture is available.
    /// </summary>
    /// <returns>True if the provider can capture stack traces</returns>
    function IsAvailable: Boolean;
  end;

  /// <summary>
  /// Singleton manager for stack trace providers.
  /// Provides centralized configuration and access to stack trace functionality.
  /// Thread-safe for concurrent access.
  /// </summary>
  TStackTraceManager = class
  private
    class var FInstance: TStackTraceManager;
    class var FLock: TCriticalSection;

    FProvider: IStackTraceProvider;
    FEnabled: Boolean;

    constructor Create;
  public
    class constructor ClassCreate;
    class destructor ClassDestroy;

    /// <summary>
    /// Gets the singleton instance.
    /// </summary>
    class function Instance: TStackTraceManager;

    /// <summary>
    /// Sets the stack trace provider implementation.
    /// </summary>
    /// <param name="AProvider">The provider to use for stack trace capture</param>
    class procedure SetProvider(AProvider: IStackTraceProvider);

    /// <summary>
    /// Enables stack trace capture.
    /// </summary>
    class procedure Enable;

    /// <summary>
    /// Disables stack trace capture.
    /// </summary>
    class procedure Disable;

    /// <summary>
    /// Checks if stack trace capture is enabled and available.
    /// </summary>
    /// <returns>True if enabled and provider is available</returns>
    class function IsEnabled: Boolean;

    /// <summary>
    /// Gets the stack trace for an exception.
    /// Returns empty string if disabled or provider not available.
    /// </summary>
    /// <param name="AException">The exception to get the stack trace for</param>
    /// <returns>Formatted stack trace string</returns>
    class function GetStackTrace(AException: Exception): string;

    /// <summary>
    /// Gets the current call stack.
    /// Returns empty string if disabled or provider not available.
    /// </summary>
    /// <returns>Formatted stack trace string</returns>
    class function GetCurrentStackTrace: string;

    /// <summary>
    /// Formats an exception message with stack trace if available.
    /// </summary>
    /// <param name="AMessage">The log message</param>
    /// <param name="AException">The exception</param>
    /// <returns>Formatted message with exception details and optional stack trace</returns>
    class function FormatExceptionMessage(const AMessage: string; AException: Exception): string;
  end;

implementation

{ TStackTraceManager }

class constructor TStackTraceManager.ClassCreate;
begin
  FLock := TCriticalSection.Create;
  FInstance := nil;
end;

class destructor TStackTraceManager.ClassDestroy;
begin
  FreeAndNil(FInstance);
  FreeAndNil(FLock);
end;

constructor TStackTraceManager.Create;
begin
  inherited Create;
  FProvider := nil;
  FEnabled := False;
end;

class function TStackTraceManager.Instance: TStackTraceManager;
begin
  if FInstance = nil then
  begin
    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TStackTraceManager.Create;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TStackTraceManager.SetProvider(AProvider: IStackTraceProvider);
begin
  FLock.Enter;
  try
    Instance.FProvider := AProvider;
    if (AProvider <> nil) and AProvider.IsAvailable then
      Instance.FEnabled := True;
  finally
    FLock.Leave;
  end;
end;

class procedure TStackTraceManager.Enable;
begin
  FLock.Enter;
  try
    Instance.FEnabled := True;
  finally
    FLock.Leave;
  end;
end;

class procedure TStackTraceManager.Disable;
begin
  FLock.Enter;
  try
    Instance.FEnabled := False;
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.IsEnabled: Boolean;
begin
  FLock.Enter;
  try
    Result := Instance.FEnabled and
              (Instance.FProvider <> nil) and
              Instance.FProvider.IsAvailable;
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.GetStackTrace(AException: Exception): string;
begin
  Result := '';

  if not IsEnabled then
    Exit;

  FLock.Enter;
  try
    if Instance.FProvider <> nil then
      Result := Instance.FProvider.GetStackTrace(AException);
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.GetCurrentStackTrace: string;
begin
  Result := '';

  if not IsEnabled then
    Exit;

  FLock.Enter;
  try
    if Instance.FProvider <> nil then
      Result := Instance.FProvider.GetCurrentStackTrace;
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.FormatExceptionMessage(const AMessage: string;
  AException: Exception): string;
var
  StackTrace: string;
begin
  if AException = nil then
    Exit(AMessage);

  // Base exception info
  Result := Format('%s - Exception: %s: %s',
    [AMessage, AException.ClassName, AException.Message]);

  // Add stack trace if available
  if IsEnabled then
  begin
    StackTrace := GetStackTrace(AException);
    if StackTrace <> '' then
      Result := Result + sLineBreak + 'Stack Trace:' + sLineBreak + StackTrace;
  end;
end;

end.
