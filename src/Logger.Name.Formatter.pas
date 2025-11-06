{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Name.Formatter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Utility class for formatting logger names in various styles.
  /// Supports Spring Boot/Logback-style abbreviation where package names
  /// are abbreviated to single characters while preserving the class name.
  ///
  /// Example: "App.Database.Repository.Orders" -> "A.D.R.Orders"
  /// </summary>
  TLoggerNameFormatter = class sealed
  public
    /// <summary>
    /// Abbreviates a logger name to fit within specified width using
    /// Spring Boot/Logback-style abbreviation.
    ///
    /// Rules:
    /// - Package names (all segments except last) are abbreviated to single character
    /// - Class name (last segment) is preserved fully if possible
    /// - Only truncates class name with "..." if absolutely necessary
    ///
    /// Examples:
    /// - "App.Database.Repository.Orders" with width 40 -> "A.D.R.Orders"
    /// - "A.B.C.VeryLongClassNameExceedsWidth" with width 20 -> "A.B.C.VeryLongClas..."
    /// - "SingleName" with width 40 -> "SingleName"
    /// </summary>
    /// <param name="AName">Logger name to abbreviate</param>
    /// <param name="AWidth">Maximum width for the result</param>
    /// <returns>Abbreviated logger name</returns>
    class function Abbreviate(const AName: string; AWidth: Integer): string;
  end;

implementation

{ TLoggerNameFormatter }

class function TLoggerNameFormatter.Abbreviate(const AName: string; AWidth: Integer): string;
var
  Segments: TArray<string>;
  NumSegments, i: Integer;
  ClassName: string;
  AbbreviatedLength: Integer;
  ClassNameMaxLength: Integer;
begin
  // Handle empty names
  if AName = '' then
    Exit('');

  // Split by '.' separator
  Segments := AName.Split(['.']);
  NumSegments := Length(Segments);

  // Single segment (no packages) - just handle length
  if NumSegments = 1 then
  begin
    if Length(AName) > AWidth then
      Exit(Copy(AName, 1, AWidth - 3) + '...')
    else
      Exit(AName);
  end;

  // Extract class name (last segment)
  ClassName := Segments[NumSegments - 1];

  // Calculate length with all packages abbreviated to single character
  // Format: "A.B.C.ClassName" = (NumPackages * 2) + Length(ClassName)
  AbbreviatedLength := (NumSegments - 1) * 2 + Length(ClassName);

  if AbbreviatedLength <= AWidth then
  begin
    // Build abbreviated form: all packages as single char, full class name
    Result := '';
    for i := 0 to NumSegments - 2 do
      Result := Result + Segments[i][1] + '.';
    Result := Result + ClassName;
  end
  else
  begin
    // Even with abbreviated packages, the class name is too long
    // Abbreviate packages and truncate class name
    ClassNameMaxLength := AWidth - ((NumSegments - 1) * 2);

    Result := '';
    for i := 0 to NumSegments - 2 do
      Result := Result + Segments[i][1] + '.';

    if ClassNameMaxLength > 3 then
      Result := Result + Copy(ClassName, 1, ClassNameMaxLength - 3) + '...'
    else
      Result := Result + '...';  // Extremely narrow width
  end;
end;

end.
