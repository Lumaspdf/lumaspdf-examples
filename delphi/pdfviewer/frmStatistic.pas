unit frmStatistic;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TStatisticDlg = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    lbAnnots: TLabel;
    lbFields: TLabel;
    lbCurves: TLabel;
    lbLines: TLabel;
    lbRectangles: TLabel;
    lbGlyphs: TLabel;
    lbTextRecords: TLabel;
    lbImages: TLabel;
    lbSoftMasks: TLabel;
    lbPaths: TLabel;
    lbClipPaths: TLabel;
    lbSaveGStates: TLabel;
    lbRestGStates: TLabel;
    lbErrors: TLabel;
    Label15: TLabel;
    lbPatterns: TLabel;
    Label16: TLabel;
    lbShadings: TLabel;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  StatisticDlg: TStatisticDlg;

implementation

{$R *.dfm}

end.
