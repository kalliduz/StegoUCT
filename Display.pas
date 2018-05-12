unit Display;

interface
uses Classes,Windows, VCL.Graphics, DataTypes,VCL.ExtCtrls,SysUtils;
procedure PaintEmptyBoard(ADrawImage:TImage;ABoardSize:Integer);
function CalcStoneSize(ADrawImage:TImage;ABoardSize:Integer):Double;inline;
procedure PaintOccupation(ADrawImage:TImage;ABoardSize:Integer;ABoard:PBoard);
procedure PaintRatingOverlay(ADrawImage:TImage;ABoardSize:Integer;ARatingOverlay:PRatingTable;APaintWinrateInstead:Boolean);
procedure PaintTokenAtBoardCoord(ADrawImage:TImage;ABoardSize:Integer;ADrawToken:TDrawToken;AX,AY:SmallInt);
procedure PaintWinrateBar(ADrawImage:TImage;AWinrate:Double);
function PlayerToColor(APlayer:SmallInt):TColor;inline;
procedure DisplayToBoard(AX,AY:Integer;ADisplay:TImage;ABoardSize:Integer;var X:Integer;var Y:Integer); //only square displays
procedure DisplayGameInformation(AGameInformation:TGameInformation;ADisplay:TImage);
implementation




  function PlayerToColor(APlayer:SmallInt):TColor;
  begin
    Result:=cllime;
    if APlayer=1 then Result:=clWhite;
    if APlayer=2 then Result:=clblack;

  end;

 procedure DisplayGameInformation(AGameInformation:TGameInformation;ADisplay:TImage);
 var lText:String; r:TRect;
 begin
   ADisplay.Canvas.Brush.Color:=clMoneyGreen;
   ADisplay.Canvas.Pen.Color:=clBlack;
   ADisplay.Canvas.Font.Size:=10;
   r.Left:=1;
   r.Top:=1;
   R.Bottom:=ADisplay.Height;
   R.Right:=ADisplay.Width;
   ADisplay.Canvas.Rectangle(0,0,ADisplay.Width-1,ADisplay.Height-1);
   lText:=inttostr(AGameInformation.MemoryUsed div 1024 div 1024)+ 'MB of '+inttostr(AGameInformation.MaxMemory div 1024 div 1024)+' MB'+#13#10;
   lText:=lText+inttostr(AGameInformation.NodeCount)+' Nodes'+#13#10;
   lText:=lText+'Ply/Sec: '+Inttostr(AGameInformation.PlyPerSec)+#13#10;
   lText:=lText+'Move playouts: '+inttostr(AGameInformation.PlayoutsXY)+#13#10;
   lText:=lText+'Move AMAF playouts: '+inttostr(AGameInformation.PlayoutsXYAMAF)+#13#10;
   lText:=lText+'Playouts total: '+inttostr(AGameInformation.PlayoutsAll)+#13#10;
   lText:=lText+'DynKomi: '+floattostr(AGameInformation.DynKomi)+#13#10;
   lText:=lText+'Best sequence:'+#13#10
   +'['+inttostr(AGameInformation.BestMoveX)+', '+inttostr(AGameInformation.BestMoveY)+'] ('+floattostr(round(AGameInformation.BestMoveWinrate*100)/100)+' %)'+#13#10
   +'['+inttostr(AGameInformation.BestResponseX)+', '+inttostr(AGameInformation.BestResponseY)+'] ('+floattostr(round(AGameInformation.BestResponseWinrate*100)/100)+' %)'+#13#10;
   DrawText(ADisplay.Canvas.Handle,PChar(lText),length(lText),r,DT_NOPREFIX OR DT_WORDBREAK)

 end;
 procedure DisplayToBoard(AX,AY:Integer;ADisplay:TImage;ABoardSize:Integer;var X:Integer;var Y:Integer);
 var step,offset:double;
 begin
  step:=ADisplay.Width/ABoardSize;
  offset:=step/2;
  x:=round((Ax+offset)/step);
  y:=round((Ay+offset)/step);
 end;

 procedure PaintWinrateBar(ADrawImage:TImage;AWinrate:Double);
 var mid:integer;
 begin
  mid:=Round(ADrawImage.Width*AWinrate);
  ADrawImage.Canvas.Brush.Color:=clWhite;
  ADrawImage.Canvas.Pen.Color:=clBlack;
  ADrawImage.Canvas.Rectangle(0,0,mid,ADrawImage.Height);

  ADrawImage.Canvas.Brush.Color:=ClBlack;
  ADrawImage.Canvas.Rectangle(mid,0,ADrawImage.Width,ADrawImage.Height);

  ADrawImage.Canvas.Pen.Color:=clRed;
  ADrawImage.Canvas.MoveTo(ADrawImage.Width div 2, 0);
  ADrawImage.Canvas.LineTo(ADrawImage.Width div 2, ADrawImage.Height);
 end;
  procedure PaintTokenAtBoardCoord(ADrawImage:TImage;ABoardSize:Integer;ADrawToken:TDrawToken;AX,AY:SmallInt);
  var offset:Double;
      StoneSize:Double;
      TokenSize:Double;
      TopLeft:TPoint;
      BottomRight:TPoint;
  begin
    StoneSize:=CalcStoneSize(ADrawImage,ABoardSize);
    offSet:=StoneSize/2;
    TokenSize:=StoneSize*ADrawToken.RelativeSize;
    TopLeft.X:=round(((AX-1)*StoneSize-(TokenSize / 2) +offset));
    TopLeft.Y:=round(((AY-1)*StoneSize-(TokenSize / 2) +offset));
    BottomRight.X:=TopLeft.X+Round(TokenSize);
    BottomRight.Y:=TopLeft.Y+Round(TokenSize);
    ADrawImage.Canvas.Brush.Color:=ADrawToken.Color;
    case ADrawToken.DrawTokenType of
      dttBlackStone: ;
      dttWhiteStone: ;
      dttString: ;
      dttTriangle: ;
      dttSquare: ;
      dttCircle: ADrawImage.Canvas.Ellipse(topleft.X,topleft.Y,BottomRight.X,BottomRight.Y);
    end;
  end;





  procedure PaintRatingOverlay(ADrawImage:TImage;ABoardSize:Integer;ARatingOverlay:PRatingTable;APaintWinrateInstead:Boolean);
  var i,j:Integer;
      offSet:Double;
      StoneSize:Double;
      minEnds,maxEnds:Int64;
      minRate,maxRate:Double;
      curEnds,countEnds:Int64;
      clr:Integer;
      bestX,bestY:SmallInt;
      lTempToken:TDrawToken;
      wr:Double;
      ply:int64;
  begin
     StoneSize:=CalcStoneSize(ADrawImage,ABoardSize);
     offSet:=StoneSize/2;
     minEnds:=1000000000000;
     maxEnds:=0;
     minRate:=1;
     maxRate:=0;
     for i := 0 to (BOARD_SIZE-1) do
     begin
       for j := 0 to (BOARD_SIZE-1) do
       begin
         if ARatingOverlay.RatingAt[i+1,j+1].Valid then
         begin
         curEnds:=ARatingOverlay.RatingAt[i+1,j+1].WinsWhite+ARatingOverlay.RatingAt[i+1,j+1].WinsBlack;
         if curEnds>maxEnds then begin maxEnds:=curEnds;bestX:=i+1;bestY:=j+1; end;
         if curEnds<minEnds then begin minEnds:=curEnds;end;
            ply:=ARatingOverlay.RatingAt[i+1,j+1].WinsWhite+ARatingOverlay.RatingAt[i+1,j+1].WinsBlack;
            if ply=0 then  wr:=0.5 else wr:=ARatingOverlay.RatingAt[i+1,j+1].WinsWhite/ply;
            if wr>maxRate then maxRate:=wr;
            if wr<minRate then minRate:=wr;

         end;
       end;
     end;
     for i := 0 to (ABoardSize-1) do
     begin
       for j := 0 to (ABoardSize-1) do
       begin
         begin
          if ARatingOverlay.RatingAt[i+1,j+1].Valid then
          begin
            ADrawImage.Canvas.Pen.Color:=RGB(round(((ARatingOverlay.RatingAt[i+1,j+1].WinsWhite+ARatingOverlay.RatingAt[i+1,j+1].WinsBlack)-minEnds+1)/(maxEnds-minEnds+1)*255),0,0);
          end else
          begin
            ADrawImage.Canvas.Brush.Color:=RGB(0,0,255);
            ADrawImage.Canvas.Pen.Color:=RGB(0,0,255);
          end;
          if APaintWinrateInstead then
          begin
            if ARatingOverlay.RatingAt[i+1,j+1].Valid then
            begin
              ply:=ARatingOverlay.RatingAt[i+1,j+1].WinsWhite+ARatingOverlay.RatingAt[i+1,j+1].WinsBlack;
              if ply=0 then  wr:=0.5 else wr:=ARatingOverlay.RatingAt[i+1,j+1].WinsWhite/ply;
              if maxRate<>MinRate then wr:=(wr-Minrate)/(maxRate-minRate);
              ADrawImage.Canvas.Pen.Color:=rgb(round(255*wr),0,0);
            end;
          end;
          ADrawImage.Canvas.Brush.Color:=ADrawImage.Canvas.Pen.Color;
          ADrawImage.Canvas.Rectangle(Round(i*StoneSize-(StoneSize / 2)+offset),
                                      Round(j*StoneSize-(StoneSize / 2)+offset),
                                      Round(i*StoneSize+(StoneSize / 2)+offset),
                                      Round(j*StoneSize+(StoneSize / 2)+offset));
         end;
       end;
     end;
     lTempToken.RelativeSize:=0.5;
     lTempToken.Centered:=True;
     lTempToken.DrawTokenType:=dttCircle;
     lTempToken.Color:=clblue;
     PaintTokenAtBoardCoord(ADrawImage,ABoardSize,lTempToken,bestX,bestY);
  end;





  procedure PaintOccupation(ADrawImage:TImage;ABoardSize:Integer;ABoard:PBoard);
  var i,j:Integer;
      occ:SmallInt;
      offSet:Double;
      StoneSize:Double;
      lTempToken:TDrawToken;
  begin
    StoneSize:=CalcStoneSize(ADrawImage,ABoardSize);
    offSet:=StoneSize/2;
    for i := 0 to (ABoardSize-1) do
    begin
      for j := 0 to (ABoardSize-1) do
      begin
        occ:= ABoard.Occupation[i+1,j+1];
        if occ>0 then
        begin
          if occ = 1 then ADrawImage.Canvas.Brush.Color:=clWhite;
          if occ = 2 then ADrawImage.Canvas.Brush.Color:=clBlack;
          ADrawImage.Canvas.Ellipse(Round(i*StoneSize-(StoneSize / 2)+offset),
                                    Round(j*StoneSize-(StoneSize / 2)+offset),
                                    Round(i*StoneSize+(StoneSize / 2)+offset),
                                    Round(j*StoneSize+(StoneSize / 2)+offset));
        end;
      end;
    end;
     lTempToken.RelativeSize:=0.5;
     lTempToken.Centered:=True;
     lTempToken.DrawTokenType:=dttCircle;
     lTempToken.Color:=clgreen;
     PaintTokenAtBoardCoord(ADrawImage,ABoardSize,lTempToken,ABoard.LastMoveCoordX,ABoard.LastMoveCoordY);
  end;


  function CalcStoneSize(ADrawImage:TImage;ABoardSize:Integer):Double;
  begin
    Result:=ADrawImage.Width / ABoardSize;
  end;






  procedure PaintEmptyBoard(ADrawImage:TImage;ABoardSize:Integer);
  var StoneSize:Double;
      offset:Double;
      i,j:Integer;
  begin
   StoneSize:=CalcStoneSize(ADrawImage,ABoardSize);
   offset:=StoneSize / 2;
   ADrawImage.Canvas.Brush.Color:=clYellow;
   ADrawImage.Canvas.Pen.Color:=clYellow;
   ADrawImage.Canvas.Rectangle(0,0,ADrawImage.Width,ADrawImage.Height);
   ADrawImage.Canvas.Pen.Color:=clblack;
   for i := 0 to (ABoardSize-1) do
   begin
     ADrawImage.Canvas.MoveTo(Round(i*StoneSize+offset),round(offset));
     ADrawImage.Canvas.LineTo(Round(i*StoneSize+offset),round(ADrawImage.Height-offset));
     ADrawImage.Canvas.MoveTo(Round(offset),Round(i*StoneSize+offset));
     ADrawImage.Canvas.LineTo(round(ADrawImage.Width-offset),Round(i*StoneSize+offset));
   end;
    for i := 0 to (ABoardSize-1) do
    begin
      for j := 0 to (ABoardSize-1) do
      begin

        if
        ((i = ABoardSize DIV 2) AND (j = ABoardSize DIV 2)) OR
        ((i+1=4)                AND (j+1=4))                OR
        ((i+1=ABoardSize-3)     AND (j+1=4))                OR
        ((i+1=ABoardSize-3)     AND (j+1=ABoardSize-3))     OR
        ((i+1=4)                AND (j+1=ABoardSize-3))     OR             //Calculating the 4/4 points
        ((i+1=4)                AND (j = ABoardSize DIV 2)) OR
        ((i=ABoardSize DIV 2)   AND (j+1 = 4))              OR
        ((i=ABoardSize DIV 2)   AND (j+1 = ABoardSize-3))   OR
        ((i+1=ABoardSize-3)     AND (j = ABoardSize DIV 2))
        then
        begin
          ADrawImage.Canvas.Brush.Color:=clBlack;
          ADrawImage.Canvas.Ellipse(Round(i*StoneSize-(StoneSize / 8)+offset),
                                    Round(j*StoneSize-(StoneSize / 8)+offset),
                                    Round(i*StoneSize+(StoneSize / 8)+offset),
                                    Round(j*StoneSize+(StoneSize / 8)+offset));
        end;
      end;
    end;
  end;

end.
