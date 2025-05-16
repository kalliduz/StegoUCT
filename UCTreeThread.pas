unit UCTreeThread;

interface
uses
  UCTree,Tree,BoardControls,DataTypes,MonteCarlo,System.Classes,System.SysUtils,Threading.Playout;
type

  TUCTreeThread = class (TThread)
  private
    FBestX,FBestY:Integer;
    FExpectedScore:Double;
    FMovePlayouts:Int64;
    FMovePlayoutsAMAF:Int64;
    FAllPlayouts:Int64;
    FUCTree:TUCTree;
    FWinrate:Double;
    FNodeCount:Int64;
    FTreeLocked:Boolean;
    FDynKomi:Double;
    FThreads:array[0..MC_MAX_THREADS-1] of TMCPlayoutThread;
    function PlayoutNode(ANode:PUCTData):Boolean; //true if player on turn wins
    procedure AddRandomSubNode(AParent:TTreeNode<TUCTNode>);
    function AddSpecificSubNode(AParent:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean;
    procedure OnMCThreadFinished(ANode:TTreeNode<TUCTNode>;APlayouts:Integer;AWhiteWins:Integer;AScoreSum:Double);
    procedure SpawnMCThread(ANode:TTreeNode<TUCTNode>;APlayouts:Integer);
  protected
    procedure Execute;override;
  public
    constructor Create(ABoard:TBoard;const ADynKomi:Double = 0);
    property BestX:Integer read FBestX;
    property BestY:Integer read FBestY;
    property Winrate:Double read FWinrate;
    property NodeCount:Int64 read FNodeCount;
    property MovePlayouts:Int64 read FMovePlayouts;
    property MovePlayoutsAMAF:Int64 read FMovePlayoutsAMAF;
    property AllPlayouts:Int64 read FAllPlayouts;
    property Tree:TUCTree read FUCTree; //NOT THREADSAFE !!!
    property DynKomi:Double read FDynKomi;
    property ExpectedScore:Double read FExpectedScore;
    destructor Destroy;override;
  end;

implementation

destructor TUCTreeThread.Destroy;
var
  i:Integer;
begin
  Inherited Destroy;
  for i := 0 to MC_MAX_THREADS-1 do
  begin
    FThreads[i].Terminate;
    FThreads[i].WaitFor;
    FThreads[i].Free;
  end;
  FUCTree.Destroy;

end;
procedure TUCTreeThread.SpawnMCThread(ANode:TTreeNode<TUCTNode>;APlayouts:Integer);
var
  i:Integer;
  LAssigned:Boolean;
begin
  {
    lets search the first unoccupied thread
    and assign the job to it

    if there is no thread available, we just repeat the loop until we find one
  }
  repeat
    LAssigned:=False;
    for i := 0 to MC_MAX_THREADS-1 do
    begin
      if not FThreads[i].IsRunning then
      begin
        FThreads[i].AddJob(ANode.Content.Data.FBoard,APlayouts,ANode,OnMCThreadFinished,Self,FDynKomi);
        LAssigned:=true;
        Break;
      end;
    end;
  until LAssigned;

end;

procedure TUCTreeThread.OnMCThreadFinished(ANode:TTreeNode<TUCTNode>;APlayouts:Integer;AWhiteWins:Integer;AScoreSum:Double);
var
  AB:Integer;
begin
  while FTreeLocked do
  begin
    Sleep(0);
  end;
  {
    update all white wins
    with the white wins, we also update the summed up scores
  }
    FTreeLocked:=True;

    if AWhiteWins > 0 then
    begin
      FUCTree.UpdatePlayout(ANode,True,True,False,AWhiteWins,AScoreSum);
      FUCTree.UpdateAllAMAFSiblings(ANode,FUCTree.RootNode,True,AWhiteWins);
    end;

  {
    Update all black wins
  }
    AB:=APlayouts-AWhiteWins;
    if AB > 0 then
    begin
      {
        if we don't ahve any white wins to update, we need to update the scores together with the black wins
      }
      if AWhiteWins = 0 then
        FUCTree.UpdatePlayout(ANode,False,True,False,AB,AScoreSum)
      else
        FUCTree.UpdatePlayout(ANode,False,True,False,AB);
      FUCTree.UpdateAllAMAFSiblings(ANode,FUCTree.RootNode,False,AB);
    end;

   FTreeLocked:=False;
end;

function TUCTreeThread.AddSpecificSubNode(AParent:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean;
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LMoveList1,LMoveList2:TMoveList;
begin
  Result:=False;
   if Terminated then
   Exit;
   if AParent.Content.Data.FBoard.Over then
   begin
     AParent.Content.Data.HasAllChilds:=True;
     Exit;
   end;
   if AParent.Content.Data.HasAllChilds then
    Exit; //no more submoves to simulate here

    {
      if we have this move here already, we quit
    }
   if FUCTree.DoesNodeHaveChild(AParent,AX,AY)  then
   begin
    Exit;
   end;
   LBoard:=new(PBoard);

   SetLength(LMoveList1,0);
   SetLength(LMoveList2,0);
   Move(AParent.Content.Data.FBoard^,LBoard^,SizeOf(TBoard));
   LPUCTData:= new(PUCTData);
   Result:=False;

   if  IsValidMove(AX,AY,LBoard.PlayerOnTurn,LBoard) then
   begin
     Result:=True;
     ExecuteMove(AX,AY,LBoard.PlayerOnTurn,LBoard,False,False);
   end
   else
    Exit;

   LPUCTData.X:=AX;
   LPUCTData.Y:=AY;

   LPUCTData.FBoard:=LBoard;
   LPUCTData.IsPassMove:= ((AX=0) and(AY=0)) ;
   LPUCTData.IsValid:=True;
   LPUCTData.WinsWhite:=0;
   LPUCTData.WinsBlack:=0;
   LPUCTData.WinsWhiteAMAF:=0;
   LPUCTData.WinsBlackAMAF:=0;
   LPUCTData.Depth:=AParent.Depth+1;
   LPUCTData.HasAllChilds:=False;

   LPUCTData.ISUCTUpToDate:=False;
   LUctNode:=TUCTNode.Create;

   LUctNode.Data:= LPUCTData;
   LPUCTData.AssignedNode:=LUctNode;
   FUCtree.SetPointers(LUCTNode);
   AParent.AddChild(LUctNode);
   LUctNode.Parent:=AParent;
   {for i := 1 to 1 do
   begin
    LWhiteWin:=PlayoutNode(LPUCTData);
    FUCTree.UpdatePlayout(LNode,LWhiteWin,True);
    FUCTree.UpdateAllAMAFSiblings(LNode,FUCTree.RootNode,LWhiteWin);
   end;    }

  // LUctNode.CalculateUCTValue;


end;
procedure TUCTreeThread.AddRandomSubNode(AParent:TTreeNode<TUCTNode>);
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LMoveList1,LMoveList2:TMoveList;
  LSuccess:Boolean;
  i,j:Integer;
  LX,LY:Integer;
  Ltmp:Integer;
  LRandX,LRandY:array [1..BOARD_SIZE] of Integer;

begin
   if Terminated then
   Exit;
   if AParent.Depth > (BOARD_SIZE*BOARD_SIZE) then  //don't go too deep!
   begin
     AParent.Content.Data.HasAllChilds:=True;
     Exit;
   end;
   if AParent.Content.Data.HasAllChilds then
    Exit; //no more submoves to simulate here
   for i := 1 to BOARD_SIZE do
   begin
     LRandX[i]:=i;
     LRandY[i]:=i;
   end;
   for i := 1 to BOARD_SIZE do  //generate random initialised sequences  from 1 to boardsize for both dimensions
   begin
      LX:=Random(BOARD_SIZE)+1;
      LY:=Random(BOARD_SIZE)+1;
      Ltmp:=LRandX[i];
      LRandX[i]:=LRandX[LX];
      LRandX[LX]:=Ltmp;
      Ltmp:=LRandY[i];
      LRandY[i]:=LRandY[LY];
      LRandY[LY]:=Ltmp;
   end;
   LBoard:=new(PBoard);

   SetLength(LMoveList1,0);
   SetLength(LMoveList2,0);
   Move(AParent.Content.Data.FBoard^,LBoard^,SizeOf(TBoard));
   LPUCTData:= new(PUCTData);
   LSuccess:=False;
   for i := 1 to BOARD_SIZE do
   begin
     for j := 1 to BOARD_SIZE do
     begin
       if not FUCTree.DoesNodeHaveChild(AParent,LRandX[i],LRandY[j]) then
       begin
         if  IsValidMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard) then
         begin
           LSuccess:=True;
           LX:=LRandX[i];
           LY:=LRandY[j];
           ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,False,False);
           Break;
         end;
       end;
     end;
     if LSuccess then Break;
   end;
   if not LSuccess then
   begin
      if  (not LBoard.Over) AND
          (not FUCTree.DoesNodeHaveChild(AParent,0,0)) then
      begin
        LX:=0;
        LY:=0;
        ExecuteMove(LX,LY,LBoard.PlayerOnTurn,LBoard,True,False);
      end
      else
      begin
        AParent.Content.Data.HasAllChilds:=True;
        Exit;
      end;
   end;
   LPUCTData.X:=LX;
   LPUCTData.Y:=lY;

   LPUCTData.FBoard:=LBoard;
   LPUCTData.IsPassMove:=((LX=0)and(LY=0));
   LPUCTData.IsValid:=True;
   LPUCTData.WinsWhite:=0;
   LPUCTData.WinsBlack:=0;
   LPUCTData.WinsWhiteAMAF:=0;
   LPUCTData.WinsBlackAMAF:=0;
   LPUCTData.Depth:=AParent.Depth+1;
   LPUCTData.HasAllChilds:=LPUCTData.IsPassMove; //since pass move is the last considered move, it will decide if the node is "full"

   LPUCTData.ISUCTUpToDate:=False;
   LUctNode:=TUCTNode.Create;

   LUctNode.Data:=LPUCTData;
   LPUCTData.AssignedNode:=LUctNode;
   FUCtree.SetPointers(LUCTNode);
   AParent.AddChild(LUctNode);
   LUctNode.Parent:=AParent;
{   for i := 1 to 1 do
   begin
    LWhiteWin:=PlayoutNode(LPUCTData);
    FUCTree.UpdatePlayout(LNode,LWhiteWin,True);
    FUCTree.UpdateAllAMAFSiblings(LNode,FUCTree.RootNode,LWhiteWin);
   end;       }

   LUctNode.CalculateUCTValue;
  {    for i := 1 to BOARD_SIZE do
    begin
      for j := 1 to BOARD_SIZE do
      begin
        AddSpecificSubNode(LNode,i,j);
      end;
    end;
     AddSpecificSubNode(LNode,0,0);  }

