object Form1: TForm1
  Left = 703
  Top = 412
  BorderStyle = bsDialog
  Caption = 'Hello World'
  ClientHeight = 161
  ClientWidth = 336
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
  object Button1: TButton
    Left = 64
    Top = 49
    Width = 208
    Height = 56
    Caption = 'Create and view PDF file'
    TabOrder = 0
    OnClick = Button1Click
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '*.pdf'
    FileName = 'dout.pdf'
    InitialDir = 'c:'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing, ofDontAddToRecent]
    Title = 'Save PDF file'
  end
end
