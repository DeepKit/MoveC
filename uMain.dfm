object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C'#30424#28411#36523#31070#22120' - '#26234#33021#30446#24405#36801#31227#19987#23478
  ClientHeight = 875
  ClientWidth = 984
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Microsoft YaHei UI'
  Font.Size = 9
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 984
    Height = 642
    Align = alClient
    BevelOuter = bvNone
    Color = 16053754
    TabOrder = 0
    ExplicitHeight = 633
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 642
      Align = alLeft
      BevelOuter = bvNone
      BorderStyle = bsSingle
      BorderWidth = 1
      Caption = #28304#30446#24405
      Color = clWhite
      TabOrder = 0
      ExplicitTop = 89
      ExplicitHeight = 592
      object lblSourceDir: TLabel
        Left = 10
        Top = 10
        Width = 48
        Height = 17
        Caption = #28304#30446#24405#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 1668818
        Font.Height = -13
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 10
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edtSourceDir: TEdit
        Left = 12
        Top = 49
        Width = 300
        Height = 25
        BorderStyle = bsSingle
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 2171169
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object btnBrowseSource: TBitBtn
        Left = 234
        Top = 14
        Width = 104
        Height = 26
        Caption = #27983#35272'...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnBrowseSourceClick
      end
      object btnSourceUp: TBitBtn
        Left = 157
        Top = 14
        Width = 90
        Height = 26
        Caption = #19978#32423
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnSourceUpClick
      end
      object tvSource: TTreeView
        Left = 14
        Top = 80
        Width = 300
        Height = 545
        BorderStyle = bsSingle
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4342338
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        Indent = 19
        ParentFont = False
        PopupMenu = pmSource
        TabOrder = 2
        OnChange = tvSourceChange
        OnDblClick = tvSourceDblClick
        OnExpanding = tvSourceExpanding
        OnKeyDown = tvSourceKeyDown
      end
    end
    object pnlRight: TPanel
      Left = 320
      Top = 0
      Width = 320
      Height = 642
      Align = alLeft
      BevelOuter = bvNone
      BorderStyle = bsSingle
      BorderWidth = 1
      Caption = #30446#26631#30446#24405
      Color = clWhite
      TabOrder = 1
      ExplicitTop = 89
      ExplicitHeight = 592
      object lblTargetDir: TLabel
        Left = 10
        Top = 10
        Width = 60
        Height = 17
        Caption = #30446#26631#30446#24405#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 1668818
        Font.Height = -13
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 10
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edtTargetDir: TEdit
        Left = 11
        Top = 49
        Width = 295
        Height = 25
        BorderStyle = bsSingle
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 2171169
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object btnBrowseTarget: TBitBtn
        Left = 235
        Top = 10
        Width = 110
        Height = 26
        Caption = #27983#35272'...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnBrowseTargetClick
      end
      object btnTargetUp: TBitBtn
        Left = 148
        Top = 10
        Width = 90
        Height = 26
        Caption = #19978#32423
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnTargetUpClick
      end
      object tvTarget: TTreeView
        Left = 10
        Top = 80
        Width = 300
        Height = 545
        BorderStyle = bsSingle
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4342338
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        Indent = 19
        ParentFont = False
        PopupMenu = pmTarget
        TabOrder = 2
        OnChange = tvTargetChange
        OnDblClick = tvTargetDblClick
        OnExpanding = tvTargetExpanding
        OnKeyDown = tvTargetKeyDown
      end
    end
    object pnlStatus: TPanel
      Left = 640
      Top = 0
      Width = 344
      Height = 642
      Align = alClient
      BevelOuter = bvNone
      Caption = #29366#24577#20449#24687
      Color = 16449532
      TabOrder = 2
      ExplicitTop = 89
      ExplicitHeight = 592
      object lblStatus: TLabel
        Left = 10
        Top = 10
        Width = 36
        Height = 17
        Caption = #36827#24230#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3830863
        Font.Height = -13
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 10
        Font.Style = [fsBold]
        ParentFont = False
      end
      object ProgressBar1: TProgressBar
        Left = 10
        Top = 30
        Width = 740
        Height = 17
        TabOrder = 0
        Visible = False
      end
      object memoStatus: TMemo
        AlignWithMargins = True
        Left = 11
        Top = 9
        Width = 322
        Height = 627
        Margins.Left = 10
        Margins.Top = 8
        Margins.Right = 10
        Margins.Bottom = 5
        Align = alClient
        BorderStyle = bsSingle
        Color = 16449532
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3687759
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 9
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 1
        ExplicitHeight = 577
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 856
    Width = 984
    Height = 19
    Color = 15527921
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
    ExplicitTop = 681
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 642
    Width = 984
    Height = 214
    Align = alBottom
    TabOrder = 2
    ExplicitTop = 644
    object pnlToolbar: TPanel
      Left = 624
      Top = 1
      Width = 359
      Height = 212
      Align = alRight
      BevelOuter = bvNone
      Color = 1713790
      ParentBackground = False
      TabOrder = 0
      object btnCleanRecycleBin: TBitBtn
        Left = 10
        Top = 10
        Width = 120
        Height = 38
        Caption = #28165#31354#22238#25910#31449
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = btnCleanRecycleBinClick
      end
      object btnCleanTemp: TBitBtn
        Left = 127
        Top = 10
        Width = 120
        Height = 38
        Caption = #28165#29702#20020#26102#25991#20214
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnCleanTempClick
      end
      object btnCleanBackup: TBitBtn
        Left = 246
        Top = 10
        Width = 120
        Height = 38
        Caption = #28165#29702#22791#20221
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = btnCleanBackupClick
      end
      object btnCleanUpdate: TBitBtn
        Left = 10
        Top = 50
        Width = 120
        Height = 38
        Caption = #28165#29702#26356#26032#32531#23384
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnCleanUpdateClick
      end
      object btnSmartClean: TBitBtn
        Left = 127
        Top = 50
        Width = 120
        Height = 38
        Caption = #26234#33021#28165#29702
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
        OnClick = btnSmartCleanClick
      end
      object btnSmartMigration: TBitBtn
        Left = 246
        Top = 50
        Width = 120
        Height = 38
        Caption = #26234#33021#36801#31227
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
        OnClick = btnSmartMigrationClick
      end
      object btnExecute: TBitBtn
        Left = 246
        Top = 90
        Width = 120
        Height = 38
        Caption = #25191#34892#36801#31227
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 6
        OnClick = btnExecuteClick
      end
      object btnAnalyze: TBitBtn
        Left = 10
        Top = 90
        Width = 120
        Height = 38
        Caption = #20998#26512#30446#24405
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 7
        OnClick = btnAnalyzeClick
      end
      object btnCalculateSize: TBitBtn
        Left = 127
        Top = 89
        Width = 120
        Height = 38
        Caption = #35745#31639#22823#23567
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
        OnClick = btnCalculateSizeClick
      end
      object btnExit: TBitBtn
        Left = 246
        Top = 162
        Width = 120
        Height = 38
        Caption = #36864#20986
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Microsoft YaHei UI'
        Font.Size = 11
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 9
        OnClick = btnExitClick
      end
    end
    object pnlAboutMe: TPanel
      Left = 1
      Top = 1
      Width = 623
      Height = 212
      Align = alClient
      BevelInner = bvLowered
      TabOrder = 1
      ExplicitLeft = 136
      ExplicitTop = 40
      ExplicitWidth = 185
      ExplicitHeight = 41
    end
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
      object MenuCleanupSeparator2: TMenuItem
        Caption = '-'
      end
      object MenuCleanupDuplicateFiles: TMenuItem
        Caption = #26234#33021#37325#22797#25991#20214#28165#29702'(&D)'
        OnClick = MenuCleanupDuplicateFilesClick
      end
    end
    object MenuTools: TMenuItem
      Caption = #24037#20855'(&T)'
      object miConfigManager: TMenuItem
        Caption = #37197#32622#31649#29702'(&C)'
        OnClick = miConfigManagerClick
      end
      object miSeparatorTools1: TMenuItem
        Caption = '-'
      end
      object miLogManager: TMenuItem
        Caption = #26085#24535#31649#29702'(&L)'
        OnClick = miLogManagerClick
      end
      object miAdvancedOptions: TMenuItem
        Caption = #39640#32423#21151#33021'(&A)'
        OnClick = miAdvancedOptionsClick
      end
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
  object pmSource: TPopupMenu
    OnPopup = pmSourcePopup
    Left = 400
    Top = 80
    object miSrcOpen: TMenuItem
      Caption = #25171#24320'(&O)'
      OnClick = miSrcOpenClick
    end
    object miSrcOpenInExplorer: TMenuItem
      Caption = #22312#36164#28304#31649#29702#22120#20013#25171#24320'(&E)'
      OnClick = miSrcOpenInExplorerClick
    end
    object miSrcCopyPath: TMenuItem
      Caption = #22797#21046#36335#24452'(&C)'
      OnClick = miSrcCopyPathClick
    end
    object miSrcSetRoot: TMenuItem
      Caption = #35774#20026#28304#26681'(&R)'
      OnClick = miSrcSetRootClick
    end
    object miSrcScanHere: TMenuItem
      Caption = #22312#27492#25195#25551'(&S)'
      OnClick = miSrcScanHereClick
    end
    object miSrcAnalyzeHere: TMenuItem
      Caption = #22312#27492#20998#26512'(&A)'
      OnClick = miSrcAnalyzeHereClick
    end
    object miSrcRefresh: TMenuItem
      Caption = #21047#26032'(&F)'
      OnClick = miSrcRefreshClick
    end
  end
  object pmTarget: TPopupMenu
    OnPopup = pmTargetPopup
    Left = 560
    Top = 80
    object miTgtOpen: TMenuItem
      Caption = #25171#24320'(&O)'
      OnClick = miTgtOpenClick
    end
    object miTgtOpenInExplorer: TMenuItem
      Caption = #22312#36164#28304#31649#29702#22120#20013#25171#24320'(&E)'
      OnClick = miTgtOpenInExplorerClick
    end
    object miTgtCopyPath: TMenuItem
      Caption = #22797#21046#36335#24452'(&C)'
      OnClick = miTgtCopyPathClick
    end
    object miTgtSetRoot: TMenuItem
      Caption = #35774#20026#30446#26631#26681'(&R)'
      OnClick = miTgtSetRootClick
    end
    object miTgtSetAsTargetPath: TMenuItem
      Caption = #35774#20026#30446#26631#36335#24452'(&T)'
      OnClick = miTgtSetAsTargetPathClick
    end
    object miTgtRefresh: TMenuItem
      Caption = #21047#26032'(&F)'
      OnClick = miTgtRefreshClick
    end
  end
end
