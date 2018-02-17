unit MonteCarlo;

interface
uses DataTypes,BoardControls,SysUtils;
  const
  Directions : array [1..8,1..2] of SmallInt =((1,0),(1,1),(1,-1),(0,1),(0,-1),(-1,0),(-1,1),(-1,-1));
  function SingleMonteCarloWin(APSimBoard:PBoard;var Score:Double):SmallInt;

// TODO:
// - Optimize CleanMoveList and compare to GetMoveList (error if not equal)
//    -->temporary solution with random movelist-update via GetMoveList-Call
// ALGORITHM OPTIMIZATIONS! (NOW: 9x9 6kGames/Sec  GOAL: 40kGames/sec)
// Light vs Heavy Playouts? Think about balance!
//Implement automatic 3x3-pattern-builder(rate by monte-carlo playouts/UCT-Playouts?)
implementation


 function SingleMonteCarloWin(APSimBoard:PBoard;var Score:Double):SmallInt;
 var i:integer;ldoneCount,lValCount:Integer;valid:array[1..8]of Boolean;notMovedFor,movC:Int64;lx,ly,x,y:SmallInt;superKoTrouble:Integer;hasmoved:Boolean; movesB,movesW:TMoveList;len,rnd:Integer;StonesOnBoard:SmallInt;
 begin
  // randomize;
   notMovedFor:=0;
   superKoTrouble:=0;
   movC:=0;
   GetMoveList(APSimBoard,1,@movesW);
   GetMoveList(APSimBoard,2,@movesB);
   while True do
   begin
         inc(MovC);

         if APSimBoard^.LastMoveCatchedExactlyOne then
         begin
           inc(superKoTrouble);
         end else superKoTrouble:=0;

         if (APSimBoard^.Over){or ((MovC>MC_TRUNK))}then
         begin
              Score:=CountScore(APSimBoard);
             if (Score) > 0 then
               Result:=1 else
                Result:=2;
             exit;
         end;
        if (superKoTrouble>100) then
         begin
            Score:=0;//CountScore(APSimBoard);
             //if (CountScore(APSimBoard)) > 0 then
               Result:=random(2)+1;
             exit;
         end;

        //TODO: Reuse the old movelist and just get rid of already made moves,
        //TODO: So we have a very high chance to guess a valid move from the remaining list
        //TODO: There are only few possibilities a already valid move gets invalid after another
        //TODO:     --> maybe check all options for this, and always have valid moves in this list, would be brilliant
         if APSimBoard^.PlayerOnTurn=1 then
         begin
            len:=length(movesW);
//            GetMoveList(APSimBoard,1,@movesW);
      if random(MC_MOVE_REFRESH_RATE)=0 then    GetMoveList(APSimBoard,1,@movesW);
          CleanMoveList(APSimBoard,1,@movesW); //possible only ko-move left
             len:=length(movesW);
        //  if len = 0 then GetMoveList(APSimBoard,1,@movesW);
        //  len:=length(movesW);
         end else
          begin
               len:=length(movesB);
//                GetMoveList(APSimBoard,2,@movesB);
        if random(MC_MOVE_REFRESH_RATE)=0 then  GetMoveList(APSimBoard,2,@movesB);
          CleanMoveList(APSimBoard,2,@movesB) ;
             len:=length(movesB);
         //   if len=0 then  GetMoveList(APSimBoard,2,@movesB);
        //     len:=length(movesB);
          end;
