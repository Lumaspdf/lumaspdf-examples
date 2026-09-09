object FormErrorLog: TFormErrorLog
  Left = 202
  Top = 237
  BorderIcons = [biSystemMenu]
  Caption = 'FormErrorLog'
  ClientHeight = 431
  ClientWidth = 682
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    682
    431)
  PixelsPerInch = 96
  TextHeight = 13
  object Messages: TMemo
    Left = 0
    Top = 0
    Width = 545
    Height = 431
    Align = alLeft
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvNone
    BevelOuter = bvNone
    Ctl3D = False
    HideSelection = False
    ParentCtl3D = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    WantReturns = False
  end
  object Button1: TButton
    Left = 560
    Top = 12
    Width = 113
    Height = 33
    Anchors = [akTop, akRight]
    Caption = 'Close'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 560
    Top = 56
    Width = 113
    Height = 33
    Caption = 'Clear'
    TabOrder = 2
    OnClick = Button2Click
  end
end
