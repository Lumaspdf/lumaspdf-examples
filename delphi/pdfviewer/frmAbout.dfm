object AboutDlg: TAboutDlg
  Left = 489
  Top = 381
  BorderStyle = bsDialog
  Caption = 'AboutDlg'
  ClientHeight = 282
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 416
    Top = 8
    Width = 129
    Height = 33
    Caption = 'Close'
    ModalResult = 1
    TabOrder = 0
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 410
    Height = 282
    Align = alLeft
    BevelInner = bvNone
    BevelOuter = bvNone
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    Lines.Strings = (
      
        'This application was developed with Delphi. It uses the page cac' +
        'he of '
      'DynaPDF to render pages.'
      ''
      
        'The page cache offers multi-threaded rendering, perfectly smooth' +
        ' '
      
        'scrolling, flicker free redrawing, and anything else that is typ' +
        'ically '
      'required in a PDF viewer.'
      ''
      
        'To simplify the usage, the page cache is encapsulated in the Del' +
        'phi '
      
        'control TPDFCanvas. This controls is delivered with source codes' +
        ' '
      'and can be easily extended if necessary. The TPDFCanvas control '
      
        'was tested with Delphi 6, 7, 2009, and Delphi XE but it should a' +
        'lso '
      
        'be usable with older Delphi versions, with very few modification' +
        's.'
      ''
      'The rendering engine is part of DynaPDF Professional and '
      'Enterprise.')
    ParentCtl3D = False
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
  end
end
