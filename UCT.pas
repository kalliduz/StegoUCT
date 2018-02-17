unit UCT;

interface
  uses DataTypes,BoardControls,Windows,SyncObjs;

  const
  MIN_TREE_WIDTH = 1;
  type
    PTreeNode = ^TTreeNode;
    TExplorationList = array [0..BOARD_SIZE,0..BOARD_SIZE] of PTreeNode;
    PExplorationList = ^TExplorationList;
    THeuristicTable = array[1..BOARD_SIZE,1..BOARD_SIZE] of Double;
    PHeuristicTable = ^THeuristicTable;

    TTreeNode = record
      RatingTable:PRatingTable;
      Board:PBoard;
      ExplorationList:PExplorationList;
      HeuristicTable:PHeuristicTable;
      ParentPointer:PTreeNode;
      MyMoveX,MyMoveY:SmallInt;
      Depth:Byte;
      PlayOuts:Int64;
      IsSettled:Boolean;
      ChildCount:SmallInt;
    end;
    PUCT = ^TUCT;
    TUct = class
      private
        FMaxMemory:Int64;
        FMaxMemReached:Boolean;
        FMaxDepth:Integer;
        FPRootNode:PTreeNode;
        FThreadLocked:Boolean;
        FThreadLockDestroyNode:Boolean;
        FNodeCount:Int64;
        FPlayOutCount:Int64;
        procedure ResetExplorationList(AExplorationList:PExplorationList);
        procedure InitHeuristicTable(ATable:PHeuristicTable;ANode:PTreeNode);
      public
        constructor Create(ABoard:TBoard);
        destructor Destroy;override;
        function AddExploreNode(AParentNode:PTreeNode;AMoveX,AMoveY:SmallInt;var Success:Boolean):PTreeNode;
        function AddPlayOutsToNode(ANode:PTreeNode;AMoveX,AMoveY:SmallInt;AWinsWhite,AWinsBlack:Integer):Boolean;
        function GetCurrentBest(ANode:PTreeNode;var MoveX:SmallInt;var MoveY:SmallInt):Boolean;
        function IsValid(X,Y:SmallInt;Node:PTreeNode):Boolean;
        function GetChildAt(X,Y:SmallInt;ANode:PTreeNode;out ChildNode:PTreeNode):Boolean;
        property RootNode       :PTreeNode  read FPRootNode;
        property MaxDepth       :Integer    read FMaxDepth;
        property NodeCount      :Int64      read FNodeCount;
        property MaxMemReached  :Boolean    read FMaxMemReached;
        function GetNodeBoard(ANode:PTreeNode):TBoard;
        function GetPlayOutCount:Int64;

        function WinrateAt(ANode:PTreeNode;X,Y:SmallInt):Double;
        procedure GetMostPlayed(ANode:PTreeNode;var X:SmallInt;var Y:SmallInt);
        procedure GetBestExploitationNode(ANode:PTreeNode;var X:SmallInt;var Y:SmallInt);
        function GetRatingtable:TRatingTable;
        function SetNewRoot(ANewRootNode:PTreeNode):Boolean;
        procedure FreeTree(AStartNode:PTreeNode; APreserveNewRoot:Boolean;ANewRootNode:PTreeNode);
        function GetMemAllocSize:Int64;inline; //in Bytes
        function GetWorstSubNode(ARootNode:PTreeNode;AAdaptiveDepth:Integer):PTreeNode;
        function PruneTree:Boolean;
        function GetUpperConfidenceFactor(ANode:PTreeNode;ax,ay:SmallInt):Double;
    end;

implementation

uses Math;
 function TUCT.GetUpperConfidenceFactor(ANode:PTreeNode;ax,ay:SmallInt):Double;
  var PlayOutsXY:Int64;
      Wins:Int64;
      RaveBeta:Double;
      UCRave:Double;
      UCNormal:Double;
      Heuristic:Double;
  begin

    if ANode.Board.PlayerOnTurn = 1  then Wins:=Anode.RatingTable.RatingAt[ax,ay].WinsWhite else
    Wins:=Anode.RatingTable.RatingAt[ax,ay].WinsBlack;



    PlayOutsXY:=ANode.RatingTable.RatingAt[ax][ay].WinsBlack+ ANode.RatingTable.RatingAt[ax][ay].WinsWhite;


    if PlayOutsXY=0 then
    begin

     Result:=10000000;
    end else
    begin

       UCNormal:=( Wins/PlayOutsXY)+  //winrate for player on turn
          (Max(EXPLORATION_FACTOR_START-(ANode.Depth*EXPLORATION_FACTOR_STEP),EXPLORATION_FACTOR_END))*
              //the deeper we get, the less broadened will be the tree
          sqrt(Ln(ANode.PlayOuts)/PlayOutsXY);
       Heuristic:=(ANode.HeuristicTable[ax][ay]/PlayOutsXY)*2;


      try
         Result:= UCRave+UCNormal+Heuristic;

      except
        Result:=10000;
      end;
    end;

  end;

