object frmSyncSettingsSimple: TfrmSyncSettingsSimple
  Left = 0
  Top = 0
  Caption = '同步盘设置'
  ClientHeight = 400
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object lblTitle: TLabel
    Left = 16
    Top = 16
    Width = 120
    Height = 15
    Caption = '同步盘功能模块'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object memoInfo: TMemo
    Left = 16
    Top = 48
    Width = 568
    Height = 300
    Lines.Strings = (
      '')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btnClose: TButton
    Left = 509
    Top = 360
    Width = 75
    Height = 25
    Caption = '关闭'
    TabOrder = 1
    OnClick = btnCloseClick
  end
end
