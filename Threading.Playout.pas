unit Threading.Playout;

interface
uses
  System.Classes,MonteCarlo,UCTree,Tree,DataTypes,BoardControls;

type
  TOnThreadFinishedCallBack = procedure(ACaller:TTreeNode<TUCTNode>;APlayouts:Integer;AWhiteWins:Integer) of object;
  TMCPlayoutThread = class(TThread)
  private
    FIsRunning:Boolean;
    FWhiteWins:Integer;
    FBoard:PBoard;
    FPlayOuts:Integer;
    FCallingThread:TThread;
    FOnFinish:TOnThreadFinishedCallBack;
    FNode:TTreeNode<TUCTNode>;
    procedure SynchResults;
    procedure DoJob;
  protected
    procedure Execute;override;
  public
    property IsRunning:Boolean read FIsRunning;
    function AddJob(ABoard:PBoard;APlayouts:Integer;ACallingNode:TTreeNode<TUCTNode>;ACallBack:TOnThreadFinishedCallBack;ACallingThread:TThread):Boolean;
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
    LWinner:= PlayoutPosition (@LSimBoard,LScore);

    if  LWinner = 1
    then
      Inc(FWhiteWins);

  end;
  SynchResults;
 // Synchronize(FCallingThread,SynchResults);
end;

function TMCPlayoutThread.AddJob(ABoard:PBoard;APlayouts:Integer;ACallingNode:TTreeNode<TUCTNode>;ACallBack:TOnThreadFinishedCallBack;ACallingThread:TThread):Boolean;
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
  FOnFinish:=ACallBack;
  FCallingThread:=ACallingThread;
  FIsRunning:=True;

end;

procedure TMCPlayoutThread.SynchResults;
begin
  FOnFinish(FNode,FPlayOuts,FWhiteWins);
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
