object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 411
  ClientWidth = 852
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 32
    Top = 16
    Width = 385
    Height = 387
    OnMouseDown = Image1MouseDown
  end
  object Image2: TImage
    Left = 423
    Top = 16
    Width = 194
    Height = 387
  end
  object Button1: TButton
    Left = 640
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Best Move'
    OnClick = Button1Click
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 656
    Top = 104
  end
end
