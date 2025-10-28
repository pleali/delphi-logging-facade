{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Null;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types,
  Logger.Base;

type
  /// <summary>
  /// Null Object Pattern implementation for ILogger.
  /// This logger discards all log messages - useful for testing,
  /// benchmarking, or completely disabling logging without modifying application code.
  /// All methods are no-ops and all IsXxxEnabled methods return False.
  /// Now inherits from TBaseLogger for Chain of Responsibility support.
  /// </summary>
  TNullLogger = class(TBaseLogger)
  protected
    /// <summary>
    /// Does nothing - all messages are discarded.
    /// </summary>
    procedure DoLog(ALevel: TLogLevel; const AMessage: string); override;
  public
    constructor Create(const AName: string = '');
  end;

implementation

{ TNullLogger }

constructor TNullLogger.Create(const AName: string);
begin
  // Set to a level above FATAL to effectively disable all logging
  inherited Create(AName, TLogLevel(Ord(llFatal) + 1));
end;

procedure TNullLogger.DoLog(ALevel: TLogLevel; const AMessage: string);
begin
  // Do nothing - all messages are discarded
end;

end.
