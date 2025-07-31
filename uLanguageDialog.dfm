object frmLanguageDialog: TfrmLanguageDialog
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #35821#35328#35774#32622
  ClientHeight = 200
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 350
    Height = 200
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 16
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 16
      Width = 318
      Height = 16
      Align = alTop
      Caption = #36873#25321#30028#38754#35821#35328
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 78
    end
    object lblDescription: TLabel
      Left = 16
      Top = 40
      Width = 318
      Height = 13
      Align = alTop
      Caption = #35831#36873#25321#24744#24076#26395#20351#29992#30340#30028#38754#35821#35328#65306
      ExplicitWidth = 168
    end
    object lblCurrentLanguage: TLabel
      Left = 16
      Top = 61
      Width = 318
      Height = 13
      Align = alTop
      Caption = #24403#21069#35821#35328': '#31616#20307#20013#25991
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitWidth = 84
    end
    object cmbLanguage: TComboBox
      Left = 16
      Top = 90
      Width = 318
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbLanguageChange
    end
    object pnlButtons: TPanel
      Left = 16
      Top = 127
      Width = 318
      Height = 57
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 126
      object btnOK: TButton
        Left = 162
        Top = 16
        Width = 75
        Height = 25
        Caption = #30830#23450
        Default = True
        TabOrder = 0
        OnClick = btnOKClick
      end
      object btnCancel: TButton
        Left = 243
        Top = 16
        Width = 75
        Height = 25
        Cancel = True
        Caption = #21462#28040
        TabOrder = 1
        OnClick = btnCancelClick
      end
    end
  end
end
