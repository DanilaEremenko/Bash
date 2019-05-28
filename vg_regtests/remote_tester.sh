#! /bin/bash

die(){
  echo "$*" 1>&2 ;
  exit 1;
}

#------------------- copy test files from valgrind to test dir -----------------
#$1 = relative path after cd $PATH_TO_VG
pull_tests(){
  for next_dir in $(ls -l $1 | grep ^d | awk '{ print $9 }' | grep -v nto-)
  do
    if [[ $next_dir == 'tests' ]]; then
      if [ ! -d "$AP_TEST_DIR/$1" ]; then mkdir $AP_TEST_DIR/$1;fi
      cp -r $1/$next_dir $AP_TEST_DIR/$1/tests
    else pull_tests $1/$next_dir ;fi
  done
}


# --------------------------- main ---------------------------------------------
#
#$1 = PATH_TO_VG
#$2 = AP_TEST_DIR
#
# ------------------------------------------------------------------------------
if [[ $# != 1 ]];then die 'Illegal amount of arguments\n';fi

PATH_TO_VG=$1
TEST_DIR="vg_remote_test_dir"
CUR_DIR=$(pwd)
CC='powerpc-unknown-nto-qnx6.5.0-gcc'
AP_TEST_DIR=$CUR_DIR/$TEST_DIR #save absolute path to TEST_DIR


#---------------------------- create dir with test files -----------------------
if [ ! -d $TEST_DIR ]; then
  mkdir $TEST_DIR;
  cd $PATH_TO_VG
  pull_tests .
  cd $CUR_DIR/$TEST_DIR
else printf "vg_remote_test_dir already exist\n";fi

#---------------------------- compiling C files --------------------------------
cd $TEST_DIR
for tool in memcheck;do
  cd $tool/tests
  # printf $(ls | grep '*.vgtest')\n
  for f in $(ls | grep '.vgtest');do
    tname=$(echo $f | cut -d . -f1)
    $CC -o $tname $tname.c 1>/dev/null
    if [ ! -f $tname ];then die "compilation failed\n";
    else printf "$tname compilation done";fi
  done
  cd ../..
done


#---------------------------- load to remote machine for testing ---------------
#scp -r $TEST_DIR root@172.16.36.99:home/

#ssh root@172.16.36.99 pwd
