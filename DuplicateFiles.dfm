object frmDuplicateFiles: TfrmDuplicateFiles
  Left = 0
  Top = 0
  Caption = '重复文件检测器'
  ClientHeight = 700
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
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
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitle: TLabel
        Left = 16
        Top = 16
        Width = 144
        Height = 16
        Caption = '重复文件检测与清理'
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
        Caption = '开始扫描'
        TabOrder = 0
        OnClick = btnStartScanClick
      end
      object btnStopScan: TButton
        Left = 281
        Top = 12
        Width = 75
        Height = 25
        Caption = '停止扫描'
        TabOrder = 1
        OnClick = btnStopScanClick
      end
      object btnSelectAll: TButton
        Left = 362
        Top = 12
        Width = 75
        Height = 25
        Caption = '全选'
        TabOrder = 2
        OnClick = btnSelectAllClick
      end
      object btnSelectNone: TButton
        Left = 443
        Top = 12
        Width = 75
        Height = 25
        Caption = '全不选'
        TabOrder = 3
        OnClick = btnSelectNoneClick
      end
      object btnSelectRecommended: TButton
        Left = 524
        Top = 12
        Width = 75
        Height = 25
        Caption = '选择推荐'
        TabOrder = 4
        OnClick = btnSelectRecommendedClick
      end
      object btnDeleteSelected: TButton
        Left = 605
        Top = 12
        Width = 75
        Height = 25
        Caption = '删除选中'
        TabOrder = 5
        OnClick = btnDeleteSelectedClick
      end
      object chkMoveToRecycleBin: TCheckBox
        Left = 686
        Top = 16
        Width = 145
        Height = 17
        Caption = '移动到回收站（推荐）'
        Checked = True
        State = cbChecked
        TabOrder = 6
      end
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 50
      Width = 400
      Height = 590
      Align = alLeft
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 1
      object lblGroups: TLabel
        Left = 8
        Top = 8
        Width = 72
        Height = 13
        Caption = '重复文件组'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lvGroups: TListView
        Left = 8
        Top = 27
        Width = 384
        Height = 555
        Align = alClient
        Columns = <
          item
            Caption = '文件大小'
            Width = 100
          end
          item
            Caption = '重复数量'
            Width = 80
          end
          item
            Caption = '可节省空间'
            Width = 100
          end
          item
            Caption = '示例文件'
            Width = 200
          end>
        GridLines = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvGroupsSelectItem
      end
    end
    object Splitter1: TSplitter
      Left = 400
      Top = 50
      Width = 8
      Height = 590
      Align = alLeft
      ExplicitLeft = 393
      ExplicitTop = 1
      ExplicitHeight = 591
    end
    object pnlRight: TPanel
      Left = 408
      Top = 50
      Width = 592
      Height = 590
      Align = alClient
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 2
      object lblFiles: TLabel
        Left = 8
        Top = 8
        Width = 48
        Height = 13
        Caption = '文件详情'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lvFiles: TListView
        Left = 8
        Top = 27
        Width = 576
        Height = 555
        Align = alClient
        Checkboxes = True
        Columns = <
          item
            Caption = '文件名'
            Width = 200
          end
          item
            Caption = '路径'
            Width = 300
          end
          item
            Caption = '修改时间'
            Width = 120
          end
          item
            Caption = '建议'
            Width = 150
          end>
        GridLines = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnItemChecked = lvFilesItemChecked
        OnDblClick = lvFilesDblClick
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 640
      Width = 1000
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 3
      object lblStatus: TLabel
        Left = 8
        Top = 8
        Width = 32
        Height = 13
        Caption = '就绪'
      end
      object ProgressBar: TProgressBar
        Left = 8
        Top = 27
        Width = 984
        Height = 16
        Align = alBottom
        TabOrder = 0
        Visible = False
      end
      object lblStats: TLabel
        Left = 8
        Top = 44
        Width = 984
        Height = 13
        Align = alBottom
        Caption = ''
      end
    end
  end
  object pmGroups: TPopupMenu
    Left = 240
    Top = 200
    object miSelectGroup: TMenuItem
      Caption = '选择组内所有文件'
      OnClick = miSelectGroupClick
    end
    object miDeselectGroup: TMenuItem
      Caption = '取消选择组内所有文件'
      OnClick = miDeselectGroupClick
    end
    object miSeparator1: TMenuItem
      Caption = '-'
    end
    object miOpenLocation: TMenuItem
      Caption = '打开文件位置'
      OnClick = miOpenLocationClick
    end
  end
  object pmFiles: TPopupMenu
    Left = 640
    Top = 200
    object miSelectFile: TMenuItem
      Caption = '选择文件'
      OnClick = miSelectFileClick
    end
    object miDeselectFile: TMenuItem
      Caption = '取消选择文件'
      OnClick = miDeselectFileClick
    end
    object miSeparator2: TMenuItem
      Caption = '-'
    end
    object miOpenFile: TMenuItem
      Caption = '打开文件'
      OnClick = miOpenFileClick
    end
    object miOpenFileLocation: TMenuItem
      Caption = '打开文件位置'
      OnClick = miOpenFileLocationClick
    end
    object miFileProperties: TMenuItem
      Caption = '文件属性'
      OnClick = miFilePropertiesClick
    end
  end
end
