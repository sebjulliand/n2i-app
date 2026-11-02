#!/QOpenSys/pkgs/bin/bash
set -u

LIBRARY=$1
DEBUG_VIEW=${2:-*LIST}

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $BASE_DIR
echo "Building from $BASE_DIR"
echo ""
rm -rf .logs .evfevent
mkdir -p .logs .evfevent

FAILED=0

run(){
  local command=$1
  local ifsFile=${2:-}
  local eventf=${3:-}

  local output=".logs/$(basename $ifsFile).splf"
  local srcStmf=$([[ -f $ifsFile ]] && echo "SRCSTMF('$ifsFile')" || echo "")

  echo -n "Building $ifsFile..."  
  cl "$command $srcStmf" &>> $output && echo ✅ || {
     echo ❌
     FAILED=$(($FAILED+1))
     echo $FAILED
  }

  [[ -n "$eventf" ]] && dumpEventf $eventf $ifsFile
}

dumpEventf(){
  local member=$1
  local file=$2

  local target="/QSYS.LIB/$LIBRARY.LIB/EVFEVENT.FILE/$member.MBR"
  [[ -e "$target" ]] && cl "CPYTOSTMF STMFCCSID(1208) FROMMBR('$target') TOSTMF('.evfevent/$(basename $file).evfevent')" > /dev/null
}

cl "call QGPL/STRUSTEST"

run "CRTCLMOD MODULE($LIBRARY/OVRPRTF) OPTION(*EVENTF) DBGVIEW($DEBUG_VIEW) TGTCCSID(*JOB)" "N2IAPP/modules/ovrprtf.clle" "OVRPRTF"
run "CRTSRVPGM SRVPGM($LIBRARY/TOOLS) MODULE($LIBRARY/OVRPRTF) ACTGRP(TOOLS)" "TOOLS.ilesrvpgm"

run "CRTSQLRPGI OBJ($LIBRARY/JOKESPOOL) OBJTYPE(*MODULE) OPTION(*EVENTF) DBGVIEW($DEBUG_VIEW) CLOSQLCSR(*ENDMOD) CVTCCSID(*JOB) COMPILEOPT('TGTCCSID(*JOB)') RPGPPOPT(*LVL2)" "N2IAPP/modules/JOKESPOOL.sqlrpgle" "JOKESPOOL"
run "CRTPGM PGM($LIBRARY/JOKESPOOL) MODULE($LIBRARY/JOKESPOOL) ENTMOD($LIBRARY/JOKESPOOL) BNDSRVPGM(($LIBRARY/TOOLS)) ACTGRP(*CALLER)" "JOKESPOOL.ilesrvpgm"

run "CRTSQLRPGI OBJ($LIBRARY/FORTUNES) OBJTYPE(*PGM) OPTION(*EVENTF) DBGVIEW($DEBUG_VIEW) CLOSQLCSR(*ENDMOD) CVTCCSID(*JOB) COMPILEOPT('TGTCCSID(*JOB)') RPGPPOPT(*LVL2)" "N2IAPP/programs/fortunes.pgm.sqlrpgle" "FORTUNES"

run "RUNSQLSTM COMMIT(*NONE) NAMING(*SYS) DFTRDBCOL($LIBRARY) OPTION(*LIST)" "N2IAPP/tables/FORTUNES.table"
run "RUNSQLSTM COMMIT(*NONE) NAMING(*SYS) DFTRDBCOL($LIBRARY) OPTION(*LIST)" "N2IAPP/sql/RandomFortune.sqludf"

exit $FAILED