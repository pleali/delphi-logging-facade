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
  DesignIntf,
  Logger.Component;

procedure Register;

implementation

uses
  DesignEditors;

procedure Register;
begin
  RegisterComponents('Logging', [TLoggerComponent]);

  // Register the component icon from the resource
  // The icon resource (ID=1) will be automatically loaded from Logger.Component.res
end;

end.
