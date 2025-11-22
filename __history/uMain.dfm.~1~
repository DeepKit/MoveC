object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C'#30424#28411#36523#31070#22120' - '#26234#33021#30446#24405#36801#31227#19987#23478
  ClientHeight = 875
  ClientWidth = 984
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -9
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 12
  object pnlMain: TPanel
    Left = 0
    Top = 43
    Width = 984
    Height = 599
    Align = alClient
    BevelOuter = bvNone
    Color = 16053754
    TabOrder = 0
    ExplicitTop = 60
    ExplicitHeight = 582
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 599
      Align = alLeft
      BevelOuter = bvNone
      BorderWidth = 1
      BorderStyle = bsSingle
      Caption = #28304#30446#24405
      Color = clWhite
      TabOrder = 0
      ExplicitHeight = 582
      object lblSourceDir: TLabel
        Left = 10
        Top = 10
        Width = 52
        Height = 19
        Caption = #28304#30446#24405#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 1668818
        Font.Height = -13
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edtSourceDir: TEdit
        Left = 9
        Top = 33
        Width = 300
        Height = 25
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
        Left = 208
        Top = 4
        Width = 99
        Height = 26
        Caption = #27983#35272'...'
        TabOrder = 1
        OnClick = btnBrowseSourceClick
      end
      object btnSourceUp: TBitBtn
        Left = 115
        Top = 4
        Width = 90
        Height = 26
        Caption = #19978#32423
        TabOrder = 3
        OnClick = btnSourceUpClick
      end
      object tvSource: TTreeView
        Left = 9
        Top = 64
        Width = 300
        Height = 522
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
      Height = 599
      Align = alLeft
      BevelOuter = bvNone
      BorderWidth = 1
      BorderStyle = bsSingle
      Caption = #30446#26631#30446#24405
      Color = clWhite
      TabOrder = 1
      ExplicitHeight = 582
      object lblTargetDir: TLabel
        Left = 10
        Top = 10
        Width = 65
        Height = 19
        Caption = #30446#26631#30446#24405#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 1668818
        Font.Height = -13
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edtTargetDir: TEdit
        Left = 7
        Top = 35
        Width = 300
        Height = 25
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
        Left = 209
        Top = 4
        Width = 96
        Height = 26
        Caption = #27983#35272'...'
        TabOrder = 1
        OnClick = btnBrowseTargetClick
      end
      object btnTargetUp: TBitBtn
        Left = 117
        Top = 4
        Width = 90
        Height = 26
        Caption = #19978#32423
        TabOrder = 3
        OnClick = btnTargetUpClick
      end
      object tvTarget: TTreeView
        Left = 8
        Top = 64
        Width = 300
        Height = 522
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
    object pnlFileList: TPanel
      Left = 640
      Top = 0
      Width = 344
      Height = 599
      Align = alClient
      TabOrder = 2
      ExplicitHeight = 582
      object lvFiles: TListView
        Left = 1
        Top = 1
        Width = 342
        Height = 597
        Align = alClient
        Columns = <
          item
            Caption = #25991#20214#21517
            Width = 280
          end
          item
            Alignment = taRightJustify
            Caption = #22823#23567
            Width = 60
          end
          item
            Caption = #20462#25913#26085#26399
            Width = 100
          end
          item
            Caption = #31867#22411
            Width = 58
          end>
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        GridLines = True
        ReadOnly = True
        RowSelect = True
        ParentFont = False
        TabOrder = 0
        ViewStyle = vsReport
        ExplicitWidth = 536
        ExplicitHeight = 580
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
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 642
    Width = 984
    Height = 214
    Align = alBottom
    TabOrder = 2
    object pnlAboutMe: TPanel
      Left = 1
      Top = 1
      Width = 982
      Height = 212
      Align = alClient
      BevelInner = bvLowered
      TabOrder = 0
      object Splitter1: TSplitter
        Left = 977
        Top = 2
        Height = 208
        Align = alRight
        ExplicitLeft = 496
        ExplicitTop = 56
        ExplicitHeight = 100
      end
      object pnlStatus: TPanel
        Left = 2
        Top = 2
        Width = 975
        Height = 208
        Align = alClient
        BevelOuter = bvNone
        Caption = #29366#24577#20449#24687
        Color = 16449532
        TabOrder = 0
        object lblStatus: TLabel
          Left = 10
          Top = 10
          Width = 39
          Height = 19
          Caption = #36827#24230#65306
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 3830863
          Font.Height = -13
          Font.Name = 'Microsoft YaHei UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCurrentFile: TLabel
          Left = 10
          Top = 50
          Width = 60
          Height = 17
          Caption = #24403#21069#25991#20214#65306
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5263440
          Font.Height = -12
          Font.Name = 'Microsoft YaHei UI'
          Font.Style = []
          ParentFont = False
        end
        object lblTimeRemaining: TLabel
          Left = 895
          Top = 10
          Width = 65
          Height = 19
          Alignment = taRightJustify
          Caption = #21097#20313#26102#38388#65306
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5263440
          Font.Height = -13
          Font.Name = 'Microsoft YaHei UI'
          Font.Style = []
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
        object btnCancelOperation: TBitBtn
          Left = 760
          Top = 30
          Width = 100
          Height = 30
          Caption = #21462#28040
          TabOrder = 2
          Visible = False
          OnClick = btnCancelOperationClick
        end
        object memoStatus: TMemo
          AlignWithMargins = True
          Left = 10
          Top = 8
          Width = 955
          Height = 195
          Margins.Left = 10
          Margins.Top = 8
          Margins.Right = 10
          Margins.Bottom = 5
          Align = alClient
          Color = 16449532
          Font.Charset = GB2312_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Microsoft YaHei UI'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 1
          ExplicitWidth = 1149
        end
      end
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 984
    Height = 43
    Align = alTop
    BevelOuter = bvLowered
    TabOrder = 3
    object btnCleanBackup: TBitBtn
      Left = 679
      Top = 5
      Width = 90
      Height = 32
      Caption = #28165#29702#22791#20221
      TabOrder = 0
      OnClick = btnCleanBackupClick
    end
    object btnSmartClean: TBitBtn
      Left = 103
      Top = 5
      Width = 90
      Height = 32
      Caption = #19968#38190#28165#29702
      TabOrder = 1
      OnClick = btnSmartCleanClick
    end
    object btnSmartMigration: TBitBtn
      Left = 199
      Top = 5
      Width = 90
      Height = 32
      Caption = #19968#38190#36801#31227
      TabOrder = 2
      OnClick = btnSmartMigrationClick
    end
    object btnAnalyze: TBitBtn
      Left = 391
      Top = 5
      Width = 90
      Height = 32
      Caption = #20998#26512#30446#24405
      TabOrder = 3
      OnClick = btnAnalyzeClick
    end
    object btnCalculateSize: TBitBtn
      Left = 487
      Top = 5
      Width = 90
      Height = 32
      Caption = #35745#31639#22823#23567
      TabOrder = 4
      OnClick = btnCalculateSizeClick
    end
    object btnExecute: TBitBtn
      Left = 583
      Top = 5
      Width = 90
      Height = 32
      Caption = #25191#34892#36801#31227
      TabOrder = 5
      OnClick = btnExecuteClick
    end
    object btnRollback: TBitBtn
      Left = 295
      Top = 5
      Width = 90
      Height = 32
      Caption = #19968#38190#22238#36864
      TabOrder = 6
      OnClick = btnRollbackClick
    end
    object btnOneKeyDiagnose: TBitBtn
      Left = 7
      Top = 5
      Width = 90
      Height = 32
      Caption = #19968#38190#35786#26029
      TabOrder = 7
      OnClick = btnOneKeyDiagnoseClick
    end
    object btnExit: TBitBtn
      Left = 878
      Top = 5
      Width = 90
      Height = 32
      Caption = #36864#20986
      TabOrder = 8
      OnClick = btnExitClick
    end
  end
  object MainMenu1: TMainMenu
    Left = 496
    Top = 232
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
      object miSimpleMode: TMenuItem
        AutoCheck = True
        Caption = #31616#27905#27169#24335
        Checked = True
        OnClick = miSimpleModeClick
      end
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
    Left = 736
    Top = 176
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
    object miSrcDelete: TMenuItem
      Caption = #21024#38500#24403#21069#30446#24405'(&D)'
      OnClick = miSrcDeleteClick
    end
    object miSrcProperties: TMenuItem
      Caption = #23646#24615'(&P)'
      OnClick = miSrcPropertiesClick
    end
  end
  object pmTarget: TPopupMenu
    OnPopup = pmTargetPopup
    Left = 656
    Top = 272
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
    object miTgtDelete: TMenuItem
      Caption = #21024#38500#24403#21069#30446#24405'(&D)'
      OnClick = miTgtDeleteClick
    end
    object miTgtProperties: TMenuItem
      Caption = #23646#24615'(&P)'
      OnClick = miTgtPropertiesClick
    end
  end
end
