unit BoardControls;

interface
///////////////////////////////////
/// TODOS:
/// - rewrite movelists to static arrays
/// - rewrite all IsEqualField to its static replacement (out of bounds allowed now)
uses DataTypes,Types;

    //------NOT DEPENDING ON VALID MOVES------------------------
    function RecMarkGroupSize(const ARecX,ARecY:SmallInt;const APBoard:PBoard;const FirstCall:Boolean):SmallInt;
    function IsValidMove(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
    function CountLiberties(const AX,AY:SmallInt;const APBoard:PBoard;const AStopAfterTwo:Boolean):SmallInt;
    function HasLiberties(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
    function CountLibertiesRecursive(const AX,AY:SmallInt;const APBoard:PBoard;const AMatchColor:SmallInt; const AStopAfterTwo:Boolean):SmallInt;
    function CountLibertiesRec_(const AX,AY:SmallInt;const APBoard:PBoard;const AFirstCall:Boolean;const MarkedFields:PMarkList;var ALen:SmallInt;const AStopAfterTwo:Boolean):SmallInt;
    function CountLibertiesIterative_(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
   // function HasLiberties(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean):Boolean; //much faster than test CountLiberties = 0
    function IsEqualField(const AX,AY,AOccupation:SmallInt;const APBoard:PBoard):Boolean;
    function ExecuteMove(const AX,AY,AColor:SmallInt;const APBoard:PBoard;const ANullMove:Boolean;const AFastMode:Boolean):Boolean; //fastmode requires valid move check
    function RemoveGroupRec(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
    procedure ResetBoard(const APBoard:PBoard);
    function HasMovesLeft(const AColor:SmallInt;const APBoard:PBoard):Boolean;
    function IsOwnEye(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
    function WhiteSpaceBelongsTo(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
    function GetOccupationAt(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt; //-1 if oob;
    function HasReasonableMoves(const APBoard:PBoard;const AColor:SmallInt):Boolean;
    function IsReasonableMove(const AX,AY:SmallInt;const APBoard:PBoard;const AColor:SmallInt):Boolean;
    procedure GetMoveList(const APBoard:PBoard;const AColor:SmallInt; const MoveList:PMoveList);
    function HasNeighbour(const AX,AY:SmallInt;const ApBoard:PBoard):Boolean;
    procedure CleanMoveList(const APBoard:PBoard;const AColor:SmallInt;const  MoveList:PMoveList);
    procedure ResetRatingTable(const APRatingTable:PRatingTable;const APBoard:PBoard);
    function IsSelfAtari(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
    function WouldCaptureLastMove(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
    function WouldCaptureAnyThing_(const AX,AY:SmallInt;const APboard:PBoard):SmallInt;
    function WouldCaptureAnyThing(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
  //-----------------------------------------------------------

  function GetBoardHash(const APBoard:PBoard):Int64;
  function CountScore(const APBoard:PBoard):Double;

  //-----VALID MOVES NEEDED----------------

  function IsKoValidMove(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
  function IsSuicide(const AX,AY:SmallInt;const AColor:SmallInt;const  APBoard:PBoard):Boolean;
  //--------------------------------------------
    function ReverseColor(const AColor:SmallInt):SmallInt;

threadvar
  LRecursionCounter:Integer;
  TopMark,LeftMark,BotMark,RightMark:Integer;

implementation


uses Math,System.Generics.Collections,Winapi.Windows;


function HasLiberties(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
var
  LCol:SmallInt;
begin
  {
    if a direct neighbour is empty,
    we can directly return true and exit
  }
  if APBoard.Occupation[AX-1,AY] = 0 then
    Exit(True);
  if APBoard.Occupation[AX+1,AY] = 0 then
    Exit(True);
  if APBoard.Occupation[AX,AY-1] = 0 then
    Exit(True);
  if APBoard.Occupation[AX,AY+1] = 0 then
    Exit(True);

  Result:=False;
  LCol:=APBoard.Occupation[AX,AY];
  try
  {
    we mark our current position as already visited
  }
  APBoard.Occupation[AX,AY] := 254;
  {
    now we just check, if any same colored neighbour has
    any liberties and exit directly if so
  }
  if APBoard.Occupation[AX-1,AY] = LCol then
    Result:= HasLiberties(AX-1,AY,APBoard);
  if Result then
    Exit(True);

  if APBoard.Occupation[AX+1,AY] = LCol then
    Result:= HasLiberties(AX+1,AY,APBoard);
  if Result then
    Exit(True);

  if APBoard.Occupation[AX,AY-1] = LCol then
    Result:= HasLiberties(AX,AY-1,APBoard);
  if Result then
    Exit(True);

  if APBoard.Occupation[AX,AY+1] = LCol then
    Result:= HasLiberties(AX,AY+1,APBoard);
  if Result then
    Exit(True);
  finally
    {
      we move the removing of the mark in finally,
      so we can exit inside the try block and avoid a lot of
      if then logic
    }
    APBoard.Occupation[AX,AY] := LCol;
  end;


end;
function WouldCaptureAnyThing(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
var LCol:SmallInt;
function IsInAtari(X,Y:SmallInt):Boolean;
begin
  Result:=False;
  if APBoard.Occupation[X,Y] <> LCol then
    Exit;
  Result:= CountLiberties(X,Y,APBoard,True)=1;
end;
begin
{
  the functionality is simple:
  look for opponent neighbour stones
  count the liberties of the group of these stones
  return TRUE, if one of these liberties is 1,
  because placing the stone would reduce it to 0
}
  LCol:=ReverseColor(APBoard.PlayerOnTurn);
  Result:=False;
  if IsInAtari(AX,AY-1) then
    Exit(True);
  if IsInAtari(AX,AY+1) then
    Exit(True);
  if IsInAtari(AX-1,AY) then
    Exit(True);
  if IsInAtari(AX+1,AY) then
    Exit(True);

end;

function MarkAndCall(const X,Y:SmallInt;const APBoard:PBoard;const AMatchColor:SmallInt;const AStopAfterTwo:Boolean):Integer;
begin

  Result:=0;
  if AStopAfterTwo and (LRecursionCounter>= 2) then
    Exit;
  if APBoard.Occupation[X,Y] = AMatchColor then
  begin
    Result:=Result+CountLibertiesRecursive(X,Y,APBoard,AMatchColor,AStopAfterTwo);
    {
      if the field is a stone, we just want its remaining liberties
    }
  end else
  begin
    if APBoard.Occupation[X,Y] = 0 then
    begin
      if X>RightMark then
        RightMark:=X;
      if X<LeftMark then
        LeftMark:=X;
      if Y>BotMark then
        BotMark:=Y;
      if Y<TopMark then
        TopMark:=Y;
      APBoard.Occupation[X,Y] := 254; //so now 0 fields are 254
      Inc(Result);
      Inc(LRecursionCounter);
      {
        if the field is empty, its a group liberty, so we count and mark it
      }
    end;
  end;
end;

function CountLibertiesRecursive(const AX,AY:SmallInt;const APBoard:PBoard;const AMatchColor:SmallInt;const AStopAfterTwo:Boolean):SmallInt;

begin
  Result:=0;
  if APBoard.Occupation[AX,AY]=0 then
    Exit;
  if ((AStopAfterTwo) AND (LRecursionCounter >= 2)) then
    Exit;
  //we can assume this is a valid stone, because otherwise this proc
  //wouldn't have been called
  {
    we mark with different value here, so we can turn them back
  }
  if AX>RightMark then
    RightMark:=AX;
  if AX<LeftMark then
    LeftMark:=AX;
  if AY>BotMark then
    BotMark:=AY;
  if AY<TopMark then
    TopMark:=AY;
  if AMatchColor = 1  then
  APBoard.Occupation[AX,AY]:=3 else
  APBoard.Occupation[AX,AY]:=4;   //so lets mark it as a group stone before we call the recursion
  Result:= Result + MarkAndCall(AX-1,AY,APBoard,AMatchColor,AStopAfterTwo);
  Result:= Result + MarkAndCall(AX+1,AY,APBoard,AMatchColor,AStopAfterTwo);
  Result:= Result + MarkAndCall(AX,AY-1,APBoard,AMatchColor,AStopAfterTwo);
  Result:= Result + MarkAndCall(AX,AY+1,APBoard,AMatchColor,AStopAfterTwo);
end;

function CountLiberties(const AX,AY:SmallInt;const APBoard:PBoard;const AStopAfterTwo:Boolean):SmallInt;
var
  i,j:Integer;
begin
    if AStopAfterTwo then
      LRecursionCounter:=0;
    Result:=0;
    //first step: general boundary check
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;


    {
      for faster cleanup, we remember how big the rectangle around
      the counted group was, so we don't need to cleanup everything
    }
    TopMark:=BOARD_SIZE;
    LeftMark:=BOARD_SIZE;
    RightMark:=1;
    BotMark:=1;

    try

      Result:= CountLibertiesRecursive(AX,AY,APBoard,APBoard.Occupation[AX,AY],AStopAfterTwo);
    finally
      {
        cleanup the marks
      }
      for i := LeftMark to RightMark do
      begin
        for j := TopMark to BotMark do
        begin
          if APBoard.Occupation[i,j] = 254 then
          begin
            APBoard.Occupation[i,j]:=0;
            Continue;
          end;
          if APBoard.Occupation[i,j] = 3 then
          begin
            APBoard.Occupation[i,j]:=1;
            Continue;
          end;
          if APBoard.Occupation[i,j] = 4 then
          begin
            APBoard.Occupation[i,j]:=2;
            Continue;
          end;
        end;
      end;
    end;

end;

  function CountLibertiesIterative_(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
  var
    LBoard:PBoard;
    LCol:SmallInt;
    LTop,LLeft,LRight,LDown:SmallInt;
    LMarked:Boolean;
    i,j:Integer;
  procedure AddMarkAndExtendRect(const X,Y:SmallInt);
  begin
    if LBoard.Occupation[X,Y] = 0 then
    begin
      LBoard.Occupation[X,Y]:=254; //liberty marker
    end else
    begin
      if LBoard.Occupation[X,Y] = LCol then
      begin
        LMarked:=True;
        LBoard.Occupation[X,Y]:=255;
        //expanding the rectangle
        if X<LLeft then
          LLeft:=X;
        if X>LRight then
          LRight:=X;
        if Y<LTop then
          LTop:=Y;
        if Y>LDown then
          LDown:=Y;
      end;
    end;
  end;

  begin
    Result:=0;
    //first step: general boundary check
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    //we work on a copy of the board because it's faster than cleaning up the real board
    New(LBoard);
    CopyMemory(LBoard,APBoard,sizeof(APBoard^));

    //next step: save the color for comparison
    LCol:=LBoard.Occupation[AX,AY];

    //now we mark the initial stone and set the initial search boundaries
    LBoard.Occupation[AX,AY]:=255; //this is our stone marker
    LTop:=AY;LDown:=AY;
    LLeft:=AX;LRight:=AX;

    //now the important part:
    {
      We now go iteratively over the target rectangle, and mark every
      neighbour of marked stones, that are unmarked stone
      When marking a stone, we check if its position leaves
      the target rectangle, and expand the rect on demand
      We do this until one iteration nothing was marked, so no stone has an
      unmarked neighbour, which means the group is completely marked
    }
    while true do
    begin
      LMarked:=False;
      for i := LLeft to LRight do
      begin
        for j := LTop to LDown do
        begin
          //these procedures are setting the LMarked flag!
          if LBoard.Occupation[i,j] = 255 then
          begin
            AddMarkAndExtendRect(i-1,j);
            AddMarkAndExtendRect(i+1,j);
            AddMarkAndExtendRect(i,j-1);
            AddMarkAndExtendRect(i,j+1);
          end;
        end;
      end;
      if not LMarked then
        Break;
    end;

    //now for counting the liberties:
    {
    this step is pretty straight forward.
    We just look for marked liberties in the target rect and count them
    }
    for i := LLeft-1 to LRight+1 do
    begin
      for j := LTop-1 to LDown+1 do
      begin
         if LBoard.Occupation[i,j] = 254 then
          inc(Result);
      end;
    end;


    //last step, throw the counting board away
    Dispose(LBoard);
  end;

  function WouldCaptureAnyThing_(const AX,AY:SmallInt;const APboard:PBoard):SmallInt;
  var
    lBoard:PBoard;
    lLen:SmallInt;
    X,Y:SmallInt;
  begin

    Result:=0;
   // if not IsValidMove(Ax,AY,APBoard.PlayerOnTurn,APBoard) then Exit;
    new(LBoard);
    try
      MoveMemory(LBoard,apBoard,Sizeof(TBoard));

       lBoard.Occupation[AX,AY]:=APBoard.PlayerOnTurn;
       X:=AX-1;
       Y:=AY;
     // if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
      if CountLiberties(X,Y,@LBoard,True) = 0 then
      begin
        Result:=RecmarkgroupSize(x,y,apboard,true);

      end;
           X:=AX+1;
       Y:=AY;
  //    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
      if CountLiberties(X,Y,@LBoard,True) = 0 then
      begin
        Result:=Result+RecmarkgroupSize(x,y,apboard,true);

      end;
            X:=AX;
       Y:=AY-1;
  //    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
      if CountLiberties(X,Y,@LBoard,True) = 0 then
      begin
        Result:=Result+RecmarkgroupSize(x,y,apboard,true);
        Exit;
      end;
           X:=AX;
       Y:=AY+1;
  //    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
      if CountLiberties(X,Y,@LBoard,True) = 0 then
      begin
        Result:=Result+RecmarkgroupSize(x,y,apboard,true);
        Exit;
      end;
    finally
      Dispose(LBoard);
    end;

  end;
   function WouldCaptureLastMove(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
   var lMarkList:TMarkList;lLen:SmallInt; LOccup:SmallInt;
   begin
    if (APBoard.LastMoveCoordX = 0) AND ( APboard.LastMoveCoordY = 0) then
      Exit(False);

    Result:=False;

      LOccup:=APBoard.Occupation[AX,AY];
      APBoard.Occupation[AX,AY]:=APBoard.PlayerOnTurn;
      if CountLiberties(APBoard.LastMoveCoordX,APBoard.LastMoveCoordY,APBoard,True)=0 then
      begin
        Result:=True;
      end;
      APBoard.Occupation[AX,AY]:=LOccup;


   end;

    function IsSelfAtari(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
    var lLen:SmallInt;LWasEmpty:Boolean;
    begin
      Result:=False;
      try
        if WouldCaptureLastMove(AX,AY,APBoard) then Exit; //no self atari if capture....

        if APBoard.Occupation[AX,AY]=0 then
        begin
         APBoard.Occupation[AX,AY]:=AColor;
         LWasEmpty:=True;
        end;
        if CountLiberties(AX,AY,APBoard,True)<2 then
        begin
          Result:=True;

        end;
        if LWasEmpty then
          APBoard.Occupation[AX,AY]:=0;
      finally
      end;



    end;

    procedure ResetRatingTable(const APRatingTable:PRatingTable;const APBoard:PBoard);
    var i,j:INteger;
    begin
      for i := 1 to BOARD_SIZE do
      begin
        for j := 1 to BOARD_SIZE do
        begin
          APRatingTable.RatingAt[i][j].Valid:=IsValidMove(i,j,APBoard.PlayerOnTurn,APBoard);
          APRatingTable.RatingAt[i][j].WinsWhite:=0;
          APRatingTable.RatingAt[i][j].WinsBlack:=0;
          APRatingTable.RatingAt[i][j].MovesDone:=0;

        end;
      end;
      APRatingTable.RatingPass.Valid:=True;
      APRatingTable.RatingPass.WinsWhite:=0;
      APRatingTable.RatingPass.WinsBlack:=0;
    end;

    procedure CleanMoveList(const APBoard:PBoard;const AColor:SmallInt; const MoveList:PMoveList);
    var i:Integer;len:Integer;
    begin
      i:=0;
      while i<length(MoveList^) do
      begin
        if not IsReasonableMove(MoveList^[i][1],MoveList^[i][2],APBoard,AColor) then
        begin

          len:=Length(MoveList^)-1;
          MoveList^[i]:=MoveList^[len];
          SetLength(MoveList^,len);
        end
         else
          Inc(i);
      end;
    end;

    function HasLiberties_(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean):Boolean;
    var memFlag:SmallInt;i,j:Integer;
    begin
    Result:=False;
    //Size of the Group is not important for counting liberties, so only mark liberties here
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    if APBoard^.Occupation[AX,AY]=0 then Exit;
    if APBoard^.Occupation[AX,AY]=254 then exit;  //marker for already "touched" stones
    //----MARK AND COUNT LIBERTIES-----
     if IsEqualField(AX-1,AY,0, APBoard) then
//     if APBoard.Occupation[AX-1,AY]=0 then
     begin

      Result:=True;
      Exit;
     end;
     if IsEqualField(AX+1,AY,0, APBoard) then
//     if APBoard.Occupation[AX+1,AY]=0 then
     begin
      Result:=True;
      Exit;
     end;
     if IsEqualField(AX,AY-1,0, APBoard) then
//     if APBoard.Occupation[AX,AY-1]=0 then
     begin
     Result:=True;
     Exit;
     end;
     if IsEqualField(AX,AY+1,0, APBoard) then
//     if APBoard.Occupation[AX,AY+1]=0 then
     begin
      Result:=True;
      Exit;
     end;
    //---------------------------------
   memFlag:=APBoard^.Occupation[AX,AY];
    APBoard^.Occupation[AX,AY]:=254; //marker nr. 2, preventing stackoverflow in counting (infinite recursion)
    //---SUM UP RECURSIVELY------------
     if IsEqualField(AX-1,AY,memFlag, APBoard) then
//   if APBoard.Occupation[AX-1,AY]=memFlag then
     begin
      Result:=HasLiberties_(AX-1,AY,APBoard,False);
     end;

     if IsEqualField(AX+1,AY,memFlag, APBoard) then if not Result then
//     if APBoard.Occupation[AX+1,AY]=memFlag then
     begin
      Result:= HasLiberties_(AX+1,AY,APBoard,False);
     end;

     if IsEqualField(AX,AY-1,memFlag, APBoard) then   if not Result then
//  if APBoard.Occupation[AX,AY-1]=memFlag then
     begin
      Result:=HasLiberties_(AX,AY-1,APBoard,False);
     end;

     if IsEqualField(AX,AY+1,memFlag, APBoard) then  if not Result then
//    if APBoard.Occupation[AX,AY+1]=memFlag then
     begin
      Result:=HasLiberties_(AX,AY+1,APBoard,False);
     end;
    //---------------------------------
    //--CLEAN UP THE MARKERS------------
     if AFirstCall then  // only after every recursion stopped we want to unmark
     begin
        for i := 1 to BOARD_SIZE do
        begin
          for j := 1 to BOARD_SIZE do
          begin
           if APBoard^.Occupation[i,j]=254 then APBoard^.Occupation[i,j]:=memFlag;
          end;
        end;
     end;

    //----------------------------------

    end;
 function HasNeighbour(const AX,AY:SmallInt;const ApBoard:PBoard):Boolean;
 begin
    Result := True;
//    if IsEqualField(Ax-1,AY,1,APBoard) then exit;
     if APBoard.Occupation[AX-1,AY]=1 then  Exit;
      if APBoard.Occupation[AX-1,AY]=2 then Exit;

//    if IsEqualField(Ax-1,AY,2,APBoard) then exit;
         if APBoard.Occupation[AX+1,AY]=1 then  Exit;
      if APBoard.Occupation[AX+1,AY]=2 then Exit;
//    if IsEqualField(Ax+1,AY,1,APBoard) then exit;
//    if IsEqualField(Ax+1,AY,2,APBoard) then exit;
        if APBoard.Occupation[AX,AY-1]=1 then  Exit;
      if APBoard.Occupation[AX,AY-1]=2 then Exit;
//    if IsEqualField(Ax,AY-1,1,APBoard) then exit;
//    if IsEqualField(Ax,AY-1,2,APBoard) then exit;
      if APBoard.Occupation[AX,AY+1]=1 then  Exit;
      if APBoard.Occupation[AX,AY+1]=2 then Exit;
//    if IsEqualField(Ax,AY+1,1,APBoard) then exit;
//    if IsEqualField(Ax,AY+1,2,APBoard) then exit;
    Result:=False;
 end;
procedure GetMoveList(const APBoard:PBoard;const AColor:SmallInt;const  MoveList:PMoveList);
var i,j:Integer; len:integer; mark:Boolean;
begin

   //   mark:=HasReasonableMoves(APBoard,AColor);
     SetLength(MoveList^,0);
    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
         if isReasonableMove(i,j,APBoard,AColor) then

        begin
          len:=length(MoveList^);
          setlength(MoveList^,len+1);
          MoveList^[len][1]:=i;
          MoveList^[len][2]:=j;
        end;
      end;
    end;
end;
 function IsReasonableMove(const AX,AY:SmallInt;const APBoard:PBoard;const AColor:SmallInt):Boolean;
 begin

 if IsValidMove(AX,AY,AColor,APBoard) then
  begin
    Result:=True;
    if IsOwnEye(AX,AY,APBoard^.PlayerOnTurn,APBoard) then
    begin
     Result:=False;
     Exit;
    end;
   { if IsSelfAtari(AX,AY,Acolor,APBoard) then
    begin
      Result:=False;
      Exit;
    end;   }
    //Result:= Result AND (HasNeighbour(Ax,AY,APBoard) or (random(100)=0));
   end else Result:=False;
 end;
  function HasReasonableMoves(const APBoard:PBoard;const AColor:SmallInt):Boolean;
  var i,j:Integer;
  begin
    Result:=True;
    for i := 1 to BOARD_SIZE do for j := 1 to BOARD_SIZE do (If IsReasonableMove(i,j,APBoard,Acolor) then Exit);
    Result:=False;
  end;

   function GetOccupationAt(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
   begin
     Result:=-1;
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    Result:=APBoard^.Occupation[AX,Ay];
   end;
   function WhiteSpaceBelongsTo(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
   var GotColor:Boolean;n,w,s,e:SmallInt;black,white:integer;
   begin
     Result := 0;
     n:=GetOccupationAt(AX,AY-1,APBoard);
     s:=GetOccupationAt(AX,AY+1,APBoard);
     e:=GetOccupationAt(AX+1,AY,APBoard);
     w:=GetOccupationAt(AX-1,AY,APBoard);
     black:=0;
     white:=0;
     if n = 2 then Inc(black);
     if n = 1 then inc(white);

     if s = 2 then inc(black);
     if s = 1 then inc(white);

     if e = 2 then inc(black);
     if e = 1 then inc(white);

     if w = 2 then inc(black);
     if w = 1 then inc(white);

     if black>0 then if white =0 then Result:=2;
     if white>0 then if black =0 then Result:=1;

   end;
   function IsOwnEye(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
   var
    LCol:SmallInt;
   begin
     Result:=False;
     LCol:=ReverseColor(AColor);
     if IsEqualField(AX-1,AY,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY,LCol,APBoard) then Exit;
     if IsEqualField(AX+1,AY,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY,LCol,APBoard) then Exit;

     if IsEqualField(AX,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX,AY-1,LCol,APBoard) then Exit;
     if IsEqualField(AX,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX,AY+1,LCol,APBoard) then Exit;


     if IsEqualField(AX-1,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY-1,LCol,APBoard) then Exit;
     if IsEqualField(AX+1,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY+1,LCol,APBoard) then Exit;

     if IsEqualField(AX+1,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY-1,LCol,APBoard) then Exit;
     if IsEqualField(AX-1,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY+1,LCol,APBoard) then Exit;

     {
       when placing a enemy stone inside the "eye" would capture it,
       this shape has obviously only one eye, so its now real eye
     }
    // if not IsSuicide(AX,AY,LCol,APBoard) then Exit;

     Result :=True;
   end;
   function CountScore(const APBoard:PBoard):Double;
   var i,j:integer;occ:SmallInt;Stones:Integer;
   begin
     Result:=KOMI;
    // Stones:=APBoard^.MoveNr div 2;
   //  Result:=Result// -(Stones+1)  //black stones in the game  (one more than whites..)
//              +(APBoard^.RemovedStones[2]) // captured black stones removed from black points, added to white points
            //  +Stones    //White Stones in the game
//              -(APBoard^.RemovedStones[1]); // captured white stones removed from white points, added to black points
//      Result:=Result+ApBOard.RemovedStones[2]-ApBoard.RemovedStones[1];
     for i := 1 to BOARD_SIZE do
     begin
       for j := 1 to BOARD_SIZE do
       begin
         occ:= APBoard^.Occupation[i,j];
         if occ=0 then occ:= WhiteSpaceBelongsTo(i,j,APBoard);
         if occ=1 then Result:=Result+1;//,CountLibertiesRec(i,j,APBoard,True) );
         if occ=2 then Result:=Result-1;//,CountLibertiesRec(i,j,APBoard,True));

       end;
     end;

    // Result:=Result+APBoard^.RemovedStones[2]*2-APBoard^.RemovedStones[1]*2;
   end;
   function HasMovesLeft(const AColor:SmallInt;const APBoard:PBoard):Boolean;
   var i,j:Integer;
   begin
     Result := False;
    for i := 1 to BOARD_SIZE do
    begin
        for j := 1 to BOARD_SIZE do
        begin
          if IsValidMove(i,j,AColor,APBoard) then
          begin
            Result:= True;
            exit;
          end;
        end;
    end;
   end;
   procedure ResetBoard(const APBoard:PBoard);
   var i,j:Integer;
   begin
    APBoard^.MoveNr:=0;
    for i := 1 to BOARD_SIZE do for j := 1 to BOARD_SIZE do APBoard^.Occupation[i,j]:=0;
    for i := 0 to BOARD_SIZE+1 do
    begin
      APBoard.Occupation[i,0]:=111; //no color but no liberty either..., walldummy
      APBoard.Occupation[i,BOARD_SIZE+1]:=111;
      APBoard.Occupation[0,i]:=111;
      APBoard.Occupation[BOARD_SIZE+1,i]:=111;
    end;
    APBoard^.LastMoveCatchedExactlyOne:=false;
    APBoard^.PlayerOnTurn:=2;
    APBoard^.LastPlayerPassed:=False;
    APBoard^.Over:=False;
    APBoard^.RemovedStones[1]:=0;
    APBoard^.RemovedStones[2]:=0;
    APBoard.LastMoveCoordX:=0;
    APBoard.LastMoveCoordY:=0;
   end;
  function ExecuteMove(const AX,AY,AColor:SmallInt;const APBoard:PBoard;const ANullMove:Boolean;const AFastMode:Boolean):Boolean;
  var enemyColor:SmallInt;RemCount:SmallInt;
  begin
    if AX < 0 then
      Exit(False);
    if AY < 0 then
      Exit(False);
    if AX > BOARD_SIZE then
      Exit(False);
    if AY > BOARD_SIZE then
      Exit(False);
    if ((AX = 0)and (AY <> 0))then
      Exit(False);
    if ((AY = 0)and (AX <> 0))then
      Exit(False);
    if ANullMove or ((AX = 0) AND (AY=0)) then
    begin
      APBoard.LastMoveCatchedExactlyOne:=False;
      if APBoard^.LastPlayerPassed then
      begin
        APBoard^.Over:=True;
        APBoard.LastMoveCatchedExactlyOne:=False;
        if APBoard^.PlayerOnTurn=1 then APBoard^.PlayerOnTurn:=2 else APBoard^.PlayerOnTurn:=1;
        Result := True;
        Exit;
      end;
      APBoard^.LastPlayerPassed:=True;
      if APBoard^.PlayerOnTurn=1 then APBoard^.PlayerOnTurn:=2 else APBoard^.PlayerOnTurn:=1;
      Result := True; //passing always valid
      Exit;
    end;
    Result := false;
    if not AFastMode then //skip validation in FastMode
    begin
        if not IsValidMove(AX,AY,AColor,APBoard) then
        begin
          Result:=False;
         exit;
        end;
    end;

    APBoard^.Occupation[AX,AY]:=AColor;
    //---------NOW REMOVE CAPTURED ENEMY GROUPS-------
    enemyColor:=ReverseColor(AColor);
    APBoard^.LastMoveCatchedExactlyOne:=False;  //switch back the ko-marker
     if ALLOW_SUICIDE then
     begin
        if not HasLiberties(AX,AY,APBoard) then
        begin
          RemCount:= RemoveGroupRec(AX,AY,APBoard);
           APBoard^.RemovedStones[AColor]:=APBoard^.RemovedStones[AColor]+RemCount;  //keep track of captured stones

        end;
     end;
      RemCount:=0;
      If IsEqualField(AX-1,AY,enemyColor,APBoard) then
      begin
        if not HasLiberties(AX-1,AY,APBoard) then
//        If not HasLiberties(AX-1,AY,APBoard,True) then
        begin
         RemCount:=RemCount+ RemoveGroupRec(AX-1,AY,APBoard);
           APBoard^.LastCatchX:=AX-1;
           APBoard^.LastCatchY:=AY;
        end;
      end;
      If IsEqualField(AX+1,AY,enemyColor,APBoard) then
      begin
        if not HasLiberties(AX+1,AY,APBoard) then
//        If not HasLiberties(AX+1,AY,APBoard,True) then
        begin
         RemCount:= RemCount+RemoveGroupRec(AX+1,AY,APBoard);
            APBoard^.LastCatchX:=AX+1;
           APBoard^.LastCatchY:=AY;

        end;
      end;
      If IsEqualField(AX,AY-1,enemyColor,APBoard) then
      begin
        if not HasLiberties(AX,AY-1,APBoard) then
//        If not HasLiberties(AX,AY-1,APBoard,True) then
        begin
         RemCount:=RemCount+ RemoveGroupRec(AX,AY-1,APBoard);
             APBoard^.LastCatchX:=AX;
           APBoard^.LastCatchY:=AY-1;

        end;
      end;
      If IsEqualField(AX,AY+1,enemyColor,APBoard) then
      begin
        if not HasLiberties(AX,AY+1,APBoard) then
//        If not HasLiberties(AX,AY+1,APBoard,True) then
        begin
         RemCount:= RemoveGroupRec(AX,AY+1,APBoard);
           APBoard^.LastCatchX:=AX;
           APBoard^.LastCatchY:=AY+1;
         end;
      end;
        if RemCount = 1 then
         begin
           APBoard^.LastMoveCatchedExactlyOne:=True;
         end;
        APBoard^.RemovedStones[enemyColor]:=APBoard^.RemovedStones[enemyColor]+RemCount;
    //------------------------------------------------
    if APBoard^.PlayerOnTurn=1 then APBoard^.PlayerOnTurn:=2 else APBoard^.PlayerOnTurn:=1;
    APBoard^.LastPlayerPassed:=False;
    APBoard^.LastMoveCoordX:=AX;
    APBoard^.LastMoveCoordY:=AY;
    inc(APBoard^.MoveNr);
    Result := True;
  end;

  function ReverseColor(const AColor:SmallInt):SmallInt;
  begin
    if AColor = 1 then Result := 2 else Result:=1; //Assuming Valid Color;
  end;

  function IsSuicide(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
  var enemyColor:SmallInt;lMarkedFields:TMarkList;lLen:SmallInt;
  begin
    Result := False;
    //---OBVIOUS FIRST, CHECK FOR LIBERTIES----
    if APBoard.Occupation[AX-1,AY]=0 then Exit;
     if APBoard.Occupation[AX+1,AY]=0 then Exit;
      if APBoard.Occupation[AX,AY-1]=0 then Exit;
       if APBoard.Occupation[AX,AY+1]=0 then Exit;
//    If IsEqualField(AX-1,AY,0,APBoard) then Exit;
//    If IsEqualField(AX+1,AY,0,APBoard) then Exit;
//    If IsEqualField(AX,AY-1,0,APBoard) then Exit;
//    If IsEqualField(AX,AY+1,0,APBoard) then Exit;
    //--------------------
    //----NOW CHECK FOR CAPTURE--------
      enemyColor:=ReverseColor(AColor);
//      If IsEqualField(AX-1,AY,enemyColor,APBoard) then
     if APBoard.Occupation[AX-1,AY]=enemyColor then
      begin
//        If CountLibertiesRec(AX-1,AY,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
        if CountLiberties(AX-1,AY,APBoard,True) = 1 then Exit;
      end;
//      If IsEqualField(AX+1,AY,enemyColor,APBoard) then
     if APBoard.Occupation[AX+1,AY]=enemyColor then
      begin
//        If CountLibertiesRec(AX+1,AY,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
          if CountLiberties(AX+1,AY,APBoard,True) = 1 then Exit;
      end;
//      If IsEqualField(AX,AY-1,enemyColor,APBoard) then
   if APBoard.Occupation[AX,AY-1]=enemyColor then
      begin
//        If CountLibertiesRec(AX,AY-1,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
        if CountLiberties(AX,AY-1,APBoard,True) = 1 then Exit;
      end;
//      If IsEqualField(AX,AY+1,enemyColor,APBoard) then
    if APBoard.Occupation[AX,AY+1]=enemyColor then
      begin
//        If CountLibertiesRec(AX,AY+1,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
        if CountLiberties(AX,AY+1,APBoard,True) = 1 then Exit;
      end;
    //---------------------------------
    //----NOW CHECK FOR OWN GROUP LIBERTIES----------
//      If IsEqualField(AX-1,AY,AColor,APBoard) then
   if APBoard.Occupation[AX-1,AY]=AColor then
      begin
//        If CountLibertiesRec(AX-1,AY,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
        if CountLiberties(AX-1,AY,APBoard,True) > 1 then Exit;
      end;
//      If IsEqualField(AX+1,AY,AColor,APBoard) then
      if APBoard.Occupation[AX+1,AY]=AColor then
      begin
//        If CountLibertiesRec(AX+1,AY,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
        if CountLiberties(AX+1,AY,APBoard,True) > 1 then Exit;
      end;
//      If IsEqualField(AX,AY-1,AColor,APBoard) then
      if APBoard.Occupation[AX,AY-1]=AColor then
      begin
//        If CountLibertiesRec(AX,AY-1,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
        if CountLiberties(AX,AY-1,APBoard,True) > 1 then Exit;
      end;
//      If IsEqualField(AX,AY+1,AColor,APBoard) then
    if APBoard.Occupation[AX,AY+1]=AColor then
      begin
//        If CountLibertiesRec(AX,AY+1,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
          if CountLiberties(AX,AY+1,APBoard,True) > 1 then Exit;
      end;
    //-----------------------------------------------
    // no adjacent liberties
    // no capture of enemy stones
    // no own group with  liberties > 1
    //-------->>>>    SUICIDE!  <<<<----------
    Result:=True;
  end;

  function IsValidMove(const AX,AY:SmallInt;const AColor:SmallInt;const APBoard:PBoard):Boolean;
  begin
    Result := False;
     if (AX=0) and (AY=0) then
      Exit(True); //ofcourse passing is always valid.....gnarf
    //-----OUT OF BOUNDS-------

    if AX<=0 then exit;
    if AY<=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
  //--------------------------
  //----------FIELD TAKEN----
    if APBoard^.Occupation[AX,AY]<>0 then Exit;
  //------------------------

  //--------------KO MOVE------------
    if not IsKoValidMove(AX,AY,APBoard) then Exit;
  //---------------------------------
  //----------SUICIDE MOVE---------
   if not ALLOW_SUICIDE then if IsSuicide(AX,AY,AColor,APBoard) then Exit;
  //---------------------------------
  //No negative criteria matched---> VALID MOVE!
    Result:=True;
  end;

  function IsKoValidMove(const AX,AY:SmallInt;const APBoard:PBoard):Boolean;
  var lMarkedFields:TMarkList; lLen:SmallInt;
  begin
    Result:=True;
    if not APBoard^.LastMoveCatchedExactlyOne then Exit;
    if (AX<>APBoard^.LastCatchX) or (AY<>APBoard^.LastCatchY) then Exit; //not the spot of the last captured stone-> no ko
//    if CountLibertiesRec(APBoard^.LastMoveCoordX,APBoard^.LastMoveCoordY,APBoard,True,@lMarkedFields,lLen,True)<>1 then Exit ; //no killing-move
    if CountLiberties(APBoard^.LastMoveCoordX,APBoard^.LastMoveCoordY,APBoard,True) <> 1 then Exit;
    if RecMarkGroupSize(APBoard^.LastMoveCoordX,APBoard^.LastMoveCoordY,APBoard,True)<>1 then Exit; //if count >1 --> snapback
    //every ko criteria passed, so it's a ko!
    Result := False;
  end;

  function IsEqualField(const AX,AY,AOccupation:SmallInt;const APBoard:PBoard):Boolean;
  begin
    //result := False;
   { if AX=0 then begin Result:=False; end else
    if AY=0 then begin Result:=False; end else
    if AX>(BOARD_SIZE) then begin Result:=False; end else
    if AY>(BOARD_SIZE) then begin Result:=False; end else   }
    if (APBoard.Occupation[AX,AY] <> AOccupation) then result:=False else Result:=True;
  end;

  function CountLibertiesRec_(const AX,AY:SmallInt;const APBoard:PBoard;const AFirstCall:Boolean;const MarkedFields:PMarkList;var ALen:SmallInt;const AStopAfterTwo:Boolean):SmallInt;
  var memFlag:SmallInt;
      i,j:Integer;
      x,y:Integer;
      P:Pointer;
  begin
    Result:=0;
    if AFirstCall then ALen:=-1;
    if AFirstCall then
    begin
      //do a snapshot of the board
      P:=GetMemory(SizeOf(APBoard^));
      CopyMemory(P,APBoard,SizeOf(ApBoard^));
    end;
    //Size of the Group is not important for counting liberties, so only mark liberties here
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    if APBoard^.Occupation[AX,AY]=0 then Exit;
    if APBoard^.Occupation[AX,AY]=255 then exit;  //marker for liberties
    if APBoard^.Occupation[AX,AY]=254 then exit;  //marker for already "touched" stones
    //----MARK AND COUNT LIBERTIES-----
    // if IsEqualField(AX-1,AY,0, APBoard) then

    if APBoard.Occupation[AX-1,AY]=0 then
     begin
      APBoard^.Occupation[AX-1,AY]:=255;

      inc(ALen);
      MarkedFields[Alen][1]:=AX-1;
      MarkedFields[Alen][2]:=AY;

      inc(Result);
     end;
   //  if IsEqualField(AX+1,AY,0, APBoard) then
   if APBoard.Occupation[AX+1,AY]= 0 then
     begin
      APBoard^.Occupation[AX+1,AY]:=255;

      inc(ALen);
      MarkedFields[ALen][1]:=AX+1;
      MarkedFields[ALen][2]:=AY;

      inc(Result);
     end;
    // if IsEqualField(AX,AY-1,0, APBoard) then
    if APBoard.Occupation[AX,AY-1]=0 then
     begin
     APBoard^.Occupation[AX,AY-1]:=255;

      inc(ALen);
      MarkedFields[ALen][1]:=AX;
      MarkedFields[Alen][2]:=AY-1;


      inc(Result);
     end;
//     if IsEqualField(AX,AY+1,0, APBoard) then
     if APBoard.Occupation[AX,AY+1]=0 then
     begin
     APBoard^.Occupation[AX,AY+1]:=255;

       inc(ALen);
      MarkedFields[Alen][1]:=AX;
      MarkedFields[Alen][2]:=AY+1;


      inc(Result);
     end;

     if AStopAfterTwo AND (Result>1) then
     begin

     end else
     begin
          //---------------------------------
         memFlag:=APBoard^.Occupation[AX,AY];

          APBoard^.Occupation[AX,AY]:=254; //marker nr. 2, preventing stackoverflow in counting (infinite recursion)
             inc(ALen);
         MarkedFields[ALen][1]:=AX;
         MarkedFields[ALen][2]:=AY;

          //---SUM UP RECURSIVELY------------
      //     if IsEqualField(AX-1,AY,memFlag, APBoard) then
           if not (AStopAfterTwo and(Result>1)) then
           begin
               if APBoard.Occupation[AX-1,AY]=memFlag then
               begin


                Result:=Result+CountLibertiesRec_(AX-1,AY,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
               end;
           end;
           if not (AStopAfterTwo and(Result>1)) then
           begin
        //     if IsEqualField(AX+1,AY,memFlag, APBoard) then
             if APBoard.Occupation[AX+1,AY]=memFlag then
             begin


              Result:=Result+CountLibertiesRec_(AX+1,AY,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
             end;
          end;
      //     if IsEqualField(AX,AY-1,memFlag, APBoard) then
           if not (AStopAfterTwo and(Result>1)) then
           begin
             if APBoard.Occupation[AX,AY-1]=memFlag then
               begin


                Result:=Result+CountLibertiesRec_(AX,AY-1,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
               end;
           end;
      //     if IsEqualField(AX,AY+1,memFlag, APBoard) then
           if not (AStopAfterTwo and(Result>1)) then
           begin
              if APBoard.Occupation[AX,AY+1]=memFlag then
               begin


                Result:=Result+CountLibertiesRec_(AX,AY+1,APBoard,False,MarkedFields,Alen,AStopAfterTwo);
               end;
           end;
     end;
    //---------------------------------
    //--CLEAN UP THE MARKERS------------
    if AFirstCall then  // only after every recursion stopped we want to unmark
    begin
      CopyMemory(APBoard,P,sizeof(APBoard^));  //replace the used board with the snapshot
      Dispose(P);
    end;

    //----------------------------------
  end;

  function GetBoardHash(const APBoard:PBoard):Int64;
  begin
    //TODO: Implement hashing
  end;
  function RemoveGroupRec(const AX,AY:SmallInt;const APBoard:PBoard):SmallInt;
  var ownCol:SmallInt; len:Integer;
  begin
    Result:=0;
    if AX<=0 then exit;
    if AY<=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    if APBoard^.Occupation[AX,AY]=0 then exit;
    ownCol:=APBoard^.Occupation[AX,AY];
    APBoard^.Occupation[AX,AY]:=0; //delete this stone
    //------------ enable this field as valid move ----------
   { len:=length(MovesB);
    SetLength(MovesB,len+1);
    MovesB[len][1]:=AX;MovesB[len][2]:=AY;

    len:=length(MovesW);
    SetLength(MovesW,len+1);
    MovesW[len][1]:=AX;MovesW[len][2]:=AY;    }
    //------------- ---------------------
    Result:=1;
    //---------DELETE ALL OWN NEIGHBBOURS-----------
        if APBoard^.Occupation[AX+1,AY] = ownCol then Result:=Result+RemoveGroupRec(AX+1,AY,APBoard);
        if APBoard^.Occupation[AX-1,AY] = ownCol then Result:=Result+RemoveGroupRec(AX-1,AY,APBoard);
        if APBoard^.Occupation[AX,AY+1] = ownCol then Result:=Result+RemoveGroupRec(AX,AY+1,APBoard);
        if APBoard^.Occupation[AX,AY-1] = ownCol then Result:=Result+RemoveGroupRec(AX,AY-1,APBoard);
    //---------------------------------------
  end;
  function RecMarkGroupSize(const ARecX,ARecY:SmallInt;const APBoard:PBoard;const FirstCall:Boolean):SmallInt;
  var memFlag:SmallInt;i,j:Integer;
  begin
    Result:=0;
    if ARecX<=0 then exit;
    if ARecY<=0 then exit;
    if ARecX>BOARD_SIZE then exit;
    if ARecY>BOARD_SIZE then exit;
    if APBoard^.Occupation[ARecX,ARecY]=0 then exit;
    if APBoard^.Occupation[ARecX,ARecY]=255 then exit; //255 = already marked
    memFlag:=APBoard^.Occupation[ARecX,ARecY];
    APBoard^.Occupation[ARecX,ARecY]:=255; //set marking flag now
    Result :=1;
          if IsEqualField(ARecX+1,ARecY,memFlag,APBoard) then Result := Result+ RecMarkGroupSize(ARecX+1,ARecY,APBoard,False);
          if IsEqualField(ARecX-1,ARecY,memFlag,APBoard) then Result := Result+ RecMarkGroupSize(ARecX-1,ARecY,APBoard,False);
           if IsEqualField(ARecX,ARecY+1,memFlag,APBoard) then Result := Result+ RecMarkGroupSize(ARecX,ARecY+1,APBoard,False);
          if IsEqualField(ARecX,ARecY-1,memFlag,APBoard) then Result := Result+    RecMarkGroupSize(ARecX,ARecY-1,APBoard,False);

    if FirstCall then
    begin
      for i := 1 to BOARD_SIZE do for j := 1 to BOARD_SIZE do if APBoard^.Occupation[i,j]=255 then APBoard^.Occupation[i,j]:=memFlag;

    end;
  end;

end.
