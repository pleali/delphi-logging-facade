{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
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
  /// Provider class type for registry pattern.
  /// Providers register their class, which is instantiated lazily on first use.
  /// </summary>
  TStackTraceProviderClass = class of TInterfacedObject;

  /// <summary>
  /// Singleton manager for stack trace providers.
  /// Provides centralized configuration and access to stack trace functionality.
  /// Thread-safe for concurrent access.
  /// </summary>
  TStackTraceManager = class
  private
    class var FInstance: TStackTraceManager;
    class var FLock: TCriticalSection;
    class var FProviderClass: TStackTraceProviderClass;

    FProvider: IStackTraceProvider;
    FEnabled: Boolean;

    constructor Create;
    class function GetProvider: IStackTraceProvider; static;
  public
    class constructor ClassCreate;
    class destructor ClassDestroy;

    /// <summary>
    /// Gets the singleton instance.
    /// </summary>
    class function Instance: TStackTraceManager;

    /// <summary>
    /// Registers a provider class for lazy instantiation.
    /// The provider instance is created on first use.
    /// </summary>
    /// <param name="AClass">The provider class to register</param>
    class procedure RegisterProviderClass(AClass: TStackTraceProviderClass);

    /// <summary>
    /// Sets the stack trace provider implementation directly.
    /// This overrides any registered provider class.
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

uses
  Logger.Factory;

{ TStackTraceManager }

class constructor TStackTraceManager.ClassCreate;
begin
  FLock := TCriticalSection.Create;
  FInstance := nil;
  FProviderClass := nil;
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

class procedure TStackTraceManager.RegisterProviderClass(AClass: TStackTraceProviderClass);
begin
  FLock.Enter;
  try
    FProviderClass := AClass;
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.GetProvider: IStackTraceProvider;
begin
  FLock.Enter;
  try
    // Lazy initialization: create provider instance on first use
    if (Instance.FProvider = nil) and (FProviderClass <> nil) then
    begin
      try
        Instance.FProvider := FProviderClass.Create as IStackTraceProvider;
        if (Instance.FProvider <> nil) and Instance.FProvider.IsAvailable then
          Instance.FEnabled := True;
      except
        on E: Exception do
        begin
          // Log error if logger available
          if TLoggerFactory.HasLogger then
          begin
            try
              TLoggerFactory.GetLogger.Error(
                Format('Failed to create stack trace provider: %s', [E.Message]));
            except
              // Ignore logging errors
            end;
          end;
        end;
      end;
    end;

    Result := Instance.FProvider;
  finally
    FLock.Leave;
  end;
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
var
  Provider: IStackTraceProvider;
begin
  Provider := GetProvider;  // Lazy initialization
  FLock.Enter;
  try
    Result := Instance.FEnabled and
              (Provider <> nil) and
              Provider.IsAvailable;
  finally
    FLock.Leave;
  end;
end;

class function TStackTraceManager.GetStackTrace(AException: Exception): string;
var
  Provider: IStackTraceProvider;
begin
  Result := '';

  if not IsEnabled then
    Exit;

  Provider := GetProvider;
  if Provider <> nil then
  begin
    try
      Result := Provider.GetStackTrace(AException);
    except
      on E: Exception do
      begin
        // Log error if logger available
        if TLoggerFactory.HasLogger then
        begin
          try
            TLoggerFactory.GetLogger.Error(
              Format('Exception in GetStackTrace: %s', [E.Message]));
          except
            // Ignore logging errors
          end;
        end;
      end;
    end;
  end;
end;

class function TStackTraceManager.GetCurrentStackTrace: string;
var
  Provider: IStackTraceProvider;
begin
  Result := '';

  if not IsEnabled then
    Exit;

  Provider := GetProvider;
  if Provider <> nil then
  begin
    try
      Result := Provider.GetCurrentStackTrace;
    except
      on E: Exception do
      begin
        // Log error if logger available
        if TLoggerFactory.HasLogger then
        begin
          try
            TLoggerFactory.GetLogger.Error(
              Format('Exception in GetCurrentStackTrace: %s', [E.Message]));
          except
            // Ignore logging errors
          end;
        end;
      end;
    end;
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