//         GetMoveList(APSimBoard,APSimBoard^.PlayerOnTurn,moves);

            if (len=0) then
           begin
             ExecuteMove(0,0,APSimBoard^.PlayerOnTurn,APSimBoard,True,True,movesB,MovesW);
             Continue;
           end;

           if APSimBoard^.PlayerOnTurn=1 then
           begin
                rnd:=random(len);
                x:=movesW[rnd][1];
                y:=movesW[rnd][2];
           end else
           begin
               rnd:=random(len);
                x:=movesB[rnd][1];
                y:=movesB[rnd][2];
           end;
        //  if IsReasonableMove(x,y,APSimBoard,APSimBoard.PlayerOnTurn) then



                    //-------CAPTURE GO APPENDIX---------------
           { if APSimBoard.RemovedStones[2]>0 then
            begin
              Result:=1;
              Exit;
            end;
            if APSimBoard.RemovedStones[1]>0 then
            begin
              Result:=2;
              Exit;
            end;    }

          //------------------------------------------
          //---------ANTI SELF ATARI POLICY-----------------
                    repeat
           if APSimBoard^.PlayerOnTurn=1 then
           begin
                rnd:=random(len);
                x:=movesW[rnd][1];
                y:=movesW[rnd][2];
           end else
           begin
               rnd:=random(len);
                x:=movesB[rnd][1];
                y:=movesB[rnd][2];
           end;
          until (not IsSelfAtari(x,y,ApSimBoard.PlayerOnTurn,APsimBoard))
          OR (random(5)=0) ; //random accept self atari (if not -> can't kill enemy shapes and possible playout lock)
          //-------------ANTI SELF ATARI POLICY END---------------------

          //-----------CATCH STONE IF YOU CAN POLICY-------------------------
          if random((WouldCaptureAnyThing(x,y,APSimBoard)*5)+1)=0  then
          begin


         { if IsSelfAtari(ApSimBoard.LastMoveCoordX,APsimBoard.LastMoveCoordY,ReverseColor(ApSimBoard.PlayerOnTurn),APSimBoard) then   //try to capture playout policy
          begin
            if WouldCaptureLastMove(ApSimBoard.LastMoveCoordX-1,ApSimBoard.LastMoveCoordY,APSimBoard) then
            begin
              X:=ApSimBoard.LastMoveCoordX-1;
              Y:=ApSimBoard.LastMoveCoordY;
            end;
            if WouldCaptureLastMove(ApSimBoard.LastMoveCoordX+1,ApSimBoard.LastMoveCoordY,APSimBoard) then
            begin
              X:=ApSimBoard.LastMoveCoordX+1;
              Y:=ApSimBoard.LastMoveCoordY;
            end;
                        if WouldCaptureLastMove(ApSimBoard.LastMoveCoordX,ApSimBoard.LastMoveCoordY-1,APSimBoard) then
            begin
              X:=ApSimBoard.LastMoveCoordX;
              Y:=ApSimBoard.LastMoveCoordY-1;
            end;
                        if WouldCaptureLastMove(ApSimBoard.LastMoveCoordX,ApSimBoard.LastMoveCoordY+1,APSimBoard) then
            begin
              X:=ApSimBoard.LastMoveCoordX;
              Y:=ApSimBoard.LastMoveCoordY+1;
            end;
          end;  }
          //-----------CATCH STONE IF YOU CAN POLICY END-------------------------
          //--------------LOCAL MOVE POLICY----------------
          if random(3)=0 then //prefer local answer
          begin
            lValCount:=0;
            for i := 1 to 8 do
            begin
              lx:=APSimBoard.LastMoveCoordX+Directions[i,1];
              ly:=APSimBoard.LastMoveCoordY+Directions[i,2];
              valid[i]:=false;
              if IsValidMove(lx,ly,ApSimBoard.PlayerOnTurn,ApSimBoard) then
              begin
                inc(lValCount);
                valid[i]:=True;
              end;
            end;
            ldoneCount:=0;
            for i := 1 to 8 do
            begin
                if valid[i] then
                begin
                  if random(lValCount-ldoneCount)=0 then
                  begin
                    x:=lx;
                    y:=ly;
                    break;
                  end else inc(ldoneCount);
                end;


            end;

          end;
          end;
          //--------LOCAL MOVE POLICY END----------------------
          ExecuteMove (x,y,APSimBoard^.PlayerOnTurn,APSimBoard,False,False,movesB,MovesW); //else


                  //  begin
        //     ExecuteMove(0,0,APSimBoard^.PlayerOnTurn,APSimBoard,True,True,movesB,MovesW);
       //   end;

   end;
 end;
end.
