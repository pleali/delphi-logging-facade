{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Component.Reg;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Classes,
  Logger.Component;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Logging', [TLoggerComponent]);
end;

end.
