unit UCTreeThread;

interface
uses
  UCTree,Tree,BoardControls,DataTypes,MonteCarlo,System.Classes,System.SysUtils;
type
  TUCTreeThread = class (TThread)
  private
    FBestX,FBestY:Integer;
    FMovePlayouts:Int64;
    FAllPlayouts:Int64;
    FUCTree:TUCTree;
    FWinrate:Double;
    FNodeCount:Int64;
    function PlayoutNode(ANode:PUCTData):Boolean; //true if player on turn wins
    procedure AddRandomSubNode(AParent:TTreeNode<PUCTData,TUCTNode>);
  protected
    procedure Execute;override;
  public
    constructor Create(ABoard:TBoard);
    property BestX:Integer read FBestX;
    property BestY:Integer read FBestY;
    property Winrate:Double read FWinrate;
    property NodeCount:Int64 read FNodeCount;
    property MovePlayouts:Int64 read FMovePlayouts;
    property AllPlayouts:Int64 read FAllPlayouts;
    destructor Destroy;
  end;

implementation
destructor TUCTreeThread.Destroy;
begin
  FUCTree.Destroy;
  Inherited Destroy;
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
  LRandX,LRandY:array [1..BOARD_SIZE] of Integer;
begin
   if Terminated then
   Exit;
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
      if not LBoard.Over then
      if not FUCTree.DoesNodeHaveChild(AParent,0,0) then
      begin
        LX:=0;
        LY:=0;
        ExecuteMove(LRandX[i],LRandY[j],LBoard.PlayerOnTurn,LBoard,True,False,LMoveList1,LMoveList2);
      end
      else
        Exit; //if two players passed, nothing more to to here.
   end;
   LPUCTData.X:=LX;
   LPUCTData.Y:=lY;

   LPUCTData.FBoard:=LBoard;
   LPUCTData.IsPassMove:=False;
   LPUCTData.IsValid:=True;
   LPUCTData.WinsWhite:=0;
   LPUCTData.WinsBlack:=0;

   LPUCTData.ISUCTUpToDate:=False;
   LUctNode:=TUCTNode.Create;

   LUctNode.SetData(LPUCTData);
   FUCtree.SetPointers(LPUctData);

    FUCTree.UpdatePlayout(AParent.AddChild(LUctNode),    PlayoutNode(LPUCTData),True);
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

   LUctNode:=TUCTNode.Create;
   LUctNode.SetData(LPUCTData);

   FUCTree:=TUCTree.Create(LUctNode);
   FUCtree.SetPointers(LPUctData);
   FUCTree.UpdatePlayout(FUCTree.RootNode,PlayoutNode(LPUCTData),True);
   LUctNode.CalculateUCTValue;
   Resume;
 end;
 procedure TUCTreeThread.Execute;
 var
  LHighestNode:TTreeNode<PUCTData,TUCTNode>;
  Ply:Integer;
  i:Integer;
 begin
  for i := 1 to (BOARD_SIZE*BOARD_SIZE) do
  begin
    AddRandomSubNode(FUCTree.RootNode);
  end;
  i:=0;
  while True do
  begin
      if Terminated then
        Exit;
      inc(i);
      LHighestNode:=FUCTree.GetHighestNode;
      FUCTree.UpdatePlayout(LHighestNode,PlayoutNode(LHighestNode.Content.GetData),True);
      if i mod 2  = 0 then
        AddRandomSubNode(FUCTree.GetBestMoveNode(FUCTree.RootNode,False,0));


        LHighestNode:=FUCTree.GetBestMoveNode(FUCTree.RootNode,True,0);
      FBestX:=LHighestNode.Content.GetData.X;
      FBestY:=LHighestNode.Content.GetData.Y;
      Ply:=LHighestNode.Content.GetData.WinsWhite+LHighestNode.Content.GetData.WinsBlack;
      if Ply>0 then
        FWinrate:=LHighestNode.Content.GetData.WinsWhite/Ply
      else
        FWinrate:=-1;
      FMovePlayouts:=Ply;
      FAllPlayouts:=LHighestNode.Content.GetData.WinsWhiteTotal^+LHighestNode.Content.GetData.WinsBlackTotal^;
      FNodeCount:=FUCTree.NodeCount;
  end;
 end;
end.
