object frmConvProgress: TfrmConvProgress
  Left = 318
  Top = 328
  Width = 560
  Height = 358
  Caption = 'Convert PDF to Text'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object pProgress: TPanel
    Left = 0
    Top = 41
    Width = 548
    Height = 98
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      548
      98)
    object pProgress2: TPanel
      Left = 0
      Top = 0
      Width = 668
      Height = 100
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        668
        100)
      object lbActivePage: TLabel
        Left = 98
        Top = 49
        Width = 31
        Height = 16
        Caption = '0 of 0'
      end
      object lbState: TLabel
        Left = 5
        Top = 49
        Width = 70
        Height = 16
        Caption = 'Read Page'
      end
      object lbFileName: TLabel
        Left = 98
        Top = 0
        Width = 3
        Height = 16
      end
      object lbMainState: TLabel
        Left = 5
        Top = 0
        Width = 71
        Height = 16
        Caption = 'In Progress:'
      end
      object prgFile: TProgressBar
        Left = 0
        Top = 20
        Width = 666
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Min = 0
        Max = 100
        Smooth = True
        Step = 1
        TabOrder = 0
      end
      object prgPage: TProgressBar
        Left = 0
        Top = 69
        Width = 666
        Height = 26
        Anchors = [akLeft, akTop, akRight]
        Min = 0
        Max = 100
        Smooth = True
        Step = 1
        TabOrder = 1
      end
    end
    object pFinish: TPanel
      Left = 0
      Top = 0
      Width = 548
      Height = 98
      Align = alClient
      BevelOuter = bvNone
      Caption = 'Finish'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 548
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      548
      41)
    object btnCancel: TButton
      Left = 417
      Top = 10
      Width = 124
      Height = 31
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 0
      OnClick = btnCancelClick
    end
  end
  object lstErrorLog: TValueListEditor
    Left = 0
    Top = 139
    Width = 548
    Height = 162
    Align = alClient
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goTabs, goRowSelect, goThumbTracking]
    TabOrder = 2
    TitleCaptions.Strings = (
      'File'
      'Conversion status')
    ColWidths = (
      238
      304)
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 301
    Width = 548
    Height = 20
    Panels = <
      item
        Text = 'Files selected:'
        Width = 75
      end
      item
        Text = '0'
        Width = 80
      end
      item
        Text = 'Files converted:'
        Width = 90
      end
      item
        Text = '0'
        Width = 50
      end>
    SimplePanel = False
  end
end
