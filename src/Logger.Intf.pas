unit Logger.Intf;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Types;

type
  /// <summary>
  /// Main logging interface - inspired by SLF4J.
  /// This interface provides a facade for various logging implementations.
  /// Application code should depend only on this interface, not on concrete implementations.
  /// </summary>
  ILogger = interface
    ['{B9A7E5D1-4F2C-4E8D-A3B6-7C8D9E0F1A2B}']

    // Basic logging methods

    /// <summary>
    /// Logs a TRACE level message.
    /// </summary>
    procedure Trace(const AMessage: string); overload;

    /// <summary>
    /// Logs a TRACE level message with format arguments.
    /// </summary>
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs a DEBUG level message.
    /// </summary>
    procedure Debug(const AMessage: string); overload;

    /// <summary>
    /// Logs a DEBUG level message with format arguments.
    /// </summary>
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs an INFO level message.
    /// </summary>
    procedure Info(const AMessage: string); overload;

    /// <summary>
    /// Logs an INFO level message with format arguments.
    /// </summary>
    procedure Info(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs a WARN level message.
    /// </summary>
    procedure Warn(const AMessage: string); overload;

    /// <summary>
    /// Logs a WARN level message with format arguments.
    /// </summary>
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs an ERROR level message.
    /// </summary>
    procedure Error(const AMessage: string); overload;

    /// <summary>
    /// Logs an ERROR level message with format arguments.
    /// </summary>
    procedure Error(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs an ERROR level message with exception information.
    /// </summary>
    procedure Error(const AMessage: string; AException: Exception); overload;

    /// <summary>
    /// Logs a FATAL level message.
    /// </summary>
    procedure Fatal(const AMessage: string); overload;

    /// <summary>
    /// Logs a FATAL level message with format arguments.
    /// </summary>
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;

    /// <summary>
    /// Logs a FATAL level message with exception information.
    /// </summary>
    procedure Fatal(const AMessage: string; AException: Exception); overload;

    // Level checking methods

    /// <summary>
    /// Checks if TRACE level logging is enabled.
    /// Use this to avoid expensive message construction when trace is disabled.
    /// </summary>
    function IsTraceEnabled: Boolean;

    /// <summary>
    /// Checks if DEBUG level logging is enabled.
    /// Use this to avoid expensive message construction when debug is disabled.
    /// </summary>
    function IsDebugEnabled: Boolean;

    /// <summary>
    /// Checks if INFO level logging is enabled.
    /// </summary>
    function IsInfoEnabled: Boolean;

    /// <summary>
    /// Checks if WARN level logging is enabled.
    /// </summary>
    function IsWarnEnabled: Boolean;

    /// <summary>
    /// Checks if ERROR level logging is enabled.
    /// </summary>
    function IsErrorEnabled: Boolean;

    /// <summary>
    /// Checks if FATAL level logging is enabled.
    /// </summary>
    function IsFatalEnabled: Boolean;

    // Configuration methods

    /// <summary>
    /// Sets the minimum log level. Messages below this level will be ignored.
    /// </summary>
    procedure SetLevel(ALevel: TLogLevel);

    /// <summary>
    /// Gets the current minimum log level.
    /// </summary>
    function GetLevel: TLogLevel;
  end;

implementation

end.
