object frmCleanupHistory: TfrmCleanupHistory
  Left = 0
  Top = 0
  Caption = '清理历史记录'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlTop: TPanel
      Left = 0
      Top = 0
      Width = 900
      Height = 50
      Align = alTop
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 0
      object lblTitle: TLabel
        Left = 8
        Top = 8
        Width = 100
        Height = 19
        Caption = '清理历史记录'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object pnlSummary: TPanel
      Left = 0
      Top = 50
      Width = 900
      Height = 40
      Align = alTop
      BevelOuter = bvLowered
      BorderWidth = 8
      TabOrder = 1
      object lblTotalRecords: TLabel
        Left = 8
        Top = 12
        Width = 80
        Height = 13
        Caption = '总记录: 0 条'
      end
      object lblTotalFiles: TLabel
        Left = 150
        Top = 12
        Width = 120
        Height = 13
        Caption = '累计删除: 0 个文件'
      end
      object lblTotalSpace: TLabel
        Left = 330
        Top = 12
        Width = 80
        Height = 13
        Caption = '累计释放: 0 B'
      end
    end
    object pnlFilter: TPanel
      Left = 0
      Top = 90
      Width = 900
      Height = 35
      Align = alTop
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 2
      object lblFilter: TLabel
        Left = 8
        Top = 10
        Width = 60
        Height = 13
        Caption = '筛选类型:'
      end
      object cbFilterType: TComboBox
        Left = 74
        Top = 6
        Width = 180
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbFilterTypeChange
      end
      object btnRefresh: TButton
        Left = 264
        Top = 5
        Width = 75
        Height = 23
        Caption = '刷新'
        TabOrder = 1
        OnClick = btnRefreshClick
      end
    end
    object pnlList: TPanel
      Left = 0
      Top = 125
      Width = 900
      Height = 420
      Align = alClient
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 3
      object lvHistory: TListView
        Left = 8
        Top = 8
        Width = 884
        Height = 404
        Align = alClient
        Columns = <
          item
            Caption = '时间'
            Width = 150
          end
          item
            Caption = '类型'
            Width = 140
          end
          item
            Caption = '状态'
            Width = 60
          end
          item
            Alignment = taRightJustify
            Caption = '删除文件'
            Width = 80
          end
          item
            Alignment = taRightJustify
            Caption = '释放空间'
            Width = 100
          end
          item
            Alignment = taRightJustify
            Caption = '耗时'
            Width = 80
          end
          item
            Caption = '错误信息'
            Width = 250
          end>
        GridLines = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnColumnClick = lvHistoryColumnClick
        OnCustomDrawItem = lvHistoryCustomDrawItem
      end
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 545
      Width = 900
      Height = 55
      Align = alBottom
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 4
      object btnExportText: TButton
        Left = 8
        Top = 12
        Width = 100
        Height = 25
        Caption = '导出报告(TXT)'
        TabOrder = 0
        OnClick = btnExportTextClick
      end
      object btnExportJSON: TButton
        Left = 114
        Top = 12
        Width = 100
        Height = 25
        Caption = '导出(JSON)'
        TabOrder = 1
        OnClick = btnExportJSONClick
      end
      object btnClear: TButton
        Left = 220
        Top = 12
        Width = 100
        Height = 25
        Caption = '清空历史'
        TabOrder = 2
        OnClick = btnClearClick
      end
      object btnClose: TButton
        Left = 817
        Top = 12
        Width = 75
        Height = 25
        Caption = '关闭'
        TabOrder = 3
        OnClick = btnCloseClick
      end
    end
  end
  object SaveDialog: TSaveDialog
    Filter = '文本文件 (*.txt)|*.txt|JSON文件 (*.json)|*.json'
    Left = 840
    Top = 8
  end
end
