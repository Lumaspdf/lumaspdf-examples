object Form1: TForm1
  Left = 746
  Top = 231
  Caption = 'RenderPage'
  ClientHeight = 999
  ClientWidth = 807
  Color = 5263440
  Constraints.MinHeight = 50
  Constraints.MinWidth = 50
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyUp = FormKeyUp
  OnMouseWheel = FormMouseWheel
  OnPaint = FormPaint
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object OpenDialog: TOpenDialog
    Filter = 'PDF Files|*.pdf'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 72
    Top = 56
  end
end
