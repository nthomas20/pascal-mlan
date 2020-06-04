program MultiLAN2LAN;
{$V-}
{$I-}

uses Crt, objects, Dos, FastTTT5, MiscTTT5, NestTTT5, WinTTT5, ReadTTT5, StrnTTT5, KeyTTT5;

const
  VersionNum = '3.2';

  cmQuit         = 201;
  cmClearLocal   = 202;
  cmClearRemote  = 203;
  cmOneLine      = 204;
  cmOnePers      = 205;
  cmSound        = 206;
  cmProtectAlias = 208;

  cmAddConference      = 301;
  cmDelConference      = 302;
  cmStealth            = 303;
  cmKickOff            = 304;
  cmSearchConfs        = 305;
  cmChangeRemote       = 306;
  cmChangeLocal        = 307;
  cmSendMessage        = 308;
  cmClearRemotewindows = 309;

  Maximum_Number_Of_People_In_Conference = 40;
  Maximum_Number_Of_Confs                = 50;
  Maximum_Number_Of_Mail                 = 500;
  MaxMessages                            = 30;

  FullAccessPass = 'YDJSKKA';
  GODAccessPass  = 'HFXUJW';
  StealthPass    = 'SNLMY%WNIJW';  {NIGHT RIDER}

  RemoteColor   : integer = cyan;
  LocalColor    : integer = yellow;
  ClockColor    : integer = lightgray;

type
  ChatLineType = record
    Alias    : string[10];
    UStealth : boolean;
    Txt      : string[79];
  end;

  ConferenceRecord = record
    CName       : string[30];
    CDir        : string[62];
    CInfo       : string[62];
  end;

  MessageLineType = record
    From          : string[10];
    Destination   : string[10];
    TxtLine       : string[76];
    Opened        : boolean;
    Date          : string[6];
  end;

  AliasInfo = record
    Alias   : string[10];
    Pass    : string[20];
    FileLoc : word;
    LColor,
    RColor  : integer;
    SndOn   : boolean;
  end;

var
  CurrAlias      : AliasInfo;
  ChatFile       : TDosStream;
  ConfFile       : TDosStream;
  MessStream     : TDosStream;
  AlStream       : TDosStream;
  Key            : char;
  count          : integer;
  MyPos          : integer;
  Row1           : integer;
  Row2           : integer;
  finished       : boolean;
  Main_Menu,
  Conf_Menu,
  Change_Menu,
  Delete_Menu,
  Users_Menu,
  Color_Menu,
  Mail_Menu,
  ASCII_Menu     : Nest_Menu;
  fle            : boolean;
  currConference : integer;
  UID            : string;
  PrimeDir,
  ConferenceDataFile : string;
  Stealth            : boolean;
  FullAccess         : boolean;

  StartDirectory     : string;
  Snd                : boolean;
  MyLine             : ChatLineType;
  PLine              : ChatLineType;
  Temp               : array[0..Maximum_Number_Of_People_In_Conference] of ChatLineType;
  Conference         : array[0..Maximum_Number_Of_Confs] of ConferenceRecord;
  Messages           : array[0..MaxMessages] of MessageLineType;
  MessageNumber      : array[0..MaxMessages] of integer;
  ASCIIChar          : char;

  DelayTime          : integer;
  NewStartRainBow    : integer;


function Encode(txt : string) : string;
var
  count : integer;
  vtxt  : string;
begin
vtxt := txt;

  for count := 1 to Length(vtxt) do
    vtxt[count] := Chr(Ord(vtxt[count]) + 5);

  Encode := vtxt;
end;


procedure RainBow(txt : string);
var
  count   : integer;
  count1  : integer;
  currCol : integer;
begin
currCol := NewStartRainbow;
  for count := 1 to Length(txt) do
  begin
    TextColor(currCol);
      Write(txt[count]);

      Inc(currCol);
        if currCol > 15 then
          currCol := 1;
  end;

  Inc(NewStartRainbow);
    if NewStartRainbow > 15 then
      NewStartRainBow := 1;

WriteLn;
end;


