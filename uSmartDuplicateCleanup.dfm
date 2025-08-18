object frmSmartDuplicateCleanup: TfrmSmartDuplicateCleanup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #26234#33021#37325#22797#25991#20214#28165#29702
  ClientHeight = 500
  ClientWidth = 600
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
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 500
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 594
    ExplicitHeight = 483
    object pnlTop: TPanel
      Left = 0
      Top = 0
      Width = 600
      Height = 80
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      ExplicitWidth = 594
      object lblTitle: TLabel
        Left = 24
        Top = 16
        Width = 136
        Height = 19
        Caption = #26234#33021#37325#22797#25991#20214#28165#29702
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 24
        Top = 45
        Width = 192
        Height = 13
        Caption = #38646#20915#31574#36127#25285#65292#19968#38190#26234#33021#28165#29702#37325#22797#25991#20214
      end
    end
    object pnlCenter: TPanel
      Left = 0
      Top = 80
      Width = 600
      Height = 360
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 594
      ExplicitHeight = 343
      object pnlActions: TPanel
        Left = 24
        Top = 16
        Width = 552
        Height = 120
        BevelOuter = bvLowered
        TabOrder = 0
        object lblStatus: TLabel
          Left = 16
          Top = 72
          Width = 162
          Height = 13
          Caption = #23601#32490' - '#28857#20987'"'#25195#25551#37325#22797#25991#20214'"'#24320#22987
        end
        object btnScanDuplicates: TButton
          Left = 16
          Top = 16
          Width = 160
          Height = 40
          Caption = #62733' '#25195#25551#37325#22797#25991#20214
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnClick = btnScanDuplicatesClick
        end
        object btnOneClickCleanup: TButton
          Left = 196
          Top = 16
          Width = 160
          Height = 40
          Caption = #9889' '#19968#38190#26234#33021#28165#29702
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 1
          OnClick = btnOneClickCleanupClick
        end
        object btnViewReport: TButton
          Left = 376
          Top = 16
          Width = 160
          Height = 40
          Caption = #62666' '#26597#30475#35814#32454#25253#21578
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          OnClick = btnViewReportClick
        end
        object ProgressBar: TProgressBar
          Left = 16
          Top = 91
          Width = 520
          Height = 17
          TabOrder = 3
          Visible = False
        end
      end
      object gbMode: TGroupBox
        Left = 24
        Top = 152
        Width = 200
        Height = 100
        Caption = #28165#29702#27169#24335
        TabOrder = 1
        object rbConservative: TRadioButton
          Left = 16
          Top = 24
          Width = 150
          Height = 17
          Caption = #20445#23432#27169#24335#65288#26368#23433#20840#65289
          TabOrder = 0
          OnClick = rbModeClick
        end
        object rbStandard: TRadioButton
          Left = 16
          Top = 47
          Width = 150
          Height = 17
          Caption = #26631#20934#27169#24335#65288#25512#33616#65289
          Checked = True
          TabOrder = 1
          TabStop = True
          OnClick = rbModeClick
        end
        object rbAggressive: TRadioButton
          Left = 16
          Top = 70
          Width = 150
          Height = 17
          Caption = #28608#36827#27169#24335#65288#26368#22823#28165#29702#65289
          TabOrder = 2
          OnClick = rbModeClick
        end
      end
      object gbScanOptions: TGroupBox
        Left = 240
        Top = 152
        Width = 336
        Height = 100
        Caption = #25195#25551#33539#22260
        TabOrder = 2
        object chkIncludeDownloads: TCheckBox
          Left = 16
          Top = 24
          Width = 97
          Height = 17
          Caption = #19979#36733#30446#24405
          Checked = True
          State = cbChecked
          TabOrder = 0
        end
        object chkIncludeDesktop: TCheckBox
          Left = 16
          Top = 47
          Width = 97
          Height = 17
          Caption = #26700#38754
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object chkIncludeDocuments: TCheckBox
          Left = 16
          Top = 70
          Width = 97
          Height = 17
          Caption = #25991#26723#30446#24405
          TabOrder = 2
        end
        object edtCustomPath: TEdit
          Left = 128
          Top = 24
          Width = 150
          Height = 21
          TabOrder = 3
        end
        object btnBrowsePath: TButton
          Left = 284
          Top = 22
          Width = 40
          Height = 25
          Caption = '...'
          TabOrder = 4
          OnClick = btnBrowsePathClick
        end
      end
      object pnlResults: TPanel
        Left = 24
        Top = 268
        Width = 552
        Height = 80
        BevelOuter = bvLowered
        TabOrder = 3
        Visible = False
        object lblResults: TLabel
          Left = 16
          Top = 12
          Width = 169
          Height = 13
          Caption = #25195#25551#23436#25104#65306#25214#21040' 0 '#32452#37325#22797#25991#20214
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblFilesFound: TLabel
          Left = 16
          Top = 32
          Width = 105
          Height = 13
          Caption = #37325#22797#25991#20214#25968#37327#65306'0 '#20010
        end
        object lblSpaceSaved: TLabel
          Left = 200
          Top = 32
          Width = 87
          Height = 13
          Caption = #21487#33410#30465#31354#38388#65306'0 B'
        end
        object lblSafetyLevel: TLabel
          Left = 16
          Top = 52
          Width = 183
          Height = 13
          Caption = #63104' '#27809#26377#21457#29616#37325#22797#25991#20214#65292#31995#32479#24456#24178#20928
        end
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 440
      Width = 600
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      ExplicitTop = 423
      ExplicitWidth = 594
      object btnClose: TButton
        Left = 500
        Top = 16
        Width = 75
        Height = 25
        Caption = #20851#38381
        TabOrder = 0
        OnClick = btnCloseClick
      end
      object btnAdvanced: TButton
        Left = 400
        Top = 16
        Width = 90
        Height = 25
        Caption = #39640#32423#36873#39033'...'
        TabOrder = 1
        OnClick = btnAdvancedClick
      end
    end
  end
end
