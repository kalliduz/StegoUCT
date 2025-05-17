
unit GtpWrapperThread;
// {$APPTYPE CONSOLE}
interface

uses
  Classes,DataTypes,
  {$IFDEF FPC}
  StdCtrls,
  {$ELSE}
  Windows, VCL.StdCtrls,
  {$ENDIF}
  SysUtils,GameControl;
 procedure HandleCommand(ACommand:TStringList);
 function ParseParams(Acommand:String):TStringList;
 function IsKnownCommand(ACommand:String):Boolean;
 function ColorToLetter(AColor:SmallInt):String;
 function LetterToColor(ALetter:String):SmallInt;
 function XYToLetter(X,Y:SmallInt):String;
 procedure StringToColorMove(AVertex:String;var X,Y,Color:SmallInt);
 procedure LetterToXY(ALetters:String; var X:SmallInt;var Y:SmallInt);
 procedure Writeln(Astring:String;ID:Integer);

  var GGameManager:TGameManager;
      gLiteral:String='abcdefghjklmnopqrstuvwxyz';
      log:String;
implementation

{ TGtpWrapperThread }

 procedure LetterToXY(ALetters:String; var X:SmallInt;var Y:SmallInt);
 var tmp:String;
 begin
  X:= Pos(ALetters[1],gLiteral);
  tmp:=ALetters;
  delete(tmp,1,1);
  Y:=strToInt(tmp);
 end;
 procedure Writeln(Astring:String;ID:Integer);
 var str:String;
 begin
    if ID<>-1 then  str:='='+(inttostr(ID))+' '+(AString)+#13#10 else
                    str:='= '+AString+#13#10;
    log:=log+'Answering:'+#13#10+str+#13#10
          +'---------------------------'+#13#10;
    System.WriteLn(str);
    Flush(Output);
 end;
 function LetterToColor(ALetter:String):SmallInt;
 begin
   if ((ALetter='b')or (Aletter='black')) then Result:=2 else Result:=1;

 end;
 procedure StringToColorMove(AVertex:String;var X,Y,Color:SmallInt);
 var tmp:String;
 begin
 { if (AVertex[1]='b')OR(A then Color:=2 else Color:=1;
  X:= Pos(AVertex[2],gLiteral)+1;
  tmp:=AVertex;
  delete(tmp,1,2);
  Y:=strToInt(tmp);    }

 end;
 function XYToLetter(X,Y:SmallInt):String;
 begin
  Result:=gLiteral[X]+inttostr(Y);
 end;
 function ColorToLetter(AColor:SmallInt):String;
 begin
   case AColor of
   1: Result:='w';
   2: Result:='b';
   end;
 end;
 function IsKnownCommand(ACommand:String):Boolean;
 var tmpInt:Integer;
 begin
   Result:=(Acommand='name')OR
           (Acommand='protocol_version')OR
           (ACommand='version')OR
           (ACommand='known_command')OR
           (Acommand='list_commands')OR
           (ACommand='quit')OR
           (ACommand='boardsize')OR
           (ACommand='clear_board')OR
           (ACommand='komi')OR
           (ACommand='play')OR
           (ACommand='genmove')OR
           (ACommand='time_left');
 end;
 function ParseParams(Acommand:String):TStringList;
 begin
   Result:=TStringList.Create;
   Result.Delimiter:=' ';
   Result.StrictDelimiter:=True;
   Result.DelimitedText:=LowerCase(ACommand);
 end;
 procedure HandleCommand(ACommand:TStringList);
 var tmpInt:Integer;Color,X,Y:SmallInt;ID:integer;
 begin
 if ACommand.Count=0 then Exit;
 log:=log+'----------------------'+#13#10+
          'Handling parsed list:'+#13#10+
      String(ACommand.GetText)+#13#10;
 //----ADMINISTRATIVE COMMANDS-------------------
   ID:=StrToIntDef(ACommand[0],-1);
   if ID<>-1 then ACommand.Delete(0);

  if ACommand[0] = 'name' then
  begin
    Writeln('Stegosaurus UCT',ID);
    Exit;
  end;
  if ACommand[0] = 'protocol_version' then
  begin
    Writeln('2',ID);
    Exit;
  end;
  if ACommand[0] = 'version' then
  begin
    Writeln('0.02 Pre-Alpha',ID);
    Exit;
  end;
  if ACommand[0] = 'list_commands' then
  begin
    Writeln('name'+#10+
            'protocol_version'+#10+
            'version'+#10+
            'list_commands'+#10+
            'known_command'+#10+
            'quit'+#10+
            'boardsize'+#10+
            'clear_board'+#10+
            'play'+#10+
            'komi'+#10+
            'genmove'+#10+
            'time_left',ID);
  end;
  if ACommand[0] = 'quit' then
  begin
    if Assigned(GGameManager) then GGameManager.Free;

    Writeln('',ID);
  end;
  if Acommand[0]='known_command' then
  begin
    if IsKnownCommand(Acommand[1]) then
      Writeln('true',ID) else
      Writeln('false',ID);
    Exit;
  end;

 //-----------------------------------------------------
 //------------BOARD_SETUP-----------------------------
  if Acommand[0]='boardsize' then
  begin
    tmpInt:=StrToInt(Acommand[1]);
    if tmpInt<>BOARD_SIZE then
      Writeln('unacceptable size',ID)else
      Writeln('',ID);
    Exit;
  end;

  if ACommand[0]='clear_board' then
  begin
    if not Assigned(GGameManager) then GGameManager:=TGameManager.Create;
    GGameManager.NewGame(1300000,1300000,10000,10,False,False);
      Writeln('',ID);
    Exit;
  end;
  if ACommand[0]='komi' then
  begin
    //komi handling
        Writeln('',ID);
  end;
  if ACommand[0]='play' then
  begin
    if not Assigned(GGameManager) then
    begin
      GGameManager:=TGameManager.Create;
      GGameManager.NewGame(1300000,1300000,10000,10,False,False);
    end;
    Color:=LetterToColor(ACommand[1]);
    if ACommand[2]='pass' then
    begin
      X:=0;
      Y:=0;
    end else
    begin
      LetterToXY(ACommand[2],x,y);
    end;
    if ACommand[2]='resign' then
    begin
      Writeln('',ID);
      Exit;
    end;

    GGameManager.PlaceStone(x,y,Color);
    Writeln('',ID);
    Exit;
  end;
  if ACommand[0]='genmove' then
  begin
    if not Assigned(GGameManager) then
    begin
      GGameManager:=TGameManager.Create;
      GGameManager.NewGame(1000000,1000000,10000,10,False,False);
    end;
    Color:=LetterToColor(ACommand[1]);
    GGameManager.ChangeThinkPerspectiveFor(Color); //only in case we thought for wrong color
    sleep(5000);
    if GGameManager.ShouldResign then
    begin
      Writeln('resign',ID);
      Exit;
    end;
    GGameManager.CMoveAfterMilliSec(22000);
    GGameManager.GetLastMove(x,y);

    if ((X=0) AND (Y=0)) then
        Writeln('pass',ID) else
          Writeln(XYToLetter(x,y),ID);
  end;
  if Acommand[0]='final_status_list' then
  begin
    Writeln('',ID);
    Exit;
  end;
  if Acommand[0]='time_left' then
  begin
    //kgs time management here
    Writeln('',ID);
  end;
 //---------------------------------------------------

 end;

end.
