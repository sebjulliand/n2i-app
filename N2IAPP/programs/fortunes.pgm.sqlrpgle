**free
Ctl-Opt Main(FORTUNE);

Dcl-Proc FORTUNE;
  DCL-S message VarChar(5000);

  exec SQL Set Option COMMIT=*NONE;

  exec SQL values RandomFortune() into :message;
  snd-msg %Char(message);

  Exec SQL Insert Into FORTUNES (MESSAGE) Values (:message);
End-Proc;