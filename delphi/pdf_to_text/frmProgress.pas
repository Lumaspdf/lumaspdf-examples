unit frmProgress;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Grids, ValEdit;

type
  TfrmConvProgress = class(TForm)
    pProgress: TPanel;
    Panel1: TPanel;
    btnCancel: TButton;
    pFinish: TPanel;
    pProgress2: TPanel;
    lbActivePage: TLabel;
    lbState: TLabel;
    prgFile: TProgressBar;
    prgPage: TProgressBar;
    lbFileName: TLabel;
    lbMainState: TLabel;
    lstErrorLog: TValueListEditor;
    StatusBar1: TStatusBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FCancel: Boolean;
  public
    procedure AddLine(const FileName, Comment: String);
    procedure SetFinish;
    property Cancel: Boolean read FCancel write FCancel;
  end;

var
  frmConvProgress: TfrmConvProgress;

implementation

{$R *.dfm}

procedure TfrmConvProgress.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   btnCancel.Caption := 'Cancel';
end;

procedure TfrmConvProgress.btnCancelClick(Sender: TObject);
begin
   FCancel := true;
   if btnCancel.Caption = 'Close' then Self.Close;
end;

procedure TfrmConvProgress.FormShow(Sender: TObject);
begin
   FCancel := false;
   lbMainState.Caption := 'In Progress:';
   pProgress2.Visible  := true;
   pFinish.Visible     := false;
end;

procedure TfrmConvProgress.AddLine(const FileName, Comment: String);
begin
   lstErrorLog.InsertRow(FileName, Comment, true);
end;

procedure TfrmConvProgress.SetFinish;
begin
   pFinish.Visible    := true;
   pProgress2.Visible := false;
   btnCancel.Caption  := 'Close';
end;

end.
