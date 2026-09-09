object PwdDialog: TPwdDialog
  Left = 559
  Top = 383
  BorderStyle = bsDialog
  Caption = 'Enter Password'
  ClientHeight = 90
  ClientWidth = 314
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 32
    Width = 49
    Height = 13
    Caption = 'Password:'
  end
  object txtPassword: TEdit
    Left = 16
    Top = 48
    Width = 169
    Height = 21
    PasswordChar = '*'
    TabOrder = 0
  end
  object Button1: TButton
    Left = 200
    Top = 16
    Width = 105
    Height = 25
    Caption = 'Ok'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 200
    Top = 48
    Width = 105
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
