unit DataTypes;

interface
  uses Graphics,Classes;
  const
    BOARD_SIZE=9;
    SIMULATIONS=3000;
    UCT_BESTMOVE = 1;
//    ALPHA_AMAF_FACTOR = 0.1;
    ALPHA_AMAF_MINMOVES = 2000;
    UCT_NORMALMOVE = (BOARD_SIZE*BOARD_SIZE);
   // MC_TRUNK=BOARD_SIZE*BOARD_SIZE*1000000;
    DYN_KOMI=6.5;
    MC_MOVE_REFRESH_RATE=BOARD_SIZE;
    MC_MAX_THREADS=5;
    ALLOW_SUICIDE = FALSE;
    EXPLORATION_FACTOR_START=0.5; //should be sqrt(2), bigger values -> broader tree
    EXPLORATION_FACTOR_END=0.2;
    EXPLORATION_FACTOR_STEP=0.0;

    AMAF_WIN_REDUCTION_FACTOR=1.41;
    RESIGN_TRESHOLD = 0.15;
    MAX_AMAF_MOVES = BOARD_SIZE*BOARD_SIZE;
    CAPTURE_EXPLORE_FACTOR=1;
    NEIGHBOUR_HEURISTIC_FACTOR=1;
    HISTOGRAMM_RANGE=BOARD_SIZE*BOARD_SIZE -1 ;
    BOARDER_HEURISTIC_FACTOR =1;
    TENUKI_PREVENT_HEURISTIC_FACTOR=1;

    MAX_MEMORY = 1473741824;

    MAX_PRUNE_TREE_PRESERVE=10; //minimum variations preservered in every node of the tree
    MIN_DEPTH_FORCED_PRUNE=5; //specifies the minimum depth at which the tree is forcefully cut if
                              //memory limits are exceeding

    MAX_INPUT_BUFFER_SIZE=1024;
type

  TBoard = record
    LastMoveCatchedExactlyOne:Boolean;
    LastCatchX,LastCatchY:SmallInt;
    LastMoveCoordX:SmallInt;
    LastMoveCoordY:SmallInt;
    RemovedStones:array [1..2] of SmallInt;
    PlayerOnTurn:SmallInt;
    LastPlayerPassed:Boolean;
    Over:Boolean;
    MoveNr:Integer;
    Occupation: array[0..BOARD_SIZE+1,0..BOARD_SIZE+1] of SmallInt; //0 = empty, 1 = white, 2 = black;
  end;
  TGameInformation = record
    MemoryUsed:Int64;
    MaxMemory:Int64;
    PlyPerSec:Int64;
    NodeCount:Int64;
    PlayoutsXY:Int64;
    PlayoutsXYAMAF:Int64;
    PlayoutsAll:Int64;
    BestMoveX,BestMoveY:SmallInt;
    BestMoveWinrate:Double;
    BestResponseX,BestResponseY:SmallInt;
    BestResponseWinrate:Double;

  end;
  THistogrammTable = array [-HISTOGRAMM_RANGE..HISTOGRAMM_RANGE] of Int64;
  PHistogrammTable = ^THistogrammTable;
  TRating = record
    Valid:Boolean;
    WinsWhite:Int64;
    WinsBlack:Int64;
    MovesDone:Int64;
  end;
  TMove=record
    Color:SmallInt;
    X,Y:SmallInt;
  end;
  TAMAFList = record
    Moves: array [1..MAX_AMAF_MOVES] of TMove;
    MoveCount:SmallInt;
  end;
  PRatingTable = ^TRatingTable;
  TRatingTable = record
    RatingAt : array[0..BOARD_SIZE,0..BOARD_SIZE] of TRating;     //board_size+1 --> pass move
    RatingPass:TRating;
  end;
  PBoard = ^TBoard;
    TMoveList= array of array [1..2] of SmallInt;
    PMoveList = ^TMoveList;
    TMarkList = array[0..(BOARD_SIZE*BOARD_SIZE)] of array[1..2] of SmallInt;
    PMarkList = ^TMarkList;
  TDrawTokenType = (dttBlackStone,dttWhiteStone,dttString,dttTriangle,dttSquare,dttCircle);
  TDrawToken = record
    RelativeSize:Double; //0..1
    Centered:Boolean;
    DrawTokenType:TDrawTokenType;
    Color:TColor;
    PrintData:String; //optional for dttString
  end;
  TLocalValue = record
    NumberNeighboursOwnColor:Byte;
    SelfOwnColor:Boolean;
  end;


implementation

end.
