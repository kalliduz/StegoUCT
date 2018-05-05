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
    procedure AddRandomSubNode(AParent:TTreeNode<TUCTNode>);
    function AddSpecificSubNode(AParent:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean;
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
    property Tree:TUCTree read FUCTree; //NOT THREADSAFE !!!
    destructor Destroy;
  end;

implementation
destructor TUCTreeThread.Destroy;
begin
  FUCTree.Destroy;
  Inherited Destroy;
end;

function TUCTreeThread.AddSpecificSubNode(AParent:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean;
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
  LNode:TTreeNode<TUCTNode>;
  LRandX,LRandY:array [1..BOARD_SIZE] of Integer;
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

   LUctNode.Data:= LPUCTData;
   LPUCTData.AssignedNode:=LUctNode;
   FUCtree.SetPointers(LUCTNode);
   LNode:=AParent.AddChild(LUctNode);
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
  LWhiteWin:Boolean;
  LNode:TTreeNode<TUCTNode>;
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
           ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,False,False,LMoveList1,LMoveList2);
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
        ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,True,False,LMoveList1,LMoveList2);
      end
      else
      begin
        AParent.Content.Data.HasAllChilds:=True;
        Exit;
        Exit; //if two players passed, nothing more to do here.
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
   LNode:=AParent.AddChild(LUctNode);
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
   LUctNode.Data:= LPUCTData;
   LUctNode.Parent:=nil;
   LPUCTData.AssignedNode:=LUctNode;
   FUCTree:=TUCTree.Create(LUctNode);
   FUCtree.SetPointers(LUCTNode);
   LWhiteWin:=PlayoutNode(LPUCTData);
   FUCTree.UpdatePlayout(FUCTree.RootNode,LWhiteWin,True);
   LUctNode.CalculateUCTValue;
   Resume;
 end;
 procedure TUCTreeThread.Execute;
 var
  LHighestNode:TTreeNode<TUCTNode>;
  LMoveNode:TTreeNode<TUCTNode>;
  LLast:TTreeNode<TUCTNode>;
  Ply:Integer;
  LWhiteWin:Boolean;
  i,j,k:Integer;
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

       {
        First we start with the best UCT root node
       }
       LHighestNode:=FUCTree.RootNode.GetHighestDirectChild(False);

       while true do
       begin
           {
            The highest node should never be nil here
           }
         //   if LHighestNode.Depth>2 then Break;
           if LHighestNode = nil then
           begin
            break;
             raise Exception.Create('Should not happen!');
           end;
           {
            If the node was never played out, we do so, and exit the loop
           }
           if LHighestNode.Content.Data.WinsWhite+LHighestNode.Content.Data.WinsBlack < 10 then
           begin
             for j := 1 to 1 do
             begin
                LWhiteWin:=PlayoutNode(LHighestNode.Content.Data);
                FUCTree.UpdatePlayout(LHighestNode,LWhiteWIn,True);
                FUCTree.UpdateAllAMAFSiblings(LHighestNode,FUCTree.RootNode,LWhiteWin);
             end;
             Break;
           end else
           begin

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
              //   AddRandomSubNode(LHighestNode);
                LHighestNode.Content.Data.HasAllChilds:=true;
                Break;
             end;

             {
               now we select the best move, which is now
               either a random with 0 visits
               or the best child
             }
            { for i := 1 to 1 do
             begin
                LWhiteWin:=PlayoutNode(LHighestNode.Content.Data);
                FUCTree.UpdatePlayout(LHighestNode,LWhiteWIn,True);
                FUCTree.UpdateAllAMAFSiblings(LHighestNode,FUCTree.RootNode,LWhiteWin);
             end;     }
             if LHighestNode.Content.Data.FBoard.Over then
              Break;
            LHighestNode:=LHighestNode.GetHighestDirectChild(False);//not LHighestNode.Content.Data.HasAllChilds);
           end;

       //  if LHighestNode.Depth>= 9 then Break;




       end;


      //this is only move chosing stuff now-----

      LMoveNode:=FUCTree.GetBestMoveNode(FUCTree.RootNode,True,0);

      FBestX:=LMoveNode.Content.Data.X;
      FBestY:=LMoveNode.Content.Data.Y;
      Ply:=LMoveNode.Content.Data.WinsWhite+LMoveNode.Content.Data.WinsBlack;
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
