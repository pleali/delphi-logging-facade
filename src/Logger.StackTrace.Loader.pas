{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.StackTrace.Loader;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

{$IFDEF MSWINDOWS}

/// <summary>
/// Dynamic BPL loader for stack trace providers.
/// Must be explicitly invoked via EnsureStackTraceProvidersLoaded.
/// This unit should only be included when dynamic BPL loading is desired.
/// For static linking, use the provider units directly (e.g., Logger.StackTrace.JclDebug).
/// </summary>

/// <summary>
/// Ensures stack trace BPL providers are loaded.
/// Safe to call multiple times (idempotent).
/// Thread-safe.
/// </summary>
procedure EnsureStackTraceProvidersLoaded;

{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

uses
  System.SysUtils,
  System.SyncObjs,
  Winapi.Windows,
  Logger.StackTrace,
  Logger.Factory;

const
  /// <summary>
  /// List of known stack trace BPL packages to try loading, in priority order.
  /// The first available BPL will be loaded.
  /// </summary>
  KNOWN_STACK_TRACE_BPLS: array[0..0] of string = (
    'LoggingFacade.StackTrace.JclDebug.bpl'
  );

type
  /// <summary>
  /// Singleton manager for dynamic BPL loading of stack trace providers.
  /// Ensures thread-safe, lazy initialization of the loader.
  /// </summary>
  TStackTraceLoaderManager = class sealed
  private
    class var FInstance: TStackTraceLoaderManager;
    class var FClassLock: TCriticalSection;

    FLoadedBplHandle: HMODULE;
    FLoadersInitialized: Boolean;
    FLastError: string;
    FLock: TCriticalSection;

    constructor Create;
    destructor Destroy; override;

    procedure DoLoadBplProviders;

  public
    class function Instance: TStackTraceLoaderManager; static;
    procedure EnsureStackTraceProvidersLoaded;
    function GetLastError: string;
  end;

/// <summary>
/// Checks if running in debug mode.
/// Debug mode detection: DEBUG conditional or attached debugger.
/// </summary>
function IsDebugMode: Boolean;
begin
  {$IFDEF DEBUG}
  Result := True;
  {$ELSE}
  Result := DebugHook <> 0;  // Detect if debugger is attached
  {$ENDIF}
end;

/// <summary>
/// Gets the executable's directory with trailing path delimiter.
/// </summary>
function GetExeDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

/// <summary>
/// Gets the LoggingFacade.bpl directory with trailing path delimiter.
/// This allows finding stack trace BPLs in the same location as the core package.
/// </summary>
function GetLoggingFacadeDirectory: string;
var
  ModulePath: array[0..MAX_PATH] of Char;
begin
  // Get the path of the LoggingFacade.bpl module itself
  GetModuleFileName(HInstance, ModulePath, Length(ModulePath));
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ModulePath));
end;

/// <summary>
/// Gets the full path of a loaded BPL module.
/// </summary>
function GetBplPath(ABplHandle: HMODULE): string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  Result := '';
  if ABplHandle <> 0 then
  begin
    if GetModuleFileName(ABplHandle, Buffer, MAX_PATH) > 0 then
      Result := IncludeTrailingPathDelimiter(ExtractFilePath(Buffer));
  end;
end;

{ TStackTraceLoaderManager }

constructor TStackTraceLoaderManager.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLoadedBplHandle := 0;
  FLoadersInitialized := False;
  FLastError := '';
end;

destructor TStackTraceLoaderManager.Destroy;
begin
  // Cleanup: unload BPL if loaded
  if FLoadedBplHandle <> 0 then
  begin
    try
      UnloadPackage(FLoadedBplHandle);
    except
      // Ignore errors during cleanup
    end;
  end;

  FreeAndNil(FLock);
  inherited Destroy;
end;

class function TStackTraceLoaderManager.Instance: TStackTraceLoaderManager;
begin
  if FInstance = nil then
  begin
    if FClassLock = nil then
      FClassLock := TCriticalSection.Create;

    FClassLock.Enter;
    try
      if FInstance = nil then
        FInstance := TStackTraceLoaderManager.Create;
    finally
      FClassLock.Leave;
    end;
  end;

  Result := FInstance;
