unit GameControl;

interface
uses DataTypes,Dialogs,UCT,UCTThread,BoardControls,Display,ExtCtrls,DateUtils,SysUtils;

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

TGameManager=class
  private
    FBoard:TBoard;
    FUCT:TUct;
    FThinkThreads:array[0..MC_MAX_THREADS-1]of TUCTThread;

    FDisplayTimer:TTimer;
    FThinkTimer:TTimer;
    FGameStatus:TGameStatus;

    FAssignedMainDisplay:TImage;
    FAssignedWinRateDisplay:TImage;
    FAssignedInfoDisplay:TImage;

    FDisplayRating:Boolean;
    FGTpMode:Boolean;

    FLastPlayOuts:Int64;
    procedure OnDisplayTimer(Sender:TObject);
    procedure OnThinkTimer(Sender:TObject);
    procedure StopThreads;
    procedure StartThreads; //expects clean and closed threads
    procedure UseOldUCTAt(AX,AY:SmallInt);
    procedure NewUCT;
    procedure CalculateNewTime;  //only call with executed move;

  public
    constructor Create();
    destructor Destroy();
    procedure ComputerMoveNow;
    procedure MoveNow(X,Y:SmallInt);
    procedure CMoveAfterMilliSec(AMilliSec:Integer);
    procedure DisplayClicked(X,Y:Integer);
    procedure ChangeThinkPerspectiveFor(AColor:SmallInt);
    procedure Pass;
    procedure NewGame(AMainTimeBlack,AMainTimeWhite,AByoTime,AByoPeriods:Integer;ACompWhite,ACompBlack:Boolean);
    procedure SetMainDisplay(ADisplay:TImage);
    procedure SetWinrateDisplay(ADisplay:TImage);
    procedure SetInfoDisplay(ADisplay:TImage);
    procedure PlaceStone(X,Y:SmallInt;AColor:SmallInt);  //does not reset timing and can be any color at any place
    procedure GetLastMove(var X:SmallInt;var Y:SmallInt);
    function ShouldResign:Boolean;
end;

