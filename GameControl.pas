unit GameControl;

interface
uses DataTypes,UCTreeThread,UCTree,BoardControls,ExtCtrls,DateUtils,SysUtils;

type
TTimeSetting=record
  MainTime:Integer;
  ByoLength:Integer;
  ByoPeriods:Integer;
end;

TGameStatus = record
  TimeWhite,TimeBlack:TTimeSetting;
  MoveHistory:TMoveList;
  CompWhite,CompBlack:Boolean;
  LastMoveTime:TTime;
  TimeTicker:Int64;
end;

TGameOverEvent = procedure(const AScore:Double) of object;

TGameManager=class
  private
    FBoard:TBoard;
    FThinkThread:TUCTreeThread;

    FThinkTimer:TTimer;
    FGameStatus:TGameStatus;


    FDisplayRating:Boolean;
    FDisplayRatingOverlay:Boolean;
    FGTpMode:Boolean;
    FDynKomi:Double;

    FOnGameOver:TGameOverEvent;
    procedure OnThinkTimer(Sender:TObject);
    procedure StopThreads;
    procedure DestroyThreads;
    procedure CreateThreads;
    procedure StartThreads; //expects clean and closed threads
    procedure UseOldUCTAt(AX,AY:SmallInt);
    procedure NewUCT;
    procedure CalculateNewTime;  //only call with executed move;

  public
    constructor Create();
    destructor Destroy();
    procedure ComputerMoveNow;
    function MoveNow(X,Y:SmallInt):Boolean;
    procedure CMoveAfterMilliSec(AMilliSec:Integer);
    procedure ChangeThinkPerspectiveFor(AColor:SmallInt);
    procedure Pass;
    procedure NewGame(AMainTimeBlack,AMainTimeWhite,AByoTime,AByoPeriods:Integer;ACompWhite,ACompBlack:Boolean);
    procedure PlaceStone(X,Y:SmallInt;AColor:SmallInt);  //does not reset timing and can be any color at any place
    procedure GetLastMove(var X:SmallInt;var Y:SmallInt);
    function AquireTree:TUCTree;
    procedure ReleaseTree;
    function ShouldResign:Boolean;
    procedure Think;
    function GetGameInformation:TGameInformation;
    function GetBoard:PBoard;
    property OnGameOver:TGameOverEvent read FOnGameOver write FOnGameOver;
end;

implementation
function TGameManager.AquireTree:TUCTree;
begin
  Result:=FThinkThread.Tree;
  FThinkThread.Suspended:=True;
end;

procedure TGameManager.ReleaseTree;
begin
  FThinkThread.Suspended:=False;
end;

procedure TGameManager.DestroyThreads;
begin
  if not Assigned(FThinkThread) then
    Exit;
  FThinkThread.Terminate;
  FThinkThread.WaitFor;
  FThinkThread.Free;
  FThinkThread:=nil;
end;

procedure TGameManager.CreateThreads;
begin
  FThinkThread:=TUCTreeThread.Create(FBoard,FDynKomi);
end;

function TGameManager.ShouldResign:Boolean;
var wr:double;bx,by:SMallInt;
begin
  //FUCT.GetCurrentBest(FUCT.RootNode,bx,by);
  bx:= FThinkThread.BestX;
  by:= FThinkThread.BestY;
  wr:=FThinkThread.Winrate;
  Result:=False;
  if FBoard.PlayerOnTurn=1 then if wr< RESIGN_TRESHOLD then Result:=True;
  if FBoard.PlayerOnTurn=2 then if wr>(1-RESIGN_TRESHOLD) then Result:=True;
end;

destructor TGameManager.Destroy();
begin
  FThinkTimer.Free;
  DestroyThreads;
  inherited Destroy;
end;

function TGameManager.GetBoard: PBoard;
begin
    if Assigned(FThinkThread) then
    begin
      StopThreads;
      Result:=@FBoard;
      StartThreads;
    end;
end;

