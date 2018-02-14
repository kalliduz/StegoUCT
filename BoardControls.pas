unit BoardControls;

interface
///////////////////////////////////
/// TODOS:
/// - rewrite movelists to static arrays
/// - rewrite all IsEqualField to its static replacement (out of bounds allowed now)
uses DataTypes;
    //------NOT DEPENDING ON VALID MOVES------------------------
    function RecMarkGroupSize(ARecX,ARecY:SmallInt;APBoard:PBoard;FirstCall:Boolean):SmallInt;
    function IsValidMove(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
    function CountLibertiesRec(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean;MarkedFields:PMarkList;var ALen:SmallInt;AStopAfterTwo:Boolean):SmallInt;
    function HasLiberties(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean):Boolean; //much faster than test CountLiberties = 0
    function IsEqualField(AX,AY,AOccupation:SmallInt;const APBoard:PBoard):Boolean;
    function ExecuteMove(AX,AY,AColor:SmallInt;APBoard:PBoard;ANullMove:Boolean;AFastMode:Boolean;var MovesB,MovesW:TMoveList):Boolean; //fastmode requires valid move check
    function RemoveGroupRec(AX,AY:SmallInt;APBoard:PBoard;var MovesB,MovesW:TMoveList):SmallInt;
    procedure ResetBoard(APBoard:PBoard);
    function HasMovesLeft(AColor:SmallInt;APBoard:PBoard):Boolean;
    function IsOwnEye(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
    function WhiteSpaceBelongsTo(AX,AY:SmallInt;APBoard:PBoard):SmallInt;
    function GetOccupationAt(AX,AY:SmallInt;APBoard:PBoard):SmallInt; //-1 if oob;
    function HasReasonableMoves(APBoard:PBoard;AColor:SmallInt):Boolean;
    function IsReasonableMove(AX,AY:SmallInt;APBoard:PBoard;AColor:SmallInt):Boolean;
    procedure GetMoveList(APBoard:PBoard;AColor:SmallInt; MoveList:PMoveList);
    function HasNeighbour(AX,AY:SmallInt;ApBoard:PBoard):Boolean;
    procedure CleanMoveList(APBoard:PBoard;AColor:SmallInt; MoveList:PMoveList);
    procedure ResetRatingTable(APRatingTable:PRatingTable;APBoard:PBoard);
    function IsSelfAtari(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
    function WouldCaptureLastMove(AX,AY:SmallInt;APBoard:PBoard):Boolean;
    function WouldCaptureAnyThing(AX,AY:SmallInt;APboard:PBoard):SmallInt;
  //-----------------------------------------------------------

  function GetBoardHash(APBoard:PBoard):Int64;
  function CountScore(APBoard:PBoard):Double;

  //-----VALID MOVES NEEDED----------------

  function IsKoValidMove(AX,AY:SmallInt;APBoard:PBoard):Boolean;
  function IsSuicide(AX,AY:SmallInt;AColor:SmallInt; APBoard:PBoard):Boolean;
  //--------------------------------------------
    function ReverseColor(AColor:SmallInt):SmallInt;
implementation

uses Math;
  function WouldCaptureAnyThing(AX,AY:SmallInt;APboard:PBoard):SmallInt;
  var lBoard:TBoard;lMarkList:TMarkList;lLen:SmallInt;X,Y:SmallInt;
  begin

    Result:=0;
   // if not IsValidMove(Ax,AY,APBoard.PlayerOnTurn,APBoard) then Exit;

    lBoard:=ApBoard^;
    lBoard.Occupation[AX,AY]:=APBoard.PlayerOnTurn;
     X:=AX-1;
     Y:=AY;
    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
    begin
      Result:=RecmarkgroupSize(x,y,apboard,true);

    end;
         X:=AX+1;
     Y:=AY;
    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
    begin
      Result:=Result+RecmarkgroupSize(x,y,apboard,true);

    end;
          X:=AX;
     Y:=AY-1;
    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
    begin
      Result:=Result+RecmarkgroupSize(x,y,apboard,true);
      Exit;
    end;
         X:=AX;
     Y:=AY+1;
    if CountLibertiesRec(X,Y,@lBoard,True,@lMarkList,lLen,True)= 0 then
    begin
      Result:=Result+RecmarkgroupSize(x,y,apboard,true);
      Exit;
    end;
  end;
   function WouldCaptureLastMove(AX,AY:SmallInt;APBoard:PBoard):Boolean;
   var lBoard:TBoard;lMarkList:TMarkList;lLen:SmallInt;
   begin
    Result:=False;
    if not IsValidMove(Ax,AY,APBoard.PlayerOnTurn,APBoard) then Exit;

    lBoard:=ApBoard^;
    lBoard.Occupation[AX,AY]:=APBoard.PlayerOnTurn;
    if CountLibertiesRec(LBoard.LastMoveCoordX,LBoard.LastMoveCoordY,@lBoard,True,@lMarkList,lLen,True)= 0 then
    begin
      Result:=True;
    end;


   end;
    function IsSelfAtari(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
    var SimBoard:TBoard; lMarkList:TMarkList; lLen:SmallInt;
    begin
      Result:=False;
      SimBoard:=APBoard^; //copy to not interfere threads working on pointed board
      if WouldCaptureLastMove(AX,AY,APBoard) then Exit; //no self atari if capture....

      if SimBoard.Occupation[AX,AY]=0 then SimBoard.Occupation[AX,AY]:=AColor;
      if CountLibertiesRec(AX,AY,@SimBoard,True,@lMarkList,lLen,True)< 2 then
      begin
        Result:=True;
      end;


    end;
    procedure ResetRatingTable(APRatingTable:PRatingTable;APBoard:PBoard);
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
    procedure CleanMoveList(APBoard:PBoard;AColor:SmallInt; MoveList:PMoveList);
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
    function HasLiberties(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean):Boolean;
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
      Result:=HasLiberties(AX-1,AY,APBoard,False);
     end;

     if IsEqualField(AX+1,AY,memFlag, APBoard) then if not Result then
//     if APBoard.Occupation[AX+1,AY]=memFlag then
     begin
      Result:= HasLiberties(AX+1,AY,APBoard,False);
     end;

     if IsEqualField(AX,AY-1,memFlag, APBoard) then   if not Result then
//  if APBoard.Occupation[AX,AY-1]=memFlag then
     begin
      Result:=HasLiberties(AX,AY-1,APBoard,False);
     end;

     if IsEqualField(AX,AY+1,memFlag, APBoard) then  if not Result then
//    if APBoard.Occupation[AX,AY+1]=memFlag then
     begin
      Result:=HasLiberties(AX,AY+1,APBoard,False);
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
 function HasNeighbour(AX,AY:SmallInt;ApBoard:PBoard):Boolean;
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
procedure GetMoveList(APBoard:PBoard;AColor:SmallInt; MoveList:PMoveList);
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
 function IsReasonableMove(AX,AY:SmallInt;APBoard:PBoard;AColor:SmallInt):Boolean;
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
  function HasReasonableMoves(APBoard:PBoard;AColor:SmallInt):Boolean;
  var i,j:Integer;
  begin
    Result:=True;
    for i := 1 to BOARD_SIZE do for j := 1 to BOARD_SIZE do (If IsReasonableMove(i,j,APBoard,Acolor) then Exit);
    Result:=False;
  end;

   function GetOccupationAt(AX,AY:SmallInt;APBoard:PBoard):SmallInt;
   begin
     Result:=-1;
    if AX=0 then exit;
    if AY=0 then exit;
    if AX>BOARD_SIZE then exit;
    if AY>BOARD_SIZE then exit;
    Result:=APBoard^.Occupation[AX,Ay];
   end;
   function WhiteSpaceBelongsTo(AX,AY:SmallInt;APBoard:PBoard):SmallInt;
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
   function IsOwnEye(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
   begin
     Result:=False;
     if IsEqualField(AX-1,AY,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY,ReverseColor(AColor),APBoard) then Exit;
     if IsEqualField(AX+1,AY,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY,ReverseColor(AColor),APBoard) then Exit;

     if IsEqualField(AX,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX,AY-1,ReverseColor(AColor),APBoard) then Exit;
     if IsEqualField(AX,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX,AY+1,ReverseColor(AColor),APBoard) then Exit;


     if IsEqualField(AX-1,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY-1,ReverseColor(AColor),APBoard) then Exit;
     if IsEqualField(AX+1,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY+1,ReverseColor(AColor),APBoard) then Exit;

     if IsEqualField(AX+1,AY-1,0,APBoard) then Exit;
     if IsEqualField(AX+1,AY-1,ReverseColor(AColor),APBoard) then Exit;
     if IsEqualField(AX-1,AY+1,0,APBoard) then Exit;
     if IsEqualField(AX-1,AY+1,ReverseColor(AColor),APBoard) then Exit;

     if not IsSuicide(AX,AY,ReverseColor(AColor),APBoard) then Exit; // threatened "false" eye can be filled

     Result :=True;
   end;
   function CountScore(APBoard:PBoard):Double;
   var i,j:integer;occ:SmallInt;Stones:Integer;
   begin
     Result:=DYN_KOMI;
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
   function HasMovesLeft(AColor:SmallInt;APBoard:PBoard):Boolean;
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
   procedure ResetBoard(APBoard:PBoard);
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
    APBoard.LastMoveCoordX:=BOARD_SIZE div 2+1;
    APBoard.LastMoveCoordY:=BOARD_SIZE div 2+1;
   end;
  function ExecuteMove(AX,AY,AColor:SmallInt;APBoard:PBoard;ANullMove:Boolean;AFastMode:Boolean;var MovesB,MovesW:TMoveList):Boolean;
  var enemyColor:SmallInt;RemCount:SmallInt;
  begin
    if ANullMove then
    begin
      APBoard.LastMoveCatchedExactlyOne:=False;
      if APBoard^.LastPlayerPassed then
      begin
        APBoard^.Over:=True;
        APBoard.LastMoveCatchedExactlyOne:=False;
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
        if not IsValidMove(AX,AY,AColor,APBoard) then exit;

    APBoard^.Occupation[AX,AY]:=AColor;
    //---------NOW REMOVE CAPTURED ENEMY GROUPS-------
    enemyColor:=ReverseColor(AColor);
    APBoard^.LastMoveCatchedExactlyOne:=False;  //switch back the ko-marker
     if ALLOW_SUICIDE then
     begin
        If not HasLiberties(AX,AY,APBoard,True) then
        begin
          RemCount:= RemoveGroupRec(AX,AY,APBoard,MovesB,MovesW);
           APBoard^.RemovedStones[AColor]:=APBoard^.RemovedStones[AColor]+RemCount;  //keep track of captured stones

        end;
     end;
      RemCount:=0;
      If IsEqualField(AX-1,AY,enemyColor,APBoard) then
      begin
        If not HasLiberties(AX-1,AY,APBoard,True) then
        begin
         RemCount:=RemCount+ RemoveGroupRec(AX-1,AY,APBoard,MovesB,MovesW);
           APBoard^.LastCatchX:=AX-1;
           APBoard^.LastCatchY:=AY;
        end;
      end;
      If IsEqualField(AX+1,AY,enemyColor,APBoard) then
      begin
        If not HasLiberties(AX+1,AY,APBoard,True) then
        begin
         RemCount:= RemCount+RemoveGroupRec(AX+1,AY,APBoard,MovesB,MovesW);
            APBoard^.LastCatchX:=AX+1;
           APBoard^.LastCatchY:=AY;

        end;
      end;
      If IsEqualField(AX,AY-1,enemyColor,APBoard) then
      begin
        If not HasLiberties(AX,AY-1,APBoard,True) then
        begin
         RemCount:=RemCount+ RemoveGroupRec(AX,AY-1,APBoard,MovesB,MovesW);
             APBoard^.LastCatchX:=AX;
           APBoard^.LastCatchY:=AY-1;

        end;
      end;
      If IsEqualField(AX,AY+1,enemyColor,APBoard) then
      begin
        If not HasLiberties(AX,AY+1,APBoard,True) then
        begin
         RemCount:= RemoveGroupRec(AX,AY+1,APBoard,MovesB,MovesW);
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
  function ReverseColor(AColor:SmallInt):SmallInt;
  begin
    if AColor = 1 then Result := 2 else Result:=1; //Assuming Valid Color;
  end;
  function IsSuicide(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
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
        If CountLibertiesRec(AX-1,AY,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
      end;
//      If IsEqualField(AX+1,AY,enemyColor,APBoard) then
     if APBoard.Occupation[AX+1,AY]=enemyColor then
      begin
        If CountLibertiesRec(AX+1,AY,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
      end;
//      If IsEqualField(AX,AY-1,enemyColor,APBoard) then
   if APBoard.Occupation[AX,AY-1]=enemyColor then
      begin
        If CountLibertiesRec(AX,AY-1,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
      end;
//      If IsEqualField(AX,AY+1,enemyColor,APBoard) then
    if APBoard.Occupation[AX,AY+1]=enemyColor then
      begin
        If CountLibertiesRec(AX,AY+1,APBoard,True,@lMarkedFields,lLen,True)=1 then Exit;
      end;
    //---------------------------------
    //----NOW CHECK FOR OWN GROUP LIBERTIES----------
//      If IsEqualField(AX-1,AY,AColor,APBoard) then
   if APBoard.Occupation[AX-1,AY]=AColor then
      begin
        If CountLibertiesRec(AX-1,AY,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
      end;
//      If IsEqualField(AX+1,AY,AColor,APBoard) then
      if APBoard.Occupation[AX+1,AY]=AColor then
      begin
        If CountLibertiesRec(AX+1,AY,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
      end;
//      If IsEqualField(AX,AY-1,AColor,APBoard) then
      if APBoard.Occupation[AX,AY-1]=AColor then
      begin
        If CountLibertiesRec(AX,AY-1,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
      end;
//      If IsEqualField(AX,AY+1,AColor,APBoard) then
    if APBoard.Occupation[AX,AY+1]=AColor then
      begin
        If CountLibertiesRec(AX,AY+1,APBoard,True,@lMarkedFields,lLen,True)>1 then Exit;
      end;
    //-----------------------------------------------
    // no adjacent liberties
    // no capture of enemy stones
    // no own group with  liberties > 1
    //-------->>>>    SUICIDE!  <<<<----------
    Result:=True;
  end;
  function IsValidMove(AX,AY:SmallInt;AColor:SmallInt;APBoard:PBoard):Boolean;
  begin
    Result := False;
    //-----OUT OF BOUNDS-------
    if AX=0 then exit;
    if AY=0 then exit;
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
  function IsKoValidMove(AX,AY:SmallInt;APBoard:PBoard):Boolean;
  var lMarkedFields:TMarkList; lLen:SmallInt;
  begin
    Result:=True;
    if not APBoard^.LastMoveCatchedExactlyOne then Exit;
    if (AX<>APBoard^.LastCatchX) or (AY<>APBoard^.LastCatchY) then Exit; //not the spot of the last captured stone-> no ko
    if CountLibertiesRec(APBoard^.LastMoveCoordX,APBoard^.LastMoveCoordY,APBoard,True,@lMarkedFields,lLen,True)<>1 then Exit ; //no killing-move
    if RecMarkGroupSize(APBoard^.LastMoveCoordX,APBoard^.LastMoveCoordY,APBoard,True)<>1 then Exit; //if count >1 --> snapback
    //every ko criteria passed, so it's a ko!
    Result := False;
  end;
  function IsEqualField(AX,AY,AOccupation:SmallInt;const APBoard:PBoard):Boolean;
  begin
    //result := False;
    if AX=0 then begin Result:=False; end else
    if AY=0 then begin Result:=False; end else
    if AX>(BOARD_SIZE) then begin Result:=False; end else
    if AY>(BOARD_SIZE) then begin Result:=False; end else
    if (APBoard.Occupation[AX,AY] <> AOccupation) then result:=False else Result:=True;
  end;

  function CountLibertiesRec(AX,AY:SmallInt;APBoard:PBoard;AFirstCall:Boolean;MarkedFields:PMarkList;var ALen:SmallInt;AStopAfterTwo:Boolean):SmallInt;
  var memFlag:SmallInt;i,j:Integer; x,y:Integer;
  begin
    Result:=0;
    if AFirstCall then ALen:=-1;
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


                Result:=Result+CountLibertiesRec(AX-1,AY,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
               end;
           end;
           if not (AStopAfterTwo and(Result>1)) then
           begin
        //     if IsEqualField(AX+1,AY,memFlag, APBoard) then
             if APBoard.Occupation[AX+1,AY]=memFlag then
             begin


              Result:=Result+CountLibertiesRec(AX+1,AY,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
             end;
          end;
      //     if IsEqualField(AX,AY-1,memFlag, APBoard) then
           if not (AStopAfterTwo and(Result>1)) then
           begin
             if APBoard.Occupation[AX,AY-1]=memFlag then
               begin


                Result:=Result+CountLibertiesRec(AX,AY-1,APBoard,False,MarkedFields,ALen,AStopAfterTwo);
               end;
           end;
      //     if IsEqualField(AX,AY+1,memFlag, APBoard) then
           if not (AStopAfterTwo and(Result>1)) then
           begin
              if APBoard.Occupation[AX,AY+1]=memFlag then
               begin


                Result:=Result+CountLibertiesRec(AX,AY+1,APBoard,False,MarkedFields,Alen,AStopAfterTwo);
               end;
           end;
     end;
    //---------------------------------
    //--CLEAN UP THE MARKERS------------
     if AFirstCall then  // only after every recursion stopped we want to unmark
     begin
        for i := 0 to ALen do
        begin
           x:=MarkedFields[i][1];
           y:=MarkedFields[i][2];
           if APBoard.Occupation[x,y]=255 then APBoard.Occupation[x,y]:=0;
           if APBoard.Occupation[x,y]=254 then APBoard.Occupation[x,y]:=memFlag;
          end;
         { for i := 1 to BOARD_SIZE do
          begin
            for j := 1 to BOARD_SIZE do
            begin
            if APBoard^.Occupation[i,j]=255 then APBoard^.Occupation[i,j]:=0;
           if APBoard^.Occupation[i,j]=254 then APBoard^.Occupation[i,j]:=memFlag;
            end;
          end;  }
     end;

    //----------------------------------
  end;

  function GetBoardHash(APBoard:PBoard):Int64;
  begin
    //TODO: Implement hashing
  end;
  function RemoveGroupRec(AX,AY:SmallInt;APBoard:PBoard;var MovesB,MovesW:TMoveList):SmallInt;
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
    len:=length(MovesB);
    SetLength(MovesB,len+1);
    MovesB[len][1]:=AX;MovesB[len][2]:=AY;

    len:=length(MovesW);
    SetLength(MovesW,len+1);
    MovesW[len][1]:=AX;MovesW[len][2]:=AY;
    //------------- ---------------------
    Result:=1;
    //---------DELETE ALL OWN NEIGHBBOURS-----------
        if APBoard^.Occupation[AX+1,AY] = ownCol then Result:=Result+RemoveGroupRec(AX+1,AY,APBoard,MovesB,MovesW);
        if APBoard^.Occupation[AX-1,AY] = ownCol then Result:=Result+RemoveGroupRec(AX-1,AY,APBoard,MovesB,MovesW);
        if APBoard^.Occupation[AX,AY+1] = ownCol then Result:=Result+RemoveGroupRec(AX,AY+1,APBoard,MovesB,MovesW);
        if APBoard^.Occupation[AX,AY-1] = ownCol then Result:=Result+RemoveGroupRec(AX,AY-1,APBoard,MovesB,MovesW);
    //---------------------------------------
  end;
  function RecMarkGroupSize(ARecX,ARecY:SmallInt;APBoard:PBoard;FirstCall:Boolean):SmallInt;
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
