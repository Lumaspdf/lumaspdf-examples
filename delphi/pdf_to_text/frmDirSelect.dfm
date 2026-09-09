object frmSelectDir: TfrmSelectDir
  Left = 362
  Top = 355
  BorderStyle = bsDialog
  Caption = 'Convert PDF files to text'
  ClientHeight = 101
  ClientWidth = 391
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
  object Label1: TLabel
    Left = 8
    Top = 48
    Width = 75
    Height = 13
    Caption = 'Output directory'
  end
  object edtPath: TEdit
    Left = 8
    Top = 72
    Width = 350
    Height = 21
    TabOrder = 0
  end
  object BitBtn1: TBitBtn
    Left = 364
    Top = 72
    Width = 21
    Height = 21
    TabOrder = 1
    OnClick = BitBtn1Click
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFF0000000000000FF77777777777700FF7FB8B8B8B8
      B700F7FB8B8B8B8B8070F7F8B8B8B8B870707F8B8B8B8B8B07707FFFFFFFFFF7
      08707777777777777B70F7F8B8B8B8B8B870F7FB8B8B8FFFFF70F7F8B8B8F777
      777FFF7FFFFF7FFFFFFFFFF77777FFFFFFFFFFFFFFFFFFFFFFFF}
    Layout = blGlyphRight
  end
  object Button1: TButton
    Left = 264
    Top = 8
    Width = 121
    Height = 25
    Caption = 'Convert now'
    ModalResult = 1
    TabOrder = 3
  end
  object Button2: TButton
    Left = 264
    Top = 40
    Width = 121
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object chkRecursive: TCheckBox
    Left = 8
    Top = 16
    Width = 129
    Height = 17
    Caption = 'Include subdirectories'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
end