implementation
  procedure TGameManager.SetInfoDisplay(ADisplay:TImage);
  begin
    FAssignedInfoDisplay:=ADisplay;
  end;
  function TGameManager.ShouldResign:Boolean;
  var wr:double;bx,by:SMallInt;
  begin
    FUCT.GetCurrentBest(FUCT.RootNode,bx,by);
    wr:=FUCT.WinrateAt(FUCT.RootNode,bx,by);
    Result:=False;
    if FBoard.PlayerOnTurn=1 then if wr< RESIGN_TRESHOLD then Result:=True;
    if FBoard.PlayerOnTurn=2 then if wr>(1-RESIGN_TRESHOLD) then Result:=True;
  end;
  destructor TGameManager.Destroy();
  begin
    FDisplayTimer.Free;
    FThinkTimer.Free;
    StopThreads;
    FUCT.Free;
    inherited Destroy;
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
  var dummy1,dummy2:TMoveList;
  begin
    StopThreads;
    ExecuteMove(X,Y,
                AColor,
                @FBoard,
                (X=0)AND(Y=0), //passmove criterium
                False,
                dummy1,dummy2
                );
    CalculateNewTime;
    NewUCT;
    StartThreads;
  end;
  procedure TGameManager.DisplayClicked(X,Y:Integer);
  var lx,ly:Integer;
  begin
    DisplayToBoard(x,y,FAssignedMainDisplay,BOARD_SIZE,lx,ly);
    if IsValidMove(lx,ly,FBoard.PlayerOnTurn,@FBoard) then
      MoveNow(lx,ly);
   { if IsSelfAtari(lx,ly,ReverseColor(FBoard.PlayerOnTurn),@FBoard) then
    begin
      Showmessage('Self Atari');
    end;    }
  end;
  procedure TGameManager.SetWinrateDisplay(ADisplay:TImage);
  begin
    FAssignedWinRateDisplay:=ADisplay;
  end;
  procedure TGameManager.SetMainDisplay(ADisplay:TImage);
  begin
    FAssignedMainDisplay:=ADisplay;
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
  procedure TGameManager.MoveNow(X,Y:SmallInt);
  var dummy1,dummy2:TMoveList;
  begin
    StopThreads;
    ExecuteMove(X,Y,
                FBoard.PlayerOnTurn,
                @FBoard,
                (X=0)AND(Y=0), //passmove criterium
                False,
                dummy1,dummy2
                );
    CalculateNewTime;
    UseOldUCTAt(X,Y);
    StartThreads;
  end;
  procedure TGameManager.ComputerMoveNow;
  var x,y:SmallInt;dummy1,dummy2:TMoveList;
  begin

    if not Assigned(FUCT) then Exit;
    StopThreads;
    FUCT.GetMostPlayed(FUCT.RootNode,X,Y);
    if FBoard.LastPlayerPassed then
      ExecuteMove(X,Y,
                  FBoard.PlayerOnTurn,
                  @FBoard,
                  true, //passmove criterium
                  False,
                  dummy1,dummy2
                  )
    else
    ExecuteMove(X,Y,
                FBoard.PlayerOnTurn,
                @FBoard,
                (X=0)AND(Y=0), //passmove criterium
                False,
                dummy1,dummy2
                );
    CalculateNewTime;
    UseOldUCTAt(X,Y);
    StartThreads;
  end;
  procedure TGameManager.OnThinkTimer(Sender:TObject);
  begin
    inc(FGameStatus.TimeTicker);
  end;
  procedure TGameManager.NewUCT;
  begin
    if Assigned(FUCT) then FUCT.Destroy;
    FUCT:=TUCT.Create(FBoard);
  end;
  procedure TGameManager.UseOldUCTAt(AX,AY:SmallInt);
  var Child:PTreeNode;
  begin
  Child:=nil;
   if Assigned(FUCT) then
   begin
    if FUCT.GetChildAt(AX,AY,FUCT.RootNode,child) then
    FUCT.SetNewRoot(child) else
    begin //if child wasn't thought
      FUCT.Free;
      FUCT:=TUCT.Create(FBoard);
    end;
   end else FUCT:=TUCT.Create(FBoard);
  end;

  procedure TGameManager.StartThreads;
  var i:integer;
  begin
     for i := 0 to MC_MAX_THREADS-1 do FThinkThreads[i]:=TUCTThread.Create(@FUCT);
  end;

  procedure TGameManager.StopThreads;
  var i:integer;
  begin
    for i := 0 to MC_MAX_THREADS-1 do
    begin
      if Assigned(FThinkThreads[i]) then
      begin
            FThinkThreads[i].FreeOnTerminate:=false;
            FThinkThreads[i].KillFlag:=True;
            FThinkThreads[i].Free;
            FThinkThreads[i]:=nil;
      end;
    end;
  end;

  procedure TGameManager.OnDisplayTimer(Sender:TObject);
  var RatingTable:TRatingTable;X,Y:SmallInt; tmp:Int64; gameInfo:TGameInformation;  child:PTreeNode;
  begin
    //GENERATE GAME INFOS
    child:=nil;
    if Assigned(FUCT) then
    begin
      X:=0;Y:=0;
      tmp:=FUCT.GetPlayOutCount;
      gameInfo.PlyPerSec:=round((tmp-FLastPlayouts)*(1000/FDisplayTimer.Interval));
      FLastPlayOuts:=tmp;
      gameInfo.MemoryUsed:=FUCT.GetMemAllocSize;
      gameInfo.MaxMemory:=MAX_MEMORY;
      gameInfo.NodeCount:=FUCT.NodeCount;
      FUCT.GetMostPlayed(FUCT.RootNode,X,Y);
      gameInfo.BestMoveX:=X;
      gameInfo.BestMoveY:=Y;
      gameInfo.BestMoveWinrate:=FUCT.WinrateAt(FUCT.RootNode,X,Y);
      FUCT.GetChildAt(x,y,FUCT.RootNode,Child);
      FUCT.GetMostPlayed(Child,X,y);
      gameInfo.BestResponseX:=X;
      gameInfo.BestResponseY:=Y;

      gameInfo.BestResponseWinrate:=FUCT.WinrateAt(Child,x,y);

      if Assigned(FAssignedInfoDisplay) then
        DisplayGameInformation(gameInfo,FAssignedInfoDisplay);
    end;
    //-------------------
    if not Assigned(FAssignedMainDisplay) then Exit;
    PaintEmptyBoard(FAssignedMainDisplay,BOARD_SIZE);
    if FDisplayRating then if Assigned(FUCT) then if
      (((FBoard.PlayerOnTurn=1)AND FGameStatus.CompWhite)OR
      ((FBoard.PlayerOnTurn=2)AND FGameStatus.CompBlack))
    then

    begin
      RatingTable:=FUCT.GetRatingtable;
      PaintRatingOverlay(FAssignedMainDisplay,BOARD_SIZE,@RatingTable,False);
    end;
    PaintOccupation(FAssignedMainDisplay,BOARD_SIZE,@FBoard);
    if Assigned(FAssignedWinRateDisplay) then if Assigned(FUCT) then

    begin
     FUCT.GetMostPlayed(FUCT.RootNode,x,y);
     PaintWinrateBar(FAssignedWinRateDisplay,FUCT.WinrateAt(FUCT.RootNode,x,y));
    end;

  end;

  procedure TGameManager.NewGame(AMainTimeBlack,AMainTimeWhite,AByoTime,AByoPeriods:Integer;ACompWhite,ACompBlack:Boolean);
    var i:Integer;
  begin
    StopThreads;
    ResetBoard(@FBoard);
    if Assigned(FUCT) then FreeAndNil(FUCT);
    FUCT:=TUct.Create(FBoard);
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
    StartThreads;

  end;
  constructor TGameManager.Create();
  begin
    FGTPMode:=True;
    FDisplayRating:=True;
    FDisplayTimer:=TTimer.Create(nil);
    FDisplayTimer.Interval:=100;
    FDisplayTimer.OnTimer:=OnDisplayTimer;
    FThinkTimer:=TTimer.Create(nil);
    FThinkTimer.Interval:=10;
    FThinkTimer.OnTimer:=OnThinkTimer;

  end;


end.
