object frmAdvancedOptions: TfrmAdvancedOptions
  Left = 0
  Top = 0
  Caption = #39640#32423#36873#39033
  ClientHeight = 760
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  OnCreate = FormCreate
  OnShow = FormShow
  object pnlButtons: TPanel
    Left = 0
    Top = 704
    Width = 1100
    Height = 56
    Align = alBottom
    TabOrder = 0
    object btnOK: TBitBtn
      Left = 740
      Top = 12
      Width = 80
      Height = 32
      Caption = #30830#23450
      OnClick = btnOKClick
      TabOrder = 0
    end
    object btnCancel: TBitBtn
      Left = 830
      Top = 12
      Width = 80
      Height = 32
      Caption = #21462#28040
      OnClick = btnCancelClick
      TabOrder = 1
    end
    object btnApply: TBitBtn
      Left = 920
      Top = 12
      Width = 80
      Height = 32
      Caption = #24212#29992
      OnClick = btnApplyClick
      TabOrder = 2
    end
    object btnReset: TBitBtn
      Left = 100
      Top = 12
      Width = 80
      Height = 32
      Caption = #24674#22797#40664#35748
      OnClick = btnResetClick
      TabOrder = 3
    end
    object btnExport: TBitBtn
      Left = 190
      Top = 12
      Width = 80
      Height = 32
      Caption = #23548#20986
      OnClick = btnExportClick
      TabOrder = 4
    end
    object btnImport: TBitBtn
      Left = 280
      Top = 12
      Width = 80
      Height = 32
      Caption = #23548#20837
      OnClick = btnImportClick
      TabOrder = 5
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 704
    Align = alClient
    TabOrder = 1
    object pgcSettings: TPageControl
      Left = 8
      Top = 8
      Width = 1084
      Height = 688
      ActivePage = tsMigration
      TabOrder = 0
      object tsMigration: TTabSheet
        Caption = #36716#31227#35774#32622
        object gbMigrationDefaults: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 180
          Caption = #40664#35748#36873#39033
          TabOrder = 0
          object chkCreateBackupByDefault: TCheckBox
            Left = 16
            Top = 24
            Width = 200
            Height = 24
            Caption = #21024#21019#22791#20221
            TabOrder = 0
          end
          object chkVerifyFilesAfterCopy: TCheckBox
            Left = 16
            Top = 52
            Width = 220
            Height = 24
            Caption = #22797#21046#21518#39564#35777#25991#20214
            TabOrder = 1
          end
          object chkUseMultiThreading: TCheckBox
            Left = 16
            Top = 80
            Width = 220
            Height = 24
            Caption = #21551#29992#22810#32447#31243
            TabOrder = 2
          end
          object lblMaxConcurrentOps: TLabel
            Left = 280
            Top = 28
            Width = 160
            Height = 16
            Caption = #26368#22823#24182#21457#25805#20316#25968
          end
          object seMaxConcurrentOps: TSpinEdit
            Left = 460
            Top = 24
            Width = 80
            Height = 24
            MaxValue = 64
            MinValue = 1
            TabOrder = 3
            Value = 4
          end
          object lblBufferSize: TLabel
            Left = 280
            Top = 60
            Width = 120
            Height = 16
            Caption = #32531#20914#21306#22823#23567
          end
          object seBufferSize: TSpinEdit
            Left = 460
            Top = 56
            Width = 80
            Height = 24
            MaxValue = 65536
            MinValue = 64
            TabOrder = 4
            Value = 1024
          end
          object lblBufferSizeKB: TLabel
            Left = 548
            Top = 60
            Width = 40
            Height = 16
            Caption = 'KB'
          end
        end
      end
      object tsCleaning: TTabSheet
        Caption = #28165#29702#35774#32622
        object gbAutoCleanup: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 140
          Caption = #33258#21160#28165#29702
          TabOrder = 0
          object chkAutoCleanupTemp: TCheckBox
            Left = 16
            Top = 24
            Width = 200
            Height = 24
            Caption = #28165#29702#20020#26102#25991#20214
            TabOrder = 0
          end
          object chkAutoCleanupRecycleBin: TCheckBox
            Left = 16
            Top = 52
            Width = 220
            Height = 24
            Caption = #28165#31354#22238#25910#31449
            TabOrder = 1
          end
          object chkKeepRecentBackups: TCheckBox
            Left = 16
            Top = 80
            Width = 220
            Height = 24
            Caption = #20445#30041#26368#36817#22791#20221
            TabOrder = 2
          end
          object lblBackupRetentionDays: TLabel
            Left = 280
            Top = 28
            Width = 140
            Height = 16
            Caption = #22791#20221#20445#30041#22825#25968
          end
          object seBackupRetentionDays: TSpinEdit
            Left = 440
            Top = 24
            Width = 80
            Height = 24
            MaxValue = 365
            MinValue = 1
            TabOrder = 3
            Value = 30
          end
          object lblDays: TLabel
            Left = 528
            Top = 28
            Width = 24
            Height = 16
            Caption = #22825
          end
        end
      end
      object tsLogging: TTabSheet
        Caption = #26085#24535#35774#32622
        object gbLogSettings: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 200
          Caption = #26085#24535
          TabOrder = 0
          object lblLogLevel: TLabel
            Left = 16
            Top = 28
            Width = 80
            Height = 16
            Caption = #26085#24535#32423#21035
          end
          object cmbLogLevel: TComboBox
            Left = 120
            Top = 24
            Width = 160
            Height = 24
            Style = csDropDownList
            TabOrder = 0
          end
          object chkEnableFileLogging: TCheckBox
            Left = 16
            Top = 60
            Width = 220
            Height = 24
            Caption = #21551#29992#25991#20214#26085#24535
            TabOrder = 1
          end
          object lblLogRotationSize: TLabel
            Left = 16
            Top = 92
            Width = 120
            Height = 16
            Caption = #26085#24535#36716#25442#22823#23567
          end
          object seLogRotationSize: TSpinEdit
            Left = 140
            Top = 88
            Width = 80
            Height = 24
            MaxValue = 1024
            MinValue = 1
            TabOrder = 2
            Value = 10
          end
          object lblMB: TLabel
            Left = 224
            Top = 92
            Width = 24
            Height = 16
            Caption = 'MB'
          end
          object lblMaxLogFiles: TLabel
            Left = 16
            Top = 124
            Width = 120
            Height = 16
            Caption = #20445#30041#26085#24535#25991#20214
          end
          object seMaxLogFiles: TSpinEdit
            Left = 140
            Top = 120
            Width = 80
            Height = 24
            MaxValue = 100
            MinValue = 1
            TabOrder = 3
            Value = 5
          end
          object btnOpenLogFolder: TBitBtn
            Left = 280
            Top = 120
            Width = 120
            Height = 24
            Caption = #25171#24320#26085#24535#25991#20214#22841
            OnClick = btnOpenLogFolderClick
            TabOrder = 4
          end
          object btnClearLogs: TBitBtn
            Left = 408
            Top = 120
            Width = 100
            Height = 24
            Caption = #28165#31354#26085#24535
            OnClick = btnClearLogsClick
            TabOrder = 5
          end
        end
      end
      object tsSecurity: TTabSheet
        Caption = #23433#20840#35774#32622
        object gbSecurityOptions: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 140
          Caption = #23433#20840
          TabOrder = 0
          object chkRequireConfirmation: TCheckBox
            Left = 16
            Top = 24
            Width = 220
            Height = 24
            Caption = #37325#35201#25805#20316#38656#30830#35748
            TabOrder = 0
          end
          object chkRestrictedMode: TCheckBox
            Left = 16
            Top = 52
            Width = 220
            Height = 24
            Caption = #38480#21046#27169#24335
            OnClick = chkRestrictedModeClick
            TabOrder = 1
          end
          object chkAllowSystemDirectories: TCheckBox
            Left = 16
            Top = 80
            Width = 260
            Height = 24
            Caption = #20801#35768#25805#20316#31995#32479#30446#24405
            TabOrder = 2
          end
          object lblSecurityWarning: TLabel
            Left = 280
            Top = 24
            Width = 600
            Height = 16
            Caption = #27880#24847#65306#38480#21046#27169#24335#20250#38450#27490#39640#39118#38505#25805#20316#12290
          end
        end
      end
      object tsInterface: TTabSheet
        Caption = #30028#38754#35774#32622
        object gbAppearance: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 180
          Caption = #22806#35266
          TabOrder = 0
          object lblWindowStyle: TLabel
            Left = 16
            Top = 28
            Width = 80
            Height = 16