procedure DoSaver;
begin
Window(1,1,80,25);
MkWin(1,1,80,25,black,black,0);
  repeat
    for count := 1 to 24 do
    begin
      gotoXY(1,count);
        Rainbow(PadLeft('',79,#254));
    end;
          delay(205);
  until keypressed;
RmWin;
end;


procedure PlaySound;
var
  count1   : integer;
  count2   : integer;
begin
  for count1 := 800 downto 400 do
  begin
    sound(count1);
      delay(1);
  end;
    delay(1);
  for count1 := 400 to 800 do
  begin
    sound(count1);
      delay(1);
  end;

  nosound;
end;

function Decode(pass : string) : string;
var
  count : integer;
  tPass : string;
begin
tPass := pass;

  for count := 1 to Length(tPass) do
    tPass[count] := Chr(Ord(tPass[count]) - 5);

  Decode := tPass;
end;


procedure ResetMessStream;
var
  MyError : integer;
begin
  repeat
    MessStream.Init('MESSAGES.SBN', stOpen);
      MyError := MessStream.Status;
      if MyError <> stOK then
        delay(DelayTime);
    MessStream.Reset;
  until (MyError = stOK);
end;


procedure ResetAlStream;
var
  MyError : integer;
begin
  repeat
    AlStream.Init('ALINFO.SBN', stOpen);
      MyError := AlStream.Status;
      if MyError <> stOK then
        delay(DelayTime);
    AlStream.Reset;
  until (MyError = stOK);
end;



procedure ResetChatFile;
var
  MyError : integer;
begin
  repeat
    ChatFile.Init('MCHAT.SBN', stOpen);
      MyError := ChatFile.Status;
      if MyError <> stOK then
        delay(DelayTime);
      if ChatFile.ErrorInfo in [1..10] then
      begin
        ChDir(PrimeDir);
          halt(2);
      end;
    ChatFile.Reset;
  until (MyError = stOK);
end;


procedure ResetConfFile;
var
  MyError : integer;
begin
  repeat
    ConfFile.Init(ConferenceDataFile, stOpen);
      MyError := ConfFile.Status;
      if MyError <> stOK then
        delay(50);
    ConfFile.Reset;
  until MyError = stOK;
end;


procedure Terminate;
begin
  Window(1,2,80,25);
  TextColor(lightgray);
  TextBackground(black);
  ClrScr;
    if Exist('MCHAT.SBN') then
    begin
      ResetChatFile;
        ChatFile.Seek((MyPos * SizeOf(ChatLineType)));
        with MyLine do
        begin
          Alias := '';
          Txt := '';
          UStealth := FALSE;
        end;

          ChatFile.Write(MyLine, SizeOf(MyLine));
      ChatFile.Done;
  end;
      CHDir(StartDirectory);

Delete_All_Topics(Main_Menu);
Delete_All_Topics(Conf_Menu);
Delete_All_Topics(Change_Menu);
Delete_All_Topics(Delete_Menu);
Delete_All_Topics(Users_Menu);

    OnCursor;
      Halt(1);
end;


procedure ShowTime(check : boolean);
begin
if check = TRUE then
  if Copy(Time, 7, 2) = '00' then
  begin
    Window(73,1,79,1);
      if ColorScreen then
      begin
        TextColor(ClockColor);
        TextBackground(blue);
      end
      else
      begin
        TextColor(darkgray);
        TextBackground(white);
      end;
        if Copy(Time, 10, 1) = 'p' then
          Write(Copy(Time, 1, 5), Copy(Time, 10, 1))
        else
          Write(' ' +Copy(Time, 1, 4), Copy(Time, 9, 1));

        TextBackground(black);
  end;

if check = FALSE then
begin
  Window(73,1,79,1);
      if ColorScreen then
      begin
        TextColor(ClockColor);
        TextBackground(blue);
      end
      else
      begin
        TextColor(darkgray);
        TextBackground(white);
      end;
        if Copy(Time, 10, 1) = 'p' then
          Write(Copy(Time, 1, 5), Copy(Time, 10, 1))
        else
          Write(' ' +Copy(Time, 1, 4), Copy(Time, 9, 1));
    TextBackground(black);
end;
end;


procedure LookForOtherInput;
var
  blank    : char;
  L,
  T        : string;
  GoAhead  : boolean;
  Lines    : array[0..Maximum_Number_Of_People_In_Conference] of ChatLineType;
begin
GoAhead := TRUE;

ResetChatFile;
  for count := 0 to Maximum_Number_Of_People_In_Conference do
  begin
    ChatFile.Seek(count * SizeOf(ChatLineType));
      ChatFile.Read(Lines[count], SizeOf(ChatLineType));
  end;
ChatFile.Done;

    for count := 0 to Maximum_Number_Of_People_In_Conference do
    begin
      if (Lines[count].Txt <> Temp[count].Txt) and (Lines[count].Alias <> '') then
      begin
{Clear Remote Screens}
        if Copy(Lines[count].Txt, 1, 4) = 'OR~:' then
        begin
          if upper(Copy(Lines[count].Txt, 5, Length(FullAccessPass))) = upper(FullAccessPass) then
          begin
            if not fullaccess then
            begin
              Window(1,14,80,23);
                Row2 := 1;
                ClrScr;

                GoAhead := FALSE;
            end
            else
            begin
              Lines[count].Txt := '  *** Cleared all remote windows *** ';
            end;
          end;
        end;

{Global One Liner}
        if Copy(Lines[count].Txt, 1, 4) = 'OL~:' then
        begin
          if Snd = TRUE then
          begin
            PlaySound;
          end;

          while keypressed do
            blank := ReadKey;

          if (Copy(Lines[count].Txt,5,61) <> '') and
             (Copy(Lines[count].Txt,5,61) <> #255) and
             (Lines[count].alias <> #255) then
            TempMessageBox(5,7,yellow,red,2,Lines[count].Alias + ':' + Copy(Lines[count].Txt,5,65))
          else
            if Lines[count].Alias = #255 then
              TempMessageBox(5,7,yellow,red,2,'GOD SAYS ' + Copy(Lines[count].Txt,5,65));

          GoAhead := FALSE;
        end;

{Personal One Liner}
        if Copy(Lines[count].Txt, 1, 4) = 'OP~:' then
        begin
          if Lower(Copy(Lines[count].Txt, 5, Length(UID) + 1)) = Lower(UID) + ':' then
          begin
            if Snd = TRUE then
            begin
              PlaySound;
            end;

            while keypressed do
              blank := ReadKey;

            if (Copy(Lines[count].Txt,5 + Length(UID) + 1,61) <> '') and
               (Copy(Lines[count].Txt,5 + Length(UID) + 1,61) <> #255) and
               (Lines[count].Alias <> #255) then
              TempMessageBox(5,7,yellow,red,2,Lines[count].Alias + ':' + Copy(Lines[count].Txt,6 + Length(UID),65))
            else
              if Lines[count].Alias = #255 then
                TempMessageBox(5,7,yellow,red,2,'GOD SAYS ' + Copy(Lines[count].Txt,6 + Length(UID),65))
          end;

          if FullAccess then
          begin
            OffCursor;
              Window(1,14,80,23);
                TextColor(white);
                  GotoXY(1,Row2);
                    if Lines[count].Alias <> '' then
                    begin
                      if Lines[count].Alias <> #255 then
                        WriteLn('*** PM from ' + Lines[count].Alias + '. ' +
                          Copy(Lines[count].Txt, 5, Length(Lines[count].Txt)))
                      else
                        if Lines[count].Alias = #255 then
                          WriteLn('*** PM from GOD. ' + Copy(Lines[count].Txt, 5, Length(Lines[count].Txt)));
                    end;
                      Temp[count] := Lines[count];
            OnCursor;

            if Length(Lines[count].Alias + Lines[count].Txt) + 15 > 80 then
              Row2 := Row2 + 2
            else
              Row2 := Row2 + 1;

              if Row2 > 10 then
                Row2 := 10;
          end;

          GoAhead := FALSE;
        end;

{Kick you off}
        if (Copy(Lines[count].Txt, 1, 4) = 'OF~:') then
          if not fullaccess or (Lines[count].Alias = #255) and (UID <> #255) then
          begin
            if (Copy(Lines[count].Txt, 5, Length(FullAccessPass) + 1) = FullAccessPass + ':') and
              (Lower(Copy(Lines[count].Txt, 6 + Length(FullAccessPass), Length(UID) + 1)) = Lower(UID) + ':') then
              begin
                if Snd = TRUE then
                begin
                  sound(50);
                    delay(150);
                 nosound;
                end;

                if Lines[count].Alias <> #255 then
                  TempMessageBox(24,7,white,blue,2,' <' + Lines[count].Alias + '> has kicked you off! ')
                else
                  TempMessageBox(24,7,white,blue,2,' GOD has kicked you off! ');

                Terminate;
             end;

            GoAhead := FALSE;
          end;

        if (Copy(Lines[count].Txt, 1, 4) = 'OF~:') and FullAccess then
        begin
          GoAhead := FALSE;
            OffCursor;
              Window(1,14,80,23);
                TextColor(white);
                  GotoXY(1,Row2);
                    if Lines[count].Alias <> '' then
                    begin
                      WriteLn('*** ' + Lines[count].Alias + ' removed ' +
                        Lower(Copy(Lines[count].Txt, 6 + Length(FullAccessPass), Length(Lines[count].Txt) -
                        (6+Length(FullAccessPass)))));
                    end;
                      Temp[count] := Lines[count];
            OnCursor;

              Inc(Row2);

              if Row2 > 10 then
                Row2 := 10;
        end;
      end;

      if FullAccess and GoAhead and (Lines[count].Alias <> '') and (Temp[count].Alias = '') and
        (Lines[count].UStealth) and (Lines[count].Alias <> #255) then
        Lines[count].Txt := '  *** Entered conference (Stealth Mode) *** ';

      if FullAccess and GoAhead and Lines[count].UStealth and not Temp[count].Ustealth and
        (Lines[count].Txt = '') then
        Lines[count].Txt := '  *** Activated Stealth Mode *** ';

      if FullAccess and GoAhead and not Lines[count].UStealth and Temp[count].Ustealth and
        (Lines[count].Txt = '') then
        Lines[count].Txt := '  *** Deactivated Stealth Mode *** ';

      if GoAhead and (Lines[count].Alias <> '') and
        (Lines[count].Txt <> Temp[count].Txt) and
        (Lines[count].Txt <> '') and (Lines[count].Txt <> #255) then
      begin
        OffCursor;
          Window(1,14,80,23);
            if count = MyPos then
              TextColor(LocalColor)
            else
              TextColor(RemoteColor);

              GotoXY(1,Row2);

              if Lines[count].Alias <> #255 then
                WriteLn('<', Lines[count].Alias, '> ', Lines[count].Txt)
              else
                WriteLn(Lines[count].txt);

                Temp[count].Txt := Lines[count].Txt;
        OnCursor;

        if Length(Lines[count].Alias + Lines[count].Txt) + 1 > 80 then
          Row2 := Row2 + 2
        else
          Row2 := Row2 + 1;

        if Row2 > 10 then
          Row2 := 10;
      end;

      Temp[count] := Lines[count];
    end;
end;

procedure DetectMail;
var
  mail     : boolean;
  count    : integer;
  TempMess : MessageLinetype;
  number   : integer;
begin
number := -1;
mail := FALSE;
ChDir(PrimeDir);

Window(1,1,80,25);
  for count := 0 to MaxMessages do
    MessageNumber[count] := -1;

  ResetMessStream;
    for count := 0 to Maximum_Number_Of_Mail do
    begin
      MessStream.Read(TempMess, SizeOf(MessageLineType));
        if lower(TempMess.Destination) = lower(UID) then
        begin
          if not TempMess.Opened then
            mail := TRUE;

          Inc(number);
            MessageNumber[number] := count;
        end
    end;
  MessStream.Done;

  if mail then
  begin
    if Snd then
      for count := 1 to 2 do
      begin
        sound(3000);
          delay(150);
        nosound;

        sound(2500);
          delay(150);
        nosound;
      end;
    TempMessageBox(29,9,blue,cyan,2,' You have messages. ');
  end;

ChDir(Conference[currConference].CDir);
TextBackground(black);
end;


procedure LoadMail;
var
  TempMess : MessageLineType;
  count    : integer;
begin
ChDir(PrimeDir);
  ResetMessStream;
    for count := 0 to MaxMessages do
    begin
      if MessageNumber[count] > -1 then
      begin
        MessStream.Seek(MessageNumber[count] * SizeOf(MessageLineType));
        MessStream.Read(TempMess, SizeOf(MessageLineType));
          if TempMess.Opened then
            Add_Topic(Mail_Menu, '*from: ' + lower(TempMess.From), TRUE, #0, count + 900, nil)
          else
            Add_Topic(Mail_Menu, ' from: ' + lower(TempMess.From), TRUE, #0, count + 900, nil)
      end
      else
        Add_Topic(Mail_Menu, '<empty>', FALSE, #0, 0, nil)

    end;
  MessStream.Done;

ChDir(PrimeDir);
ChDir(Conference[currConference].CDir);
end;


procedure LoadUsers(ReLoad : boolean);
var
  Blank : ChatLineType;
begin
  CHDir(PrimeDir);
  CHDir(Conference[currConference].CDir);

ResetChatFile;
  for count := 0 to Maximum_Number_Of_People_In_Conference do
  begin
    ChatFile.Seek(count * SizeOf(ChatLineType));
    ChatFile.Read(Blank, SizeOf(ChatLineType));
      Blank.Alias := Lower(Blank.Alias);

      if (Blank.Alias = '') or (Blank.Alias = #255) and (UID <> #255) then
        Blank.Alias := '<open>';

      if Blank.UStealth and not FullAccess and (count <> MyPos) then
        Blank.Alias := '<open>';

      if Blank.UStealth and not FullAccess and (count = MyPos) and (UID <> #255) then
        Blank.Alias := '*' + lower(UID);

      if Blank.UStealth and FullAccess and (Blank.Alias = #255) then
        Blank.Alias := '<GOD>';

      if Blank.UStealth and FullAccess and (Blank.Alias <> '<GOD>') and (Blank.Alias <> '<open>') then
        Blank.Alias := '*' + Blank.Alias;


          if not ReLoad then
            Add_Topic(Users_Menu, Int_to_Str(count) + ' ' + Blank.Alias, TRUE, #0, 0, nil)
          else
            Modify_Topic_Name(Users_Menu, (count + 1), Int_to_Str(count) + ' ' + Blank.Alias);
  end;
ChatFile.Done;
end;


procedure LoadConferences(ReLoad : boolean);
begin
  CHDir(PrimeDir);

ResetConfFile;
  for count := 0 to Maximum_Number_Of_Confs do
  begin
    ConfFile.Read(Conference[count], SizeOf(ConferenceRecord));
    if ReLoad = FALSE then
    begin
      Add_Topic(Change_Menu, Int_to_Str(count) + ' ' + Conference[count].CName, TRUE, #0, (count + 500), nil);
      Add_Topic(Delete_Menu, Int_to_Str(count) + ' ' + Conference[count].CName, TRUE, #0, (count + 600), nil);
    end
    else
    begin
      Modify_Topic_Name(Change_Menu, (count + 1), Int_to_Str(count) + ' ' + Conference[count].CName);
      Modify_Topic_Name(Delete_Menu, (count + 1), Int_to_Str(count) + ' ' + Conference[count].CName);
    end;
  end;
ConfFile.Done;
  CHDir(Conference[currConference].CDir);
end;


procedure ToggleSound;
begin
  Snd := not Snd;

  if ColorScreen then
  begin
    TextColor(white);
    TextBackground(blue);
  end
  else
  begin
    TextColor(black);
    TextBackground(white);
  end;

  Window(1,1,80,1);
    GotoXY(33,1);

  if Snd = TRUE then
    Write(#14)
  else
    Write(#32);

  TextBackground(black);
end;


procedure SingleInput;
var
  cter : longint;
begin
cter := 0;
  while (not KEYPRESSED) and (not finished) and (ASCIIChar = #0) do
  begin
  finished := FALSE;

    LookForOtherInput;

    ShowTime(TRUE);

    OffCursor;
      Window(1,3,80,12);
        GotoXY(1+Length(MyLine.Txt),Row1);
    OnCursor;

    Inc(cter);

    if cter = 10000 then
      DoSaver;

    if keypressed then
      cter := 0;

  end;

    if ASCIIChar = #0 then
      Key := ReadKey
    else
      Key := ASCIIChar;

    ASCIIChar := #0;

if Key = #0 then
begin
  Key := ReadKey;

  case Key of
    #45:                      {ALT-X}
    begin
      finished := TRUE;
      MyLine.Txt := '';
    end;
    #68:                      {F10}
    begin
      LoadConferences(TRUE);
      LoadUsers(TRUE);
      OffCursor;
        Show_Nest(Main_Menu);
      OnCursor;
        if fle = TRUE then
        begin
          Window(1,3,80,12);
            ClrScr;
              fle := FALSE;
                Row1 := 1;
                MyLine.Txt := '';
        end;
        if Row2 = 1 then
        begin
          Window(1,14,80,23);
            ClrScr;
        end;
    end;
    #38:                      {ALT-L}
    begin
      MyLine.Txt := '';
      Row1 := 1;
        Window(1,3,80,12);
          ClrScr;
    end;
    #19:                      {ALT-R}
    begin
      Row2 := 1;
        Window(1,14,80,23);
          ClrScr;
    end;
    #23:                      {ALT-I}
    begin
      OffCursor;
        Show_Nest(ASCII_Menu);
      OnCursor;
    end;
    #25:                      {ALT-P}
    begin
      MyLine.Txt := PLine.Txt;
        GotoXY(1,Row1);
          for count := 1 to 79 do
            Write(' ');
        gotoXY(1, Row1);
          TextColor(LocalColor);
            Write(MyLine.Txt);
    end;
    #83:                      {DEL}
    begin
      MyLine.Txt := '';
        GotoXY(1,Row1);
          for count := 1 to 79 do
            Write(' ');
    end;
    #31:                      {ALT-S}
      ToggleSound;
  end;
    Key := #0;
end;

if (Key > #31) or (Key = #13) then
begin
    if Key <> #13 then
    begin
      if Length(MyLine.Txt) < 79 then
        MyLine.Txt := MyLine.Txt + Key;

      OffCursor;
        Window(1,3,80,12);
          GotoXY(1,Row1);
          TextColor(LocalColor);
            Write(MyLine.Txt);
      OnCursor;

        if Key <> #27 then
          finished := FALSE;
    end
    else
    begin
      if MyLine.Txt = PLine.Txt then
        MyLine.Txt := MyLine.Txt + #255;

      PLine := MyLine;

      ResetChatFile;
        ChatFile.Seek(MyPos * SizeOf(ChatLineType));

        if FullAccess then
          MyLine.UStealth := TRUE
        else
          MyLine.UStealth := FALSE;

          ChatFile.Write(MyLine, SizeOf(ChatLineType));
      ChatFile.Done;
      Window(1,3,80,12);
        if (Length(MyLine.Txt) < 80) then
          GotoXY(1+Length(MyLine.Txt),Row1)
        else
          GotoXY(1+(Length(MyLine.Txt)-80),Row1+1);
      WriteLn;

      if Length(MyLine.Txt) > 80 then
        Row1 := Row1 + 2
      else
        Row1 := Row1 + 1;

      if Length(MyLine.Txt) > 160 then
        Row1 := Row1 + 1;

        if Row1 > 10 then
          Row1 := 10;

      MyLine.Txt := '';
    end;
end
else
  if Key = #8 then
  begin
    MyLine.Txt := Copy(MyLine.Txt, 1, (Length(MyLine.Txt)-1));
    OffCursor;
      Window(1,3,80,12);
        GotoXY(1,Row1);
        TextColor(LocalColor);
          Write(MyLine.Txt,' ');
    OnCursor;
  end;
end;


procedure MakeOneLine;
var
  OneLine  : string;
  count    : integer;
  PrevLine : string;
begin
OneLine := '';
PrevLine := MyLine.Txt;
  Window(1,1,80,25);
    MkWin(1,6,72,8,lightgray,lightgray,0);
      Read_String(1,7,61,'Message: ',2,OneLine);

if OneLine <> '' then
begin
    MyLine.Txt := 'OL~:' + OneLine;
      ResetChatFile;
        ChatFile.Seek(MyPos * SizeOf(ChatLineType));
          ChatFile.Write(MyLine, SizeOf(ChatLineType));
      ChatFile.Done;

  if Snd = TRUE then
  begin
    Sound(400);
      Delay(50);
    NoSound;
  end;
  TempMessageBox(30,11,yellow,red,2,' Message sent. ');
  MyLine.Txt := PrevLine;
end;
    RmWin;
  ShowTime(FALSE);
end;


procedure MakePersonLine;
var
  OneLine  : string;
  Dest     : string;
  count    : integer;
  PrevLine : string;
begin
OneLine := '';
Dest := '';
PrevLine := MyLine.Txt;

  Window(1,1,80,25);
    MkWin(1,6,72,8,black,black,0);
      Read_String(1,7,61,'Message: ',2,OneLine);

if OneLine <> '' then
begin
  MkWin(2,7,22,9,black,black,0);
    Read_String(2,8,10,'To whom: ',2,Dest);

    if Dest <> '' then
    begin
      MyLine.Txt := 'OP~:' + Dest + ':' + OneLine;
        ResetChatFile;
          ChatFile.Seek(MyPos * SizeOf(ChatLineType));
            ChatFile.Write(MyLine, SizeOf(ChatLineType));
        ChatFile.Done;

      if Snd = TRUE then
      begin
        Sound(400);
          Delay(50);
        NoSound;
      end;
        TempMessageBox(30,11,yellow,red,2,' Message sent. ');
      MyLine.Txt := PrevLine;
    end;
  RmWin;
end;
    RmWin;
  ShowTime(FALSE);
end;


procedure AddConf;
var
  openarea : integer;
  Blank    : ChatLineType;
begin
Window(1,1,80,25);
  openarea := -1;

    ResetConfFile;
      for count := 0 to Maximum_Number_Of_Confs do
      begin
        ConfFile.Read(Conference[count], SizeOf(ConferenceRecord));
          if (Conference[count].CName = '<none>') and (openarea = -1) then
            openarea := count;
      end;
    ConfFile.Done;

    if openarea = -1 then
    begin
      if Snd = TRUE then
      begin
        Sound(400);
          Delay(50);
        NoSound;
      end;

      TempMessageBox(20,11,yellow,red,2,' No open conference areas. ');
    end
    else
    begin
    RTTT.EraseDefault := TRUE;
      MkWin(3,6,51,8,black,black,0);
        Read_String(3,7,30,'Conference Name: ',2,Conference[openarea].CName);
      RmWin;
        if (Conference[openarea].CName <> '') and (Conference[openarea].CName <> '<none>') then
        begin
          Conference[openarea].CName := Lower(Conference[openarea].CName);

          RTTT.EraseDefault := FALSE;
          MkWin(1,6,80,8,black,black,0);
            Read_String_Upper(1,7,62,'Conference Dir: ',2,Conference[openarea].CDir);
          RmWin;
            if (Conference[openarea].CDir <> '') and (Conference[openarea].CDir <> PrimeDir) then
            begin
              Conference[openarea].CInfo := '';

              MkWin(4,6,78,8,black,black,0);
                Read_String(4,7,62,'Info text: ',2,Conference[openarea].CInfo);
              RmWin;


            CHDir(PrimeDir);
              MKDir(Conference[openarea].CDir);

                  if IOResult <> 0 then
                  begin
                    if Snd = TRUE then
                    begin
                      Sound(400);
                        Delay(50);
                      NoSound;
                    end;

                    TempMessageBox(25,11,yellow,red,2,' Error making directory. ');
                  end
                  else
                  begin
                      CHDir(PrimeDir);

                    ResetConfFile;
                      ConfFile.Seek(openarea * SizeOf(ConferenceRecord));
                        ConfFile.Write(Conference[openarea], SizeOf(ConferenceRecord));
                    ConfFile.Done;

                      CHDir(Conference[openarea].CDir);

                      ChatFile.Init('MCHAT.SBN', stCreate);
                        Blank.Alias := '';
                        Blank.Txt := '';
                        Blank.UStealth := FALSE;

                        for count := 0 to Maximum_Number_Of_People_In_Conference do
                          ChatFile.Write(Blank, SizeOf(ChatLineType));
                      ChatFile.Done;

                      CHDir(PrimeDir);
                      CHDir(Conference[currConference].CDir);

                      if Snd = TRUE then
                      begin
                        Sound(400);
                          Delay(50);
                        NoSound;
                      end;

                      TempMessageBox(28,11,white,blue,2,  ' Conference Added. ');
                  end;
        end;
    end;
  end;
    ShowTime(FALSE);
      CHDir(PrimeDir);
      CHDir(Conference[currConference].CDir);
end;


procedure ChangeConf(number : integer);
var
  count    : integer;
  PrevLine : string;
begin
PrevLine := MyLine.Txt;
number := number - 500;

if (Conference[number].CName <> '<none>') and (Conference[number].CDir <> '') and (currConference <> number) then
begin
  if currConference <> -1 then
  begin
    ResetChatFile;
      ChatFile.Seek(MyPos * SizeOf(ChatLineType));
        MyLine.Alias := '';
        MyLine.Txt := '';
        MyLine.UStealth := FALSE;
          ChatFile.Write(MyLine, SizeOf(ChatLineType));
      ChatFile.Done;
  end;

  MyPos := -1;
  currConference := number;
      CHDir(PrimeDir);
      CHDir(Conference[currConference].CDir);

  ResetChatFile;
    for count := 0 to Maximum_Number_Of_People_In_Conference do
    begin
      ChatFile.Read(Temp[count], SizeOf(ChatLineType));
        if (Temp[count].Alias = '') and (MyPos = -1) then
          MyPos := count;
    end;
    ChatFile.Done;

  if Stealth = FALSE then
    MyLine.Txt := '  *** Entered conference ***'
  else
    MyLine.Txt := '';

      Temp[MyPos].Txt := '';
    MyLine.Alias := UID;
    MyLine.UStealth := Stealth;

    ResetChatFile;
      ChatFile.Seek(MyPos * SizeOf(ChatLineType));
        ChatFile.Write(MyLine, SizeOf(ChatLineType));
    ChatFile.Done;

  MyLine.Txt := PrevLine;

if ColorScreen then
begin
  TextColor(white);
  TextBackground(blue);
end
else
begin
  TextColor(black);
  TextBackground(white);
end;
  Window(1,1,80,25);
    GotoXY(51, 1);
      Write(#16,'                   ',#17);
    GotoXY(52, 1);
      Write(Copy(Conference[currConference].CName, 1, 19));

    for count := 0 to Maximum_Number_Of_Confs do
      Modify_Topic_Active(Delete_Menu, count + 1, TRUE);

      Modify_Topic_Active(Delete_Menu, currConference + 1, FALSE);

  if Conference[currConference].CInfo <> '' then
    TempMessageBox(37 - (Length(Conference[currConference].CInfo) div 2),10,blue,cyan,3,
      'INFO: '+Conference[currConference].CInfo);
end;
TextBackground(black);
end;


procedure DeleteConf(number : integer);
var
  Blank  : ChatLineType;
  People : boolean;
  ChD    : char;
  CF     : file of ChatLineType;
begin
number := number - 600;
People := FALSE;

if (Conference[currConference].CName) <> 'none' then
begin
Assign(CF, 'MCHAT.SBN');

  CHDir(PrimeDir);
  CHDir(Conference[number].CDir);

  ResetChatFile;
    for count := 0 to Maximum_Number_Of_People_In_Conference do
      if not People then
      begin
        ChatFile.Seek(count * SizeOf(ChatLineType));
          ChatFile.Read(Blank, SizeOf(ChatLineType));
            if Blank.Alias <> '' then
              People := TRUE;
      end;
  ChatFile.Done;

    if People = FALSE then
      Erase(CF);


if People = FALSE then
begin
  CHDir(PrimeDir);

  RMDir(Conference[number].CDir);

Conference[number].CName := '<none>';
Conference[number].CDir := '';

  ResetConfFile;
    ConfFile.Seek(number * SizeOf(ConferenceRecord));
      ConfFile.Write(Conference[number], SizeOf(ConferenceRecord));
  ConfFile.Done;
end
else
begin
  TempMessageBoxCh(20,11,white,red,2,' There are still people in this conference! ', ChD);

  if ChD = 'O' then
  begin
      Erase(CF);
    CHDir(PrimeDir);

    RMDir(Conference[number].CDir);

      Conference[number].CName := '<none>';
      Conference[number].CDir := '';

    ResetConfFile;
      ConfFile.Seek(number * SizeOf(ConferenceRecord));
        ConfFile.Write(Conference[number], SizeOf(ConferenceRecord));
    ConfFile.Done;
  end;
end;
  CHDir(PrimeDir);
  CHDir(Conference[currConference].CDir);
end;
end;


procedure ToggleStealth;
var
  Password : string;
begin
  if ColorScreen then
  begin
    TextColor(white);
    TextBackground(blue);
  end
  else
  begin
    TextColor(black);
    TextBackground(white);
  end;

Password := '';
  if Stealth = FALSE then
  begin
    Window(1,1,80,25);
    MkWin(12,6,53,8,black,black,0);
      Read_Password(12,7,30,'Password: ',2,Password);
    RmWin;
      if Upper(Password) = Decode(StealthPass) then
      begin
        Stealth := TRUE;
          Window(1,1,80,1);
            GotoXY(34,1);
              Write('S');
      end;
  end
  else
  begin
    Stealth := FALSE;
      Window(1,1,80,1);
        GotoXY(34,1);
          Write(' ');
  end;

    TextBackground(black);

      ResetChatFile;
        ChatFile.Seek(MyPos * SizeOf(ChatLineType));
          MyLine.UStealth := Stealth;
            ChatFile.Write(MyLine, SizeOf(ChatLineType));
      ChatFile.Done;
end;


procedure KickOff;
var
  BadUser    : string;
  BadUserPos : integer;
  count      : integer;
  TempUser   : ChatLineType;
  PrevLine   : string;
begin
PrevLine := MyLine.Txt;
BadUser := '';

Window(1,1,80,25);
  MkWin(12,6,42,8,black,black,0);
    Read_String(12,7,10,'User to kick off: ',2,BadUser);
      BadUser := Lower(BadUser);

    if BadUser <> '' then
    begin
      MyLine.Txt := 'OF~:' + FullAccessPass + ':' + BadUser + ':';

        ResetChatFile;
          ChatFile.Seek(MyPos * SizeOf(ChatLineType));
            ChatFile.Write(MyLine, SizeOf(ChatLineType));

          BadUserPos := -1;
          for count := 0 to Maximum_Number_Of_People_In_Conference do
          begin
            ChatFile.Seek(count * SizeOf(ChatLineType));
              ChatFile.Read(TempUser, SizeOf(ChatLineType));

              if (Lower(TempUser.Alias) = Lower(BadUser)) then
              begin
                TempUser.Alias := '';
                TempUser.UStealth := FALSE;
                TempUser.Txt := '';

                  if count <> MyPos then
                  begin
                    ChatFile.Seek(count * SizeOf(ChatLineType));
                      ChatFile.Write(TempUser, SizeOf(ChatLineType));

                    Inc(BadUserPos);
                  end;
              end;
            end;
      ChatFile.Done;

      if Snd = TRUE then
      begin
        sound(400);
          delay(150);
        nosound;
      end;

      if BadUserPos <> -1 then
        TempMessageBox(33,11,white,red,2,' ' + Int_to_Str(BadUserPos+1) + ' User(s) Removed. ')
      else
        TempMessageBox(28,11,white,blue,2,' User not found. ');

      MyLine.Txt := '';
    end;
  RmWin;
MyLine.Txt := PrevLine;
end;


procedure SaveAliasInfo;
begin
ChDir(PrimeDir);
  CurrAlias.LColor := LocalColor;
  CurrAlias.RColor := RemoteColor;
  CurrAlias.SndOn  := Snd;
  CurrAlias.Pass   := lower(Encode(CurrAlias.Pass));

  if not Exist('ALINFO.SBN') then
  begin
    AlStream.Init('ALINFO.SBN', stCreate);
      CurrAlias.FileLoc := 0;
  end
  else
    ResetAlStream;

  if CurrAlias.FileLoc = 65535 then
    CurrAlias.FileLoc := (AlStream.GetSize div SizeOf(AliasInfo));

    AlStream.Seek(CurrAlias.FileLoc * SizeOf(AliasInfo));

  AlStream.Write(CurrAlias, SizeOf(AliasInfo));
  AlStream.Done;

ChDir(Conference[currConference].CDir);

  CurrAlias.Pass := lower(Decode(CurrAlias.Pass));
end;


function LookupAlias(alias : string; var AlInfo : AliasInfo) : boolean;
var
  count : integer;
  TempA : AliasInfo;
  dne   : boolean;
begin
dne := FALSE;
ChDir(PrimeDir);

  if Exist('ALINFO.SBN') then
  begin
    ResetAlStream;

    for count := 0 to AlStream.GetSize div SizeOf(AliasInfo) do
      if not dne then
      begin
        AlStream.Seek(count * SizeOf(AliasInfo));
        AlStream.Read(TempA, SizeOf(AliasInfo));

        if lower(TempA.Alias) = lower(Alias) then
        begin
          AlInfo := TempA;
          dne := TRUE;
        end;
      end;
    AlStream.Done;
  end;

if lower(AlInfo.Alias) = lower(Alias) then
begin
  AlInfo.Pass := lower(Decode(AlInfo.Pass));
  LookupAlias := TRUE;
end
else
  LookupAlias := FALSE;

ChDir(Conference[currConference].CDir);
end;


procedure SearchForAlias;
var
  SearchFor   : string;
  AreasFound  : array[0..Maximum_Number_Of_Confs] of boolean;
  count,
  count1      : integer;
  found       : boolean;
  TempInfo    : ChatLineType;
  FoundString : string;
begin
found := FALSE;
SearchFor := '';
  for count := 0 to Maximum_Number_Of_Confs do
    AreasFound[count] := FALSE;

Window(1,1,80,25);
  MkWin(8,5,39,7,black,black,0);
    Read_String(8,6,10,'Search For (alias): ',2,SearchFor);
  RmWin;
    SearchFor := Lower(SearchFor);

  if SearchFor <> '' then
  begin
    LoadConferences(TRUE);

    MkWin(1,25,80,25,black,lightgray,0);
      GotoXY(35,25);
      TextColor(black);
      TextBackground(lightgray);
        Write('Searching...');
      TextBackground(black);

      for count := 0 to Maximum_Number_Of_Confs do
        if Conference[count].CName <> '<none>' then
        begin
          ChDir(PrimeDir);
          ChDir(Conference[count].CDir);
            ResetChatFile;

              for count1 := 0 to Maximum_Number_Of_People_In_Conference do
                if AreasFound[count] = FALSE then
                begin
                  ChatFile.Read(TempInfo, SizeOf(ChatLineType));
                    if (Lower(TempInfo.Alias) = Lower(SearchFor)) then
                    begin
                      if (TempInfo.Alias = #255) and (UID <> #255) then
                      begin
                        found := TRUE;
                        AreasFound[count] := FALSE;
                      end;

                      if (TempInfo.UStealth and FullAccess) or not TempInfo.UStealth then
                      begin
                        found := TRUE;
                        AreasFound[count] := TRUE;
                      end;
                    end;
                end;

            ChatFile.Done;
        end;

    RmWin;

    if found then
    begin
      FoundString := '';
        for count := 0 to Maximum_Number_Of_Confs do
          if AreasFound[count] then
            FoundString := FoundString + Int_to_Str(count) + ' ';

          if Snd then
          begin
            sound(700);
              delay(150);
            nosound;
          end;

        TempMessageBox(4,6,white,blue,2,'Found in #'+ FoundString);
    end
    else
    begin
      if Snd = TRUE then
      begin
        sound(400);
          delay(150);
        nosound;
      end;

        TempMessageBox(4,6,yellow,red,2,'Alias not found in any conference');
    end;

    ChDir(PrimeDir);
    ChDir(Conference[currConference].CDir)
  end;
end;


function ChangeColor(MyColor : integer) : integer;
const
  X = 30;
  Y = 9;
var
  count : integer;
  done  : boolean;
  ch    : char;
begin
  Window(1,1,80,25);
    MkWin(X,Y,X+16,Y+3,white,blue,2);
      gotoXY(X+1,Y+2);
        for count := 1 to 15 do
        begin
          TextColor(count);
          Write(#219);
        end;

        done := FALSE;
        repeat
         TextBackground(blue);
         gotoXY(X + MyColor,Y + 1);
           Write(#31);

         ch := GetKey;

         case ch of
           #13:
             done := TRUE;
           #203:  {LEFT}
           begin
             gotoXY(X + MyColor,Y + 1);
               Write(#32);
             Dec(MyColor);
               if MyColor < 1 then
                 MyColor := 15;
           end;
           #205:  {RIGHT}
           begin
             gotoXY(X + MyColor,Y + 1);
               Write(#32);
             Inc(MyColor);
               if MyColor > 15 then
                 MyColor := 1;
           end;
         end;
        until done;

    RmWin;
TextBackground(black);

ChangeColor := MyColor;
end;


procedure SendMessage;
var
  Message    : string[76];
  Code       : integer;
  place      : integer;
  MyMess     : MessageLineType;
  TempMess   : MessageLineType;
  count      : integer;
  Dest       : string[10];
  NumOfMess  : integer;
  ch         : char;
  Month,
  Day,
  Year       : word;
  DOW        : word;
begin
Message := '';

  Window(1,1,80,25);
    MkWin(1,7,80,16,white,blue,2);
      TextColor(white);
      TextBackground(blue);
        gotoXY(3,9);
          Write('Enter a short message here, and it will be sent to the specified destination');
        gotoXY(3,11);
          Write('NOTE: These messages are NOT private!');
        gotoXY(3,13);
          Write('Message:');
            ReadLine(3,14,76,white,black,Message,Code);

      if Code <> 1 then
      begin
        Dest := '';

        Read_String(10,13,10,'Destination: ',2,Dest);

        if dest <> '' then
        begin
          ChDir(PrimeDir);

            place := -1;

          ResetMessStream;
            for count := 0 to Maximum_Number_Of_Mail do
            begin
              MessStream.Read(TempMess, SizeOf(MessageLineType));
                if (TempMess.Destination = '') and (place = -1) then
                  place := count;
            end;

            MyMess.From := lower(UID);
            MyMess.Destination := lower(Dest);
            MyMess.TxtLine := Message;
            MyMess.Opened := FALSE;
              GetDate(Year, Month, Day, DOW);
                with MyMess do
                begin
                  Date := Last(2, '0' + Int_to_str(Month));
                  Date := Date+ Last(2, '0' + Int_to_Str(Day));
                  Date := Date + Last(2, Int_to_str(Year));
                end;

            MessStream.Seek(place * SizeOf(MessageLineType));
            MessStream.Write(MyMess, SizeOf(MessageLineType));

          MessStream.Done;

          if Snd = TRUE then
          begin
            sound(400);
              delay(150);
            nosound;
          end;

          TempMessageBox(30,11,yellow,red,2,' Message sent. ');

          ChDir(Conference[currConference].CDir);
        end;
      end;
    RmWin;
TextBackground(black);
ShowTime(FALSE);
end;


procedure ShowMail(number : integer);
var
  MyMessage : MessageLineType;
  count     : integer;
  ch        : char;
begin
ChDir(PrimeDir);
Window(1,1,80,25);

  if number > -1 then
  begin
    ResetMessStream;
      MessStream.Seek(MessageNumber[number] * SizeOf(MyMessage));
      MessStream.Read(MyMessage, SizeOf(MyMessage));
    MessStream.Done;

      MkWin(1,8,80,13,white,blue,2);
        TextColor(white);
        TextBackground(blue);

        gotoXY(3,10);
          Write('From: ' + MyMessage.From);
            gotoXY(25,10);
              with MyMessage do
                Write('Sent on: ' + Copy(Date, 1, 2) + '-' + Copy(Date, 3, 2) + '-' + Copy(Date, 5, 2));
        gotoXY(3,11);
          Write(MyMessage.TxtLine);
        gotoXY(4,13);
          Write(' Press ''D'' to delete or any other to continue');

        if Snd then
        begin
          sound(200);
            delay(100);
          nosound;
        end;

        ch := ReadKey;

        ResetMessStream;
          MessStream.Seek(MessageNumber[number] * SizeOf(MyMessage));
          MyMessage.Opened := TRUE;

          if lower(ch) = 'd' then
          begin
              Modify_Topic(Mail_Menu, number + 1, '<empty>', FALSE, #0,0,nil);

                MyMessage.Destination := '';
                MyMessage.Opened := FALSE;

            MessageNumber[number] := -1;
          end
          else
            Modify_Topic_Name(Mail_Menu, number + 1, '*from: ' + MyMessage.From);

          MessStream.Write(MyMessage, SizeOf(MyMessage));
        MessStream.Done;

      RmWin;
        TextBackground(black);
  end;
ChDir(PrimeDir);
ChDir(Conference[currConference].CDir);
end;


procedure ClearRemoteWindows;
var
  Prevline : string;
begin
PrevLine := MyLine.Txt;

  if Copy(Temp[MyPos].Txt,3,15) = '*** Cleared all' then
  begin
    ResetChatFile;
      MyLine.Txt := '';
        ChatFile.Seek(MyPos * SizeOf(ChatLineType));
        ChatFile.Write(MyLine, SizeOf(ChatLineType));
    ChatFile.Done;

    delay(500);
  end;

  ResetChatFile;
    MyLine.Txt := 'OR~:' + upper(FullAccessPass);

      ChatFile.Seek(MyPos * SizeOf(ChatLineType));
      ChatFile.Write(MyLine, SizeOf(ChatLineType));
  ChatFile.Done;

MyLine.Txt := PrevLine;
end;


procedure ProtectAlias;
var
  TempOld  : string;
  OldPass  : string;
  NewPass  : string;
  NewPass1 : string;
  done     : boolean;
  ch       : char;
begin
TempOld := '';
OldPass := CurrAlias.Pass;
NewPass := '';
NewPass1 := '';
done := FALSE;

Window(1,1,80,25);
OffCursor;
  TextBackground(cyan);
  TextColor(black);

  MkWin(8,8,42,15,black,cyan,2);
    gotoXY(10,10);
      Write('Old Pass:*                    *');
    gotoXY(10,12);
      Write('New Pass:*                    *');
    gotoXY(10,13);
      Write('Retype  :*                    *');

      RTTT.FCol := white;
      RTTT.BCol := blue;
    if (OldPass <> '') and (OldPass <> #255) then
    begin
      Read_Password(20,10,20,'',0,TempOld);
    end
    else
      TempOld := OldPass;

    if (lower(TempOld) = lower(OldPass)) then
    begin
      Read_Password(20,12,20,'',0,NewPass);
      Read_Password(20,13,20,'',0,NewPass1);
    end;

      RTTT.FCol := lightgray;
      RTTT.BCol := black;

    if (lower(TempOld) = lower(OldPass)) then
      if (lower(NewPass) <> lower(NewPass1)) then
      begin
        MkWin(25,12,55,17,yellow,red,1);
            gotoXY(32,14);
              textColor(white);
              textBackground(red);
                Write('Your new password');
            gotoXY(32,15);
                Write('did not match up.');

            if Snd then
            begin
              sound(2500);
                delay(5);
              nosound;
            end;
          ch := ReadKey;
        RmWin;
      end
      else
        if lower(NewPass) = lower(NewPass1) then
        begin
          if NewPass <> '' then
            CurrAlias.Pass := lower(NewPass)
          else
            CurrAlias.Pass := #255;

          if OldPass = '' then
            CurrAlias.FileLoc := 65535;

            SaveAliasInfo;
        end;
  RmWin;
OnCursor;

TextBackground(black);
end;


{$F+}
procedure MenuHook(var Ch:char; Code : integer);
begin
  ShowTime(FALSE);
end;
{$F-}


{$F+}
procedure MenuAction(var Code : integer; var RetCode : byte);
begin

RetCode := ClearAll;

  case Code of
    cmQuit:
    begin
      finished := TRUE;
        Terminate;
    end;
    cmClearLocal:
    begin
      fle := TRUE;
    end;
    cmClearRemote:
    begin
      Row2 := 1;
    end;
    cmOneLine:
      MakeOneLine;
    cmOnePers:
      MakePersonLine;
    cmAddConference:
      AddConf;
    500..599:
      ChangeConf(Code);
    600..698:
      DeleteConf(Code);
    699..827:
      ASCIIChar := Chr(Code - 572);
    900..920:
    begin
      ShowMail(Code - 900);
      RetCode := RefreshMenu;
    end;
    cmStealth:
      ToggleStealth;
    cmSound:
      ToggleSound;
    cmKickOff:
      KickOff;
    cmSearchConfs:
      SearchForAlias;
    cmChangeRemote:
      RemoteColor := ChangeColor(RemoteColor);
    cmChangeLocal:
      LocalColor := ChangeColor(LocalColor);
    cmSendMessage:
      SendMessage;
    cmClearRemoteWindows:
      ClearRemoteWindows;
    cmProtectAlias:
      ProtectAlias;
  end;
end;
{$F-}


procedure DoIntro;
var
  count : integer;
  MyRow : integer;
begin
OffCursor;

TextBackground(black);
TextColor(white);
ClrScr;
  for count := 1 to 2 do
  begin
    gotoXY(39,13);
      Write(' * ');
        delay(300);
    gotoXY(39,13);
      Write('   ');
        delay(300);
  end;

MkWin(1,1,80,25,white,white,0);
 delay(20);
RmWin;
  gotoXY(25,13);
    Write('PRESS <DEL> TO CLEAR YOUR LINE');
  gotoXY(24,14);
    Write('PRESS ALT+P TO RETYPE LAST LINE');
  delay(15);
    ClrScr;
MkWin(1,1,80,25,white,white,0);
 delay(20);
RmWin;

MyRow := 1;
for count := 1 to 13 do
begin
  gotoxy(count * 5, MyRow);
    Write('MULTILAN2LAN');

    delay(50);

  Inc(MyRow,2);
end;

MyRow := 1;
for count := 1 to 13 do
begin
  gotoxy(count * 5, MyRow);
    Write('            ');

    delay(50);

  Inc(MyRow,2);
end;

OnCursor;
end;


procedure ParseCommandString;
var
  count : integer;
  Ps    : string;
begin
  for count := 1 to ParamCount do
  begin
    if Copy(lower(ParamStr(count)), 1, 2) = '/d' then
      DelayTime := Str_to_Int(Copy(ParamStr(count), 4, Length(ParamStr(count)) - 4));

    if Copy(lower(ParamStr(count)), 1, 2)  = '/?' then
    begin
      WriteLn('MultiLAN2LAN V'+VersionNum+'.  Written by Nathan Thomas');
      WriteLn('  (c)Copyright 1994-1996 by Nathan Thomas');
      WriteLn('  Distributed by Gammaware Software');
      WriteLn;
      WriteLn(ParamStr(0), ' [/d:delaytime] [/a:alias]');
      WriteLn;
      WriteLn('  /d:delaytime   Sets the delay time. Typically, a smaller number = faster run.');
      WriteLn('  /a:alias       The name used for communication in the program.');
      WriteLn('                  -To get alias from environment variable, use quotes.');
      WriteLn('                   e.g.  /a:"ID" get alias from variable ID.');

      halt(2);
    end;

    if Copy(lower(ParamStr(count)), 1, 2)  = '/a' then
      if Copy(lower(ParamStr(count)), 4, 1) = '"' then
        UID := GetEnv(Copy(ParamStr(count), 5, Length(ParamStr(count)) - 5))
      else
        UID := Copy(lower(ParamStr(count)), 4, Length(ParamStr(count)));
  end;
end;


var
  Password : string;
  CfgFile  : text;
  found    : boolean;
  Bt       : byte;
  U        : string;
  TempMess : MessageLineType;
  X,
  Y        : integer;
  Result   : boolean;
  ps       : string;
  goodpass : boolean;
begin
CheckBreak := FALSE;
UID := '';
Stealth := FALSE;
NewStartRainBow := 1;

if ParamCount = 0 then
  DelayTime := 30
else
  ParseCommandString;

    GetDir(0, StartDirectory);

    Assign(CfgFile, 'MLAN2LAN.INI');
      Reset(CfgFile);
        ReadLn(CfgFile, PrimeDir);
          if PrimeDir = '' then
          begin
            PrimeDir := StartDirectory;
              if PrimeDir[Length(PrimeDir)] = '\' then
                PrimeDir := First((Length(PrimeDir) - 1), PrimeDir);
          end;
        ReadLn(CfgFile, ConferenceDataFile);
          ConferenceDataFile := PrimeDir + '\' + ConferenceDataFile;
      Close(CfgFile);


with RTTT do
begin
  WhiteSpace := #32;
  BCol := black;
  FCol := green;
  HiFCol := white;
  HiBCol := red;
  LoFCol := white;
  LoBCol := red;
  PFCol := white;
  PBCol := red;
  BoxFCol := yellow;
  BoxBCol := red;
end;

if UID = '' then
begin
  DoIntro;

TextColor(white);
TextBackground(black);
ClrScr;
  WriteLn;
  Write('* Initializing the');
    TextColor(Blink + cyan);
      Write(' MultiLAN2LAN V'+VersionNum);
    TextColor(white);
  WriteLn(' chat software.');
  WriteLn('* (c)1994-1996 by Nathan Thomas');
  WriteLn;
  WriteLn('* Using ' + Int_to_Str(DelayTime) + ' millisecond delay');
  WriteLn('* Alt-254 + alias for system control');
  WriteLn;
  Write('* To consistently receive messages, using the ');
    TextColor(Blink + black);
    TextBackground(yellow);
      Write(' same ');
    TextColor(white);
    TextBackground(black);
  WriteLn(' alias is suggested');
  Rainbow(PadLeft('',80,'*'));
end
else
  ClrScr;

    TextColor(white);
repeat
goodpass := TRUE;
FullAccess := FALSE;

    if UID = '' then
    repeat
      Write('* Enter alias: ');

      ReadLn(UID);
    until (UID <> '');
      UID := Lower(UID);

    FullAccess := FALSE;

      if (UID[1] = '*') and (Length(UID) > 1) then
      begin
        Write('* Enter password: ');
          TextColor(black);
            ReadLn(Password);
          TextColor(white);

          if (UID[2] <> #255) or (Length(UID) > 2) then
          begin
            if (UID[1] = '*') and (Upper(Password) = Decode(FullAccessPass)) then
            begin
              FullAccess := TRUE;
                WriteLn('* CORRECT PASSWORD, full access granted.');
            end
            else
              WriteLn('* INCORRECT PASSWORD, control not available.');
          end
          else
            if (UID[2] = #255) and (Length(UID) = 2) then
            begin
              if Upper(Password) = Decode(GODAccessPass) then
                FullAccess := TRUE
              else
                UID := '* ';
            end;

        UID := Copy(UID, 2, Length(UID) - 1);
      end;

    Result := LookupAlias(UID, CurrAlias);

    if not Result or ((CurrAlias.Pass = '') or (CurrAlias.Pass = #255)) then
    begin
      CurrAlias.Alias := UID;
      CurrAlias.Pass  := '';
        if (CurrAlias.Pass <> '') and (CurrAlias.Pass <> #255) then
          CurrAlias.FileLoc := 65535;
      CurrAlias.LColor := LocalColor;
      CurrAlias.RColor := RemoteColor;
      CurrAlias.SndOn := TRUE;

      WriteLn('* This alias is unprotected, if you use it often and would like more');
      WriteLn('  reliable messages, you should protect it with a password');
        delay(3000);
    end
    else
    begin
      if (CurrAlias.Pass <> '') and (CurrAlias.Pass <> #255) then
      begin
        Write('* Enter protected password:');
          textColor(black);
            ReadLn(ps);
          textColor(white);

          if lower(ps) <> lower(CurrAlias.Pass) then
          begin
            WriteLn('* INCORRECT PROTECTED PASSWORD');
            WriteLn('* This alias has been protected,  please try again.');
            WriteLn;
              goodpass := FALSE;
              UID := '';
          end;
      end;
    end;

until goodpass;

    delay(1000);

    LocalColor := CurrAlias.LColor;
    RemoteColor := CurrAlias.RColor;
    Snd := CurrAlias.SndOn;

    CHDir(PrimeDir);

    if not exist('MESSAGES.SBN') then
    begin
        TempMess.Destination := '';
          MessStream.Init('MESSAGES.SBN', stCreate);
            for count := 0 to Maximum_Number_of_Mail do
              MessStream.Write(TempMess, SizeOf(MessageLineType));
          MessStream.Done;
    end;

  if not Exist(ConferenceDataFile) then
  begin
    ConfFile.Init(ConferenceDataFile, stCreate);
      for count := 0 to Maximum_Number_Of_Confs do
      begin
        Conference[count].CName := '<none>';
        Conference[count].CDir := '';
          ConfFile.Write(Conference[count], SizeOf(ConferenceRecord));
      end;
    ConfFile.Done;
  end;


Row1 := 1;
Row2 := 1;
  ClrScr;
if ColorScreen then
begin
    TextColor(white);
    TextBackground(blue);
end
else
begin
  TextColor(black);
  TextBackground(white);
end;
      for count := 1 to 80 do
        Write(' ');
    GotoXY(1,1);
  WriteLn('MLAN2LAN V'+Copy(VersionNum,1,1)+' * by Nathan Thomas');
    TextColor(white);
    TextBackground(black);
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

  Window(1,25,80,25);
if ColorScreen then
  TextColor(red)
else
  TextColor(black);

    TextBackground(white);
      ClrScr;
        Write(' ALT-X       ALT-L              ALT-R               ALT-S           F10');
if ColorScreen then
  TextColor(black)
else
  TextColor(darkgray);

    GotoXY(8,1);
      Write('Exit');
    GotoXY(20,1);
      Write('Clear Local');
    GotoXY(39,1);
      Write('Clear Remote');
    GotoXY(59,1);
      Write('Toggle ',#14);
    GotoXY(73,1);
      Write('Menu');

if ColorScreen then
begin
    TextColor(white);
    TextBackground(blue);
end
else
begin
  TextColor(black);
  TextBackground(white);
end;
  Window(1,1,80,1);
    GotoXY(36,1);
      Write('UID:', Copy(UID, 1, 10));

      if FullAccess = TRUE then
      begin
        Stealth := TRUE;
          GotoXY(34,1);
            Write('S');
      end;


  ShowTime(FALSE);
  TextBackground(black);

  Initialize_Menu(Main_Menu, '', 0, 0);
  Initialize_Menu(Conf_Menu, ' Conference Menu ', 34, 0);
  Initialize_Menu(Change_Menu, ' Change Conference ', 35, 21);
  Initialize_Menu(Delete_Menu, ' Delete Conference ', 35, 21);
  Initialize_Menu(Users_Menu, ' List of Users ', 25, 21);
  Initialize_Menu(Color_Menu,' Colors ', 19, 0);
  Initialize_Menu(ASCII_Menu,' ASCII Table ',13,0);
  Initialize_Menu(Mail_Menu,' Messages ',20,0);
    Add_Topic(Main_Menu,'clear Local window         ALT-L',TRUE,#0,cmClearLocal,nil);
    Add_Topic(Main_Menu,'clear Remote window        ALT-R',TRUE,#0,cmClearRemote,nil);
    Add_Topic(Main_Menu,'chaNge colors                   ',TRUE,#0,0,@Color_Menu);
    Add_Topic(Main_Menu,'ascIi table                ALT-I',TRUE,#0,0,@ASCII_Menu);
    Add_Topic(Main_Menu,'-',TRUE,#0,0,nil);
    Add_Topic(Main_Menu,'Conferences. . .                ',TRUE,#0,0,@Conf_Menu);
    Add_Topic(Main_Menu,'Popup message to everyone       ',TRUE,#0,cmOneLine,nil);
    Add_Topic(Main_Menu,'pOpup message to 1 person       ',TRUE,#0,cmOnePers,nil);
    Add_Topic(Main_Menu,'toggle Sound               ALT-S',TRUE,#0,cmSound,nil);
    Add_Topic(Main_Menu,'protect alias                   ',TRUE,#0,cmProtectAlias,nil);
    Add_Topic(Main_Menu,'-',TRUE,#0,0,nil);
    Add_Topic(Main_Menu,'send oFf-line message           ',TRUE,#0,cmSendMessage,nil);
    Add_Topic(Main_Menu,'chEck messages                  ',TRUE,#0,0,@Mail_Menu);

      if FullAccess = TRUE then
      begin
        Add_Topic(Main_Menu,'-',TRUE,#0,0,nil);
        Add_Topic(Main_Menu,'Add a conference                ',TRUE,#0,cmAddConference,nil);
        Add_Topic(Main_Menu,'deleTe a conference             ',TRUE,#0,0,@Delete_Menu);
        Add_Topic(Main_Menu,'reMove user                     ',TRUE,#0,cmKickOff,nil);
        Add_Topic(Main_Menu,'clear all remote Windows        ',TRUE,#0,cmClearRemoteWindows,nil);
      end;

    Add_Topic(Main_Menu,'-',TRUE,#0,0,nil);
    Add_Topic(Main_Menu,'eXit MultiLAN2LAN          ALT-X',TRUE,#0,cmQuit,nil);
      Assign_Despatcher(MenuAction);

        Add_Topic(Conf_Menu,'Change current conference',TRUE,#0,0,@Change_Menu);
        Add_Topic(Conf_Menu,'Show who''s on-line',TRUE,#0,0,@Users_Menu);
        Add_Topic(Conf_Menu,'sEarch all conferences for alias',TRUE,#0,cmSearchConfs,nil);
        Add_Topic(Conf_Menu,'-',TRUE,#0,0,nil);
        Add_Topic(Conf_Menu,'Toggle stealth mode',TRUE,#0,cmStealth,nil);

        Add_Topic(Color_Menu,'Remote text color',TRUE,#0,cmChangeRemote,nil);
        Add_Topic(Color_Menu,'Local text color ',TRUE,#0,cmChangeLocal,nil);

        for count := 127 to 254 do
          Add_Topic(ASCII_Menu,' ' + Int_to_Str(count) + ' ' + Chr(count),TRUE,#0,572 + count,nil);


    with NTTT do
    begin
      X         := 2;
      Y         := 3;
      LeftSide  := TRUE;
      AllowEsc  := TRUE;
      BoxType   := 3;
      BoxFCol   := black;
      BoxBCol   := lightgray;
      CapFCol   := red;
      BacCol    := lightgray;
      NorFCol   := black;
      HiFCol    := black;
      HiBCol    := green;
      LoFCol    := darkgray;
      LeftChar  := ' ';
      RightChar := ' ';
      Hook      := MenuHook;
    end;
      RTTT.WhiteSpace := #32;
      N_Fatal := FALSE;

    currConference := -1;
      LoadConferences(FALSE);
        found := FALSE;
          for count := 0 to Maximum_Number_Of_Confs do
            if not found and (Conference[count].CName <> '<none>') then
              found := TRUE;

        if (found = FALSE) and FullAccess then
          AddConf;

      LoadConferences(TRUE);

          currConference := -1;
          OffCursor;
            Show_Nest(Change_Menu);
              if currConference = -1 then
                Terminate;

    LoadUsers(FALSE);
    DetectMail;
    LoadMail;
      finished := FALSE;
      Snd := not Snd;
        ToggleSound;


  repeat
    SingleInput;
  until finished;
    if (CurrAlias.Pass <> '') and (CurrAlias.Pass <> #255) then
      SaveAliasInfo;

    Terminate;
end.