function TUCT.PruneTree:Boolean;
var LChild:PTreeNode;
begin
  result:=False;
{ if FThreadLockDestroyNode then Exit;
  FThreadLockDestroyNode:=True;
  Result:=False;
  LChild:=GetWorstSubNode(FPRootNode,0);
  if not Assigned(LChild) then Exit;
  Result:=True;
  FreeTree(LChild,False,nil);
  FThreadLockDestroyNode:=False;  }
  //TODO: Needs rework, pruning still causes access violations
  //TODO: think also about, what notes are best to prune
end;
function TUCT.GetWorstSubNode(ARootNode:PTreeNode;AAdaptiveDepth:Integer):PTreeNode;
var i,j:Integer;val:Int64;worst:double;wx,wy:SmallInt;
    SubNodeCount:Integer;
    wr:double;
    LP1:Boolean;
    ply:int64;
    rW:Int64;
begin


  LP1:=ARootNode.Board.PlayerOnTurn=1;
  if LP1 then worst:=1000 else worst:=-1000;
  SubNodeCount:=0;
  for i := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      if Assigned(ARootNode.ExplorationList[i,j]) then
      begin
        inc(SubNodeCount);
        rw:=ARootNode.RatingTable.RatingAt[i,j].WinsWhite;
        ply:=(rw+ARootNode.RatingTable.RatingAt[i,j].WinsBlack);
        if rw>0 then wr:=rw/ply else wr:=0.5;
        if ((LP1 AND (wr<worst) )OR(not LP1 AND(wr>worst))) then
        begin
          worst:=wr;
          wx:=i;
          wy:=j;
        end;
      end;
    end;
  end;
  if SubNodeCount>MAX_PRUNE_TREE_PRESERVE then //we can cut the whole branch without problems here
  begin
    Result:=ARootNode.ExplorationList[wx,wy];
  end else
  begin
    if SubNodeCount>0 then
    begin
      if AAdaptiveDepth>MIN_DEPTH_FORCED_PRUNE then
      begin
        Result:=ARootNode.ExplorationList[wx,wy];
      end else Result:=GetWorstSubNode(ARootNode.ExplorationList[wx,wy],AAdaptiveDepth+1);
    end else Result:=ARootNode.ExplorationList[wx,wy];
  end;

end;
function TUCT.GetMemAllocSize:Int64;
begin
  Result := FNodeCount*(SizeOf(TTreeNode)+
                        SizeOf(TRatingTable)+
                        SizeOf(TRatingTable)+
                        SizeOf(TBoard)+
                        SizeOf(TExplorationList)+
                        SizeOf(THeuristicTable)+
                        SizeOf(PTreeNode)+
                        SizeOf(SmallInt)*2+1+
                        SizeOf(Int64)*2);
end;
destructor TUCT.Destroy;
begin
  FreeTree(FPRootNode,False,nil);
  inherited;
