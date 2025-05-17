unit Threading.Playout;

interface
uses
  {$IFDEF FPC}
  Classes,
  {$ELSE}
  System.Classes,
  {$ENDIF}
  MonteCarlo,UCTree,Tree,DataTypes,BoardControls;

type
  TOnThreadFinishedCallBack = procedure(ACaller:TTreeNode<TUCTNode>;APlayouts:Integer;AWhiteWins:Integer;AScoreSum:Double) of object;
  TMCPlayoutThread = class(TThread)
  private
    FIsRunning:Boolean;
    FWhiteWins:Integer;
    FBoard:PBoard;
    FPlayOuts:Integer;
    FScoreSum:Double;
    FDynKomi:Double;
    FCallingThread:TThread;
    FOnFinish:TOnThreadFinishedCallBack;
    FNode:TTreeNode<TUCTNode>;
    procedure SynchResults;
    procedure DoJob;
  protected
    procedure Execute;override;
  public
    property IsRunning:Boolean read FIsRunning;
    function AddJob(ABoard:PBoard;APlayouts:Integer;ACallingNode:TTreeNode<TUCTNode>;ACallBack:TOnThreadFinishedCallBack;ACallingThread:TThread;const ADynKomi:Double =0):Boolean;
    constructor Create;
    end;



implementation

procedure TMCPlayoutThread.DoJob;
var
  i:Integer;
  LSimBoard:TBoard;
  LScore:Double;
  LWinner:SmallInt;
begin

  for i := 0 to FPlayOuts-1 do
  begin

    Move(FBoard^,LSimBoard,SizeOf(TBoard));
    LWinner:= PlayoutPosition (@LSimBoard,LScore,FDynKomi);
    FScoreSum:=FScoreSum+LScore;

    if  LWinner = 1
    then
      Inc(FWhiteWins);

  end;
  SynchResults;
 // Synchronize(FCallingThread,SynchResults);
end;

function TMCPlayoutThread.AddJob(ABoard:PBoard;APlayouts:Integer;ACallingNode:TTreeNode<TUCTNode>;ACallBack:TOnThreadFinishedCallBack;ACallingThread:TThread;const ADynKomi:Double):Boolean;
begin
  if FIsRunning then
  begin
    Exit;
  end;
  FWhiteWins:=0;
  New(FBoard);
  Move(ABoard^,FBoard^,SizeOf(TBoard));
  FPlayOuts:=APlayouts;
  FNode:=ACallingNode;
  FDynKomi:=ADynKomi;
  FOnFinish:=ACallBack;
  FScoreSum:=0;
  FCallingThread:=ACallingThread;
  FIsRunning:=True;

end;

procedure TMCPlayoutThread.SynchResults;
begin
  FOnFinish(FNode,FPlayOuts,FWhiteWins,FScoreSum);
  Dispose(FBoard);
  FBoard:=nil;
end;

constructor TMCPlayoutThread.Create;
begin
  inherited Create(False);
end;

procedure TMCPlayoutThread.Execute;
begin
  NameThreadForDebugging('MCWorker');
  while not Terminated do
  begin
    if FIsRunning then
    begin
      DoJob;
      FIsRunning:=False;
    end;
  end;
end;
end.
