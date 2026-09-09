object Form1: TForm1
  Left = 316
  Top = 284
  BorderStyle = bsDialog
  Caption = 'Text formatting'
  ClientHeight = 126
  ClientWidth = 285
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 4
    Width = 256
    Height = 26
    Caption = 'This example demonstrates how multi-column text can be created.'
    WordWrap = True
  end
  object Label2: TLabel
    Left = 8
    Top = 40
    Width = 98
    Height = 13
    Caption = 'How many columns?'
  end
  object Button1: TButton
    Left = 64
    Top = 64
    Width = 161
    Height = 41
    Caption = 'Create and view PDF file'
    TabOrder = 0
    OnClick = Button1Click
  end
  object cboColumns: TComboBox
    Left = 112
    Top = 36
    Width = 97
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
    Items.Strings = (
      '1 Column'
      '2 Columns'
      '3 Columns'
      '4 Columns'
      '5 Columns')
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '*.pdf'
    FileName = 'dout.pdf'
    InitialDir = 'c:'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing, ofDontAddToRecent]
    Title = 'Save PDF file'
    Left = 248
    Top = 80
  end
end
