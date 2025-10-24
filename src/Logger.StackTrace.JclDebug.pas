{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.StackTrace.JclDebug;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  Logger.StackTrace;

type
  /// <summary>
  /// Stack trace provider using JCL Debug library.
  /// Requires JCL (JEDI Code Library) to be installed.
  /// For best results, compile with detailed map files or JCL debug information.
  ///
  /// Installation:
  ///   1. Install JEDI Code Library (JCL) from https://github.com/project-jedi/jcl
  ///   2. Ensure JCL is in your library path
  ///   3. Add this unit to your project
  ///   4. Initialize: TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create)
  ///
  /// Compiler Settings for Best Results:
  ///   - Project → Options → Linking → Map file: Detailed
  ///   - Or use JCL's Insert JCL Debug Data tool
  /// </summary>
  TJclDebugStackTraceProvider = class(TInterfacedObject, IStackTraceProvider)
  private
    function FormatStackTrace(AStackTrace: TStrings): string;
    function GetStackTraceString(AAddr: Pointer): string;
  public
    /// <summary>
    /// Gets the stack trace for an exception.
    /// </summary>
    function GetStackTrace(AException: Exception): string;

    /// <summary>
    /// Gets the current call stack.
    /// </summary>
    function GetCurrentStackTrace: string;

    /// <summary>
    /// Checks if JCL Debug is available.
    /// </summary>
    function IsAvailable: Boolean;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  JclDebug;

{ TJclDebugStackTraceProvider }

function TJclDebugStackTraceProvider.IsAvailable: Boolean;
begin
  // JCL Debug is available if we can load this unit
  // In practice, if this unit compiles and links, JCL is available
  Result := True;
end;

function TJclDebugStackTraceProvider.FormatStackTrace(AStackTrace: TStrings): string;
var
  I: Integer;
begin
  Result := '';
  if (AStackTrace = nil) or (AStackTrace.Count = 0) then
    Exit;

  for I := 0 to AStackTrace.Count - 1 do
  begin
    if I > 0 then
      Result := Result + sLineBreak;
    Result := Result + '  ' + AStackTrace[I];
  end;
end;

function TJclDebugStackTraceProvider.GetStackTraceString(AAddr: Pointer): string;
var
  Info: TJclLocationInfo;
begin
  Info := GetLocationInfo(AAddr);

  if Info.UnitName <> '' then
  begin
    if Info.ProcedureName <> '' then
    begin
      if Info.LineNumber > 0 then
        Result := Format('[%p] %s.%s (Line %d)',
          [AAddr, Info.UnitName, Info.ProcedureName, Info.LineNumber])
      else
        Result := Format('[%p] %s.%s',
          [AAddr, Info.UnitName, Info.ProcedureName]);
    end
    else
      Result := Format('[%p] %s', [AAddr, Info.UnitName]);
  end
  else if Info.ProcedureName <> '' then
    Result := Format('[%p] %s', [AAddr, Info.ProcedureName])
  else
    Result := Format('[%p]', [AAddr]);
end;

function TJclDebugStackTraceProvider.GetStackTrace(AException: Exception): string;
var
  StackTrace: TStringList;
  StackList: TJclStackInfoList;
  I: Integer;
begin
  Result := '';

  if AException = nil then
    Exit;

  StackTrace := TStringList.Create;
  try
    // Try to get JCL stack list from exception
    StackList := JclLastExceptStackList;

    if (StackList <> nil) and (StackList.Count > 0) then
    begin
      // Format each stack frame
      for I := 0 to StackList.Count - 1 do
      begin
        StackTrace.Add(GetStackTraceString(StackList.Items[I].CallerAddr));
      end;

      Result := FormatStackTrace(StackTrace);
    end
    else
    begin
      // If no JCL stack info is attached, provide a basic message
      Result := '(Stack trace not available - ensure JCL exception tracking is enabled)';
    end;
  finally
    StackTrace.Free;
  end;
end;

function TJclDebugStackTraceProvider.GetCurrentStackTrace: string;
var
  StackTrace: TStringList;
  StackList: TJclStackInfoList;
  I: Integer;
begin
  Result := '';
  StackTrace := TStringList.Create;
  try
    StackList := JclCreateStackList(False, 2, nil); // Skip 2 frames (this function and caller)
    try
      if (StackList <> nil) and (StackList.Count > 0) then
      begin
        for I := 0 to StackList.Count - 1 do
        begin
          StackTrace.Add(GetStackTraceString(StackList.Items[I].CallerAddr));
        end;

        Result := FormatStackTrace(StackTrace);
      end;
    finally
      StackList.Free;
    end;
  finally
    StackTrace.Free;
  end;
end;

initialization
  // Register provider class for lazy instantiation
  TStackTraceManager.RegisterProviderClass(TJclDebugStackTraceProvider);

  // Enable JCL exception tracking automatically when this unit is used
  // This is required for stack traces to be captured for exceptions
  {$IFDEF MSWINDOWS}
  if not JclExceptionTrackingActive then
    JclStartExceptionTracking;
  {$ENDIF}

finalization
  // Cleanup JCL exception tracking
  {$IFDEF MSWINDOWS}
  if JclExceptionTrackingActive then
    JclStopExceptionTracking;
  {$ENDIF}

end.
