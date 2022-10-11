unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,GameControl,Display,DataTypes,
  Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
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

end.