end;

procedure TStackTraceLoaderManager.DoLoadBplProviders;
var
  BplFileName: string;
  BplHandle: HMODULE;
  BplPath: string;
  BplDir: string;
  ExeDir: string;
  LoggingFacadeDir: string;
  BplFullPath: string;
  CandidatePaths: array[0..1] of string;
  I: Integer;
  IsDebug: Boolean;
begin
  FLock.Enter;
  try
    IsDebug := IsDebugMode;
    ExeDir := GetExeDirectory;
    LoggingFacadeDir := GetLoggingFacadeDirectory;

    for BplFileName in KNOWN_STACK_TRACE_BPLS do
    begin
      // Prepare candidate paths for search
      CandidatePaths[0] := ExeDir + BplFileName;
      CandidatePaths[1] := LoggingFacadeDir + BplFileName;

      // Search for the file in known locations
      BplFullPath := '';
      for I := Low(CandidatePaths) to High(CandidatePaths) do
      begin
        if FileExists(CandidatePaths[I]) then
        begin
          BplFullPath := CandidatePaths[I];
          Break;
        end;
      end;

      // If file doesn't exist, skip silently
      if BplFullPath = '' then
        Continue;

      try
        // Load the BPL with full path (no exception since file exists)
        BplHandle := LoadPackage(BplFullPath);

        if BplHandle = 0 then
          Continue; // Load failed (rare if file exists)

        try
          // BPL loaded, verify location in Release mode
          if not IsDebug then
          begin
            BplPath := GetBplPath(BplHandle);
            BplDir := ExtractFilePath(BplPath);

            if not SameText(BplDir, ExeDir) then
            begin
              // BPL in wrong directory!
              FLastError := Format('Stack trace BPL loaded from wrong directory: %s (expected: %s)',
                [BplPath, ExeDir]);

              // Log warning if logger available
              if TLoggerFactory.HasLogger then
              begin
                try
                  TLoggerFactory.GetLogger.Warn(FLastError);
                except
                  // Ignore logging errors
                end;
              end;

              // Unload BPL and don't activate
              UnloadPackage(BplHandle);
              Continue;
            end;
          end;

          // BPL OK (or Debug mode)
          // The BPL's initialization section will register the provider class
          FLoadedBplHandle := BplHandle;
          Exit; // First provider found, stop searching
        except
          on E: Exception do
          begin
            FLastError := Format('Error after loading BPL %s: %s', [BplFileName, E.Message]);
            UnloadPackage(BplHandle);
          end;
        end;
      except
        on E: Exception do
        begin
          FLastError := Format('Error loading BPL %s: %s', [BplFileName, E.Message]);
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TStackTraceLoaderManager.EnsureStackTraceProvidersLoaded;
begin
  if FLoadersInitialized then
    Exit;

  FLock.Enter;
  try
    if FLoadersInitialized then
      Exit;

    DoLoadBplProviders;
    FLoadersInitialized := True;
  finally
    FLock.Leave;
  end;
end;

function TStackTraceLoaderManager.GetLastError: string;
begin
  Result := FLastError;
end;

/// <summary>
/// Public wrapper: ensures stack trace BPL providers are loaded.
/// Thread-safe and idempotent.
/// </summary>
procedure EnsureStackTraceProvidersLoaded;
begin
  TStackTraceLoaderManager.Instance.EnsureStackTraceProvidersLoaded;
end;

initialization
  // Nothing - lazy initialization on demand via Instance

finalization
  // Cleanup singleton
  if Assigned(TStackTraceLoaderManager.FInstance) then
    FreeAndNil(TStackTraceLoaderManager.FInstance);
  if Assigned(TStackTraceLoaderManager.FClassLock) then
    FreeAndNil(TStackTraceLoaderManager.FClassLock);

{$ENDIF}

end.