end;
 procedure TUCT.FreeTree(AStartNode:PTreeNode; APreserveNewRoot:Boolean;ANewRootNode:PTreeNode);
 var i,j:Integer;
 begin
  if not Assigned(AStartNode) then Exit;
  if APreserveNewRoot then if ANewRootNode = AStartNode then
    Exit;


  for i  := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
     FreeTree(AStartNode.ExplorationList[i,j],APreserveNewRoot,ANewRootNode);
    end;
  end;
  if Assigned(AStartNode.ParentPointer) then
     AStartNode.ParentPointer.ExplorationList[AStartNode.MyMoveX,AStartNode.MyMoveY]:=nil;
  Dispose(AStartNode.RatingTable);
  AStartNode.RatingTable:=nil;
  Dispose(AStartNode.Board);
  AStartNode.Board:=nil;
  Dispose(AStartNode.ExplorationList);
  AStartNode.ExplorationList:=nil;
  Dispose(AStartNode.HeuristicTable);
  AStartNode.HeuristicTable:=nil;
  Dispose(AStartNode);
  AStartNode:=Nil;
  FMaxMemReached:=False;
  Dec(FNodeCount);
 end;
 function TUCT.SetNewRoot(ANewRootNode:PTreeNode):Boolean;
 begin
  Result:=False;

  if not Assigned(ANewRootNode) then Exit;
  Result:=True;
  FreeTree(FPRootNode,True,ANewRootNode);
  FPRootNode:=ANewRootNode;
   FPRootNode:=ANewRootNode;
   FPRootNode.ParentPointer:=nil;
  //TODO: Recompute Depth and Playouts
 end;
 procedure TUCT.InitHeuristicTable(ATable:PHeuristicTable;ANode:PTreeNode);
 var i,j:Integer;
      dist:double;
      cap:integer;
 begin
   for i := 1 to BOARD_SIZE  do
   begin
     for j  := 1 to BOARD_SIZE do
       begin
        ATable[i][j]:=1;
        if HasNeighbour(i,j,ANode.Board) then
        begin
          ATable[i][j]:=ATable[i][j]*NEIGHBOUR_HEURISTIC_FACTOR;

        end;
        if (i=1)OR(j=1)OR(i=BOARD_SIZE)OR(j=BOARD_SIZE) then
          begin
            ATable[i][j]:=ATable[i][j]-BOARDER_HEURISTIC_FACTOR;
          end;
        dist:=sqrt(sqr(i-ANode.MyMoveX)+sqr(j-ANode.MyMoveY))/(BOARD_SIZE*sqrt(2));
        if dist>0 then ATable[i][j]:=Atable[i][j]-(dist*TENUKI_PREVENT_HEURISTIC_FACTOR);
        if IsSelfAtari(i,j,ANode.Board.PlayerOnTurn,ANode.Board) then// if j>1 then if j<9 then if i>1 then if i<9  then

        begin
          ATable[i,j]:=-10;
        end;


       { if WouldCaptureLastMove(i,j,ANode.Board) then
        begin
          ATable[i,j]:=20;
        end; }
        cap:= WouldCaptureAnyThing(i,j,Anode.Board) ;
       // if cap>0 then if j>2 then if j<8 then if i>2 then if i<8  then begin
        if cap>0 then
         ATable[i,j]:=ATable[i,j]+(10*cap);
      //  end;

       end;
   end;

 end;
procedure TUCT.GetBestExploitationNode(ANode:PTreeNode;var X:SmallInt;var Y:SmallInt);

  var i,j:INteger;
      Best:Double;
      Val:Double;
begin
  best:=-100000;
  x:=0;
  y:=0;
  if not Assigned(ANode) then Exit;
  if not Assigned(ANode.RatingTable) then  Exit;

  for i  := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      if ANode.RatingTable.RatingAt[i][j].Valid then
      begin
        Val:=GetUpperConfidenceFactor(Anode,i,j);
        if Val>Best then
        begin
          Best:=Val;
          X:=i;
          Y:=j;
        end;
      end;
    end;
  end;
end;

function TUCT.GetRatingtable:TRatingTable;
begin
  result := FPRootNode.RatingTable^;
end;
function TUCT.GetChildAt(X,Y:SmallInt;ANode:PTreeNode;out ChildNode:PTreeNode):Boolean;
begin
  Result:=false;
  if not Assigned(ANode) then Exit;
  if not Assigned(Anode.ExplorationList) then Exit;

  ChildNode:=ANode.ExplorationList[X][Y];
  Result:=Assigned(ChildNode);
end;
function TUCT.IsValid(X,Y:SmallInt;Node:PTreeNode):Boolean;
begin
  Result:=false;
  if not Assigned(Node) then Exit;
  Result := Node.RatingTable.RatingAt[X][Y].Valid;
end;
function TUCT.WinrateAt(ANode:PTreeNode;X,Y:SmallInt):Double;
var w,b:Int64;
begin
  Result:=-10000;
  if not Assigned(ANode) then Exit;
  if ANode.RatingTable.RatingAt[X][Y].Valid then
  begin
    w:=ANode.RatingTable.RatingAt[X][Y].WinsWhite;
    b:=ANode.RatingTable.RatingAt[X][Y].WinsBlack;
    if (w+b) = 0 then
    begin
      Result:=0.5;
      Exit;
    end;
    Result:=w/(w+b);
  end;
