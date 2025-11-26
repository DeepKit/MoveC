object frmTraySettings: TfrmTraySettings
  Left = 0
  Top = 0
  Caption = '托盘设置'
  ClientHeight = 400
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 450
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 8
    TabOrder = 0
    object pnlTop: TPanel
      Left = 8
      Top = 8
      Width = 434
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitle: TLabel
        Left = 0
        Top = 0
        Width = 80
        Height = 19
        Caption = '托盘设置'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 0
        Top = 30
        Width = 200
        Height = 13
        Caption = '配置系统托盘图标和通知设置'
      end
    end
    object pnlSettings: TPanel
      Left = 8
      Top = 68
      Width = 434
      Height = 280
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object grpTrayOptions: TGroupBox
        Left = 0
        Top = 0
        Width = 434
        Height = 80
        Align = alTop
        Caption = '托盘选项'
        TabOrder = 0
        object chkMinimizeToTray: TCheckBox
          Left = 12
          Top = 20
          Width = 200
          Height = 17
          Caption = '最小化到系统托盘'
          TabOrder = 0
        end
        object chkShowNotifications: TCheckBox
          Left = 12
          Top = 45
          Width = 200
          Height = 17
          Caption = '显示托盘通知'
          TabOrder = 1
        end
      end
      object grpStartupOptions: TGroupBox
        Left = 0
        Top = 80
        Width = 434
        Height = 80
        Align = alTop
        Caption = '启动选项'
        TabOrder = 1
        object chkStartMinimized: TCheckBox
          Left = 12
          Top = 20
          Width = 200
          Height = 17
          Caption = '启动时最小化到托盘'
          TabOrder = 0
        end
        object chkStartWithWindows: TCheckBox
          Left = 12
          Top = 45
          Width = 200
          Height = 17
          Caption = '随 Windows 自动启动'
          TabOrder = 1
          OnClick = chkStartWithWindowsClick
        end
      end
      object grpNotifications: TGroupBox
        Left = 0
        Top = 160
        Width = 434
        Height = 120
        Align = alClient
        Caption = '通知设置'
        TabOrder = 2
        object chkShowCleanupNotifications: TCheckBox
          Left = 12
          Top = 20
          Width = 200
          Height = 17
          Caption = '显示清理完成通知'
          TabOrder = 0
        end
        object chkShowSyncNotifications: TCheckBox
          Left = 12
          Top = 45
          Width = 200
          Height = 17
          Caption = '显示同步状态通知'
          TabOrder = 1
        end
        object chkShowErrorNotifications: TCheckBox
          Left = 12
          Top = 70
          Width = 200
          Height = 17
          Caption = '显示错误通知'
          TabOrder = 2
        end
      end
    end
    object pnlButtons: TPanel
      Left = 8
      Top = 348
      Width = 434
      Height = 44
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object btnOK: TButton
        Left = 180
        Top = 8
        Width = 75
        Height = 25
        Caption = '确定'
        Default = True
        ModalResult = 1
        TabOrder = 0
        OnClick = btnOKClick
      end
      object btnCancel: TButton
        Left = 261
        Top = 8
        Width = 75
        Height = 25
        Caption = '取消'
        ModalResult = 2
        TabOrder = 1
        OnClick = btnCancelClick
      end
      object btnApply: TButton
        Left = 342
        Top = 8
        Width = 75
        Height = 25
        Caption = '应用'
        TabOrder = 2
        OnClick = btnApplyClick
      end
      object btnReset: TButton
        Left = 99
        Top = 8
        Width = 75
        Height = 25
        Caption = '重置'
        TabOrder = 3
        OnClick = btnResetClick
      end
    end
  end
end
