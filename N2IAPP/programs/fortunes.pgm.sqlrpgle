**free
Ctl-Opt Main(FORTUNE);

Dcl-Proc FORTUNE;
  DCL-S response VarChar(5000);

  exec SQL Set Option COMMIT=*NONE;

  exec SQL
    values http_get('https://helloacm.com/api/fortune/', '') into :response;

  response = %scanrpl('Ö"':'"':
    %scanrpl('\n':'':
    %scanrpl('\t':' ':
    %subst(response : 2 : %Len(response)-2))));
  snd-msg %Char(response);

  Exec SQL Insert Into FORTUNES (MESSAGE) Values (:response);
End-Proc;