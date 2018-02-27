unit UCTreeThread;

interface
uses
  UCTree,Tree,BoardControls,DataTypes,MonteCarlo,System.Classes,System.SysUtils;
type
  TUCTreeThread = class (TThread)
  private
    FBestX,FBestY:Integer;
    FMovePlayouts:Int64;
    FMovePlayoutsAMAF:Int64;
    FAllPlayouts:Int64;
    FUCTree:TUCTree;
    FWinrate:Double;
    FNodeCount:Int64;
    function PlayoutNode(ANode:PUCTData):Boolean; //true if player on turn wins
    procedure AddRandomSubNode(AParent:TTreeNode<PUCTData,TUCTNode>);
    function AddSpecificSubNode(AParent:TTreeNode<PUCTData,TUCTNode>;AX,AY:Integer):Boolean;
  protected
    procedure Execute;override;
  public
    constructor Create(ABoard:TBoard);
    property BestX:Integer read FBestX;
    property BestY:Integer read FBestY;
    property Winrate:Double read FWinrate;
    property NodeCount:Int64 read FNodeCount;
    property MovePlayouts:Int64 read FMovePlayouts;
    property MovePlayoutsAMAF:Int64 read FMovePlayoutsAMAF;
    property AllPlayouts:Int64 read FAllPlayouts;
    destructor Destroy;
  end;

implementation
destructor TUCTreeThread.Destroy;
begin
  FUCTree.Destroy;
  Inherited Destroy;
end;

function TUCTreeThread.AddSpecificSubNode(AParent:TTreeNode<PUCTData,TUCTNode>;AX,AY:Integer):Boolean;
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LMoveList1,LMoveList2:TMoveList;
  LSuccess:Boolean;
  i,j:Integer;
  LX,LY:Integer;
  Ltmp:Integer;
  LWhiteWin:Boolean;
  LNode:TTreeNode<PUCTData,TUCTNode>;
  LRandX,LRandY:array [1..BOARD_SIZE] of Integer;
begin
  Result:=False;
   if Terminated then
   Exit;
   if AParent.Content.GetData.HasAllChilds then
    Exit; //no more submoves to simulate here


   LBoard:=new(PBoard);

   SetLength(LMoveList1,0);
   SetLength(LMoveList2,0);
   Move(AParent.Content.GetData.FBoard^,LBoard^,SizeOf(TBoard));
   LPUCTData:= new(PUCTData);
   Result:=False;

   if  IsValidMove(AX,AY,LBoard.PlayerOnTurn,LBoard) then
   begin
     Result:=True;
     ExecuteMove(AX,AY,LBoard.PlayerOnTurn,LBoard,False,False,LMoveList1,LMoveList2);
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

   LUctNode.SetData(LPUCTData);
   LPUCTData.AssignedNode:=LUctNode;
   FUCtree.SetPointers(LPUctData);
   LNode:=AParent.AddChild(LUctNode);
   LUctNode.Parent:=AParent;
   for i := 1 to 1 do
   begin
    LWhiteWin:=PlayoutNode(LPUCTData);
    FUCTree.UpdatePlayout(LNode,LWhiteWin,True);
    FUCTree.UpdateAllAMAFSiblings(LNode,FUCTree.RootNode,LWhiteWin);
   end;

   LUctNode.CalculateUCTValue;


end;
procedure TUCTreeThread.AddRandomSubNode(AParent:TTreeNode<PUCTData,TUCTNode>);
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LMoveList1,LMoveList2:TMoveList;
  LSuccess:Boolean;
  i,j:Integer;
  LX,LY:Integer;
  Ltmp:Integer;
  LWhiteWin:Boolean;
  LNode:TTreeNode<PUCTData,TUCTNode>;
  LRandX,LRandY:array [1..BOARD_SIZE] of Integer;
begin
   if Terminated then
   Exit;
   if AParent.Depth > (BOARD_SIZE*BOARD_SIZE) then  //don't go too deep!
   begin
     AParent.Content.GetData.HasAllChilds:=True;
     Exit;
   end;
   if AParent.Content.GetData.HasAllChilds then
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
   Move(AParent.Content.GetData.FBoard^,LBoard^,SizeOf(TBoard));
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
           ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,False,False,LMoveList1,LMoveList2);
           Break;
         end;
       end;
     end;
     if LSuccess then Break;
   end;
   if not LSuccess then
   begin
//      if not LBoard.Over then
//      if not FUCTree.DoesNodeHaveChild(AParent,0,0) then
//      begin
//        LX:=0;
//        LY:=0;
//        ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,True,False,LMoveList1,LMoveList2);
//      end
//      else
//      begin
        AParent.Content.GetData.HasAllChilds:=True;
        Exit;
//        Exit; //if two players passed, nothing more to do here.
//      end;
   end;
   LPUCTData.X:=LX;
   LPUCTData.Y:=lY;

   LPUCTData.FBoard:=LBoard;
   LPUCTData.IsPassMove:=False;
   LPUCTData.IsValid:=True;
   LPUCTData.WinsWhite:=0;
   LPUCTData.WinsBlack:=0;
   LPUCTData.WinsWhiteAMAF:=0;
   LPUCTData.WinsBlackAMAF:=0;
   LPUCTData.Depth:=AParent.Depth+1;
   LPUCTData.HasAllChilds:=False;

   LPUCTData.ISUCTUpToDate:=False;
   LUctNode:=TUCTNode.Create;

   LUctNode.SetData(LPUCTData);
   LPUCTData.AssignedNode:=LUctNode;
   FUCtree.SetPointers(LPUctData);
   LNode:=AParent.AddChild(LUctNode);
   LUctNode.Parent:=AParent;
   for i := 1 to 1 do
   begin
    LWhiteWin:=PlayoutNode(LPUCTData);
    FUCTree.UpdatePlayout(LNode,LWhiteWin,True);
    FUCTree.UpdateAllAMAFSiblings(LNode,FUCTree.RootNode,LWhiteWin);
   end;

   LUctNode.CalculateUCTValue;


