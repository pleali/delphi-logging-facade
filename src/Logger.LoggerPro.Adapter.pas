{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.LoggerPro.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.StrUtils,
  Logger.Intf,
  Logger.Types,
  Logger.Base,
  Logger.StackTrace,
  LoggerPro;  // External dependency: LoggerPro library

type
  /// <summary>
  /// Adapter that bridges our ILogger interface to LoggerPro.
  /// This allows using LoggerPro as the underlying logging implementation
  /// while keeping application code independent of LoggerPro specifics.
  /// Now inherits from TBaseLogger for Chain of Responsibility support.
  ///
  /// Usage:
  ///   var LogWriter: ILogWriter;
  ///   LogWriter := BuildLogWriter([TLoggerProFileAppender.Create]);
  ///   TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', LogWriter));
  ///
  /// Note: This unit has a dependency on the LoggerPro library.
  /// Only include this unit if you're using LoggerPro.
  /// </summary>
  TLoggerProAdapter = class(TBaseLogger)
  private
    FLogWriter: ILogWriter;
  protected
    /// <summary>
    /// Implements the actual LoggerPro output.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string); override;
  public
    constructor Create(const AName: string; ALogWriter: ILogWriter; AMinLevel: Logger.Types.TLogLevel = Logger.Types.llInfo);
  end;

implementation

{ TLoggerProAdapter }

constructor TLoggerProAdapter.Create(const AName: string; ALogWriter: ILogWriter; AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create(AName, AMinLevel);
  FLogWriter := ALogWriter;
end;

procedure TLoggerProAdapter.DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string);
var
  LTag: string;
begin
  // Use logger name as tag, or default based on level
  if GetName <> '' then
    LTag := GetName
  else
    case ALevel of
      Logger.Types.llTrace: LTag := 'TRACE';
      Logger.Types.llDebug: LTag := 'DEBUG';
      Logger.Types.llInfo:  LTag := 'INFO';
      Logger.Types.llWarn:  LTag := 'WARN';
      Logger.Types.llError: LTag := 'ERROR';
      Logger.Types.llFatal: LTag := 'FATAL';
    else
      LTag := 'APP';
    end;

  // LoggerPro doesn't have separate methods for all levels
  // Map our levels to LoggerPro's levels
  case ALevel of
    Logger.Types.llTrace, Logger.Types.llDebug:
      FLogWriter.Debug(AMessage, LTag);
    Logger.Types.llInfo:
      FLogWriter.Info(AMessage, LTag);
    Logger.Types.llWarn:
      FLogWriter.Warn(AMessage, LTag);
    Logger.Types.llError, Logger.Types.llFatal:
      FLogWriter.Error(AMessage, LTag);
  end;
end;

end.
