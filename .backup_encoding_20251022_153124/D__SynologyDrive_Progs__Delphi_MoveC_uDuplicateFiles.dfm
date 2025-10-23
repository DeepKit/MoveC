object frmDuplicateFiles: TfrmDuplicateFiles
  Left = 0
  Top = 0
  Caption = #37325#22797#25991#20214#26816#27979#22120
  ClientHeight = 700
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 700
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlTop: TPanel
      Left = 0
      Top = 0
      Width = 1000
      Height = 50
      Align = alTop
      BevelOuter = bvLowered
      TabOrder = 0
      object lblTitle: TLabel
        Left = 16
        Top = 16
        Width = 120
        Height = 16
        Caption = #37325#22797#25991#20214#26816#27979#19982#28165#29702
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnStartScan: TButton
        Left = 200
        Top = 12
        Width = 75
        Height = 25
        Caption = #24320#22987#25195#25551
        TabOrder = 0
        OnClick = btnStartScanClick
      end
      object btnStopScan: TButton
        Left = 281
        Top = 12
        Width = 75
        Height = 25
        Caption = #20572#27490#25195#25551
        TabOrder = 1
        OnClick = btnStopScanClick
      end
      object btnSelectAll: TButton
        Left = 400
        Top = 12
        Width = 75
        Height = 25
        Caption = #20840#36873
        TabOrder = 2
        OnClick = btnSelectAllClick
      end
      object btnSelectNone: TButton
        Left = 481
        Top = 12
        Width = 75
        Height = 25
        Caption = #20840#19981#36873
        TabOrder = 3
        OnClick = btnSelectNoneClick
      end
      object btnSelectRecommended: TButton
        Left = 562
        Top = 12
        Width = 75
        Height = 25
        Caption = #36873#25321#25512#33616
        TabOrder = 4
        OnClick = btnSelectRecommendedClick
      end
      object btnDeleteSelected: TButton
        Left = 643
        Top = 12
        Width = 75
        Height = 25
        Caption = #21024#38500#36873#20013
        TabOrder = 5
        OnClick = btnDeleteSelectedClick
      end
      object chkMoveToRecycleBin: TCheckBox
        Left = 750
        Top = 16
        Width = 150
        Height = 17
        Caption = #31227#21160#21040#22238#25910#31449#65288#25512#33616#65289
        Checked = True
        State = cbChecked
        TabOrder = 6
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 640
      Width = 1000
      Height = 60
      Align = alBottom
      BevelOuter = bvLowered
      TabOrder = 1
      object lblStatus: TLabel
        Left = 16
        Top = 12
        Width = 24
        Height = 13
        Caption = #23601#32490
      end
      object lblStats: TLabel
        Left = 16
        Top = 35
        Width = 3
        Height = 13
      end
      object ProgressBar: TProgressBar
        Left = 200
        Top = 12
        Width = 400
        Height = 17
        TabOrder = 0
        Visible = False
      end
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 50
      Width = 400
      Height = 590
      Align = alLeft
      BevelOuter = bvLowered
      TabOrder = 2
      object lblGroups: TLabel
        Left = 8
        Top = 8
        Width = 60
        Height = 13
        Caption = #37325#22797#25991#20214#32452
      end
      object lvGroups: TListView
        Left = 8
        Top = 27
        Width = 384
        Height = 555
        Anchors = [akLeft, akTop, akRight, akBottom]
        Columns = <>
        PopupMenu = pmGroups
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvGroupsSelectItem
      end
    end
    object pnlRight: TPanel
      Left = 400
      Top = 50
      Width = 600
      Height = 590
      Align = alClient
      BevelOuter = bvLowered
      TabOrder = 3
      object lblFiles: TLabel
        Left = 8
        Top = 8
        Width = 48
        Height = 13
        Caption = #25991#20214#35814#24773
      end
      object lvFiles: TListView
        Left = 8
        Top = 27
        Width = 584
        Height = 555
        Anchors = [akLeft, akTop, akRight, akBottom]
        Checkboxes = True
        Columns = <>
        PopupMenu = pmFiles
        TabOrder = 0
        ViewStyle = vsReport
        OnDblClick = lvFilesDblClick
        OnItemChecked = lvFilesItemChecked
      end
    end
  end
  object pmGroups: TPopupMenu
    Left = 320
    Top = 200
    object miSelectGroup: TMenuItem
      Caption = #36873#25321#35813#32452#25152#26377#25991#20214
      OnClick = miSelectGroupClick
    end
    object miDeselectGroup: TMenuItem
      Caption = #21462#28040#36873#25321#35813#32452
      OnClick = miDeselectGroupClick
    end
    object miSeparator1: TMenuItem
      Caption = '-'
    end
    object miOpenLocation: TMenuItem
      Caption = #25171#24320#25991#20214#22841#20301#32622
      OnClick = miOpenLocationClick
    end
  end
  object pmFiles: TPopupMenu
    Left = 720
    Top = 200
    object miSelectFile: TMenuItem
      Caption = #36873#25321#25991#20214
      OnClick = miSelectFileClick
    end
    object miDeselectFile: TMenuItem
      Caption = #21462#28040#36873#25321
      OnClick = miDeselectFileClick
    end
    object miSeparator2: TMenuItem
      Caption = '-'
    end
    object miOpenFile: TMenuItem
      Caption = #25171#24320#25991#20214
      OnClick = miOpenFileClick
    end
    object miOpenFileLocation: TMenuItem
      Caption = #25171#24320#25991#20214#20301#32622
      OnClick = miOpenFileLocationClick
    end
    object miFileProperties: TMenuItem
      Caption = #25991#20214#23646#24615
      OnClick = miFilePropertiesClick
    end
  end
end
