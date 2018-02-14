unit UCTThread;

interface

uses
  Classes,BoardControls,DataTypes,MonteCarlo,UCT,Math;

type
  TUCTThread = class(TThread)
  private
    { Private-Deklarationen }
    FPUCT:PUCT;
    FIsKilled:Boolean;
    procedure PlayOutPosition(APlayOuts:Integer;ANode:PTreeNode);
    procedure PlayOutXY(ANode:PTreeNode;APlayOuts:Integer;X,Y:SmallInt);
    procedure ExploreNode(ANode:PTreeNode;MaxDepth:Byte;APlayOutsPerExplore:Integer;MaxExploreWidth:Byte);
    procedure Expand(ANode:PTreeNode); //adds a recursive node to the best-winrate-node
    procedure Explore(ANode:PTreeNode); //thinks through the position after every best move was made
    procedure ExploreAll(Root:PTreeNode); //Thinks through every node below the RootNode
  protected
    procedure Execute; override;
  public
    constructor Create(AUCT:PUCT);
    property KillFlag :Boolean  read FIsKilled  write FIsKilled;
  end;

implementation
procedure TUCTThread.PlayOutXY(ANode:PTreeNode;APlayOuts:Integer;X,Y:SmallInt);
var NodeBoard,SimBoardXY,SimBoard:TBoard; w,b:Integer;i:Integer;score:Double;k:integer;lAMAF:TAMAFList;
begin
  //-------CRITICAL-------------
  NodeBoard:=FPUCT.GetNodeBoard(ANode);
  //-------END CRITICAL------------

            if FPUCT.IsValid(x,y,ANode) then
            begin
              Move(NodeBoard,SimBoardXY,SizeOf(TBoard));
              b:=0;w:=0;
              for i := 1 to APlayOuts do
              begin
                if FIsKilled then Exit;
                Move(SimBoardXY,SimBoard,SizeOf(TBoard));
                lAMAF.MoveCount:=1;
                if SingleMonteCarloWin(@SimBoard,score,lAMAF) = 1 then inc(w) else inc(b);
              end;
              //------CRITICAL------------
              FPUCT.AddPlayOutsToNode(ANode,x,y,w,b,false,lAMAF);
              //----END CRITICAL------------
            end;


end;
 procedure TUCTThread.ExploreAll(Root:PTreeNode);
 var i,j:Integer; Child:PtreeNode;
 begin
   PlayOutPosition(1,Root);
   for i  := 1 to BOARD_SIZE do
   begin
     for j  := 1 to BOARD_SIZE do
     begin
      if FPUCT.GetChildAt(i,j,Root,Child) then
      begin
        ExploreAll(Child);
      end;
     end;
   end;

 end;
 procedure TUCTThread.Explore(Anode:PTreeNode);
 var mX,mY:SmallInt; Child:PTreeNode;
 begin
    Child:=nil;
    FPUCT.GetBestExploitationNode(ANode,mX,mY);
    if FPUCT.GetChildAt(mX,mY,ANode,Child) then  //if best move already has a child
    begin
      Explore(Child); // Go one step further
    end else
    begin
//      PlayOutPosition(1,ANode); //else playout this position
        PlayOutXY(ANode,1,mx,MY);
    end;
 end;
 procedure TUCTThread.Expand(ANode:PTreeNode);
 var mx,mY:SmallInt; child:PTreeNode; success:Boolean;
 begin
  if FPUCT.MaxMemReached then Exit;

  FPUCT.GetBestExploitationNode(ANode,mx,mY);
  child:=FPUCT.AddExploreNode(ANode,mx,my,success);
  if success then
  begin

  // PlayOutPosition(1,Child);//new position needs to be playout immediately, else bestmove= (1,1)
  // PlayOutPosition(1,ANode);//playout position the node started from to ensure this is best move
   Exit;
   end else
  begin
  if Child<>ANode then
    Expand(child) else
    begin
     mx:=mx+1;
    end;  //else not expandable because last move on board
  end;
 end;
