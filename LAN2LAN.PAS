program LAN2LAN;

uses Crt, Dos;

var
  File1    : text;
  File2    : text;
  Key      : char;
  Line1    : string;
  Line2    : string;
  Station  : integer;
  count    : integer;
  Temp2    : string;
  Row1     : integer;
  Row2     : integer;
  finished : boolean;
  Hour,
  Minute,
  Second,
  Sec100   : word;


function Exist(FileName : string) : boolean;
var
  InFile : text;
begin
  Assign(InFile, FileName);
  {$I-}
    Reset(InFile);
  {$I+}
    if IOResult <> 0 then
      Exist := FALSE
    else
    begin
      Exist := TRUE;
      Close(InFile);
    end;
end;


procedure ShowError;
var
  BLANK : char;
begin

Window(1,1,80,25);
  GotoXY(1,25);
  TextColor(lightred);
    Write('The other chat mode has been terminated by the other user.');
    Sound(1200);
      Delay(200);
    NoSound;
      Delay(4000);

  Window(1,3,80,25);
  TextColor(cyan);
  ClrScr;
    WriteLn('The chat session has been terminated.');
    WriteLn;
    WriteLn('Thank you for using the LAN2LAN communications software!');
    WriteLn('(c)Copyright 1994 by Nathan Thomas');
    WriteLn;
  TextColor(lightgray);
  Delay(3000);
    if ((Station = 1) and Exist('TALK1.FLE')) or ((Station = 2) and Exist('TALK2.FLE')) then
      Erase(File1);
    Halt(1);
end;


procedure SingleInput;
begin
  while (not KEYPRESSED) and (not finished) do
  begin
  finished := FALSE;

    Window(1,3,80,12);
    if (Length(Line1) < 80) then
      GotoXY(1+Length(Line1),Row1)
    else
      GotoXY(1+(Length(Line1)-80),Row1+1);

    if (((1+(Length(Line1)-80)+Row1) > 10)) then
      GotoXY(1,10);

  Delay(100);

  if ((Station = 1) and Exist('TALK2.FLE')) or ((Station = 2) and Exist('TALK1.FLE')) then
    begin
      Reset(File2);
        ReadLn(File2,Line2);
      Close(File2);
    end
  else
    ShowError;

    if Line2 <> Temp2 then
    begin
      Window(1,14,80,23);
        TextColor(red);
        GotoXY(1,Row2);
          WriteLn(Line2);
            Temp2 := Line2;

      if Length(Line2) > 80 then Row2 := Row2 + 2
                            else Row2 := Row2 + 1;

      if Length(Line2) > 160 then
        Row2 := Row2 + 2;

        if Row2 > 10 then
          Row2 := 10;
    end;

    GetTime(Hour, Minute, Second, Sec100);

    if (Second >= 0) and (Second <= 1) then
    begin
      if Hour > 12 then
        Hour := Hour - 12;
      Window(73,1,79,1);
      ClrScr;
      TextColor(cyan);
        Write(Hour,':',Minute);
    end;

  end;

    Key := ReadKey;

if Key = #27 then
begin
  finished := TRUE;
  Line1 := '';
end;

if Key <> #8 then
begin
    if Key <> #13 then
    begin
      Line1 := Line1 + Key;
      Window(1,3,80,12);
        GotoXY(1,Row1);
        TextColor(yellow);
          Write(Line1);
            if Key <> #27 then finished := FALSE;
    end
    else
    begin
      Rewrite(File1);
        Writeln(File1, Line1);
      Close(File1);
      Window(1,3,80,12);
        if (Length(Line1) < 80) then
          GotoXY(1+Length(Line1),Row1)
        else
          GotoXY(1+(Length(Line1)-80),Row1+1);
      WriteLn;

      if Length(Line1) > 80 then
        Row1 := Row1 + 2
      else
        Row1 := Row1 + 1;

      if Length(Line1) > 160 then
        Row1 := Row1 + 1;

        if Row1 > 10 then
          Row1 := 10;

      Line1 := '';

    end;
end
else
begin
  Line1 := Copy(Line1, 1, (Length(Line1)-1));
    Window(1,3,80,12);
      GotoXY(1,Row1);
      TextColor(yellow);
        Write(Line1,' ');
end;
end;



begin
TextColor(lightgray);
TextBackground(black);

  ClrScr;
  WriteLn;
  Write('* Initializing the LAN2LAN communications software, ',GetEnv('ID'),'.');
  if Exist('TALK1.FLE') then
    Station := 2
  else
    Station := 1;


  if Station = 1 then
  begin
    Assign(File1,'TALK1.FLE');
    Assign(File2,'TALK2.FLE');
  end
  else
  begin
    Assign(File1,'TALK2.FLE');
    Assign(File2,'TALK1.FLE');
      Rewrite(File2);
        Close(File2);
  end;

    Rewrite(File1);
      Close(File1);

  WriteLn;
  Write('* Waiting for connection on Station #',Station,' -- <ESC> to cancel.');

  repeat
    Delay(1000);
      if KEYPRESSED then
        if ReadKey = #27 then
        begin
          WriteLn;
          TextColor(cyan);
            WriteLn('The chat session has been terminated.');
            WriteLn;
            WriteLn('Thank you for using the LAN2LAN communications software!');
            WriteLn('(c)Copyright 1994 by Nathan Thomas');
            WriteLn;
              TextColor(lightgray);
              Delay(3000);
              if ((Station = 1) and Exist('TALK1.FLE')) or ((Station = 2) and Exist('TALK2.FLE')) then
                Erase(File1);
                  Halt(1);
      end;
  until ((Station = 1) and (Exist('TALK2.FLE'))) or ((Station = 2) and (Exist('TALK1.FLE')));

Row1 := 1;
Row2 := 1;
  ClrScr;
    TextColor(green);
  WriteLn('LAN2LAN * by Nathan Thomas');
  Write('* Local ');
  for count := 1 to 72 do
    Write('*');

  GotoXY(1,13);
  Write('* Remote ');
  for count := 1 to 71 do
    Write('*');

  GotoXY(1,24);
  for count := 1 to 80 do
    Write('*');

  GotoXY(1,25);
  Write('To quit, type <ESC>');

GetTime(Hour, Minute, Second, Sec100);
Window(73,1,79,1);
  ClrScr;
    TextColor(cyan);
    if Hour > 12 then
      Hour := Hour - 12;
    Write(Hour,':',Minute);

if Station = 1 then
begin
  TextColor(lightblue);
    Window(67,1,71,1);
      Write('HOST');
end;

Line1 := '';
Line2 := '';
Temp2 := '';

Window(1,3,80,12);

  repeat
    TextColor(yellow);
      SingleInput;
  until finished;

  Window(1,3,80,25);
  TextColor(cyan);
  ClrScr;
    WriteLn('The chat session has been terminated.');
    WriteLn;
    WriteLn('Thank you for using the LAN2LAN communications software!');
    WriteLn('(c)Copyright 1994 by Nathan Thomas');
    WriteLn;
  TextColor(lightgray);
    Delay(3000);
    if ((Station = 1) and Exist('TALK1.FLE')) or ((Station = 2) and Exist('TALK2.FLE')) then
      Erase(File1);
end.
