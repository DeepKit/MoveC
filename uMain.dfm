object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C'#30424#28165#29702#24037#20855' v3.0 Enterprise - '#20225#19994#29256
  ClientHeight = 720
  ClientWidth = 1280
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Microsoft YaHei UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pnlMain: TPanel
    Left = 0
    Top = 50
    Width = 1280
    Height = 620
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 400
      Height = 620
      Align = alLeft
      BevelOuter = bvNone
      Caption = #28304#30446#24405
      TabOrder = 0
      object lblSourceDir: TLabel
        Left = 10
        Top = 10
        Width = 39
        Height = 17
        Caption = #28304#30446#24405':'
      end
      object edtSourceDir: TEdit
        Left = 10
        Top = 33
        Width = 220
        Height = 25
        TabOrder = 0
        Text = 'C:\Users'
      end
      object btnBrowseSource: TButton
        Left = 240
        Top = 33
        Width = 70
        Height = 25
        Caption = #27983#35272'...'
        TabOrder = 1
        OnClick = btnBrowseSourceClick
      end
      object btnSelectSourceRoot: TButton
        Left = 320
        Top = 33
        Width = 70
        Height = 25
        Caption = #36873#25321#26681#30446#24405
        TabOrder = 2
        OnClick = btnSelectSourceRootClick
      end
      object stvSource: TShellTreeView
        Left = 10
        Top = 70
        Width = 380
        Height = 540
        ObjectTypes = [otFolders, otNonFolders]
        Root = 'rfDesktop'
        UseShellImages = True
        AutoRefresh = True
        TabOrder = 3
        OnChange = stvSourceChange
      end
    end
    object pnlRight: TPanel
      Left = 400
      Top = 0
      Width = 400
      Height = 620
      Align = alLeft
      BevelOuter = bvNone
      Caption = #30446#26631#30446#24405
      TabOrder = 1
      object lblTargetDir: TLabel
        Left = 10
        Top = 10
        Width = 51
        Height = 17
        Caption = #30446#26631#30446#24405':'
      end
      object edtTargetDir: TEdit
        Left = 10
        Top = 33
        Width = 220
        Height = 25
        TabOrder = 0
        Text = 'D:\Users'
      end
      object btnBrowseTarget: TButton
        Left = 240
        Top = 33
        Width = 70
        Height = 25
        Caption = #27983#35272'...'
        TabOrder = 1
        OnClick = btnBrowseTargetClick
      end
      object btnSelectTargetRoot: TButton
        Left = 320
        Top = 33
        Width = 70
        Height = 25
        Caption = #36873#25321#26681#30446#24405
        TabOrder = 2
        OnClick = btnSelectTargetRootClick
      end
      object stvTarget: TShellTreeView
        Left = 10
        Top = 70
        Width = 380
        Height = 540
        ObjectTypes = [otFolders, otNonFolders]
        Root = 'rfDesktop'
        UseShellImages = True
        AutoRefresh = True
        TabOrder = 3
        OnChange = stvTargetChange
      end
    end
    object pnlStatus: TPanel
      Left = 800
      Top = 0
      Width = 480
      Height = 620
      Align = alClient
      BevelOuter = bvNone
      Caption = #29366#24577#26174#31034#21306
      TabOrder = 2
      object lblStatus: TLabel
        Left = 10
        Top = 10
        Width = 24
        Height = 17
        Caption = #23601#32490
      end
      object ProgressBar1: TProgressBar
        Left = 10
        Top = 33
        Width = 460
        Height = 17
        TabOrder = 0
      end
      object memoStatus: TMemo
        Left = 10
        Top = 60
        Width = 460
        Height = 550
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnScan: TButton
      Left = 10
      Top = 10
      Width = 80
      Height = 30
      Caption = #25195#25551
      TabOrder = 0
      OnClick = btnScanClick
    end
    object btnAnalyze: TButton
      Left = 100
      Top = 10
      Width = 80
      Height = 30
      Caption = #20998#26512
      TabOrder = 1
      OnClick = btnAnalyzeClick
    end
    object btnExecute: TButton
      Left = 190
      Top = 10
      Width = 80
      Height = 30
      Caption = #25191#34892
      TabOrder = 2
      OnClick = btnExecuteClick
    end
    object btnStop: TButton
      Left = 280
      Top = 10
      Width = 80
      Height = 30
      Caption = #20572#27490
      Enabled = False
      TabOrder = 3
      OnClick = btnStopClick
    end
    object btnExit: TButton
      Left = 370
      Top = 10
      Width = 80
      Height = 30
      Caption = #36864#20986
      TabOrder = 4
      OnClick = btnExitClick
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 670
    Width = 1280
    Height = 50
    Panels = <
      item
        Width = 300
      end
      item
        Width = 300
      end
      item
        Width = 300
      end
      item
        Width = 50
      end>
  end
  object MainMenu1: TMainMenu
    Left = 40
    Top = 80
    object MenuFile: TMenuItem
      Caption = #25991#20214'(&F)'
      object MenuFileExit: TMenuItem
        Caption = #36864#20986'(&X)'
        OnClick = MenuFileExitClick
      end
    end
    object MenuEdit: TMenuItem
      Caption = #32534#36753'(&E)'
    end
    object MenuCleanup: TMenuItem
      Caption = #28165#29702'(&C)'
      object MenuCleanupRecycleBin: TMenuItem
        Caption = #28165#31354#22238#25910#31449'(&R)'
        OnClick = MenuCleanupRecycleBinClick
      end
      object MenuCleanupTemp: TMenuItem
        Caption = #28165#29702#20020#26102#25991#20214'(&T)'
        OnClick = MenuCleanupTempClick
      end
      object MenuCleanupSeparator: TMenuItem
        Caption = '-'
      end
      object MenuCleanupLastBackup: TMenuItem
        Caption = #28165#29702#26368#36817#22791#20221'(&B)'
        OnClick = MenuCleanupLastBackupClick
      end
      object MenuCleanupSoftwareDistribution: TMenuItem
        Caption = #28165#29702'Windows'#26356#26032#32531#23384'(&W)'
        OnClick = MenuCleanupSoftwareDistributionClick
      end
    end
    object MenuTools: TMenuItem
      Caption = #24037#20855'(&T)'
      object MenuTheme: TMenuItem
        Caption = #20999#25442#20027#39064'(&T)'
        OnClick = MenuThemeClick
      end
    end
    object MenuHelp: TMenuItem
      Caption = #24110#21161'(&H)'
      object MenuHelpAbout: TMenuItem
        Caption = #20851#20110'(&A)'
        OnClick = MenuHelpAboutClick
      end
    end
  end
end
