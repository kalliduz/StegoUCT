unit DataTypes;

interface
  uses
    VCL.Graphics,Classes;
  const

//////////////////////////////////
///
///      GENERAL CONSTANTS
///
/////////////////////////////////

    BOARD_SIZE=9;

    KOMI=6.5;

    //turn on for chinese rules
    ALLOW_SUICIDE = FALSE;

    USE_DYN_KOMI = TRUE;

    //if the adaptive winrate for computerplayer is lower, it will resign
    RESIGN_TRESHOLD = 0.15;

    MAX_MEMORY = 1473741824; //2GB

/////////////////////////////////
///
///       MCTS CONSTANTS
///
/////////////////////////////////

    //what is the maximum node depth of the playout tree
    MAX_TREE_DEPTH = 1024;

    //how many threads should be assigned to montecarlo playouts
    MC_MAX_THREADS=7;

    //how often do we want to rebuild a movelist? usually you want to have 1 here
    MC_MOVE_REFRESH_RATE=BOARD_SIZE;


    {
      minimum playouts for a node to be able to spawn subnodes
      higher value:
        - less memory consumption by nodes
        - less tree search overhead
        - better ply/sec

      lower value:
        - better exploitation of the tree
    }
    MC_MIN_NODE_PLAYOUT = 100;

    {
      this constant defines the number of MC playouts done at once
      higher value:
        - less threading overhead
        - better ply/sec
      lower value:
        - more nodes visited in given time
        - better chance of recognizing good moves
    }
    MC_PLAYOUT_CHUNK_SIZE = 10;

////////////////////////////////
///
///  UCT/AMAF/RAVE CONSTANTS
///
////////////////////////////////

    //theoretically sqrt(2), bigger values -> broader tree
    EXPLORATION_FACTOR=0.3;

     // amaf value for a node decreases linear until this node was played out X times
    ALPHA_AMAF_MINMOVES = 10000;








    HISTOGRAMM_RANGE=BOARD_SIZE*BOARD_SIZE -1 ;



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
    DynKomi:Double;

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
//    Moves: array [1..MAX_AMAF_MOVES] of TMove;
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
  TOccupation = record
    X,Y:Integer;
    Color:SmallInt;
  end;
  TOccupationList = array of TOccupation;

implementation

end.
