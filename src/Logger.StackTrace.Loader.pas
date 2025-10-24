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
/// Automatically loads known stack trace BPL packages at initialization.
/// This unit should only be included when dynamic BPL loading is desired.
/// For static linking, use the provider units directly (e.g., Logger.StackTrace.JclDebug).
/// </summary>

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

var
  /// <summary>
  /// Handle to the loaded BPL package.
  /// Used for cleanup in finalization.
  /// </summary>
  GLoadedBplHandle: HMODULE = 0;

  /// <summary>
  /// Last error message from BPL loading attempts.
  /// </summary>
  GLastError: string = '';

  /// <summary>
  /// Critical section for thread-safe BPL loading.
  /// </summary>
  GLock: TCriticalSection;

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

/// <summary>
/// Attempts to load known stack trace provider BPLs.
/// Strategy:
///   1. Search for BPL in: [exe directory, LoggingFacade.bpl directory]
///   2. Check file existence before LoadPackage (avoids debugger exceptions)
///   3. In Release mode: BPL must be in exe directory (security check)
///   4. In Debug mode: BPL can be in any of the search locations
///   5. BPL initialization will register the provider class
/// </summary>
procedure TryLoadBplProviders;
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
  GLock.Enter;
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
              GLastError := Format('Stack trace BPL loaded from wrong directory: %s (expected: %s)',
                [BplPath, ExeDir]);

              // Log warning if logger available
              if TLoggerFactory.HasLogger then
              begin
                try
                  TLoggerFactory.GetLogger.Warn(GLastError);
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
          GLoadedBplHandle := BplHandle;
          Exit; // First provider found, stop searching
        except
          on E: Exception do
          begin
            GLastError := Format('Error after loading BPL %s: %s', [BplFileName, E.Message]);
            UnloadPackage(BplHandle);
          end;
        end;
      except
        on E: Exception do
        begin
          GLastError := Format('Error loading BPL %s: %s', [BplFileName, E.Message]);
        end;
      end;
    end;
  finally
    GLock.Leave;
  end;
end;

/// <summary>
/// Returns the last error that occurred during BPL loading.
/// Useful for diagnostics.
/// </summary>
function GetLastError: string;
begin
  Result := GLastError;
end;

initialization
  GLock := TCriticalSection.Create;

  // Automatically try to load stack trace provider BPLs
  TryLoadBplProviders;

finalization
  // Cleanup: unload BPL if loaded
  if GLoadedBplHandle <> 0 then
    UnloadPackage(GLoadedBplHandle);

  FreeAndNil(GLock);

{$ENDIF}

end.