procedure TUCTThread.ExploreNode(ANode:PTreeNode;MaxDepth:Byte;APlayOutsPerExplore:Integer;MaxExploreWidth:Byte);
var mX,mY:SmallInt; child:PTreeNode; ExploreCounter:Integer; bestRate:Double;i,j,k:Integer; curRate:Double; succ:Boolean;
begin
      if MaxDepth= 0 then Exit;
      PlayOutPosition(APlayOutsPerExplore,ANode);
      FPUCT.GetCurrentBest(ANode,mX,mY);
      bestRate:=FPUCT.WinrateAt(ANode,mX,MY);
      ExploreCounter:=1;
      child:=FPUCT.AddExploreNode(ANode,mx,mY,succ);
      ExploreNode(child,MaxDepth-1,APlayOutsPerExplore,MaxExploreWidth);
  while true do
  begin
            i:=random(BOARD_SIZE)+1;
            j:=random(BOARD_SIZE)+1;
            if FPUCT.IsValid(i,j,ANode)then
            begin
                if bestRate <>0 then curRate:=FPUCT.WinrateAt(ANode,i,j)/bestRate else curRate:= 0;
               // if ((curRate>0.9 )and(curRate<1.1))   //if the difference to best move is small enough
                 //  then
                begin
                  if ExploreCounter<=MaxExploreWidth then
                  begin

                  child:=FPUCT.AddExploreNode(ANode,i,j,succ);
                  Inc(ExploreCounter);

                    ExploreNode(child,MaxDepth-1,APlayOutsPerExplore,MaxExploreWidth);

                  end else Exit;
                end;
            end;
        end;




end;
procedure TUCTThread.PlayOutPosition(APlayOuts:Integer;ANode:PTreeNode);
var NodeBoard,SimBoardXY,SimBoard:TBoard; w,b:Integer;i,x,y:Integer;score:Double;k:integer; lAMAF:TAMAFList;
begin
  //-------CRITICAL-------------
  NodeBoard:=FPUCT.GetNodeBoard(ANode);
  //-------END CRITICAL------------
  for x:= 1 to BOARD_SIZE do
  begin
    for y := 1 to BOARD_SIZE do
    begin
            if FPUCT.IsValid(x,y,ANode) then
            begin
              Move(NodeBoard,SimBoardXY,SizeOf(TBoard));
              b:=0;w:=0;
              for i := 1 to APlayOuts do
              begin
                if FIsKilled then Exit;
                Move(SimBoardXY,SimBoard,SizeOf(TBoard));
                if SingleMonteCarloWin(@SimBoard,score,lAMAF) = 1 then inc(w) else inc(b);
              end;
              //------CRITICAL------------
              FPUCT.AddPlayOutsToNode(ANode,x,y,w,b,false,lAMAF);
              //----END CRITICAL------------
            end;
    end;
  end;

end;
constructor TUCTTHread.Create(AUCT:PUCT);
begin
  inherited Create(False);
  FPUCT:=AUCT;
end;

procedure TUCTThread.Execute;
var Root:PTreeNode; i:Integer;
begin
  { Thread-Code hier einfügen }
  Root:=FPUCT.RootNode;
 // PlayOutPosition(10,Root);
  while True do
  begin
    if FIsKilled then Exit;
   { ExploreNode(Root,5,1,0);
    i:=i+1;
    if i>10000000 then
    begin
      Exit;
    end; }
 //   ExploreAll(Root);
  //  for i := 1 to 100 do
    begin
     if FPUCT.MaxMemReached then
     begin
      // ExploreAll(Root);
     end;
     for i := 1 to 1 do //ceil(900 div (BOARD_SIZE))do  //bigger boards have no time for exploration
       Explore(Root);

     // Explore(Root);
      Expand(Root);
    end;
  end;

end;

end.
