unit Test.BoardControls;

interface
uses
  DUnitX.TestFramework,
  DataTypes,
  BoardControls;

type

  [TestFixture]
  TTestBoardControls = class(TObject)
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIsSuicide;

    [Test]
    procedure TestReverseColor;
  end;

implementation

procedure TTestBoardControls.TestIsSuicide;
var
  LX,LY:SmallInt;
  LColor:SmallInt;
  ABoard:TBoard;
  i,j:Integer;
begin
  ResetBoard(@ABoard); //clear the board
  ABoard.Occupation[1,2]:=1;
  ABoard.Occupation[2,1]:=1;
  LX:=1;
  LY:=1;
  LColor:=2;
  {
    placing stone in corner, surrounded by two enemies
    Should be suicide.
  }
  Assert.AreEqual(True,IsSuicide(LX,LY,LColor,@ABoard));
  {
    reversing the color should make it a valid move
  }
  LColor:=1;
  Assert.AreEqual(False,IsSuicide(LX,LY,LColor,@ABoard));

  {
    and now enemy color again, but we take one of the surrounding stones aways
    now it has one liberty
  }
  LColor:=2;
  ABoard.Occupation[1,2]:=0;
  Assert.AreEqual(False,IsSuicide(LX,LY,LColor,@ABoard));

  {
    now we fill the board with white stones
    and only spare one corner liberty
    now a black stone on this position would take out the whole board
    so its no suicide
  }
  for i := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      ABoard.Occupation[i,j]:=1;
    end;
  end;
  LColor:=2;
  ABoard.Occupation[1,1]:=0;
  Assert.AreEqual(False,IsSuicide(LX,LY,LColor,@ABoard));

  {
    now we attempt to place a white stone on a full board with only one liberty
    this should be a suicide now
  }
  LColor:=1;
  Assert.AreEqual(True,IsSuicide(LX,LY,LColor,@ABoard));
end;

procedure TTestBoardControls.TestReverseColor;
begin
  Assert.AreEqual(1,Integer(ReverseColor(2)));
  Assert.AreEqual(2,Integer(ReverseColor(1)));
end;


procedure TTestBoardControls.Setup;
begin
end;

procedure TTestBoardControls.TearDown;
begin
end;


initialization

end.