Caption = 'Window Style'
          end
          object cmbWindowStyle: TComboBox
            Left = 120
            Top = 24
            Width = 180
            Height = 24
            Style = csDropDownList
            TabOrder = 0
            OnChange = cmbWindowStyleChange
          end
          object chkUseModernColors: TCheckBox
            Left = 16
            Top = 60
            Width = 200
            Height = 24
            Caption = #20351#29992#29616#20195#33394#24425
            TabOrder = 1
          end
          object chkShowDetailedProgress: TCheckBox
            Left = 16
            Top = 88
            Width = 220
            Height = 24
            Caption = #26174#31034#35814#32454#36827#24230
            TabOrder = 2
          end
          object lblAutoRefreshInterval: TLabel
            Left = 16
            Top = 120
            Width = 120
            Height = 16
            Caption = #33258#21160#21047#26032#38388#38548
          end
          object seAutoRefreshInterval: TSpinEdit
            Left = 140
            Top = 116
            Width = 80
            Height = 24
            MaxValue = 60
            MinValue = 1
            TabOrder = 3
            Value = 5
          end
          object lblSeconds: TLabel
            Left = 224
            Top = 120
            Width = 24
            Height = 16
            Caption = #31186
          end
          object btnPreviewTheme: TBitBtn
            Left = 280
            Top = 116
            Width = 120
            Height = 24
            Caption = #39044#35272#20027#39064
            OnClick = btnPreviewThemeClick
            TabOrder = 4
          end
        end
      end
      object tsPerformance: TTabSheet
        Caption = #24615#33021#35774#32622
        object gbPerformanceOptions: TGroupBox
          Left = 16
          Top = 16
          Width = 1040
          Height = 160
          Caption = #24615#33021
          TabOrder = 0
          object chkEnableSystemMonitoring: TCheckBox
            Left = 16
            Top = 24
            Width = 240
            Height = 24
            Caption = #21551#29992#31995#32479#30417#25511
            TabOrder = 0
          end
          object chkPerformanceOptimization: TCheckBox
            Left = 16
            Top = 52
            Width = 260
            Height = 24
            Caption = #21551#29992#24615#33021#20248#21270
            TabOrder = 1
          end
          object lblMemoryUsageLimit: TLabel
            Left = 16
            Top = 84
            Width = 120
            Height = 16
            Caption = #20869#23384#38480#21046
          end
          object seMemoryUsageLimit: TSpinEdit
            Left = 140
            Top = 80
            Width = 80
            Height = 24
            MaxValue = 16384
            MinValue = 128
            TabOrder = 2
            Value = 512
          end
          object lblMBMemory: TLabel
            Left = 224
            Top = 84
            Width = 24
            Height = 16
            Caption = 'MB'
          end
          object btnOptimizeNow: TBitBtn
            Left = 16
            Top = 116
            Width = 120
            Height = 24
            Caption = #31435#21363#20248#21270
            OnClick = btnOptimizeNowClick
            TabOrder = 3
          end
        end
      end
    end
  end
  object SaveDialog: TSaveDialog
    Left = 32
    Top = 712
  end
  object OpenDialog: TOpenDialog
    Left = 88
    Top = 712
  end
end
