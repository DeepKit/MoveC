object frmAdvancedFileManager: TfrmAdvancedFileManager
  Left = 0
  Top = 0
  Caption = '高级文件管理器'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
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
    Width = 900
    Height = 555
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    
    object pgcMain: TPageControl
      Left = 0
      Top = 0
      Width = 900
      Height = 555
      ActivePage = tsFileSearch
      Align = alClient
      TabOrder = 0
      
      object tsFileSearch: TTabSheet
        Caption = '文件搜索'
        
        object pnlSearchCriteria: TPanel
          Left = 0
          Top = 0
          Width = 892
          Height = 140
          Align = alTop
          BevelInner = bvRaised
          BevelOuter = bvLowered
          TabOrder = 0
          
          object lblSearchPath: TLabel
            Left = 16
            Top = 16
            Width = 60
            Height = 13
            Caption = '搜索路径:'
          end
          
          object lblNamePattern: TLabel
            Left = 16
            Top = 48
            Width = 60
            Height = 13
            Caption = '文件名称:'
          end
          
          object lblSizeRange: TLabel
            Left = 350
            Top = 48
            Width = 60
            Height = 13
            Caption = '文件大小:'
          end
          
          object lblSizeTo: TLabel
            Left = 520
            Top = 48
            Width = 12
            Height = 13
            Caption = '到'
          end
          
          object lblDateRange: TLabel
            Left = 16
            Top = 80
            Width = 60
            Height = 13
            Caption = '修改时间:'
          end
          
          object lblDateTo: TLabel
            Left = 220
            Top = 80
            Width = 12
            Height = 13
            Caption = '到'
          end
          
          object edtSearchPath: TEdit
            Left = 82
            Top = 13
            Width = 200
            Height = 21
            TabOrder = 0
          end
          
          object btnBrowseSearchPath: TBitBtn
            Left = 288
            Top = 12
            Width = 30
            Height = 23
            Caption = '...'
            TabOrder = 1
            OnClick = btnBrowseSearchPathClick
          end
          
          object edtNamePattern: TEdit
            Left = 82
            Top = 45
            Width = 200
            Height = 21
            TabOrder = 2
          end
          
          object chkUseRegex: TCheckBox
            Left = 288
            Top = 47
            Width = 50
            Height = 17
            Caption = '正则'
            TabOrder = 3
          end
          
          object edtMinSize: TEdit
            Left = 416
            Top = 45
            Width = 80
            Height = 21
            TabOrder = 4
          end
          
          object edtMaxSize: TEdit
            Left = 540
            Top = 45
            Width = 80
            Height = 21
            TabOrder = 5
          end
          
          object cmbSizeUnit: TComboBox
            Left = 626
            Top = 45
            Width = 50
            Height = 21
            Style = csDropDownList
            ItemIndex = 2
            TabOrder = 6
            Text = 'MB'
            Items.Strings = (
              'B'
              'KB'
              'MB'
              'GB')
          end
          
          object dtpDateFrom: TDateTimePicker
            Left = 82
            Top = 77
            Width = 130
            Height = 21
            Date = 44927.000000000000000000
            Time = 44927.000000000000000000
            TabOrder = 7
          end
          
          object dtpDateTo: TDateTimePicker
            Left = 240
            Top = 77
            Width = 130
            Height = 21
            Date = 44927.000000000000000000
            Time = 44927.000000000000000000
            TabOrder = 8
          end
          
          object chkIncludeSubdirs: TCheckBox
            Left = 400
            Top = 15
            Width = 97
            Height = 17
            Caption = '包含子目录'
            Checked = True
            State = cbChecked
            TabOrder = 9
          end
          
          object chkIncludeHidden: TCheckBox
            Left = 520
            Top = 15
            Width = 97
            Height = 17
            Caption = '包含隐藏文件'
            TabOrder = 10
          end
          
          object chkIncludeSystem: TCheckBox
            Left = 640
            Top = 15
            Width = 97
            Height = 17
            Caption = '包含系统文件'
            TabOrder = 11
          end
          
          object btnStartSearch: TBitBtn
            Left = 400
            Top = 105
            Width = 80
            Height = 25
            Caption = '开始搜索'
            TabOrder = 12
            OnClick = btnStartSearchClick
          end
          
          object btnCancelSearch: TBitBtn
            Left = 490
            Top = 105
            Width = 80
            Height = 25
            Caption = '取消'
            Enabled = False
            TabOrder = 13
            OnClick = btnCancelSearchClick
          end
        end
        
        object lvSearchResults: TListView
          Left = 0
          Top = 140
          Width = 892
          Height = 387
          Align = alClient
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
              Caption = '大小'
              Width = 100
            end
            item
              Caption = '修改时间'
              Width = 150
            end
            item
              Caption = '类型'
              Width = 100
            end>
          FullExpand = True
          GridLines = True
          PopupMenu = pmFileList
          ReadOnly = True
          RowSelect = True
          TabOrder = 1
          ViewStyle = vsReport
          OnDblClick = lvSearchResultsDblClick
        end
      end
      
      object tsDuplicateFiles: TTabSheet
        Caption = '重复文件'
        ImageIndex = 1
        
        object pnlDuplicateControls: TPanel
          Left = 0
          Top = 0
          Width = 892
          Height = 50
          Align = alTop
          BevelInner = bvRaised
          BevelOuter = bvLowered
          TabOrder = 0
          
          object lblDuplicatePath: TLabel
            Left = 16
            Top = 18
            Width = 60
            Height = 13
            Caption = '扫描路径:'
          end
          
          object edtDuplicatePath: TEdit
            Left = 82
            Top = 15
            Width = 200
            Height = 21
            TabOrder = 0
          end
          
          object btnBrowseDuplicatePath: TBitBtn
            Left = 288
            Top = 14
            Width = 30
            Height = 23
            Caption = '...'
            TabOrder = 1
            OnClick = btnBrowseDuplicatePathClick
          end
          
          object btnFindDuplicates: TBitBtn
            Left = 340
            Top = 13
            Width = 80
            Height = 25
            Caption = '开始扫描'
            TabOrder = 2
            OnClick = btnFindDuplicatesClick
          end
          
          object btnCancelDuplicate: TBitBtn
            Left = 430
            Top = 13
            Width = 80
            Height = 25
            Caption = '取消'
            Enabled = False
            TabOrder = 3
            OnClick = btnCancelDuplicateClick
          end
        end
        
        object tvDuplicateGroups: TTreeView
          Left = 0
          Top = 50
          Width = 450
          Height = 477
          Align = alLeft
          Indent = 19
          PopupMenu = pmFileList
          ReadOnly = True
          ShowButtons = True
          ShowLines = True
          TabOrder = 1
          OnChange = tvDuplicateGroupsChange
        end
        
        object pnlDuplicateInfo: TPanel
          Left = 450
          Top = 50
          Width = 442
          Height = 477
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          
          object lblDuplicateInfo: TLabel
            Left = 16
            Top = 16
            Width = 100
            Height = 13
            Caption = '重复文件信息:'
          end
          
          object btnDeleteSelected: TBitBtn
            Left = 16
            Top = 450
            Width = 80
            Height = 25
            Caption = '删除选中'
            TabOrder = 0
            OnClick = btnDeleteSelectedClick
          end
          
          object btnKeepNewest: TBitBtn
            Left = 106
            Top = 450
            Width = 80
            Height = 25
            Caption = '保留最新'
            TabOrder = 1
            OnClick = btnKeepNewestClick
          end
          
          object btnKeepLargest: TBitBtn
            Left = 196
            Top = 450
            Width = 80
            Height = 25
            Caption = '保留最大'
            TabOrder = 2
            OnClick = btnKeepLargestClick
          end
        end
      end
      
      object tsLargeFiles: TTabSheet
        Caption = '大文件'
        ImageIndex = 2
        
        object pnlLargeFileControls: TPanel
          Left = 0
          Top = 0
          Width = 892
          Height = 50
          Align = alTop
          BevelInner = bvRaised
          BevelOuter = bvLowered
          TabOrder = 0
          
          object lblLargePath: TLabel
            Left = 16
            Top = 18
            Width = 60
            Height = 13
            Caption = '扫描路径:'
          end
          
          object lblMinFileSize: TLabel
            Left = 340
            Top = 18
            Width = 84
            Height = 13
            Caption = '最小文件大小:'
          end
          
          object edtLargePath: TEdit
            Left = 82
            Top = 15
            Width = 200
            Height = 21
            TabOrder = 0
          end
          
          object btnBrowseLargePath: TBitBtn
            Left = 288
            Top = 14
            Width = 30
            Height = 23
            Caption = '...'
            TabOrder = 1
            OnClick = btnBrowseLargePathClick
          end
          
          object edtMinFileSize: TEdit
            Left = 430
            Top = 15
            Width = 80
            Height = 21
            Text = '100'
            TabOrder = 2
          end
          
          object cmbFileSizeUnit: TComboBox
            Left = 516
            Top = 15
            Width = 50
            Height = 21
            Style = csDropDownList
            ItemIndex = 2
            TabOrder = 3
            Text = 'MB'
            Items.Strings = (
              'B'
              'KB'
              'MB'
              'GB')
          end
          
          object btnFindLargeFiles: TBitBtn
            Left = 580
            Top = 13
            Width = 80
            Height = 25
            Caption = '开始扫描'
            TabOrder = 4
            OnClick = btnFindLargeFilesClick
          end
          
          object btnCancelLarge: TBitBtn
            Left = 670
            Top = 13
            Width = 80
            Height = 25
            Caption = '取消'
            Enabled = False
            TabOrder = 5
            OnClick = btnCancelLargeClick
          end
        end
        
        object lvLargeFiles: TListView
          Left = 0
          Top = 50
          Width = 892
          Height = 477
          Align = alClient
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
              Caption = '大小'
              Width = 100
            end
            item
              Caption = '修改时间'
              Width = 150
            end>
          FullExpand = True
          GridLines = True
          PopupMenu = pmFileList
          ReadOnly = True
          RowSelect = True
          TabOrder = 1
          ViewStyle = vsReport
          OnDblClick = lvLargeFilesDblClick
        end
      end
      
      object tsBatchOp: TTabSheet
        Caption = '批量操作'
        ImageIndex = 3
        
        object pnlBatchControls: TPanel
          Left = 0
          Top = 0
          Width = 892
          Height = 80
          Align = alTop
          BevelInner = bvRaised
          BevelOuter = bvLowered
          TabOrder = 0
          
          object lblBatchOperation: TLabel
            Left = 16
            Top = 18
            Width = 60
            Height = 13
            Caption = '操作类型:'
          end
          
          object lblTargetPath: TLabel
            Left = 200
            Top = 18
            Width = 60
            Height = 13
            Caption = '目标路径:'
          end
          
          object cmbBatchOperation: TComboBox
            Left = 82
            Top = 15
            Width = 100
            Height = 21
            Style = csDropDownList
            ItemIndex = 0
            TabOrder = 0
            Text = '复制文件'
            OnChange = cmbBatchOperationChange
            Items.Strings = (
              '复制文件'
              '移动文件'
              '删除文件'
              '重命名文件')
          end
          
          object edtTargetPath: TEdit
            Left = 266
            Top = 15
            Width = 200
            Height = 21
            TabOrder = 1
          end
          
          object btnBrowseTargetPath: TBitBtn
            Left = 472
            Top = 14
            Width = 30
            Height = 23
            Caption = '...'
            TabOrder = 2
            OnClick = btnBrowseTargetPathClick
          end
          
          object chkOverwrite: TCheckBox
            Left = 520
            Top = 17
            Width = 97
            Height = 17
            Caption = '覆盖现有文件'
            TabOrder = 3
          end
          
          object btnAddFiles: TBitBtn
            Left = 16
            Top = 47
            Width = 80
            Height = 25
            Caption = '添加文件'
            TabOrder = 4
            OnClick = btnAddFilesClick
          end
          
          object btnRemoveFiles: TBitBtn
            Left = 106
            Top = 47
            Width = 80
            Height = 25
            Caption = '移除文件'
            TabOrder = 5
            OnClick = btnRemoveFilesClick
          end
          
          object btnClearFiles: TBitBtn
            Left = 196
            Top = 47
            Width = 80
            Height = 25
            Caption = '清空列表'
            TabOrder = 6
            OnClick = btnClearFilesClick
          end
          
          object btnExecuteBatch: TBitBtn
            Left = 320
            Top = 47
            Width = 80
            Height = 25
            Caption = '执行操作'
            TabOrder = 7
            OnClick = btnExecuteBatchClick
          end
        end
        
        object lvBatchFiles: TListView
          Left = 0
          Top = 80
          Width = 892
          Height = 447
          Align = alClient
          CheckBoxes = True
          Columns = <
            item
              Caption = '文件名'
              Width = 200
            end
            item
              Caption = '路径'
              Width = 400
            end
            item
              Caption = '大小'
              Width = 100
            end>
          GridLines = True
          PopupMenu = pmFileList
          RowSelect = True
          TabOrder = 1
          ViewStyle = vsReport
        end
      end
    end
  end
  
  object pnlBottom: TPanel
    Left = 0
    Top = 555
    Width = 900
    Height = 45
    Align = alBottom
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    
    object lblStatus: TLabel
      Left = 16
      Top = 16
      Width = 24
      Height = 13
      Caption = '就绪'
    end
    
    object ProgressBar: TProgressBar
      Left = 200
      Top = 13
      Width = 400
      Height = 17
      TabOrder = 0
      Visible = False
    end
    
    object btnCancel: TBitBtn
      Left = 810
      Top = 10
      Width = 75
      Height = 25
      Caption = '取消'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  
  object pmFileList: TPopupMenu
    Left = 100
    Top = 200
    
    object miOpenFile: TMenuItem
      Caption = '打开文件'
      OnClick = miOpenFileClick
    end
    
    object miOpenFolder: TMenuItem
      Caption = '打开文件夹'
      OnClick = miOpenFolderClick
    end
    
    object miCopyPath: TMenuItem
      Caption = '复制路径'
      OnClick = miCopyPathClick
    end
    
    object miSeparator1: TMenuItem
      Caption = '-'
    end
    
    object miProperties: TMenuItem
      Caption = '属性'
      OnClick = miPropertiesClick
    end
    
    object miDelete: TMenuItem
      Caption = '删除'
      OnClick = miDeleteClick
    end
  end
end