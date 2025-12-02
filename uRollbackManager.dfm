object frmRollbackManager: TfrmRollbackManager
  Left = 0
  Top = 0
  Caption = #22238#28378#28857#31649#29702#22120' - MoveC'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 380
    Width = 1000
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 400
    ExplicitWidth = 800
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 200
      Height = 20
      Caption = #22238#28378#28857#31649#29702#22120
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDescription: TLabel
      Left = 16
      Top = 34
      Width = 300
      Height = 15
      Caption = #26597#30475#21644#31649#29702#25152#26377#36716#31227#35760#24405#65292#25903#25345#22238#28378#21644#28165#29702#25805#20316
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 60
    Width = 1000
    Height = 320
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lvRollbackPoints: TListView
      Left = 0
      Top = 0
      Width = 1000
      Height = 320
      Align = alClient
      Columns = <>
      GridLines = True
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      PopupMenu = pmRollbackList
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = lvRollbackPointsDblClick
      OnSelectItem = lvRollbackPointsSelectItem
    end
  end
  object pnlDetails: TPanel
    Left = 0
    Top = 385
    Width = 1000
    Height = 160
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblDetailsTitle: TLabel
      Left = 16
      Top = 8
      Width = 52
      Height = 15
      Caption = #35814#32454#20449#24687
    end
    object memoDetails: TMemo
      Left = 16
      Top = 28
      Width = 968
      Height = 124
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 545
    Width = 1000
    Height = 55
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnRefresh: TBitBtn
      Left = 16
      Top = 12
      Width = 90
      Height = 32
      Caption = #21047#26032
      TabOrder = 0
      OnClick = btnRefreshClick
    end
    object btnRollback: TBitBtn
      Left = 120
      Top = 12
      Width = 90
      Height = 32
      Caption = #22238#28378
      Enabled = False
      TabOrder = 1
      OnClick = btnRollbackClick
    end
    object btnDelete: TBitBtn
      Left = 224
      Top = 12
      Width = 90
      Height = 32
      Caption = #21024#38500
      Enabled = False
      TabOrder = 2
      OnClick = btnDeleteClick
    end
    object btnCleanup: TBitBtn
      Left = 328
      Top = 12
      Width = 120
      Height = 32
      Caption = #28165#29702#26087#35760#24405'...'
      TabOrder = 3
      OnClick = btnCleanupClick
    end
    object btnClose: TBitBtn
      Left = 894
      Top = 12
      Width = 90
      Height = 32
      Anchors = [akTop, akRight]
      Caption = #20851#38381
      TabOrder = 4
      OnClick = btnCloseClick
    end
  end
  object pmRollbackList: TPopupMenu
    Left = 872
    Top = 176
    object miRollback: TMenuItem
      Caption = #22238#28378#27492#36716#31227'...'
      OnClick = miRollbackClick
    end
    object miDelete: TMenuItem
      Caption = #21024#38500#35760#24405'...'
      OnClick = miDeleteClick
    end
    object miSeparator1: TMenuItem
      Caption = '-'
    end
    object miOpenBackupFolder: TMenuItem
      Caption = #25171#24320#22791#20221#30446#24405
      OnClick = miOpenBackupFolderClick
    end
    object miOpenTargetFolder: TMenuItem
      Caption = #25171#24320#30446#26631#30446#24405
      OnClick = miOpenTargetFolderClick
    end
    object miSeparator2: TMenuItem
      Caption = '-'
    end
    object miViewLog: TMenuItem
      Caption = #26597#30475#26085#24535
      OnClick = miViewLogClick
    end
  end
end
