object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Logger Component Example'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Size = 8
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlButtons: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 289
    Align = alTop
    TabOrder = 0
    object grpSettings: TGroupBox
      Left = 16
      Top = 8
      Width = 209
      Height = 105
      Caption = ' Settings '
      TabOrder = 0
      object lblMinLevel: TLabel
        Left = 16
        Top = 24
        Width = 80
        Height = 13
        Caption = 'Minimum Level:'
      end
      object cboMinLevel: TComboBox
        Left = 16
        Top = 43
        Width = 177
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cboMinLevelChange
      end
      object chkAsyncEvents: TCheckBox
        Left = 16
        Top = 75
        Width = 177
        Height = 17
        Caption = 'Async Events (non-blocking)'
        TabOrder = 1
        OnClick = chkAsyncEventsClick
      end
    end
    object grpFactoryTest: TGroupBox
      Left = 240
      Top = 8
      Width = 313
      Height = 105
      Caption = ' Factory Integration Test '
      TabOrder = 1
      object lblFactoryStatus: TLabel
        Left = 16
        Top = 72
        Width = 89
        Height = 13
        Caption = 'Not registered'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnRegisterWithFactory: TButton
        Left = 16
        Top = 24
        Width = 281
        Height = 25
        Caption = 'Register Component with Factory'
        TabOrder = 0
        OnClick = btnRegisterWithFactoryClick
      end
      object btnLogViaFactory: TButton
        Left = 16
        Top = 55
        Width = 281
        Height = 25
        Caption = 'Log via Factory (test all levels)'
        TabOrder = 1
        OnClick = btnLogViaFactoryClick
      end
    end
    object btnTrace: TButton
      Left = 16
      Top = 128
      Width = 121
      Height = 33
      Caption = 'Log TRACE'
      TabOrder = 2
      OnClick = btnTraceClick
    end
    object btnDebug: TButton
      Left = 143
      Top = 128
      Width = 121
      Height = 33
      Caption = 'Log DEBUG'
      TabOrder = 3
      OnClick = btnDebugClick
    end
    object btnInfo: TButton
      Left = 270
      Top = 128
      Width = 121
      Height = 33
      Caption = 'Log INFO'
      TabOrder = 4
      OnClick = btnInfoClick
    end
    object btnWarn: TButton
      Left = 16
      Top = 167
      Width = 121
      Height = 33
      Caption = 'Log WARN'
      TabOrder = 5
      OnClick = btnWarnClick
    end
    object btnError: TButton
      Left = 143
      Top = 167
      Width = 121
      Height = 33
      Caption = 'Log ERROR'
      TabOrder = 6
      OnClick = btnErrorClick
    end
    object btnFatal: TButton
      Left = 270
      Top = 167
      Width = 121
      Height = 33
      Caption = 'Log FATAL'
      TabOrder = 7
      OnClick = btnFatalClick
    end
    object btnClear: TButton
      Left = 16
      Top = 214
      Width = 375
      Height = 33
      Caption = 'Clear Log'
      TabOrder = 8
      OnClick = btnClearClick
    end
    object btnMultiThread: TButton
      Left = 16
      Top = 253
      Width = 183
      Height = 25
      Caption = 'Multi-Thread Test (50 messages)'
      TabOrder = 9
      OnClick = btnMultiThreadClick
    end
    object btnWithException: TButton
      Left = 208
      Top = 253
      Width = 183
      Height = 25
      Caption = 'Log with Exception'
      TabOrder = 10
      OnClick = btnWithExceptionClick
    end
  end
  object memoLog: TMemo
    Left = 0
    Top = 289
    Width = 784
    Height = 272
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Size = 8
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object LoggerComponent1: TLoggerComponent
    LoggerName = 'MainLogger'
    Left = 592
    Top = 168
  end
end
