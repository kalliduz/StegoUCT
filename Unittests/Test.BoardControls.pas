unit Test.BoardControls;
{
  These unittests are designed to work with any squared board
  which is at least 5x5

  Smaller boards may result in unexpected behaviour!

  Bigger boards should always pass too!

}
interface
{$IFDEF FPC}
uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  DataTypes,
  BoardControls;
{$ELSE}
uses
  DUnitX.TestFramework,
  DataTypes,
  BoardControls;
{$ENDIF}

type
{$IFDEF FPC}
  TTestBoardControls = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestIsSuicide;
    procedure TestReverseColor;
    procedure TestWouldCaptureAnyThing;
    procedure TestCountLiberties;
    procedure TestIsSelfAtari;
  end;
{$ELSE}
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

    [Test]
    procedure TestWouldCaptureAnyThing;

    [Test]
    procedure TestCountLiberties;

    [Test]
    procedure TestIsSelfAtari;
  end;
{$ENDIF}

implementation
{$IFDEF FPC}
type
  Assert = class
  public
    class procedure AreEqual(const Expected, Actual: Integer); overload; static;
    class procedure AreEqual(const Expected, Actual: Boolean); overload; static;
    class procedure AreEqualMemory(Expected, Actual: Pointer; Size: PtrUInt); static;
    class procedure IsTrue(Condition: Boolean); static;
    class procedure IsFalse(Condition: Boolean); static;
  end;

class procedure Assert.AreEqual(const Expected, Actual: Integer);
begin
  AssertEquals(Expected, Actual);
end;

class procedure Assert.AreEqual(const Expected, Actual: Boolean);
begin
  AssertEquals(Expected, Actual);
end;

class procedure Assert.AreEqualMemory(Expected, Actual: Pointer; Size: PtrUInt);
begin
  AssertTrue(CompareMem(Expected, Actual, Size));
end;

class procedure Assert.IsTrue(Condition: Boolean);
begin
  AssertTrue(Condition);
end;

class procedure Assert.IsFalse(Condition: Boolean);
begin
  AssertFalse(Condition);
end;
{$ENDIF}
procedure TTestBoardControls.TestWouldCaptureAnyThing;
var
  LX,LY:Integer;
  LBoard:TBoard;
  LResult:Boolean;
  i,j:Integer;
begin
  {
    initialize the board
  }
  ResetBoard(@LBoard);

  {
    place white stone in corner, one black as neighbour
    then test to place the other white to capture.
    with player white this should be false
  }
  LBoard.Occupation[1,1]:=1;
  LBoard.Occupation[1,2]:=2;
  LX:=2;
  LY:=1;
  LBoard.PlayerOnTurn:=1;
  LResult:=WouldCaptureAnyThing(LX,LY,@LBoard);
  Assert.IsFalse(LResult);
  {
    Now we just set the player as white, and capturing should return true now
  }
  LBoard.PlayerOnTurn:=2;
  LResult:=WouldCaptureAnyThing(LX,LY,@LBoard);
  Assert.IsTrue(LResult);

  {
    now we fill the board completely white, except for one free eye
    as black player, this would capture everything, so should return true
  }
  for i := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      LBoard.Occupation[i,j]:=1;
    end;
  end;
  LBoard.Occupation[2,2]:=0;
  LX:=2;
  LY:=2;
  LBoard.PlayerOnTurn:=2;
  LResult:=WouldCaptureAnyThing(LX,LY,@LBoard);
  Assert.IsTrue(LResult);
  {
    now we free a second eye for the big white group.
    placing a black stone now won't capture anything
  }
  LBoard.Occupation[4,4]:=0;
  LResult:=WouldCaptureAnyThing(LX,LY,@LBoard);
  Assert.IsFalse(LResult);

end

;
procedure TTestBoardControls.TestCountLiberties;
var
  LBoard:TBoard;
  LLiberties:Integer;
  i,j:Integer;
  LCompareBoard:TBoard;
begin
  ResetBoard(@LBoard);
  {
    simple check for two connected stones = 6 liberties
  }
  LBoard.Occupation[3,3]:=1;
  LBoard.Occupation[3,4]:=1;
  {
    we save the board for later
  }
  Move(LBoard,LCompareBoard,sizeof(TBoard));

  LLiberties:=CountLiberties(3,3,@LBoard,false);
  Assert.AreEqual(6,LLiberties);

  {
    since this function is using the actual board for counting,
    we also need to check if no changes were made to the board
  }
    Assert.AreEqualMemory(@LCompareBoard,@LBoard,sizeof(TBoard));



end;

procedure TTestBoardControls.TestIsSelfAtari;
var
  LBoard:TBoard;
  TestResult:Boolean;
begin
  ResetBoard(@LBoard);
  {
    first we test the classic one stone in corner self atari
  }
  LBoard.Occupation[1,2]:=1;
  TestResult:=IsSelfAtari(1,1,2,@LBoard);
  Assert.IsTrue(TestResult);

  {
    now we swap the color of the neighbour stone instead
    should be no self atari then
  }

  LBoard.Occupation[1,2]:=2;
  TestResult:=IsSelfAtari(1,1,2,@LBoard);
  Assert.IsFalse(TestResult);

  {
    now we do normal tiger-mouth shape
    white tigermouth should be self atari for black stone
  }

  ResetBoard(@LBoard);
  LBoard.Occupation[3,2]:=1;
  LBoard.Occupation[4,3]:=1;
  LBoard.Occupation[3,4]:=1;
  TestResult:=IsSelfAtari(3,3,2,@LBoard);
  Assert.IsTrue(TestResult);

  {
    now we just set a white stone in the white tigermouth
    should be no selfatari
  }
  TestResult:=IsSelfAtari(3,3,1,@LBoard);
  Assert.IsFalse(TestResult);


end;

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
{$IFDEF FPC}
  RegisterTest(TTestBoardControls);
{$ENDIF}

end.