end;
function TUCTreeThread.PlayoutNode(ANode:PUCTData):Boolean; //true if white wins
var SimBoard:TBoard; score:Double;k:integer;
    LWinningPlayer:SmallInt;
begin
  Move(Anode.FBoard^,SimBoard,SizeOf(TBoard));
  LWinningPlayer:= SingleMonteCarloWin(@SimBoard,score);
  Result:=  LWinningPlayer = 1;
end;

 constructor TUCTreeThread.Create(ABoard:TBoard);
 var
  LPUCTData:PUCTData;
  LUctNode:TUCTNode;
  LBoard:PBoard;
  LWhiteWin:Boolean;
  i:integer;
 begin
   inherited Create(True);
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
   LUctNode.SetData(LPUCTData);
   LUctNode.Parent:=nil;
   LPUCTData.AssignedNode:=LUctNode;
   FUCTree:=TUCTree.Create(LUctNode);
   FUCtree.SetPointers(LPUctData);
   LWhiteWin:=PlayoutNode(LPUCTData);
   FUCTree.UpdatePlayout(FUCTree.RootNode,LWhiteWin,True);
   LUctNode.CalculateUCTValue;
   Resume;
 end;
 procedure TUCTreeThread.Execute;
 var
  LHighestNode:TTreeNode<PUCTData,TUCTNode>;
  LLast:TTreeNode<PUCTData,TUCTNode>;
  Ply:Integer;
  LWhiteWin:Boolean;
  i,j:Integer;
 begin

  //first lets add all possible moves as first nodes in the tree
  for i := 1 to BOARD_SIZE do
  begin
    for j := 1 to BOARD_SIZE do
    begin
      AddSpecificSubNode(FUCTree.RootNode,i,j);
    end;
  end;
   AddSpecificSubNode(FUCTree.RootNode,0,0);



  i:=0;
  while True do
  begin
      if Terminated then
        Exit;
      inc(i);

       LHighestNode:=FUCTree.RootNode.GetHighestDirectChild;
       LLast:=LHighestNode;


       while true do
       begin

          if Assigned(LHighestNode) then
            AddRandomSubNode(LHighestNode);

          LHighestNode:=LHighestNode.GetHighestDirectChild(not LHighestNode.Content.GetData.HasAllChilds);

          // --> if this node already has all moves set, he should not consider himself for exploitation, but give it to a child
         if (LLast = LHighestNode)or (LHighestNode = nil)  then Break;
         LLast :=LHighestNode;
       end;
       LHighestNode:=LLast; //after executing, roll it back to the last safe node
//        for i := 1 to BOARD_SIZE do
//        begin
//          for j := 1 to BOARD_SIZE do
//          begin
//            AddSpecificSubNode(LHighestNode,i,j);
//          end;
//        end;
//          AddSpecificSubNode(LHighestNode,0,0);
//       if LHighestNode.Content.GetData.HasAllChilds then
//         LHighestNode:=LHighestNode.GetHighestDirectChild; //if node is not exploitable any more, choose best child
//
//       AddRandomSubNode(LHighestNode);
//
//       if LHighestNode.Content.GetData.HasAllChilds then
//        LHighestNode:=LHighestNode.GetHighestDirectChild; //if node is not exploitable any more, choose best child
//
//
//        AddRandomSubNode(LHighestNode);


             if LHighestNode.Content.GetData.HasAllChilds then //if we got to simulate all positions until depth 3
             begin
                LHighestNode:=FUCTree.GetRandomLeaf;
                LWhiteWin:=PlayoutNode(LHighestNode.Content.GetData);
                FUCTree.UpdatePlayout(LHighestNode,LWhiteWIn,True);
                FUCTree.UpdateAllAMAFSiblings(LHighestNode,FUCTree.RootNode,LWhiteWin);
             end;


//
//        for j := 1 to 10 do
//       begin
//            LHighestNode:=FUCTree.GetRandomLeaf;
//            LWhiteWin:=PlayoutNode(LHighestNode.Content.GetData);
//            FUCTree.UpdatePlayout(LHighestNode,LWhiteWIn,True);
//            FUCTree.UpdateAllAMAFSiblings(LHighestNode,FUCTree.RootNode,LWhiteWin);
//       end;

      LHighestNode:=FUCTree.GetBestMoveNode(FUCTree.RootNode,True,0);

      FBestX:=LHighestNode.Content.GetData.X;
      FBestY:=LHighestNode.Content.GetData.Y;
      Ply:=LHighestNode.Content.GetData.WinsWhite+LHighestNode.Content.GetData.WinsBlack;
      if Ply>0 then
        FWinrate:=LHighestNode.Content.GetData.WinsWhite/Ply
      else
        FWinrate:=-1;
      FMovePlayouts:=Ply;
      FMovePlayoutsAMAF:=LHighestNode.Content.GetData.WinsWhiteAMAF+LHighestNode.Content.GetData.WinsBlackAMAF;
      FAllPlayouts:=LHighestNode.Content.GetData.WinsWhiteTotal^+LHighestNode.Content.GetData.WinsBlackTotal^;
      FNodeCount:=FUCTree.NodeCount;
  end;
 end;
end.
