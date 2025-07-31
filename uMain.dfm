object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'C'#30424#36229#32423#30246#36523
  ClientHeight = 597
  ClientWidth = 1152
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter2: TSplitter
    Left = 435
    Top = 41
    Height = 514
    ExplicitLeft = 218
    ExplicitTop = 9
    ExplicitHeight = 357
  end
  object Splitter3: TSplitter
    Left = 849
    Top = 41
    Height = 514
    Align = alRight
    ExplicitLeft = 449
    ExplicitTop = 49
    ExplicitHeight = 431
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1152
    Height = 41
    Align = alTop
    TabOrder = 0
    DesignSize = (
      1152
      41)
    object lblSize: TLabel
      Left = 577
      Top = 14
      Width = 52
      Height = 15
      Caption = #30446#24405#22823#23567
    end
    object cBoxCalcSize: TCheckBox
      Left = 454
      Top = 13
      Width = 97
      Height = 17
      Caption = #23454#26102#35745#31639#22823#23567
      TabOrder = 5
    end
    object edtSource: TLabeledEdit
      Left = 88
      Top = 8
      Width = 265
      Height = 23
      EditLabel.Width = 78
      EditLabel.Height = 23
      EditLabel.Caption = #36801#31227#28304#30446#24405#65306
      LabelPosition = lpLeft
      TabOrder = 0
      Text = 'C:\Users\Administrator'
      OnChange = edtSourceChange
    end
    object edtTarget: TLabeledEdit
      Left = 874
      Top = 12
      Width = 166
      Height = 23
      Anchors = [akTop, akRight]
      EditLabel.Width = 65
      EditLabel.Height = 23
      EditLabel.Caption = #30446#26631#30446#24405#65306
      LabelPosition = lpLeft
      TabOrder = 1
      Text = 'D:\Users\Administrator'
      OnChange = edtTargetChange
      ExplicitLeft = 868
    end
    object btnDirSource: TButton
      Left = 359
      Top = 8
      Width = 82
      Height = 25
      Caption = #36873#25321#28304#25991#20214#22841
      TabOrder = 2
      OnClick = btnDirSourceClick
    end
    object btnDirTarget: TButton
      Left = 1046
      Top = 10
      Width = 97
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #36873#25321#30446#26631#25991#20214#22841
      TabOrder = 3
      OnClick = btnDirTargetClick
      ExplicitLeft = 1040
    end
    object btnCalcDirSize: TButton
      Left = 474
      Top = 10
      Width = 97
      Height = 25
      Caption = #35745#31639#30446#24405#22823#23567
      TabOrder = 4
      OnClick = btnCalcDirSizeClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 555
    Width = 1152
    Height = 42
    Align = alBottom
    TabOrder = 1
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 1150
      Height = 40
      Align = alClient
      BevelOuter = bvLowered
      TabOrder = 0
      DesignSize = (
        1150
        40)
      object btnAnalyze: TButton
        Left = 8
        Top = 6
        Width = 97
        Height = 25
        Caption = #20998#26512#24182#26631#35760
        TabOrder = 0
        OnClick = btnAnalyzeClick
      end
      object btnCopyFiles: TButton
        Left = 111
        Top = 6
        Width = 97
        Height = 25
        Caption = #25335#36125#24403#21069#30446#24405
        TabOrder = 1
        OnClick = btnCopyFilesClick
      end
      object btnCreateBackup: TButton
        Left = 214
        Top = 6
        Width = 97
        Height = 25
        Caption = #21019#24314#22791#20221
        TabOrder = 2
        OnClick = btnCreateBackupClick
      end
      object btnDeleteAndLink: TButton
        Left = 317
        Top = 6
        Width = 97
        Height = 25
        Caption = #21024#38500#24182#38142#25509
        TabOrder = 3
        OnClick = btnDeleteAndLinkClick
      end
      object btnRollback: TButton
        Left = 420
        Top = 6
        Width = 97
        Height = 25
        Caption = #22238#36864#24182#24674#22797
        TabOrder = 7
        OnClick = btnRollbackClick
      end
      object btnMove: TButton
        Left = 420
        Top = 6
        Width = 97
        Height = 25
        Caption = #19968#38190#31227#21160
        TabOrder = 4
        OnClick = btnMoveClick
      end
      object ProgressBar: TProgressBar
        Left = 536
        Top = 6
        Width = 503
        Height = 24
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 5
        ExplicitWidth = 497
      end
      object btnClose: TButton
        Left = 1061
        Top = 5
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '&C.'#20851#38381
        TabOrder = 6
        OnClick = btnCloseClick
        ExplicitLeft = 1055
      end
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 41
    Width = 435
    Height = 514
    Align = alLeft
    TabOrder = 2
    ExplicitHeight = 497
    object Splitter1: TSplitter
      Left = 210
      Top = 1
      Height = 512
      ExplicitLeft = 216
      ExplicitTop = 208
      ExplicitHeight = 100
    end
    object DirListBoxSource: TDirectoryListBox
      Left = 1
      Top = 1
      Width = 209
      Height = 512
      Align = alLeft
      FileList = FileListBoxSource
      TabOrder = 0
      OnChange = DirListBoxSourceChange
      OnDblClick = DirListBoxSourceDblClick
      ExplicitHeight = 495
    end
    object FileListBoxSource: TFileListBox
      Left = 213
      Top = 1
      Width = 221
      Height = 512
      Align = alClient
      ItemHeight = 15
      TabOrder = 1
    end
  end
  object pnlCenter: TPanel
    Left = 438
    Top = 41
    Width = 411
    Height = 514
    Align = alClient
    TabOrder = 3
    ExplicitWidth = 405
    ExplicitHeight = 497
    object Splitter4: TSplitter
      Left = 1
      Top = 355
      Width = 409
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 305
      ExplicitWidth = 63
    end
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 409
      Height = 330
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 403
      ExplicitHeight = 313
      object DirListBoxTarget: TDirectoryListBox
        Left = 1
        Top = 1
        Width = 209
        Height = 328
        Align = alLeft
        FileList = FileListBoxTarget
        TabOrder = 0
        OnChange = DirListBoxTargetChange
        OnDblClick = DirListBoxTargetDblClick
        ExplicitHeight = 311
      end
      object FileListBoxTarget: TFileListBox
        Left = 210
        Top = 1
        Width = 198
        Height = 328
        Align = alClient
        ItemHeight = 15
        TabOrder = 1
      end
    end
    object PageControl1: TPageControl
      Left = 1
      Top = 358
      Width = 409
      Height = 155
      ActivePage = tsBackup
      Align = alBottom
      TabOrder = 1
      ExplicitTop = 341
      ExplicitWidth = 403
      object tsBackup: TTabSheet
        Caption = #22791#20221#31649#29702
        object btnOpenBackupFolder: TButton
          Left = 300
          Top = 16
          Width = 85
          Height = 25
          Caption = #25171#24320#22791#20221#30446#24405
          Enabled = False
          TabOrder = 0
          OnClick = btnOpenBackupFolderClick
        end
        object btnDelBackup: TButton
          Left = 300
          Top = 47
          Width = 85
          Height = 25
          Caption = #21024#38500#24403#21069#22791#20221
          Enabled = False
          TabOrder = 1
          OnClick = btnDelBackupClick
        end
        object lvBackup: TListView
          Left = 0
          Top = 0
          Width = 273
          Height = 125
          Align = alLeft
          Columns = <>
          Items.ItemData = {050000000000000000}
          TabOrder = 2
          ViewStyle = vsReport
        end
        object btnCalcBackupSize: TButton
          Left = 300
          Top = 78
          Width = 85
          Height = 25
          Caption = #35745#31639#22791#20221#22823#23567
          Enabled = False
          TabOrder = 3
          OnClick = btnCalcBackupSizeClick
        end
      end
      object tsAboutMe: TTabSheet
        Caption = #20851#20110#24320#21457#32773
        ImageIndex = 1
      end
    end
    object PBarAFile: TProgressBar
      Left = 1
      Top = 331
      Width = 409
      Height = 24
      Align = alBottom
      TabOrder = 2
      ExplicitTop = 314
      ExplicitWidth = 403
    end
  end
  object RichEdit1: TRichEdit
    Left = 852
    Top = 41
    Width = 300
    Height = 514
    Align = alRight
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    Lines.Strings = (
      'RichEdit1')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 740
    Top = 233
  end
  object StatusTimer: TTimer
    Enabled = False
    Interval = 300
    OnTimer = StatusTimerTimer
    Left = 792
    Top = 48
  end
  object PopupMenuSource: TPopupMenu
    Left = 200
    Top = 200
    object MenuItemCalcSize: TMenuItem
      Caption = #35745#31639#30446#24405#22823#23567
      OnClick = MenuItemCalcSizeClick
    end
    object MenuItemAnalyze: TMenuItem
      Caption = #20998#26512#21487#34892#24615
      OnClick = MenuItemAnalyzeClick
    end
    object MenuItemScanSymlinks: TMenuItem
      Caption = #25195#25551#38142#25509
      OnClick = MenuItemScanSymlinksClick
    end
    object MenuItemSeparator1: TMenuItem
      Caption = '-'
    end
    object MenuItemOpenInExplorer: TMenuItem
      Caption = #22312#36164#28304#31649#29702#22120#20013#25171#24320
      OnClick = MenuItemOpenInExplorerClick
    end
    object MenuItemCopyPath: TMenuItem
      Caption = #22797#21046#36335#24452
      OnClick = MenuItemCopyPathClick
    end
    object MenuItemSeparator2: TMenuItem
      Caption = '-'
    end
    object MenuItemRefresh: TMenuItem
      Caption = #21047#26032
      OnClick = MenuItemRefreshClick
    end
    object MenuItemSeparator5: TMenuItem
      Caption = '-'
    end
    object MenuItemDeleteDir: TMenuItem
      Caption = #21024#38500#30446#24405
      OnClick = MenuItemDeleteDirClick
    end
    object MenuItemSeparator9: TMenuItem
      Caption = '-'
    end
    object MenuItemCopyToTarget: TMenuItem
      Caption = #25335#36125#21040#30446#26631#30446#24405
      OnClick = MenuItemCopyToTargetClick
    end
  end
  object PopupMenuTarget: TPopupMenu
    Left = 600
    Top = 200
    object MenuItemOpenTargetInExplorer: TMenuItem
      Caption = #22312#36164#28304#31649#29702#22120#20013#25171#24320
      OnClick = MenuItemOpenTargetInExplorerClick
    end
    object MenuItemCopyTargetPath: TMenuItem
      Caption = #22797#21046#36335#24452
      OnClick = MenuItemCopyTargetPathClick
    end
    object MenuItemSeparator3: TMenuItem
      Caption = '-'
    end
    object MenuItemRefreshTarget: TMenuItem
      Caption = #21047#26032
      OnClick = MenuItemRefreshTargetClick
    end
    object MenuItemSeparator4: TMenuItem
      Caption = '-'
    end
    object MenuItemCreateFolder: TMenuItem
      Caption = #26032#24314#25991#20214#22841
      OnClick = MenuItemCreateFolderClick
    end
    object MenuItemSeparator6: TMenuItem
      Caption = '-'
    end
    object MenuItemDeleteTargetDir: TMenuItem
      Caption = #21024#38500#30446#24405
      OnClick = MenuItemDeleteTargetDirClick
    end
    object MenuItemSeparator10: TMenuItem
      Caption = '-'
    end
    object MenuItemCreateLinkToCDrive: TMenuItem
      Caption = #21019#24314#21040'C'#30424#21516#36335#24452#38142#25509
      OnClick = MenuItemCreateLinkToCDriveClick
    end
  end
  object PopupMenuSourceFiles: TPopupMenu
    Left = 250
    Top = 250
    object MenuItemRenameSourceFile: TMenuItem
      Caption = #37325#21629#21517
      OnClick = MenuItemRenameSourceFileClick
    end
    object MenuItemDeleteSourceFile: TMenuItem
      Caption = #21024#38500#25991#20214
      OnClick = MenuItemDeleteSourceFileClick
    end
    object MenuItemSeparator7: TMenuItem
      Caption = '-'
    end
    object MenuItemOpenSourceFile: TMenuItem
      Caption = #25171#24320#25991#20214
      OnClick = MenuItemOpenSourceFileClick
    end
    object MenuItemCopySourceFileName: TMenuItem
      Caption = #22797#21046#25991#20214#21517
      OnClick = MenuItemCopySourceFileNameClick
    end
  end
  object PopupMenuTargetFiles: TPopupMenu
    Left = 650
    Top = 250
    object MenuItemRenameTargetFile: TMenuItem
      Caption = #37325#21629#21517
      OnClick = MenuItemRenameTargetFileClick
    end
    object MenuItemDeleteTargetFile: TMenuItem
      Caption = #21024#38500#25991#20214
      OnClick = MenuItemDeleteTargetFileClick
    end
    object MenuItemSeparator8: TMenuItem
      Caption = '-'
    end
    object MenuItemOpenTargetFile: TMenuItem
      Caption = #25171#24320#25991#20214
      OnClick = MenuItemOpenTargetFileClick
    end
    object MenuItemCopyTargetFileName: TMenuItem
      Caption = #22797#21046#25991#20214#21517
      OnClick = MenuItemCopyTargetFileNameClick
    end
  end
  object MainMenu1: TMainMenu
    Left = 48
    Top = 8
    object MenuFile: TMenuItem
      Caption = #25991#20214'(&F)'
      object MenuItemExit: TMenuItem
        Caption = #36864#20986'(&X)'
        OnClick = MenuItemExitClick
      end
    end
    object MenuTools: TMenuItem
      Caption = #24037#20855'(&T)'
      object MenuItemSystemCheck: TMenuItem
        Caption = #31995#32479#26816#26597'(&S)'
        OnClick = MenuItemSystemCheckClick
      end
      object MenuItemLanguage: TMenuItem
        Caption = #35821#35328#35774#32622'(&L)'
        OnClick = MenuItemLanguageClick
      end
    end
    object MenuHelp: TMenuItem
      Caption = #24110#21161'(&H)'
      object MenuItemAbout: TMenuItem
        Caption = #20851#20110'(&A)'
        OnClick = MenuItemAboutClick
      end
    end
  end
end