function TGameManager.GetGameInformation: TGameInformation;
begin
    if Assigned(FThinkThread) then
    begin
      StopThreads;
      Result.MemoryUsed:=0; //TODO:Implement
      Result.MaxMemory:=MAX_MEMORY;
      Result.NodeCount:=FThinkThread.NodeCount;
      Result.BestMoveX:=FThinkThread.BestX;
      Result.BestMoveY:=FThinkThread.BestY;
      Result.BestMoveWinrate:=FThinkThread.Winrate;
      Result.BestResponseX:=-1;
      Result.BestResponseY:=-1; //TODO Implement
      Result.PlayoutsXY:=FThinkThread.MovePlayouts;
      Result.PlayoutsXYAMAF:=FThinkThread.MovePlayoutsAMAF;
      Result.PlayoutsAll:=FThinkThread.AllPlayouts;
      Result.DynKomi:=FDynKomi;
      Result.ExpectedScore:=round(FThinkThread.ExpectedScore*100)/100;

      Result.BestResponseWinrate:=-1; //TODO Implement
      StartThreads;
    end;
end;

procedure TGameManager.GetLastMove(var X:SmallInt;var Y:SmallInt);
  begin
    X:=FBoard.LastMoveCoordX;
    Y:=FBoard.LastMoveCoordY;
    if FBoard.LastPlayerPassed then
    begin
      X:=0;
      Y:=0;
    end;
  end;
  procedure TGameManager.CMoveAfterMilliSec(AMilliSec:Integer);
  begin
    Sleep(AMilliSec);
    ComputerMoveNow;
  end;
  procedure TGameManager.ChangeThinkPerspectiveFor(AColor:SmallInt);
  begin
    if AColor<>FBoard.PlayerOnTurn then
    begin
      PlaceStone(0,0,1); //PassMove
    end;

  end;

  procedure TGameManager.PlaceStone(X,Y:SmallInt;AColor:SmallInt);
  begin
    DestroyThreads;
    ExecuteMove(X,Y,
                AColor,
                @FBoard,
                (X=0)AND(Y=0), //passmove criterium
                False
                );
    CalculateNewTime;
    CreateThreads;
  end;


  procedure TGameManager.Pass;
  begin
    MoveNow(0,0);
  end;
  procedure TGameManager.CalculateNewTime;
  var diff:Int64; periodsUsed:Integer;
  begin
    diff:=MilliSecondsBetween(FGameStatus.LastMoveTime,Now);
    if FBoard.PlayerOnTurn=1 then
    begin
      if diff<FGameStatus.TimeWhite.MainTime then  //normal time use
      begin
        FGameStatus.TimeWhite.MainTime:=FGameStatus.TimeWhite.MainTime-diff;
      end else //overtime calculation
      begin
        diff:=diff-FGameStatus.TimeWhite.MainTime;
        FGameStatus.TimeWhite.MainTime:=0;
        periodsUsed:=trunc(diff/FGameStatus.TimeWhite.ByoLength);//trunc because not finished period doesn't count
        FGameStatus.TimeWhite.ByoPeriods:=FGameStatus.TimeWhite.ByoPeriods-periodsUsed;
      end;
    end;
    if FBoard.PlayerOnTurn=2 then
    begin
      if diff<FGameStatus.TimeBlack.MainTime then  //normal time use
      begin
        FGameStatus.TimeBlack.MainTime:=FGameStatus.TimeBlack.MainTime-diff;
      end else //overtime calculation
      begin
        diff:=diff-FGameStatus.TimeBlack.MainTime;
        FGameStatus.TimeBlack.MainTime:=0;
        periodsUsed:=trunc(diff/FGameStatus.TimeBlack.ByoLength);//trunc because not finished period doesn't count
        FGameStatus.TimeBlack.ByoPeriods:=FGameStatus.TimeBlack.ByoPeriods-periodsUsed;
      end;
    end;
    FGameStatus.LastMoveTime:=Now;
  end;

