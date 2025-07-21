object FrameAboutMe: TFrameAboutMe
  Left = 0
  Top = 0
  Width = 600
  Height = 200
  TabOrder = 0
  object pcAboutMe: TPageControl
    Left = 0
    Top = 0
    Width = 600
    Height = 200
    ActivePage = tsWechat
    Align = alClient
    TabOrder = 0
    object tsWechat: TTabSheet
      Caption = #24494#20449#25171#36175
      object imgWechat: TSkAnimatedImage
        Left = 16
        Top = 16
        Width = 120
        Height = 120
      end
      object lblWechatTip: TLabel
        Left = 152
        Top = 16
        Width = 60
        Height = 13
        Caption = #24494#20449#25910#27454#30721
      end
      object lblWechatAddress: TLabel
        Left = 152
        Top = 40
        Width = 300
        Height = 13
        Caption = #24494#20449#25910#27454#22320#22336
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object tsAlipay: TTabSheet
      Caption = #25903#20184#23453#25171#36175
      ImageIndex = 1
      object imgAlipay: TSkAnimatedImage
        Left = 16
        Top = 16
        Width = 120
        Height = 120
      end
      object lblAlipayTip: TLabel
        Left = 152
        Top = 16
        Width = 72
        Height = 13
        Caption = #25903#20184#23453#25910#27454#30721
      end
      object lblAlipayAddress: TLabel
        Left = 152
        Top = 40
        Width = 300
        Height = 13
        Caption = #25903#20184#23453#25910#27454#22320#22336
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object tsBTC: TTabSheet
      Caption = 'BTC'#25171#36175
      ImageIndex = 2
      object imgBTC: TSkAnimatedImage
        Left = 16
        Top = 16
        Width = 120
        Height = 120
      end
      object lblBTCTip: TLabel
        Left = 152
        Top = 16
        Width = 60
        Height = 13
        Caption = 'BTC'#25171#36175#22320#22336
      end
      object lblBTCAddress: TLabel
        Left = 152
        Top = 40
        Width = 300
        Height = 13
        Caption = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnCopyBTC: TButton
        Left = 152
        Top = 64
        Width = 75
        Height = 25
        Caption = #22797#21046#22320#22336
        TabOrder = 0
        OnClick = btnCopyBTCClick
      end
    end
    object tsUSDT: TTabSheet
      Caption = 'USDT'#25171#36175
      ImageIndex = 3
      object imgUSDT: TSkAnimatedImage
        Left = 16
        Top = 16
        Width = 120
        Height = 120
      end
      object lblUSDTTip: TLabel
        Left = 152
        Top = 16
        Width = 96
        Height = 13
        Caption = 'USDT'#25171#36175#22320#22336'(TRON)'
      end
      object lblUSDTAddress: TLabel
        Left = 152
        Top = 40
        Width = 300
        Height = 13
        Caption = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnCopyUSDT: TButton
        Left = 152
        Top = 64
        Width = 75
        Height = 25
        Caption = #22797#21046#22320#22336
        TabOrder = 0
        OnClick = btnCopyUSDTClick
      end
    end
    object tsAboutMe: TTabSheet
      Caption = #20851#20110#25105
      ImageIndex = 4
      object imgAboutMe: TSkAnimatedImage
        Left = 16
        Top = 16
        Width = 120
        Height = 120
      end
      object lblAboutMeTip: TLabel
        Left = 152
        Top = 16
        Width = 300
        Height = 60
        Caption =
          'TwoKeyRun - '#21452#38190#24555#36895#21551#21160#24037#20855#13#10#24320#21457#32773': '#22909#35760#24518#31185#29702#24037#20316#23460#13#10#24863#35874#25903#25345': www.goodmem.cn'#13#10#24863#35874#25903#25345': www.goodmem.cn'#13#10#24863#35874#25903#25345': www.goodmem.cn'#13#10#24863#35874#25903#25345': www.goodmem.cn'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
      object lblMachineCode: TLabel
        Left = 152
        Top = 90
        Width = 48
        Height = 13
        Caption = #26426#22120#30721#65306
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblMachineCodeValue: TLabel
        Left = 206
        Top = 90
        Width = 200
        Height = 13
        Caption = #27491#22312#29983#25104'...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Cursor = crHandPoint
        OnClick = lblMachineCodeValueClick
      end
    end
  end
end
