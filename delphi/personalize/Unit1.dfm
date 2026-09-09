object Form1: TForm1
  Left = 336
  Top = 261
  BorderStyle = bsDialog
  Caption = 'Edit an existing pdf file'
  ClientHeight = 196
  ClientWidth = 337
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 10
    Top = 10
    Width = 291
    Height = 48
    Caption = 
      'This sample demonstrate how to edit an existing pdf file. The fi' +
      'le: '#39'taxform.pdf'#39' is a german tax form that will be filled out b' +
      'y this application.'
    WordWrap = True
  end
  object Button1: TButton
    Left = 39
    Top = 123
    Width = 253
    Height = 41
    Caption = 'Create and view output file'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 39
    Top = 69
    Width = 253
    Height = 41
    Caption = 'View original file'
    TabOrder = 1
    OnClick = Button2Click
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '*.pdf'
    FileName = 'dout.pdf'
    InitialDir = 'c:'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing, ofDontAddToRecent]
    Title = 'Save PDF file'
    Left = 240
    Top = 120
  end
end