function TGameManager.MoveNow(X,Y:SmallInt):Boolean;
  var l:SmallInt; Lx,Ly:Integer;
  begin

    if not Assigned(FThinkThread) then
      Exit;


    CalculateNewTime;
    StopThreads;
    StartThreads;
    DestroyThreads;
   if not ExecuteMove(X,Y,
                FBoard.PlayerOnTurn,
                @FBoard,
                (X=0)AND(Y=0), //passmove criterium
                False
                ) then
   Exit(False);
   if FBoard.Over then
   begin
     if Assigned(FOnGameOver) then
     begin
      FOnGameOver(CountScore(@FBoard));
     end;
     Exit;
   end;
    CalculateNewTime;
    CreateThreads;
  end;

  procedure TGameManager.ComputerMoveNow;
  var x,y:SmallInt;
  begin

    if not Assigned(FThinkThread) then Exit;

    //StopThreads;
    if FBoard.LastPlayerPassed then
    begin
      x:=0;
      y:=0;
    end
    else
    begin
      x:=FThinkThread.BestX;
      y:=FThinkThread.BestY;
    end;
    CalculateNewTime;
   {
    calculate new dynkomi
   }
   if USE_DYN_KOMI then
   begin
      if (FThinkThread.ExpectedScore>(BOARD_SIZE*BOARD_SIZE)/10) OR
         (FThinkThread.ExpectedScore<(-(BOARD_SIZE*BOARD_SIZE)/10))
      then
        FDynKomi:=FDynKomi-(FThinkThread.ExpectedScore/2);

   end;
    MoveNow(X,Y);
  end;
  procedure TGameManager.OnThinkTimer(Sender:TObject);
  begin
    inc(FGameStatus.TimeTicker);
  end;
  procedure TGameManager.NewUCT;
  begin
    if Assigned(FThinkThread) then FThinkThread.Destroy;
    FThinkThread:=TUCTreeThread.Create(FBoard);
  end;
  procedure TGameManager.UseOldUCTAt(AX,AY:SmallInt);
  begin
    raise Exception.Create('Not implemented anymore');
  end;

  procedure TGameManager.StartThreads;
  begin
        //TODO: Implement smarter way of pausing the threads ;) (suspend shouldn't be used)
     FThinkThread.Suspended:=false;
  end;

  procedure TGameManager.StopThreads;
  begin
      //TODO: Implement smarter way of pausing the threads ;) (suspend shouldn't be used)
    if Assigned(FThinkThread) then
      FThinkThread.Suspended:=True;
  end;



  procedure TGameManager.Think;
begin
  StartThreads;
end;

procedure TGameManager.NewGame(AMainTimeBlack,AMainTimeWhite,AByoTime,AByoPeriods:Integer;ACompWhite,ACompBlack:Boolean);
  begin
    DestroyThreads;

    ResetBoard(@FBoard);

    FGameStatus.TimeWhite.MainTime:=AMainTimeWhite;
    FGameStatus.TimeWhite.ByoLength:=AByoTime;
    FGameStatus.TimeWhite.ByoPeriods:=AByoPeriods;

    FGameStatus.TimeBlack.MainTime:=AMainTimeBlack;
    FGameStatus.TimeBlack.ByoLength:=AByoTime;
    FGameStatus.TimeBlack.ByoPeriods:=AByoPeriods;

    setlength(FGameStatus.MoveHistory,0);
    FGameStatus.CompWhite:=ACompWhite;
    FGameStatus.CompBlack:=ACompBlack;
    FGameStatus.LastMoveTime:=Now;
    CreateThreads;

  end;
  constructor TGameManager.Create();
  begin
    FGTPMode:=True;
    FDisplayRating:=True;
    FDisplayRatingOverlay:=False;
    FThinkThread:=nil;
    FThinkTimer:=TTimer.Create(nil);
    FThinkTimer.Interval:=10;
    FThinkTimer.OnTimer:=OnThinkTimer;

  end;


end.
