#! /bin/bash

die(){
  echo "$*" 1>&2 ;
  exit 1;
}

#------------------- copy test files from valgrind to test dir -----------------
#$1 = relative path after cd $AP_VG
pull_tests(){
  for next_dir in $(ls -l $1 | grep ^d | awk '{ print $9 }' | grep -v nto-)
  do
    if [[ $next_dir == 'tests' ]]; then
      if [ ! -d "$AP_TESTS/$1" ]; then mkdir $AP_TESTS/$1;fi
      cp -r $1/$next_dir $AP_TESTS/$1/tests
    else pull_tests $1/$next_dir ;fi
    cp $1/*.h $AP_TESTS/$1 2>/dev/null
  done
}


# --------------------------- main ---------------------------------------------
#
#$1 = AP_VG
#
# ------------------------------------------------------------------------------
if [[ $# != 1 ]];then die 'Illegal amount of arguments\n';fi

AP_VG=$(realpath $1)
TEST_DIR="vg_remote_test_dir"
CUR_DIR=$(pwd)
AP_TESTS=$CUR_DIR/$TEST_DIR #save absolute path to TEST_DIR
TOOLS=memcheck

# ---------------------------- create dir with test files -----------------------
if [ ! -d $TEST_DIR ]; then
  mkdir $TEST_DIR;
  cd $AP_VG
  pull_tests .
else printf "vg_remote_test_dir already exist\n";fi
# ----------------------------- create symlinks ---------------------------------
# TODO too dirty one
ln -s $AP_VG/include/valgrind.h $AP_TESTS/memcheck/valgrind.h
ln -s $AP_VG/tests/ $AP_TESTS/memcheck/tests/tests
for tool in $TOOLS;do
  for lndir in  include VEX/pub;do
    if [ ! -L $AP_TESTS/$tool/$lndir ];then ln -s $AP_VG/$lndir $AP_TESTS/$tool/$lndir;fi
    if [ ! -L $AP_TESTS/$tool/$lndir ];then die "symlink not created\n";fi
    for f in $(ls $AP_TESTS/$lndir);do
      if [ ! -L $AP_TESTS/$tool/tests/$f ];then ln -s $AP_VG/$lndir/$f $AP_TESTS/$tool/tests/$f;fi
    done
  done
  ln -s $AP_TESTS/$tool $AP_TESTS/$tool/tests/$tool
done
cp $AP_VG/config.h.in~ $AP_TESTS/config.h
ln -s $AP_VG/include $AP_TESTS

#---------------------------- compiling C files --------------------------------
# TODO
bad_progs="buflen_check.vgtest"

CC='powerpc-unknown-nto-qnx6.5.0-gcc'
CCFLAGS='-D VGO_nto -D VGA_ppc32'

for tool in $TOOLS;do
  cd $AP_TESTS/$tool/tests
  rm $bad_progs
  for f in $(ls | grep '.vgtest');do

    tname=$(cat $f | grep 'prog:' | sed -e 's/prog: //' -e 's/ //g' )
    printf "f = $f, tname = $tname\n"

    #TODO what about *.cpp
    if [ ! -f $tname ] && [ -f $tname.c ];then
      $CC -o $tname $CCFLAGS $tname.c 1>/dev/null;
      if [ ! -f $tname ];then die "compilation failed";
      else printf "$tname compilation done\n\n";fi
    elif [ ! -f $tname.c ];then printf "$tname.c not found\n";fi

  done
done


#---------------------------- load & test on remote machine for testing --------
# TARGET_PATH=/home
# scp -r $TEST_DIR root@addr:$TARGET_PATH
# ssh root@addr $TARGET_PATH/$TEST_DIR/tests/vg_regtest.sh
