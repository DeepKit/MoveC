object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C盘瘦身神器 - 智能目录迁移专家'
  ClientHeight = 700
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 700
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlToolbar: TPanel
      Left = 0
      Top = 0
      Width = 1200
      Height = 50
      Align = alTop
      BevelOuter = bvLowered
      TabOrder = 0
      object btnCleanRecycleBin: TButton
        Left = 10
        Top = 10
        Width = 100
        Height = 30
        Caption = '清空回收站'
        TabOrder = 0
        OnClick = btnCleanRecycleBinClick
      end
      object btnCleanTemp: TButton
        Left = 120
        Top = 10
        Width = 100
        Height = 30
        Caption = '清理临时文件'
        TabOrder = 1
        OnClick = btnCleanTempClick
      end
      object btnCleanBackup: TButton
        Left = 230
        Top = 10
        Width = 100
        Height = 30
        Caption = '清理备份'
        TabOrder = 2
        OnClick = btnCleanBackupClick
      end
      object btnCleanUpdate: TButton
        Left = 340
        Top = 10
        Width = 100
        Height = 30
        Caption = '清理更新缓存'
        TabOrder = 3
        OnClick = btnCleanUpdateClick
      end
      object btnSmartClean: TButton
        Left = 450
        Top = 10
        Width = 100
        Height = 30
        Caption = '智能清理'
        TabOrder = 4
        OnClick = btnSmartCleanClick
      end
      object btnSmartMigration: TButton
        Left = 560
        Top = 10
        Width = 120
        Height = 30
        Caption = '智能迁移'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
        OnClick = btnSmartMigrationClick
      end
      object btnExit: TButton
        Left = 1100
        Top = 10
        Width = 75
        Height = 30
        Caption = '退出'
        TabOrder = 6
        OnClick = btnExitClick
      end
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 50
      Width = 400
      Height = 600
      Align = alLeft
      BevelOuter = bvLowered
      Caption = '源目录'
      TabOrder = 1
      object lblSourceDir: TLabel
        Left = 10
        Top = 10
        Width = 48
        Height = 13
        Caption = '源目录：'
      end
      object edtSourceDir: TEdit
        Left = 10
        Top = 30
        Width = 300
        Height = 21
        TabOrder = 0
      end
      object btnBrowseSource: TButton
        Left = 320
        Top = 28
        Width = 70
        Height = 25
        Caption = '浏览...'
        TabOrder = 1
        OnClick = btnBrowseSourceClick
      end
      object tvSource: TTreeView
        Left = 10
        Top = 60
        Width = 380
        Height = 530
        Indent = 19
        TabOrder = 2
        OnChange = tvSourceChange
        OnDblClick = tvSourceDblClick
        OnKeyDown = tvSourceKeyDown
        PopupMenu = pmSource
      end
    end
    object pnlRight: TPanel
      Left = 400
      Top = 50
      Width = 400
      Height = 600
      Align = alLeft
      BevelOuter = bvLowered
      Caption = '目标目录'
      TabOrder = 2
      object lblTargetDir: TLabel
        Left = 10
        Top = 10
        Width = 60
        Height = 13
        Caption = '目标目录：'
      end
      object edtTargetDir: TEdit
        Left = 10
        Top = 30
        Width = 300
        Height = 21
        TabOrder = 0
      end
      object btnBrowseTarget: TButton
        Left = 320
        Top = 28
        Width = 70
        Height = 25
        Caption = '浏览...'
        TabOrder = 1
        OnClick = btnBrowseTargetClick
      end
      object tvTarget: TTreeView
        Left = 10
        Top = 60
        Width = 380
        Height = 530
        Indent = 19
        TabOrder = 2
        OnChange = tvTargetChange
        OnDblClick = tvTargetDblClick
        OnKeyDown = tvTargetKeyDown
        PopupMenu = pmTarget
      end
    end
    object pnlStatus: TPanel
      Left = 800
      Top = 50
      Width = 400
      Height = 600
      Align = alClient
      BevelOuter = bvLowered
      Caption = '状态信息'
      TabOrder = 3
      object lblStatus: TLabel
        Left = 10
        Top = 10
        Width = 380
        Height = 13
        Caption = '就绪'
      end
      object ProgressBar1: TProgressBar
        Left = 10
        Top = 30
        Width = 380
        Height = 17
        TabOrder = 0
        Visible = False
      end
      object memoStatus: TMemo
        Left = 10
        Top = 60
        Width = 380
        Height = 530
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 681
    Width = 1200
    Height = 19
    Panels = <
      item
        Width = 200
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
    object miFile: TMenuItem
      Caption = '文件(&F)'
      object miExit: TMenuItem
        Caption = '退出(&X)'
        OnClick = miExitClick
      end
    end
    object miTools: TMenuItem
      Caption = '工具(&T)'
      object miConfigManager: TMenuItem
        Caption = '配置管理器(&C)'
        OnClick = miConfigManagerClick
      end
    end
  end
  object pmSource: TPopupMenu
    Left = 120
    Top = 80
  end
  object pmTarget: TPopupMenu
    Left = 200
    Top = 80
  end
end
