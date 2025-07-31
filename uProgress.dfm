object frmProgress: TfrmProgress
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #36827#24230#26174#31034
  ClientHeight = 180
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 180
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 16
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 16
      Width = 368
      Height = 16
      Align = alTop
      Caption = #25805#20316#26631#39064
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 52
    end
    object lblMessage: TLabel
      Left = 16
      Top = 40
      Width = 368
      Height = 13
      Align = alTop
      Caption = #27491#22312#22788#29702'...'
      ShowHint = True
      ExplicitWidth = 60
    end
    object pbProgress: TProgressBar
      Left = 16
      Top = 61
      Width = 368
      Height = 17
      Align = alTop
      TabOrder = 0
    end
    object lblPercent: TLabel
      Left = 16
      Top = 86
      Width = 368
      Height = 13
      Align = alTop
      Alignment = taCenter
      Caption = '0%'
      ExplicitWidth = 12
    end
    object lblElapsedTime: TLabel
      Left = 16
      Top = 107
      Width = 368
      Height = 13
      Align = alTop
      Caption = #24050#29992#26102#38388': 00:00:00'
      ExplicitWidth = 84
    end
    object lblEstimatedTime: TLabel
      Left = 16
      Top = 128
      Width = 368
      Height = 13
      Align = alTop
      Caption = #39044#35745#21097#20313': --:--:--'
      ExplicitWidth = 84
    end
    object btnCancel: TButton
      Left = 162
      Top = 147
      Width = 75
      Height = 25
      Caption = #21462#28040
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object tmrUpdate: TTimer
    Interval = 1000
    OnTimer = tmrUpdateTimer
    Left = 360
    Top = 8
  end
end
