{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.QuickLogger.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types,
  Logger.Base,
  Logger.StackTrace,
  Quick.Logger;  // External dependency: QuickLogger library

type
  /// <summary>
  /// Adapter that bridges our ILogger interface to QuickLogger.
  /// This allows using QuickLogger as the underlying logging implementation
  /// while keeping application code independent of QuickLogger specifics.
  /// Now inherits from TBaseLogger for Chain of Responsibility support.
  ///
  /// Usage:
  ///   TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create);
  ///
  /// Note: This unit has a dependency on the QuickLogger library.
  /// Only include this unit if you're using QuickLogger.
  /// </summary>
  TQuickLoggerAdapter = class(TBaseLogger)
  protected
    /// <summary>
    /// Implements the actual QuickLogger output.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string); override;
  public
    constructor Create(const AName: string = ''; AMinLevel: Logger.Types.TLogLevel = Logger.Types.llInfo);
  end;

implementation

{ TQuickLoggerAdapter }

constructor TQuickLoggerAdapter.Create(const AName: string; AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create(AName, AMinLevel);
end;

procedure TQuickLoggerAdapter.DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string);
begin
  // Map our log levels to QuickLogger event types
  case ALevel of
    Logger.Types.llTrace:
      Quick.Logger.Logger.Add(AMessage, etTrace);
    Logger.Types.llDebug:
      Quick.Logger.Logger.Add(AMessage, etDebug);
    Logger.Types.llInfo:
      Quick.Logger.Logger.Add(AMessage, etInfo);
    Logger.Types.llWarn:
      Quick.Logger.Logger.Add(AMessage, etWarning);
    Logger.Types.llError:
      Quick.Logger.Logger.Add(AMessage, etError);
    Logger.Types.llFatal:
      Quick.Logger.Logger.Add(AMessage, etCritical);
  end;
end;

end.
