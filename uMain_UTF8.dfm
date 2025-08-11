object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C盘瘦身工具 v3.0 Enterprise - 企业版'
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
  PixelsPerInch = 96
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
      Caption = '源目录'
      TabOrder = 0
      object lblSourceDir: TLabel
        Left = 10
        Top = 10
        Width = 60
        Height = 17
        Caption = '源目录:'
      end
      object edtSourceDir: TEdit
        Left = 10
        Top = 33
        Width = 300
        Height = 25
        TabOrder = 0
        Text = 'C:\'
      end
      object btnBrowseSource: TButton
        Left = 320
        Top = 33
        Width = 70
        Height = 25
        Caption = '浏览...'
        TabOrder = 1
        OnClick = btnBrowseSourceClick
      end
      object tvSource: TTreeView
        Left = 10
        Top = 70
        Width = 380
        Height = 540
        Indent = 19
        TabOrder = 2
      end
    end
    object pnlRight: TPanel
      Left = 400
      Top = 0
      Width = 400
      Height = 620
      Align = alLeft
      BevelOuter = bvNone
      Caption = '目标目录'
      TabOrder = 1
      object lblTargetDir: TLabel
        Left = 10
        Top = 10
        Width = 60
        Height = 17
        Caption = '目标目录:'
      end
      object edtTargetDir: TEdit
        Left = 10
        Top = 33
        Width = 300
        Height = 25
        TabOrder = 0
        Text = 'D:\'
      end
      object btnBrowseTarget: TButton
        Left = 320
        Top = 33
        Width = 70
        Height = 25
        Caption = '浏览...'
        TabOrder = 1
        OnClick = btnBrowseTargetClick
      end
      object tvTarget: TTreeView
        Left = 10
        Top = 70
        Width = 380
        Height = 540
        Indent = 19
        TabOrder = 2
      end
    end
    object pnlStatus: TPanel
      Left = 800
      Top = 0
      Width = 480
      Height = 620
      Align = alClient
      BevelOuter = bvNone
      Caption = '状态显示区'
      TabOrder = 2
      object lblStatus: TLabel
        Left = 10
        Top = 10
        Width = 36
        Height = 17
        Caption = '就绪'
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
      Caption = '扫描'
      TabOrder = 0
      OnClick = btnScanClick
    end
    object btnAnalyze: TButton
      Left = 100
      Top = 10
      Width = 80
      Height = 30
      Caption = '分析'
      TabOrder = 1
      OnClick = btnAnalyzeClick
    end
    object btnExecute: TButton
      Left = 190
      Top = 10
      Width = 80
      Height = 30
      Caption = '执行'
      TabOrder = 2
      OnClick = btnExecuteClick
    end
    object btnStop: TButton
      Left = 280
      Top = 10
      Width = 80
      Height = 30
      Caption = '停止'
      Enabled = False
      TabOrder = 3
      OnClick = btnStopClick
    end
    object btnExit: TButton
      Left = 370
      Top = 10
      Width = 80
      Height = 30
      Caption = '退出'
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
      Caption = '文件(&F)'
      object MenuFileExit: TMenuItem
        Caption = '退出(&X)'
        OnClick = MenuFileExitClick
      end
    end
    object MenuEdit: TMenuItem
      Caption = '编辑(&E)'
    end
    object MenuTools: TMenuItem
      Caption = '工具(&T)'
      object MenuTheme: TMenuItem
        Caption = '切换主题(&T)'
        OnClick = MenuThemeClick
      end
    end
    object MenuHelp: TMenuItem
      Caption = '帮助(&H)'
      object MenuHelpAbout: TMenuItem
        Caption = '关于(&A)'
        OnClick = MenuHelpAboutClick
      end
    end
  end
end
