unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, GameControl, Display, DataTypes,
  Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Timer1: TTimer;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
    FGameManager:TGameManager;
    procedure DisplayLoop;
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.DisplayLoop;
var
  X,Y:SmallInt;
  tmp:Int64;
  LGameInfo:TGameInformation;
begin

  LGameInfo:=FGameManager.GetGameInformation;
  PaintEmptyBoard(Image1,BOARD_SIZE);
  PaintOccupation(Image1,BOARD_SIZE,FGameManager.GetBoard());
  DisplayGameInformation(LGameInfo,Image2);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGameManager:=TGameManager.Create;
  FGameManager.NewGame(100,100,30,3,False,False);
  FGameManager.Think;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if Assigned(FGameManager) then
    DisplayLoop;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  BX,BY:Integer;
begin
  if Button = mbLeft then
  begin
    DisplayToBoard(X,Y,Image1,BOARD_SIZE,BX,BY);
    if (BX>=1) and (BX<=BOARD_SIZE) and (BY>=1) and (BY<=BOARD_SIZE) then
      FGameManager.MoveNow(BX,BY);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  FGameManager.ComputerMoveNow;
end;

end.
