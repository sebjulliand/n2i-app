#!/QOpenSys/pkgs/bin/bash
set -u

LIBRARY=$1
DEBUG_VIEW=${2:-*LIST}

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $BASE_DIR
echo "Building from $BASE_DIR"
echo ""
rm -rf .logs
mkdir -p .logs

run(){
  local command=$1
  local ifsFile=${2:-}

  local output=".logs/$(basename $ifsFile).splf"
  local srcStmf=$([[ -n "$ifsFile" ]] && echo "SRCSTMF('$ifsFile')" || echo "")

  echo -n "Building $ifsFile..."  
  cl -q "$command $srcStmf" > $output && echo ✅ || echo ❌
}

run "CRTCLMOD MODULE($LIBRARY/OVRPRTF) OPTION(*EVENTF) DBGVIEW($DEBUG_VIEW) TGTCCSID(*JOB)" "N2IAPP/modules/ovrprtf.clle"
run "CRTSRVPGM SRVPGM($LIBRARY/TOOLS) MODULE($LIBRARY/OVRPRTF) ACTGRP(TOOLS)"

run "CRTSQLRPGI OBJ($LIBRARY/JOKESPOOL) OBJTYPE(*MODULE) OPTION(*EVENTF) DBGVIEW($DEBUG_VIEW) CLOSQLCSR(*ENDMOD) CVTCCSID(*JOB) COMPILEOPT('TGTCCSID(*JOB)') RPGPPOPT(*LVL2)" "N2IAPP/modules/JOKESPOOL.rpgle"
run "CRTPGM PGM($LIBRARY/JOKESPOOL) MODULE($LIBRARY/JOKESPOOL) ENTMOD($LIBRARY/JOKESPOOL) BNDSRVPGM(($LIBRARY/TOOLS)) ACTGRP(*CALLER)"

run "RUNSQLSTM COMMIT(*NONE) NAMING(*SYS) DFTRDBCOL($LIBRARY)" "N2IAPP/tables/FORTUNES.table"
run "RUNSQLSTM COMMIT(*NONE) NAMING(*SYS) DFTRDBCOL($LIBRARY)" "N2IAPP/sql/random_fortunes.function"