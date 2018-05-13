unit MonteCarlo;

interface
uses DataTypes,BoardControls,SysUtils,Types;
  const
  Directions : array [1..8,1..2] of SmallInt =((1,0),(1,1),(1,-1),(0,1),(0,-1),(-1,0),(-1,1),(-1,-1));

type
  TMoveEntry = record
    X:SmallInt;
    Y:SmallInt;
    Probability:Double;
  end;
  THeuristic = class
  private
  public
    class function GetHeuristicFactor(const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;virtual;abstract;
  end;


  {
    this heuristic rates moves higher, if they would capture enemy stones
  }
  TCaptureHeuristic = class(THeuristic)
  private
  public
     class function GetHeuristicFactor(const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;override;

  end;

  {
    this heuristic rates moves lower, if they are a self atari
  }
  TAntiSelfAtariHeuristic = class(THeuristic)
  private
  public
    class function GetHeuristicFactor (const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;override;

  end;

  {
    This heuristic rates moves higher, if they free a group from atari
  }
  TRunAwayHeuristic = class(THeuristic)
  private
  public
    class function GetHeuristicFactor (const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;override;
  end;

  THeuristicClass = class of THeuristic;// function (const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;

  TPlayerMoveList = array[0..BOARD_SIZE*BOARD_SIZE ]of TMoveEntry;

  TMoveGenerator = class
  private
    FRegisteredHeuristics:array of THeuristicClass;
    FPlayerMoveLists:array[1..2] of TPlayerMoveList;
    FMoveCounts:array[1..2] of Integer;
    FAssignedBoard:PBoard;
    FProbabilityList:array of Integer;
    procedure RemoveIndex(const AIndex:Integer;const APlayer:SmallInt);
    procedure PreparePropabilityList(const APlayer:SmallInt);
    procedure ApplyHeuristics(const APlayer:SmallInt);
  public
    procedure RebuildList(const APlayer:SmallInt);
    procedure RegisterHeuristic(const AHeuristic:THeuristicClass);
    property AssignedBoard:PBoard read FAssignedBoard write FAssignedBoard;
    function PopRandomHeuristicItem(const APlayer:SmallInt):TPoint;
    function PopRandomItem(const APlayer:SmallInt):TPoint;
    destructor Destroy;
    constructor Create;
  end;


  function PlayoutPosition(const ABoard:PBoard;out Score:Double;const ADynKomi:Double = 0):SmallInt;


implementation
destructor TMoveGenerator.Destroy;
begin
  inherited Destroy;
end;

  class function TAntiSelfAtariHeuristic.GetHeuristicFactor(const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;
  begin
    if IsSelfAtari(AX,AY,AColor,ABoard) then
    begin
      Result:=0.2;
    end else
      Result:=1;
  end;

  class function TCaptureHeuristic.GetHeuristicFactor(const ABoard:PBoard;const AX,AY:SmallInt;const AColor:SmallInt):Double;
  begin

    if  WouldCaptureAnyThing(AX,AY,ABoard) then
      Result:=10
    else
      Result:=1;

  end;

  constructor TMoveGenerator.Create;
  begin
   { RegisterHeuristic(TAntiSelfAtariHeuristic);
    RegisterHeuristic(TCaptureHeuristic);
    RegisterHeuristic(TRunAwayHeuristic); }
  end;

  procedure TMoveGenerator.ApplyHeuristics(const APlayer:SmallInt);
  var
    i,j:Integer;
    LX,LY:Integer;
    LFactor:Double;
  begin
    {
      here we just iterate over all possible moves, and call all
      heuristic factor calculations for every move.
      the we write back the product of these for every move.
      Et voila, we have nice probabilities :)
    }
    for i := 0 to FMoveCounts[APlayer]-1 do
    begin
      LFactor:=1;
      LX:=FPlayerMoveLists[APlayer][i].X;
      LY:=FPlayerMoveLists[APlayer][i].Y;
      for j := 0 to length(FRegisteredHeuristics)-1 do
      begin
        LFactor:=LFactor*FRegisteredHeuristics[j].GetHeuristicFactor(FAssignedBoard,LX,LY,APlayer);
      end;
      FPlayerMoveLists[APlayer][i].Probability:=LFactor;
    end;

  end;

  procedure TMoveGenerator.RegisterHeuristic(const AHeuristic:THeuristicClass);
  begin
    setlength(FRegisteredHeuristics,length(FRegisteredHeuristics)+1);
    FRegisteredHeuristics[Length(FRegisteredHeuristics)-1]:=AHeuristic;
  end;

  procedure TMoveGenerator.RemoveIndex(const AIndex:Integer;const APlayer:SmallInt);
  var
    len:Integer;
  begin
    len:=FMoveCounts[APlayer];
    FplayerMoveLists[APlayer][AIndex]:=FplayerMoveLists[APlayer][len-1];
    dec(FMoveCounts[APlayer]);
  end;

  procedure TMoveGenerator.PreparePropabilityList(const APlayer:SmallInt);
  var
    i,j:Integer;
    LIndex:Integer;
  begin
    LIndex:=-1;
    setlength(FProbabilityList,0);
    {
      With this algorithm, we generate a O(1) lookup table
      for moves with different probabilities.
      Lets assume, we have Moves M(i):
      M(0).Probability = 1
      M(1).Probability = 3
      M(2).Probability = 2

      Then we generate an array:
      [0,1,1,1,2,2]
      which represents the probability of every move

      The only drawback is possible memory consumption when working with
      high probabilites and the problem of missing granularity.
      But for our case, this should fit.
    }
    for i := 0 to FMoveCounts[APlayer]-1 do
    begin
      for j := 0 to round(FPlayerMoveLists[APlayer][i].Probability) do
      begin
        inc(LIndex);
        setlength(FProbabilityList,LIndex+1);
        FProbabilityList[LIndex]:=i;
      end;
    end;


  end;

  function TMoveGenerator.PopRandomHeuristicItem(const APlayer:SmallInt):TPoint;
  var
    LMoveInd:Integer;
  begin
    {
      First, lets compute the heuristic probabilites
    }
    ApplyHeuristics(APlayer);

    {
      Now we prepare the random choose array
    }
      PreparePropabilityList(APlayer);

    {
      Now lets choose a random move
    }
    if Length(FProbabilityList) > 0 then
    begin
      LMoveInd:=FProbabilityList[random(Length(FProbabilityList))];

      {
        Now return the coordinates of that move and remove it from the list
      }
      Result.X:=FPlayerMoveLists[APlayer][LMoveInd].X;
      Result.Y:=FPlayerMoveLists[APlayer][LMoveInd].Y;
      RemoveIndex(LMoveInd,APlayer);
    end else
    begin
      Result.X:=-1;
      Result.Y:=-1;
    end;


  end;

  function TMoveGenerator.PopRandomItem(const APlayer:SmallInt):TPoint;
  var
    LRandIndex:Integer;
    len:Integer;
  begin
    Result.X:=-1;
    Result.Y:=-1;
    len:=FMoveCounts[APlayer];
    if len > 0 then
    begin
      LRandIndex:=random(len);
      Result.X:=FPlayerMoveLists[APlayer][LRandIndex].X;
      Result.Y:=FPlayerMoveLists[APlayer][LRandIndex].Y;
      RemoveIndex(LRandIndex,APlayer);
    end;
  end;

  procedure TMoveGenerator.RebuildList(const APlayer:SmallInt);
  var
    i,j:Integer;
    len:Integer;
  begin
    FMoveCounts[APlayer]:=0;
    len:=0;
    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
        {
          move needs to be valid
        }
        if IsValidMove(i,j,APlayer,FAssignedBoard) and
        {
          don't kill your eyes as this would
          lead to endless recapture playouts
        }
           (not IsOwnEye(i,j,APlayer,FAssignedBoard)) and
        {
          If it does not capture anything, it shouldn't be a self atari.
          Of course capturing would prevent self atari anyway,
          but since this is no complete move simulation but just
          a "forecast", we need this check as a shortcut
        }
           (WouldCaptureAnyThing(i,j,FAssignedBoard) or (not IsSelfAtari(i,j,APlayer,FAssignedBoard) ))

        then
        begin

          FPlayerMoveLists[APlayer][len].X:=i;
          FPlayerMoveLists[APlayer][len].Y:=j;
          FPlayerMoveLists[APlayer][len].Probability:=1;
          inc(FMoveCounts[APlayer]);
          Inc(len);
        end;
      end;
    end;
    {
      passmove is always valid
    }
    inc(FMoveCounts[APlayer]);
    FPlayerMoveLists[APlayer][len].X:=0;
    FPlayerMoveLists[APlayer][len].Y:=0;
    FPlayerMoveLists[APlayer][len].Probability:=1;
  end;

  function PlayoutPosition(const ABoard:PBoard;out Score:Double;const ADynKomi:Double):SmallInt;
  var
    LMoveGen:TMoveGenerator;
    LMove:TPoint;
  begin
    {
      first we initialize the result with a
      random player to win to decide what happens in a tie situation
    }
    if random(2)=0 then
      Result:=1
    else
      Result:=2;
    {
      now we setup the movelists, and populate them
      with all possible moves for both players
    }
    LMoveGen:=TMoveGenerator.Create;
    try
      LMoveGen.AssignedBoard:=ABoard;
      LMoveGen.RebuildList(1);
      LMoveGen.RebuildList(2);

      {
        now we loop until the game is over, doing one random
        possible move after the other
      }
     while True do
      begin
      {
        we refresh our possible moves every iteration
        because the cost of accidentally trying an invalid move is higher
        in average than just refreshing.

        Also by always refreshing our playout is not as biased as without
        the refresh
       }
      LMoveGen.RebuildList(ABoard.PlayerOnTurn);


        if ABoard.Over then
        begin
          Score:= CountScore(ABoard,ADynKomi);
          if Score>0 then
            Exit(1)
          else
            Exit(2);
        end;
        LMove:=LMoveGen.PopRandomHeuristicItem(ABoard.PlayerOnTurn);


        if not ExecuteMove(LMove.X,LMove.Y,ABoard.PlayerOnTurn,ABoard,False,False) then
        begin
          {
            if our movelist is screwed up because we didn't refresh
            we do so and retry making a move
          }
        // LMoveGen.RebuildList(ABoard.PlayerOnTurn);
          Continue

        end;
      end;
    finally
      LMoveGen.Free;
    end;
  end;


{ TRunAwayHeuristic }

class function TRunAwayHeuristic.GetHeuristicFactor(const ABoard: PBoard;
  const AX, AY, AColor: SmallInt): Double;
  function IsOwnGroupInAtari(X,Y:SmallInt):Boolean;
  begin
    if ABoard.Occupation[X,Y] <> AColor then
      Exit(False);
    Result:= CountLiberties(X,Y,ABoard,True) = 1;
  end;
var
  LWasInAtari:Boolean;
begin
{
  first we check, if any neighbour group is in atari right now
}
  LWasInAtari:= IsOwnGroupInAtari(AX+1,AY) OR
                IsOwnGroupInAtari(AX-1,AY) OR
                IsOwnGroupInAtari(AX,AY+1) OR
                IsOwnGroupInAtari(AX,AY-1);

  if not LWasInAtari then
  begin
    Result:=1;
  end else
  begin
    {
      if one of the own neighbour groups is in atari
      we simulate a move on our field, and then check this field for liberties
      if it somehow connects or runs out, our liberties should be >1

      For simulation we can safely assume that this field must be empty!
    }

    ABoard.Occupation[AX,AY]:=AColor;
    if CountLiberties(AX,AY,ABoard,True)>1 then
    begin
      {
        if our move frees from the atari, our value depends on the groupsize we
        saved with this move
      }
      Result:=RecMarkGroupSize(AX,AY,ABoard,True);
    end else
    begin
      {
        if we have a move that just keeps the group in atari,
        it is mostly useless (not for KO though, need to think about it)
      }
      Result:=0.5;
    end;

    {
      don't forget to reset our simulated stone ;)
    }
    ABoard.Occupation[AX,AY]:=0;
  end;


end;

end.
