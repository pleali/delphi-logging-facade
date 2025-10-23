unit Logger.Config;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  Logger.Types;

type
  /// <summary>
  /// Configuration manager for logger levels, inspired by Logback.
  /// Supports hierarchical logger names with wildcard patterns and
  /// .properties file format for portable configuration.
  /// </summary>
  TLoggerConfig = class
  private
    FExactRules: TDictionary<string, TLogLevel>;
    FWildcardRules: TList<TPair<string, TLogLevel>>;
    FRootLevel: TLogLevel;
    FConfigFile: string;
    FLock: TCriticalSection;

    function ParsePropertiesLine(const ALine: string; out AKey, AValue: string): Boolean;
    function NormalizeLoggerName(const AName: string): string;
    function MatchesWildcard(const ALoggerName, APattern: string): Boolean;
    function GetSpecificity(const APattern: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Loads configuration from a .properties file.
    /// Format: logger.name=LEVEL (e.g., mqtt.transport=DEBUG)
    /// Supports comments (#) and wildcards (*).
    /// Thread-safe.
    /// </summary>
    /// <param name="AFileName">Path to .properties file</param>
    procedure LoadFromFile(const AFileName: string);

    /// <summary>
    /// Loads configuration from a string (useful for testing).
    /// Thread-safe.
    /// </summary>
    procedure LoadFromString(const AContent: string);

    /// <summary>
    /// Gets the configured log level for a logger name using Logback-style
    /// hierarchical resolution. Returns the most specific matching rule.
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name (e.g., 'mqtt.transport.ics')</param>
    /// <param name="ADefaultLevel">Default level if no rule matches</param>
    /// <returns>Configured log level</returns>
    function GetLevelForLogger(const ALoggerName: string;
                                ADefaultLevel: TLogLevel = llInfo): TLogLevel;

    /// <summary>
    /// Sets a logger level programmatically at runtime.
    /// Thread-safe.
    /// </summary>
    /// <param name="ALoggerName">Logger name or pattern (e.g., 'mqtt.*')</param>
    /// <param name="ALevel">Log level to set</param>
    procedure SetLoggerLevel(const ALoggerName: string; ALevel: TLogLevel);

    /// <summary>
    /// Reloads configuration from the last loaded file.
    /// Thread-safe.
    /// </summary>
    procedure Reload;

    /// <summary>
    /// Clears all configuration rules.
    /// Thread-safe.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Gets the root logger level.
    /// </summary>
    function GetRootLevel: TLogLevel;

    /// <summary>
    /// Sets the root logger level.
    /// </summary>
    procedure SetRootLevel(ALevel: TLogLevel);

    /// <summary>
    /// Returns the path of the currently loaded configuration file.
    /// </summary>
    property ConfigFile: string read FConfigFile;
  end;

implementation

uses
  System.StrUtils,
  System.IOUtils;

{ TLoggerConfig }

constructor TLoggerConfig.Create;
begin
  inherited Create;
  FExactRules := TDictionary<string, TLogLevel>.Create;
  FWildcardRules := TList<TPair<string, TLogLevel>>.Create;
  FRootLevel := llInfo; // Default root level
  FConfigFile := '';
  FLock := TCriticalSection.Create;
end;

destructor TLoggerConfig.Destroy;
begin
  FreeAndNil(FExactRules);
  FreeAndNil(FWildcardRules);
  FreeAndNil(FLock);
  inherited;
end;

function TLoggerConfig.NormalizeLoggerName(const AName: string): string;
begin
  // Convert to lowercase for case-insensitive matching (like Logback)
  Result := LowerCase(Trim(AName));
end;

function TLoggerConfig.ParsePropertiesLine(const ALine: string;
                                           out AKey, AValue: string): Boolean;
var
  LLine: string;
  LEqualPos: Integer;
begin
  LLine := Trim(ALine);

  // Skip empty lines and comments
  if (LLine = '') or LLine.StartsWith('#') or LLine.StartsWith('!') then
    Exit(False);

  LEqualPos := Pos('=', LLine);
  if LEqualPos <= 0 then
    Exit(False);

  AKey := Trim(Copy(LLine, 1, LEqualPos - 1));
  AValue := Trim(Copy(LLine, LEqualPos + 1, Length(LLine)));

  Result := (AKey <> '') and (AValue <> '');
end;

procedure TLoggerConfig.LoadFromString(const AContent: string);
var
  LLines: TStringList;
  I: Integer;
  LKey, LValue: string;
  LLevel: TLogLevel;
  LNormalizedKey: string;
begin
  FLock.Enter;
  try
    Clear;

    LLines := TStringList.Create;
    try
      LLines.Text := AContent;

      for I := 0 to LLines.Count - 1 do
      begin
        if ParsePropertiesLine(LLines[I], LKey, LValue) then
        begin
          // Parse log level
          LLevel := TLogLevel.FromString(LValue);
          LNormalizedKey := NormalizeLoggerName(LKey);

          // Special case for root logger
          if (LNormalizedKey = 'root') or (LNormalizedKey = '*') then
          begin
            FRootLevel := LLevel;
          end
          // Wildcard pattern
          else if LNormalizedKey.Contains('*') then
          begin
            FWildcardRules.Add(TPair<string, TLogLevel>.Create(LNormalizedKey, LLevel));
          end
          // Exact match
          else
          begin
            FExactRules.AddOrSetValue(LNormalizedKey, LLevel);
          end;
        end;
      end;

      // Sort wildcard rules by specificity (most specific first)
      FWildcardRules.Sort(TComparer<TPair<string, TLogLevel>>.Construct(
        function(const A, B: TPair<string, TLogLevel>): Integer
        begin
          Result := GetSpecificity(B.Key) - GetSpecificity(A.Key);
        end
      ));

    finally
      LLines.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLoggerConfig.LoadFromFile(const AFileName: string);
var
  LContent: string;
begin
  if not TFile.Exists(AFileName) then
    raise EFileNotFoundException.CreateFmt('Logger configuration file not found: %s', [AFileName]);

  LContent := TFile.ReadAllText(AFileName);
  FConfigFile := AFileName;
  LoadFromString(LContent);
end;

function TLoggerConfig.GetSpecificity(const APattern: string): Integer;
var
  LParts: TArray<string>;
begin
  // Calculate specificity based on number of parts before wildcard
  // mqtt.transport.* is more specific than mqtt.*
  LParts := APattern.Split(['.']);
  Result := Length(LParts);

  // Penalize patterns with wildcards
  if APattern.Contains('*') then
    Dec(Result);
end;

function TLoggerConfig.MatchesWildcard(const ALoggerName, APattern: string): Boolean;
var
  LPatternPrefix: string;
begin
  // Simple wildcard matching: mqtt.* matches mqtt.transport, mqtt.core, etc.
  if APattern.EndsWith('*') then
  begin
    LPatternPrefix := Copy(APattern, 1, Length(APattern) - 1);
    // Pattern 'mqtt.*' should match 'mqtt.transport' but not 'mqtt'
    // Pattern '*' matches everything
    if LPatternPrefix = '' then
      Exit(True);
    Result := ALoggerName.StartsWith(LPatternPrefix);
  end
  else
  begin
    Result := ALoggerName = APattern;
  end;
end;

function TLoggerConfig.GetLevelForLogger(const ALoggerName: string;
                                          ADefaultLevel: TLogLevel): TLogLevel;
var
  LNormalizedName: string;
  LLevel: TLogLevel;
  LPair: TPair<string, TLogLevel>;
begin
  FLock.Enter;
  try
    LNormalizedName := NormalizeLoggerName(ALoggerName);

    // 1. Check for exact match first (highest priority)
    if FExactRules.TryGetValue(LNormalizedName, LLevel) then
      Exit(LLevel);

    // 2. Check wildcard patterns (ordered by specificity)
    for LPair in FWildcardRules do
    begin
      if MatchesWildcard(LNormalizedName, LPair.Key) then
        Exit(LPair.Value);
    end;

    // 3. Check if we should use root level or default
    if FRootLevel <> llInfo then
      Result := FRootLevel
    else
      Result := ADefaultLevel;
  finally
    FLock.Leave;
  end;
end;

procedure TLoggerConfig.SetLoggerLevel(const ALoggerName: string; ALevel: TLogLevel);
var
  LNormalizedName: string;
begin
  FLock.Enter;
  try
    LNormalizedName := NormalizeLoggerName(ALoggerName);

    // Special case for root
    if (LNormalizedName = 'root') or (LNormalizedName = '*') then
    begin
      FRootLevel := ALevel;
      Exit;
    end;

    // Check if it's a wildcard pattern
    if LNormalizedName.Contains('*') then
    begin
      // Remove existing pattern if present
      FWildcardRules.Remove(TPair<string, TLogLevel>.Create(LNormalizedName, ALevel));
      FWildcardRules.Add(TPair<string, TLogLevel>.Create(LNormalizedName, ALevel));

      // Re-sort by specificity
      FWildcardRules.Sort(TComparer<TPair<string, TLogLevel>>.Construct(
        function(const A, B: TPair<string, TLogLevel>): Integer
        begin
          Result := GetSpecificity(B.Key) - GetSpecificity(A.Key);
        end
      ));
    end
    else
    begin
      // Exact match
      FExactRules.AddOrSetValue(LNormalizedName, ALevel);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLoggerConfig.Reload;
begin
  if FConfigFile <> '' then
    LoadFromFile(FConfigFile)
  else
    raise Exception.Create('No configuration file loaded. Cannot reload.');
end;

procedure TLoggerConfig.Clear;
begin
  FLock.Enter;
  try
    FExactRules.Clear;
    FWildcardRules.Clear;
    FRootLevel := llInfo;
  finally
    FLock.Leave;
  end;
end;

function TLoggerConfig.GetRootLevel: TLogLevel;
begin
  FLock.Enter;
  try
    Result := FRootLevel;
  finally
    FLock.Leave;
  end;
end;

procedure TLoggerConfig.SetRootLevel(ALevel: TLogLevel);
begin
  FLock.Enter;
  try
    FRootLevel := ALevel;
  finally
    FLock.Leave;
  end;
end;

end.