end;
function TUCTreeThread.PlayoutNode(ANode:PUCTData):Boolean; //true if white wins
var SimBoard:TBoard; score:Double;
    LWinningPlayer:SmallInt;
begin
  Move(Anode.FBoard^,SimBoard,SizeOf(TBoard));
  LWinningPlayer:= PlayoutPosition (@SimBoard,score);// SingleMonteCarloWin(@SimBoard,score);
  Result:=  LWinningPlayer = 1;
end;

 constructor TUCTreeThread.Create(ABoard:TBoard;const ADynKomi:Double);
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LWhiteWin:Boolean;
 begin
   FTreeLocked:=False;
   FDynKomi:=ADynKomi;
   LBoard:=new(PBoard);
   Move(ABoard,LBoard^,SizeOf(TBoard));

   LPUCTData:= new(PUCTData);
   LPUCTData.X:=0;
   LPUCTData.Y:=0;
   LPUCTData.FBoard:=LBoard;
   LPUCTData.IsPassMove:=False;
   LPUCTData.IsValid:=True;
   LPUCTData.WinsWhite:=0;
   LPUCTData.WinsBlack:=0;
   LPUCTData.WinsWhiteAMAF:=0;
   LPUCTData.WinsBlackAMAF:=0;
   LPUCTData.Depth:=0;

   LPUCTData.HasAllChilds:=False;

   LUctNode:=TUCTNode.Create;
   LUctNode.Data:= LPUCTData;
   LUctNode.Parent:=nil;
   LPUCTData.AssignedNode:=LUctNode;
   FUCTree:=TUCTree.Create(LUctNode);
   FUCtree.SetPointers(LUCTNode);
   LWhiteWin:=PlayoutNode(LPUCTData);
   FUCTree.UpdatePlayout(FUCTree.RootNode,LWhiteWin,True);
   LUctNode.CalculateUCTValue;
   inherited Create(False);
 end;
 procedure TUCTreeThread.Execute;
 var
  LHighestNode:TTreeNode<TUCTNode>;
  LMoveNode:TTreeNode<TUCTNode>;
  Ply:Integer;
  i,j,k:Integer;
 begin
 {
  first we spawn our MC threads
 }
   NameThreadForDebugging('UCTThread');
   for i := 0 to MC_MAX_THREADS-1 do
   begin
     FThreads[i]:=TMCPlayoutThread.Create;
   end;
  //first lets add all possible moves as first nodes in the tree
  for i := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      AddSpecificSubNode(FUCTree.RootNode,i,j);
    end;
  end;
   AddSpecificSubNode(FUCTree.RootNode,0,0);



  while true do
  begin
      while Suspended do
      begin
        sleep(0);
        if Terminated then
        Exit;
      end;
      if Terminated then
        Exit;

       {
        First we start with the best UCT root node
       }
       LHighestNode:=FUCTree.RootNode.GetHighestDirectChild(False);

       while true do
       begin
           {
            The highest node should never be nil here
           }
           if LHighestNode = nil then
           begin
            break;
             raise Exception.Create('Should not happen!');
           end;
           {
            If the node was never played out, we do so, and exit the loop
           }
           if LHighestNode.Content.Data.WinsWhite+LHighestNode.Content.Data.WinsBlack < MC_MIN_NODE_PLAYOUT then
           begin
              SpawnMCThread(LHighestNode,MC_PLAYOUT_CHUNK_SIZE);
              Break;
           end else
           begin

             {
              for the case we landed in a final position,
              we update the score and just exit the loop
             }
             if LHighestNode.Content.Data.FBoard.Over then
             begin
                SpawnMCThread(LHighestNode,MC_PLAYOUT_CHUNK_SIZE);
                Break;
             end;

             {
              now, since the node was already played out,
              we add all children to that node
              if it has no childs yet
             }
             if not LHighestNode.Content.Data.HasAllChilds then
             begin
                for j := 1 to BOARD_SIZE do
                begin
                  for k := 1 to BOARD_SIZE do
                  begin
                    AddSpecificSubNode(LHighestNode,j,k);
                  end;
                end;
                 AddSpecificSubNode(LHighestNode,0,0);
                LHighestNode.Content.Data.HasAllChilds:=true;
                Break;
             end;

             {
               now we select the best move, which is now
               either a random with 0 visits
               or the best child
             }
            LHighestNode:=LHighestNode.GetHighestDirectChild(False);

           end;




       end;


      //this is only move chosing stuff now-----

      LMoveNode:=FUCTree.GetBestMoveNode(FUCTree.RootNode,True,0);

      FBestX:=LMoveNode.Content.Data.X;
      FBestY:=LMoveNode.Content.Data.Y;

      Ply:=LMoveNode.Content.Data.WinsWhite+LMoveNode.Content.Data.WinsBlack;
      FExpectedScore:=LMoveNode.Content.Data.ScoreSum/Ply;
      if Ply>0 then
        FWinrate:=LMoveNode.Content.Data.WinsWhite/Ply
      else
        FWinrate:=-1;
      FMovePlayouts:=Ply;
      FMovePlayoutsAMAF:=LMoveNode.Content.Data.WinsWhiteAMAF+LMoveNode.Content.Data.WinsBlackAMAF;
      FAllPlayouts:=LMoveNode.Content.Data.WinsWhiteTotal^+LMoveNode.Content.Data.WinsBlackTotal^;
      FNodeCount:=FUCTree.NodeCount;
  end;
 end;
end.
