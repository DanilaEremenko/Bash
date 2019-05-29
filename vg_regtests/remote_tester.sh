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
LINKED_DIRS='include VEX/pub vki'

# ---------------------------- create dir with test files -----------------------
if [ ! -d $TEST_DIR ]; then
  mkdir $TEST_DIR;
  cd $AP_VG
  pull_tests .
else printf "vg_remote_test_dir already exist\n";fi
# ----------------------------- create symlinks ---------------------------------
# TODO too dirty one
for tool in $TOOLS;do
  for lndir in  $LINKED_DIRS;do
    for f in $(ls $AP_VG/$lndir);do
      if [ ! -L $AP_TESTS/$tool/tests/$f ];then ln -s $AP_VG/$lndir/$f $AP_TESTS/$tool/tests/$f;fi
    done
  done
  ln -s $AP_TESTS/$tool $AP_TESTS/$tool/tests/$tool
  ln -s $AP_VG/include $AP_TESTS/$tool/include
  ln -s $AP_VG/config.h.in~ $AP_TESTS/$tool/config.h
  ln -s $AP_VG/config.h.in~ $AP_TESTS/$tool/tests/config.h
  ln -s $AP_VG/coregrind $AP_TESTS/$tool/tests/coregrind
  ln -s $AP_VG/tests/ $AP_TESTS/$tool/tests/tests

  for f in $(ls $AP_VG/coregrind/ | grep 'pub_core_');do
    ln -s $AP_VG/coregrind/$f $AP_TESTS/$tool/tests/$f
  done

  for f in $(ls $AP_VG/coregrind/ | grep 'pub_tool_');do
    ln -s $AP_VG/coregrind/$f $AP_TESTS/$tool/tests/$f
  done

  for f in 'm_libcbase.c';do
    ln -s $AP_VG/coregrind/$f $AP_TESTS/$tool/tests/$f
  done


done


mkdir -p $AP_TESTS/vg_stdlib
ln -s $AP_VG/include/valgrind.h $AP_TESTS/vg_stdlib/valgrind.h
ln -s $AP_VG/config.h.in~ $AP_TESTS/vg_stdlib/config.h
ln -s $AP_VG/include/vki $AP_TESTS/vg_stdlib/vki


ln -s $AP_VG/include/valgrind.h $AP_TESTS/memcheck/valgrind.h
ln -s $AP_VG/include $AP_TESTS/include
cp $AP_VG/config.h.in~ $AP_TESTS/config.h
cp $AP_VG/config.h.in~ $AP_TESTS/none/config.h

#---------------------------- compiling C files --------------------------------
# TODO
bad_progs='buflen_check.vgtest
           null_socket.vgtest
           reach_thread_register.vgtest
           sendmsg.vgtest
           stpncpy.vgtest
           suppvarinfo5.vgtest
           unit_oset.vgtest
           varinfo5.vgtest
           varinforestrict.vgtest
           vcpu_fnfns.vgtest
           wrap7.vgtest'


CC='powerpc-unknown-nto-qnx6.5.0-gcc'
CCFLAGS='-D VGO_nto -D VGA_ppc32'

tnum=0
all_tnum=0

for tool in $TOOLS;do
  cd $AP_TESTS/$tool/tests
  rm $bad_progs
  for f in $(ls | grep '.vgtest');do

    tname=$(cat $f | grep 'prog:' | sed -e 's/prog: //' -e 's/ //g' )
    printf "f = $f, tname = $tname\n"

    #TODO what about *.cpp
    if [ ! -f $tname ] && [ -f $tname.c ];then
      $CC -I $AP_TESTS/vg_stdlib -o $tname $CCFLAGS $tname.c 1>/dev/null;
      if [ ! -f $tname ];then die "compilation failed";
      else printf "$tname compilation done\n\n";fi
      tnum=$((tnum+1));
    elif [ ! -f $tname.c ];then printf "$tname.c not found\n";
    else
      printf "compiled file already exists\n";
      tnum=$((tnum+1));
    fi
    all_tnum=$((all_tnum+1));
  done
done

printf "\n----------------------- compiling done -------------------------\n\n"
printf "Compiled tests number = $tnum \ $all_tnum\n"
#---------------------------- delete symlinks ----------------------------------
# TODO too dirty one
# printf "\n-------------------- removing symlinks --------------------------\n\n"
# for tool in $TOOLS;do
#   for lndir in  $LINKED_DIRS;do
#     for f in $(ls $AP_TESTS/$tool/tests/);do
#       if [ -L $AP_TESTS/$tool/tests/$f ];then rm $AP_TESTS/$tool/tests/$f;fi
#     done
#   done
#   rm $AP_TESTS/$tool/tests/$tool
#   rm $AP_TESTS/$tool/include
#   rm $AP_TESTS/$tool/config.h
#   rm $AP_TESTS/$tool/tests/config.h
#   rm $AP_TESTS/$tool/tests/coregrind
#
#   for f in $(ls $AP_VG/coregrind/ | grep 'pub_core_');do
#     rm $AP_TESTS/$tool/tests/$f
#   done
#
#   for f in $(ls $AP_VG/coregrind/ | grep 'pub_tool_');do
#     rm $AP_TESTS/$tool/tests/$f
#   done
#
#   for f in 'm_libcbase.c';do
#     rm $AP_TESTS/$tool/tests/$f
#   done
#
#
# done
#
# rm -r $AP_TESTS/vg_stdlib
#
# rm $AP_TESTS/memcheck/valgrind.h
# ln -s $AP_VG/include $AP_TESTS/include
# cp $AP_VG/config.h.in~ $AP_TESTS/config.h
# cp $AP_VG/config.h.in~ $AP_TESTS/none/config.h


#---------------------------- load & test on remote machine for testing --------
#TARGET_PATH=/home
#TARGET=root@172.16.36.99
#scp -r $TEST_DIR $TARGET:$TARGET_PATH
# ssh root@addr $TARGET_PATH/$TEST_DIR/tests/vg_regtest.sh

printf "\n------------------- testing finished -------------------------------\n"