end;
  procedure TUCT.GetMostPlayed(ANode:PTreeNode;var X:SmallInt;var Y:SmallInt);
  var i,j:Integer;best,val:Int64;
  begin
    best:=0;
    if not Assigned(ANode) then Exit;
    if not Assigned(Anode.RatingTable) then  Exit;

    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
        if ANode.RatingTable.RatingAt[i][j].Valid then
        begin
          val:=ANode.Ratingtable.RatingAt[i][j].WinsWhite+ANode.Ratingtable.RatingAt[i][j].WinsBlack;
          if val>best then
          begin
           best:=val;
           X:=i;
           Y:=j;
          end;
        end;
      end;
    end;
  end;
   function TUCT.GetPlayOutCount:Int64;
   var i,j:Integer;
   begin
     Result:=0;
    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
        if FPRootNode.RatingTable.RatingAt[i][j].Valid then
        begin
          Result:=Result+FPRootNode.RatingTable.RatingAt[i][j].WinsWhite;
          Result:=Result+FPRootNode.RatingTable.RatingAt[i][j].WinsBlack;
        end;
      end;
    end;
   end;
   function TUCT.GetNodeBoard(ANode:PTreeNode):TBoard;
   begin
    if not Assigned(ANode) then Exit;
    Result:=ANode.Board^;
   end;
  function TUCT.GetCurrentBest(ANode:PTreeNode;var MoveX:SmallInt;var MoveY:SmallInt):Boolean;
  var val,best:double;i,j,x:Integer; w,b:Int64;
  begin
    if ANode.Board.PlayerOnTurn = 1 then best:=-100000000 else best:= 10000000000;
    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
        if ANode.RatingTable.RatingAt[i][j].Valid then
        begin
          w:=ANode.RatingTable.RatingAt[i][j].WinsWhite;
          b:=ANode.RatingTable.RatingAt[i][j].WinsBlack;
          if (w+b)= 0 then val:=0.5 else val:=w/(w+b);
             if (((val<best)and(ANode.Board.PlayerOnTurn =2))or
                ((val>best)and(ANode.Board.PlayerOnTurn =1))) then
             begin
              best:=val;
              MoveX:=i;
              MoveY:=j;
             end;
        end;
        

     end;

    end;
  end;
  function TUCT.AddPlayOutsToNode(ANode:PTreeNode;AMoveX,AMoveY:SmallInt;AWinsWhite,AWinsBlack:Integer):Boolean;
  begin
   //while FThreadLockDestroyNode do sleep(0);
    Result:=False;

    if not Assigned(ANode) then Exit;
     if not Assigned(ANode.RatingTable) then Exit;

      inc(ANode.PlayOuts,AWinsWhite+AWinsBlack);
      Inc(ANode.RatingTable.RatingAt[AMoveX][AMoveY].WinsWhite,AWinsWhite);
      Inc(ANode.RatingTable.RatingAt[AMoveX][AMoveY].WinsBlack,AWinsBlack);

   AddPlayOutsToNode(ANode.ParentPointer,ANode.MyMoveX,ANode.MyMoveY,AWinsWhite,AWinsBlack);    //Backpropagate the winrate!

     Result := True;

  end;
  function TUCT.AddExploreNode(AParentNode:PTreeNode;AMoveX,AMoveY:SmallInt;var Success:Boolean):PTreeNode;
  var dummy1,dummy2:TMoveList;
  begin

    while FThreadLocked do
    begin
      sleep(0);
    end;
    FThreadLocked:=True;
    Success:=False;
    Result:=nil;

    if GetMemAllocSize>FMaxMemory then
    begin
        if not PruneTree then //Try to remove unwanted branches first
        begin
         FMaxMemReached:=True;
         FThreadLocked:=False;
         Exit;
        end;
    end;
    if not Assigned(AParentNode) then begin FThreadLocked:=false; Exit;end;
    if not AParentNode.IsSettled then begin FThreadLocked:=False; Exit;end;

   { if AParentNode.Depth>1 then
    begin
      FThreadLocked:=False;
      Exit;
    end;   }
    if not (AParentNode.PlayOuts>(MC_MAX_THREADS)) then
    begin
      FThreadLocked:=False;
      Exit;
    end;
    if not Assigned(AParentNode.ExplorationList[AMoveX][AMoveY]) then
    begin
    if not IsValidMove(AMoveX,AmoveY,AParentNode.Board.PlayerOnTurn,AParentNode.Board) then
  //  if not IsReasonableMove(AMoveX,AMoveY,AParentNode.Board,AParentNode.Board.PlayerOnTurn) then
    begin
      success:=false;
      Result:=AParentNode; //to prevent stack overflowing.
      FThreadLocked:=false;
      Exit;
    end;
      //---------MEMORY ALLOCATION--------------------
      New(Result);
      Result.IsSettled:=False;
      New(Result.Board);
      New(Result.RatingTable);
      New(Result.ExplorationList);
      New(Result.HeuristicTable);

      //--------------------------------------------
      //--------INITIALIZATION----------------------
      Result.ChildCount:=0;
      inc(AParentNode.ChildCount);
      Result.PlayOuts:=0;
    //  Result.Board^:=AParentNode.Board^;
      Move(AParentNode.Board^,Result.Board^,sizeof(TBoard));
      Result.Depth:=AParentNode.Depth+1;
      inc(FNodeCount);
      if Result.Depth>FMaxDepth then FMaxDepth:=Result.Depth;
      ExecuteMove(AMoveX,AMoveY,Result.Board.PlayerOnTurn,Result.Board,False,True,dummy1,dummy2);
      ResetRatingTable(Result.RatingTable,Result.Board);
      ResetExplorationList(Result.ExplorationList);
      Result.MyMoveX:=AMoveX;// set the move that created this position
      Result.MyMoveY:=AMoveY;
      Result.ParentPointer:=AParentNode;
      AParentNode.ExplorationList[AMoveX][AMoveY]:=Result; //set the explored-field-pointer in the parent-node
      //-------------------------------------------------
     //----------HEURISTIC STUFF--------------
      InitHeuristicTable(Result.HeuristicTable,Result);
      if Result.Board.PlayerOnTurn=1 then
      begin
        if Result.Board.RemovedStones[1]>AParentNode.Board.RemovedStones[1] then
          AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]:=AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]+CAPTURE_EXPLORE_FACTOR;
        if Result.Board.RemovedStones[2]>AParentNode.Board.RemovedStones[2] then
          AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]:=AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]-CAPTURE_EXPLORE_FACTOR;
      end else
      begin
        if Result.Board.RemovedStones[2]>AParentNode.Board.RemovedStones[2] then
          AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]:=AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]+CAPTURE_EXPLORE_FACTOR;
        if Result.Board.RemovedStones[1]>AParentNode.Board.RemovedStones[1] then
          AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]:=AParentNode.HeuristicTable[Result.MyMoveX,Result.MyMoveY]-CAPTURE_EXPLORE_FACTOR;
      end;

      Result.IsSettled:=True;
    //-----------------------------------------------------------
      Success:=True;
    end else
    begin
      Result := AParentNode.ExplorationList[AMoveX][AMoveY]; // if move was already explored, just return the pointer to it
      Success:=False;
    end;
    FThreadLocked:=False;

  end;
   procedure TUCT.ResetExplorationList(AExplorationList:PExplorationList);
   var i,j:Integer;
   begin
    for i := 0 to BOARD_SIZE do for j := 0 to BOARD_SIZE do AExplorationList^[i][j]:=nil;
   end;
   constructor TUct.Create(ABoard:TBoard);
   begin
    FMaxDepth:=0;
    FNodeCount:=1;
    FMaxMemory:=MAX_MEMORY; //1GB
    New(FPRootNode);
    New(FPRootNode.Board);
    New(FPRootNode.RatingTable);
    New(FProotNode.ExplorationList);
    New(FPRootNode.HeuristicTable);
    FPRootNode.ChildCount:=0;
    FPRootNode.MyMoveX:=BOARD_SIZE DIV 2;
    FPRootNode.MyMoveY:=BOARD_SIZE DIV 2;
    FPRootNode.Board^:=ABoard;
    InitHeuristicTable(FPRootNode.HeuristicTable,FPRootNode);
    FPRootNode.ParentPointer:=nil;
    FPRootNode.Depth:=0;
    FPRootNode.PlayOuts:=0;
    ResetRatingTable(FProotNode.RatingTable,FPRootNode.Board);
    ResetExplorationList(FPRootNode.ExplorationList);
    FPRootNode.IsSettled:=True;
   end;
end.
