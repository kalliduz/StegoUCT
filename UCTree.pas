unit UCTree;

interface
uses
  Tree,DataTypes,{$IFDEF FPC}Math{$ELSE}System.Math{$ENDIF};
type
  //TODO
  //Choose best move to get childs from !!!!
  //not best UCT! This is only for exploration
  //get actually the most interesting move, which means the most critical winrate at his level
//  TUCTNode = class(ICompareableData);
  TUCTData = record
    X,Y : Integer;
    FBoard:PBoard;
    IsPassMove:Boolean;
    IsValid:Boolean;
    WinsWhite:Int64;
    WinsBlack:Int64;
    ScoreSum:Double;
    WinsWhiteAMAF:Int64;
    WinsBlackAMAF:Int64;
    UCTVal:Double;
    HasAllChilds:Boolean;
    ISUCTUpToDate:Boolean;
    WinsWhiteTotal:^Int64;
    WinsBlackTotal:^Int64;
    Depth:Integer;
    AssignedNode:Pointer;
  end;
  PUCTData = ^TUCTData;

  TUCTNode = class(TInterfacedObject,ICompareableData)
  private

    FData:PUCTData;
    FParent:TTreeNode<TUCTNode>;
    function GetData:PUCTData;
    procedure SetData(AData:PUCTData);
  public
    procedure FreeData;
    function CompareTo(AObject:TObject):Integer;
    property Data:PUCTData read GetData write SetData;
    function CalculateUCTValue:Double;
    property Parent:TTreeNode<TUCTNode> read FParent write FParent;
    destructor Destroy; override;
  end;

  TUCTree = class(TTree<TUCTNode>)
  private
    FMovesCountOnDepth:Array[0..MAX_TREE_DEPTH-1] of Int64;
    FMovesCountOnDepthAMAF:Array[0..MAX_TREE_DEPTH-1] of Int64;
    FWinsWhiteTotal:Int64;
    FWinsBlackTotal:Int64;
  public
      function DoesNodeHaveChild(ANode:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean; //is there a good way to do this generic?
      procedure SetPointers(ANodeData:TUCtNode);
      function GetBestMoveNode(ARootNode:TTreeNode<TUCTNode>;
                              const AOnlyFirstLevel:Boolean = True;
                              const InitialWR:Double = 0
                              ):TTreeNode<TUCTNode>;
      function UpdateAllAMAFSiblings(AAMAFNode:TTreeNode<TUCTNode>;ARootNode:TTreeNode<TUCTNode>;AIsWhiteWin:Boolean;const AAmount:Integer=1):Boolean;

                                                        // Maybe a "key" value in the treenode
    procedure UpdatePlayout(ANode:TTreeNode<TUCTNode>;AIsWinWhite:Boolean;AIsInitialNode:Boolean;const AIsAMAFUPdate:Boolean = false;const AAmount:Integer=1;const AScoreSum:Double = 0);
    constructor Create(ARootNodeData:TUCTNode);reintroduce;
  end;

implementation
destructor TUCTNode.Destroy;
begin
  FreeData;
  inherited Destroy;
end;
 function TUCTree.UpdateAllAMAFSiblings(AAMAFNode:TTreeNode<TUCTNode>;ARootNode:TTreeNode<TUCTNode>;AIsWhiteWin:Boolean;const AAmount:Integer=1):Boolean;
var
  i:Integer;
begin
  if ARootNode <> AAMAFNode  then
  begin
    if (ARootNode.Content.GetData.FBoard.LastMoveCoordX =
       AAMAFNode.Content.GetData.FBoard.LastMoveCoordX) and
       (ARootNode.Content.GetData.FBoard.LastMoveCoordY =
       AAMAFNode.Content.GetData.FBoard.LastMoveCoordY) and
       (AAMAFNode.Content.GetData.FBoard.PlayerOnTurn =   //color preservation
        ARootNode.Content.GetData.FBoard.PlayerOnTurn) and
        (ARootNode.Depth<3) //if updated
    then
      UpdatePlayout(ARootNode,AIsWhiteWin,True,True,AAmount);
  end;
  for i := 0 to ARootNode.ChildCount-1 do
    UpdateAllAMAFSiblings(AAMAFNode,ARootNode.Childs[i],AIsWhiteWin,AAmount);
end;
constructor TUCTree.Create(ARootNodeData:TUCTNode);
begin
  inherited Create(ARootNodeData);
  FWinsWhiteTotal:=0;
  FWinsBlackTotal:=0;
end;
 function TUCTree.GetBestMoveNode(ARootNode:TTreeNode<TUCTNode>;const AOnlyFirstLevel:Boolean = True;const InitialWR:Double  = 0):TTreeNode<TUCTNode>;
 var
  CurWR,BestWR:Double;
  Ply:Int64;
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
    if Ply > 0 then
    begin
      if RootNode.Content.GetData.FBoard.PlayerOnTurn = 1 then
        Wins:=ARootNode.Childs[i].Content.GetData.WinsWhite
      else
        Wins:=ARootNode.Childs[i].Content.GetData.WinsBlack;
      CurWR:=Ply ;//   ... /how to Choose best move for playing?=!=!=!=!=!=!ß?!?=!==!
      if CurWR>BestWR then
    //  if Ply > ALPHA_AMAF_MINMOVES then
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

procedure TUCTree.SetPointers(ANodeData:TUCTNode);
begin
  ANodeData.Data.WinsWhiteTotal:=@FWinsWhiteTotal;
  ANodeData.Data.WinsBlackTotal:=@FWinsBlackTotal;
end;

procedure TUCTree.UpdatePlayout(ANode:TTreeNode<TUCTNode>;AIsWinWhite:Boolean;AIsInitialNode:Boolean;const AIsAMAFUPdate:Boolean = false;const AAmount:Integer=1;const AScoreSum:Double=0);
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
  {
    first we update the summed up scores
  }
  LPUCTData.ScoreSum:=LPUCTData.ScoreSum+AScoreSum;
  {
    We update the statistic here to get the value for AMAF total playouts after N-th move
  }
  if not AIsAMAFUPdate then
    FMovesCountOnDepth[ANode.Depth]:=FMovesCountOnDepth[ANode.Depth]+1
  else
    FMovesCountOnDepthAMAF[ANode.Depth]:=FMovesCountOnDepthAMAF[ANode.Depth]+1;
  if AIsWinWhite then
  begin
    if AIsAMAFUPdate then
      Inc(LPUCTData.WinsWhiteAMAF,AAmount)
    else
      inc(LPUCTData.WinsWhite,AAmount);
  end
  else
  begin
    if AIsAMAFUPdate then
      Inc(LPUCTData.WinsBlackAMAF,AAmount)
    else
      Inc(LPUCTData.WinsBlack,AAmount);

  end;

if AIsInitialNode then
if not AIsAMAFUPdate then //don't count AMAF playouts as totals
begin
   if AIsWinWhite then
      Inc(LPUCTData.WinsWhiteTotal^,AAmount)
   else
      Inc(LPUCTData.WinsBlackTotal^,AAmount);
end;
  Anode.Content.GetData.ISUCTUpToDate:=False;
  ANode.Content.CalculateUCTValue;
  UpdatePlayout(ANode.Parent,AIsWinWhite,False,AIsAMAFUPdate,AAmount,AScoreSum);

end;

function TUCTree.DoesNodeHaveChild(ANode:TTreeNode<TUCTNode>;AX,AY:Integer):Boolean;
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
  LPly:Double;
  LPlyTotal:Double;
  LWins:Double;
  LWinsAMAF:Double;
  LPlyAMAF:Double;
  LPlyAMAFTotal:Double;
  LPlyAMAFUCT:Double;
  LAlphaAMAFFactor:Double;
  lRealToAmaf:Double;
  LAMAFWR:Double;
  LWr:Double;
begin
  //if not FData.ISUCTUpToDate then
  begin

    LPly:=FData.WinsWhite+FData.WinsBlack;

    {
      normal playouts are included here for amaf heuristic in case we don't have
      amaf playouts yet
    }
    LPlyAMAF:=FData.WinsWhiteAMAF+FData.WinsBlackAMAF+LPly;

    if Assigned(Parent) then
    begin
      LPlyTotal:=Parent.Content.GetData^.WinsWhite+Parent.Content.GetData^.WinsBlack;
      LPlyAMAFTotal:=Parent.Content.GetData^.WinsWhiteAMAF+Parent.Content.GetData^.WinsBlackAMAF+LPlyTotal;
    end
    else
    begin
      //if this node is rootnode, we just use its own playouts for measurements
      LPlyTotal:=FData.WinsWhite+FData.WinsBlack;
      LPlyAMAFTotal:=FData.WinsWhiteAMAF+FData.WinsBlackAMAF+LPlyTotal;
    end;

    if (LPly>0) and (LPlyTotal>0) then
    begin

      if FData.FBoard.PlayerOnTurn = 2 then
      begin
        LWins:=FData.WinsWhite;
        LWinsAMAF:=FData.WinsWhiteAMAF+FData.WinsWhite; //always include real wins for amaf calculation in case of small AMAFs
      end
      else
      begin
        LWins:=FData.WinsBlack;
        LWinsAMAF:=FData.WinsBlackAMAF+FData.WinsBlack;
      end;


      if (LPlyAMAF>0) and (LPlyAMAFTotal>0) then
      begin
        LAMAFWR:=LWinsAMAF/LPlyAMAF; //keep in mind, winrate is adaptive for player here!
        LPlyAMAFUCT:= (LAMAFWR
          +EXPLORATION_FACTOR*
          Sqrt(Ln(LPlyAMAFTotal)/LPlyAMAF));
          ///

      end else
        LPlyAMAFUCT:=0; //if we have no playouts, the amaf of course has no value


      {
        this factor marks the influence of AMAF tree warmup.
        After we got enough "real" playouts on this node,
        AMAF value has no effect anymore
      }
      LAlphaAMAFFactor:=(ALPHA_AMAF_MINMOVES - LPly)/ALPHA_AMAF_MINMOVES;
      if LAlphaAMAFFactor<0 then
        LAlphaAMAFFactor:=0;



        LWr:=LWins/LPly;
        {
          here we calculate the new winrate based on the influence
          of the AMAF-factor
        }
        if  FData.Depth = 1 then
        begin
          LWr:=LWr+0;
        end;
        LWr:=Lwr*(1-LAlphaAMAFFactor)+LAMAFWR*LAlphaAMAFFactor;


          FData.UCTVal:= (LWr
         +EXPLORATION_FACTOR*
         sqrt(Ln(LPlyTotal)/(LPly)));
         ///
//      if LPlyAMAFUCT > 0 then //if we don't have AMAF data, don't tamper with original playout values!
//      begin
//        FData.UCTVal:=FData.UCTVal*(1-LAlphaAMAFFactor) +
//                      LAlphaAMAFFactor * LPlyAMAFUCT;
//      end;
    end
    else //endif playouts > 0
      FData.UCTVal:=10000000+ Random(1000); //we need this to make sure, nodes without playout will be visited first

    FData.ISUCTUpToDate:=True;
  end;
  Result:=FData.UCTVal;
end;

procedure TUCTNode.FreeData;
begin
  Dispose(FData.FBoard);
  Dispose(FData);
end;

function TUCTNode.CompareTo(AObject:TObject):Integer;
begin
    Result:= IfThen((CalculateUCTValue- TUCTNode(AObject).CalculateUCTValue)<0,-1,1);
end;

function TUCTNode.GetData:PUCTData;
begin
  Result:=FData;
end;
end.
