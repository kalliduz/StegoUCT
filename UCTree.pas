unit UCTree;

interface
uses
  Tree,DataTypes,System.Math;
type
  //TODO
  //Choose best move to get childs from !!!!
  //not best UCT! This is only for exploration
  //get actually the most interesting move, which means the most critical winrate at his level
  TUCTData = record
    X,Y : Integer;
    FBoard:PBoard;
    IsPassMove:Boolean;
    IsValid:Boolean;
    WinsWhite:Int64;
    WinsBlack:Int64;
    UCTVal:Double;
    ISUCTUpToDate:Boolean;
    WinsWhiteTotal:^Int64;
    WinsBlackTotal:^Int64;

  end;
  PUCTData = ^TUCTData;

  TUCTNode = class(TInterfacedObject,ICompareableData<PUCTData>)
  private
    FData:PUCTData;
  public
    procedure FreeData;
    function CompareTo(AData:PUCTData):Integer;
    function GetData:PUCTData;
    procedure SetData(AData:PUCTData);
    function CalculateUCTValue:Double;
  end;

  TUCTree = class(TTree<PUCTData,TUCTNode>)
  private
    FWinsWhiteTotal:Int64;
    FWinsBlackTotal:Int64;
  public
      function DoesNodeHaveChild(ANode:TTreeNode<PUCTData,TUCTNode>;AX,AY:Integer):Boolean; //is there a good way to do this generic?
      procedure SetPointers(ANodeData:PUCTData);
      function GetBestMoveNode(ARootNode:TTreeNode<PUCTData,TUCTNode>;const AOnlyFirstLevel:Boolean = True;const InitialWR:Double = 0):TTreeNode<PUCTData,TUCTNode>;

                                                        // Maybe a "key" value in the treenode
    procedure UpdatePlayout(ANode:TTreeNode<PUCTData,TUCTNode>;AIsWinWhite:Boolean;AIsInitialNode:Boolean);
    constructor Create(ARootNodeData:TUCTNode);reintroduce;
  end;

implementation
constructor TUCTree.Create(ARootNodeData:TUCTNode);
begin
  inherited Create(ARootNodeData);
  FWinsWhiteTotal:=0;
  FWinsBlackTotal:=0;
end;
 function TUCTree.GetBestMoveNode(ARootNode:TTreeNode<PUCTData,TUCTNode>;const AOnlyFirstLevel:Boolean = True;const InitialWR:Double  = 0):TTreeNode<PUCTData,TUCTNode>;
 var
  CurWR,BestWR:Double;
  Ply:Int64;
  PlyTotal:Int64;
  Wins:Int64;
  i:integer;
 begin
  BestWR:=0;
  if not AOnlyFirstLevel then
    BestWR:=InitialWR;
  Result:=ARootNode;
  for i := 0 to ARootNode.ChildCount-1 do
  begin
    Ply:=ARootNode.Childs[i].Content.GetData.WinsWhite+ARootNode.Childs[i].Content.GetData.WinsBlack;
    PlyTotal:=FWinsWhiteTotal+FWinsBlackTotal;
    if Ply > 0 then
    begin
      if ARootNode.Content.GetData.FBoard.PlayerOnTurn = 1 then
        Wins:=ARootNode.Childs[i].Content.GetData.WinsWhite else
        Wins:=ARootNode.Childs[i].Content.GetData.WinsBlack;
      CurWR:=(Wins/Ply);
      if CurWR>BestWR then
      begin
        BestWR:=CurWR;
        if not AOnlyFirstLevel then
          Result:=GetBestMoveNode(ARootNode.Childs[i],False,BestWR)
        else
          Result:=ARootNode.Childs[i]
      end;
    end;
  end;
 end;

procedure TUCTree.SetPointers(ANodeData:PUCTData);
begin
  ANodeData.WinsWhiteTotal:=@FWinsWhiteTotal;
  ANodeData.WinsBlackTotal:=@FWinsBlackTotal;
end;

procedure TUCTree.UpdatePlayout(ANode:TTreeNode<PUCTData,TUCTNode>;AIsWinWhite:Boolean;AIsInitialNode:Boolean);
var
  LPUCTData:PUCTData;
begin
  if ANode= nil then
    Exit;
  if ANode = RootNode then
  begin
   LPUCTData:=nil;
  end;
  LPUCTData:=ANode.Content.GetData;

  if AIsWinWhite then
    inc(LPUCTData.WinsWhite)
  else
    Inc(LPUCTData.WinsBlack);
if AIsInitialNode then
begin
   if AIsWinWhite then
      Inc(LPUCTData.WinsWhiteTotal^)
   else
      Inc(LPUCTData.WinsBlackTotal^);
end;
  Anode.Content.GetData.ISUCTUpToDate:=False;
  ANode.Content.CalculateUCTValue;
  UpdatePlayout(ANode.Parent,AIsWinWhite,False);//ofc for parent player this win is a loss and vice versa

end;

function TUCTree.DoesNodeHaveChild(ANode:TTreeNode<PUCTData,TUCTNode>;AX,AY:Integer):Boolean;
var
  i:Integer;
begin
  Result:=False;
  for i := 0 to ANode.ChildCount-1 do
  begin
    if
      (ANode.Childs[i].Content.FData.X = AX)
      AND
      (Anode.Childs[i].Content.FData.Y = AY)
    then
      Exit(True);
  end;
end;

procedure TUCTNode.SetData(AData:PUCTData);
begin
  FData:=AData;
end;

function TUCTNode.CalculateUCTValue:Double;
var
  LPly:Int64;
  LPlyTotal:Int64;
  LWins:Int64;
begin
  if not FData.ISUCTUpToDate then
  begin
    LPly:=FData.WinsWhite+FData.WinsBlack;
    LPlyTotal:=FData.WinsWhiteTotal^+FData.WinsBlackTotal^;
    if (LPly>0) and (LPlyTotal>0) then
    begin
      if GetData.FBoard.PlayerOnTurn = 2 then //the uct factor relies on the player that WANTS to make the move, not the player that is
                                              //on turn AFTER he played that move, so we need to swap the winrate here
        LWins:=FData.WinsWhite
      else
        LWins:=FData.WinsBlack;

      FData.UCTVal:= ( LWins/LPly)
         +EXPLORATION_FACTOR_START*
         sqrt(Ln(LPlyTotal)/LPly);
    end else
      FData.UCTVal:=1000;

    FData.ISUCTUpToDate:=True;
  end;
  Result:=FData.UCTVal;
end;

procedure TUCTNode.FreeData;
begin
  Dispose(FData.FBoard);
  Dispose(FData);
end;

function TUCTNode.CompareTo(AData:PUCTData):Integer;
begin
  Result:= IfThen((CalculateUCTValue-AData.UCTVal)<0,-1,1);
end;

function TUCTNode.GetData:PUCTData;
begin
  Result:=FData;
end;
end.
