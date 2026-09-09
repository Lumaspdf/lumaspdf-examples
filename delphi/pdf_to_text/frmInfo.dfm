object frmProgInfo: TfrmProgInfo
  Left = 333
  Top = 258
  BorderStyle = bsDialog
  Caption = 'About  PDF To Text'
  ClientHeight = 250
  ClientWidth = 577
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 48
    Width = 561
    Height = 193
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Lines.Strings = (
      
        'This application demonstrates how a simple algorithm to construc' +
        't words and text lines can be '
      'created.'
      ''
      
        'The class CPDFToText(defined in utils/pdf_tex_extraction.pas) cr' +
        'eates text lines from the '
      
        'output of the content parser. The text is written to the output ' +
        'text file in UTF-16LE Unicode'
      
        'format. Use the Windows Editor to view the file. It is usually b' +
        'est to use the font Arial Unicode '
      'MS'
      
        'to view such text files because it can contain Asian or other la' +
        'nguage dependent characters.'
      ''
      
        'If the logical reading order should be preserved then the entire' +
        ' text of a page must be stored in '
      
        'an array and sorted in x- and y-direction before the contents of' +
        ' the page is written to the file.')
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object Button1: TButton
    Left = 440
    Top = 8
    Width = 129
    Height = 25
    Caption = 'Close'
    ModalResult = 1
    TabOrder = 1
  end
end
