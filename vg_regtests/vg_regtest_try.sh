#! /bin/sh

die() { echo "$*" 1>&2 ; exit 1; }

#---------------------------- filters ------------------------------------------
default_filter(){
  #TODO how to define \n via sed
  sed -i 's/==.*== //g' $1
  sed -i 's/Memcheck, a memory .*$/-/g' $1
  sed -i 's/Copyright (C).*$/-/g' $1
  sed -i 's/Using Valgrind.*$/-/g' $1
  sed -i 's/Command: .*$/-/g' $1
  #sed -i 's/-$//g' $1
}

filter_allocs(){
  ns="\([0-9]\+\)" #ns - numbers sequence
  sed -i "s/in use at exit: $ns bytes in $ns blocks/in use at exit: ... bytes in ... blocks/g" $1
  sed -i "s/total heap usage: $ns allocs, $ns frees, $ns bytes allocated/total heap usage: ... allocs, ... frees, ... bytes allocated/g" $1
}

filter_addresses(){
  sed -i "s/0x\([0-9A-Fa-f]\)\+/0x......../g" $1
}

#$1 - test name
do_one_test(){
  tname=$1
  printf "________________\ndo $tname test...\n"

  # --------------------- check test files -------------------------------------
  if [ -f $tname.stdout.exp ];then
    printf "exp out exist\n"
    exp_out=$(cat $tname.stdout.exp);
  fi

  if [ -f $tname.stderr.exp ];then
    printf "exp_err exist\n"
    exp_err=$(cat $tname.stderr.exp);
  fi

  # --------------------- check filters ----------------------------------------
  if [ -f $tname.vgtest ];then
    #                                  |            parse only filter name                | remove path if contains
    stdout_filter=$( cat $tname.vgtest | grep 'stdout_filter:' | sed 's/stdout_filter: //g' | sed 's/\(\.\.\/\)*.*\///g')
    stderr_filter=$( cat $tname.vgtest | grep 'stderr_filter:' | sed 's/stderr_filter: //g' | sed 's/\(\.\.\/\)*.*\///g')
    vgopts=$( cat $tname.vgtest | grep vgopts:  | sed 's/vgopts: //g')
    printf "stdout_filter = $stdout_filter\n"
    printf "stderr_filter = $stderr_filter\n"
    printf "vgopts = $vgopts\n"
  fi

  # --------------------- do test ==--------------------------------------------
  $CC -o $tname $tname.c

  if [ -f $tname.stdout.exp ] && [ -f $tname.stderr.exp ]; then
    valgrind $vgopts ./$tname 2>$tname.stderr.res 1>$tname.stdout.res
  elif [ -f $tname.stdout.exp ];then
    valgrind $vgopts ./$tname 2>/dev/null 1>$tname.stdout.res
  elif [ -f $tname.stderr.exp ];then
    valgrind $vgopts ./$tname 2>$tname.stderr.res 1>/dev/null
  else
    die "no exp_out or exp_err files\n"
  fi

  if [ -f $tname.stdout.exp ]; then
    default_filter $tname.stdout.res
    if [ $stdout_filter ]; then $stdout_filter $tname.stdout.res; fi
    diff -u $tname.stdout.exp $tname.stdout.res > $tname.stdout.diff
  fi

  if [ -f $tname.stderr.exp ]; then
    default_filter $tname.stderr.res
    if [ $stdout_filter ]; then $stdout_filter $tname.stderr.res; fi
    if [ $stderr_filter ]; then $stderr_filter $tname.stderr.res; fi
    diff -u $tname.stderr.exp $tname.stderr.res > $tname.stderr.diff
  fi

  # --------------------- rm out files -----------------------------------------
  #rm $tname $tname.*.res $tname.*.diff
  rm $tname $tname.*.diff


}

#$1 - dir
test_one_dir(){
  cd $1

  for f in $(ls -l | awk '{ print $9 }')
  do

    if [ -d $f ]; then test_one_dir $f
    else
      if [ $(echo $f | tail -c 3) = ".c" ];then
        tname=$(echo $f | cut -d . -f1)
        do_one_test $tname
      fi
    fi
  done

  cd ..

}

# --------------------------- main ---------------------------------------------
#$1 = TEST_DIR
# ------------------------------------------------------------------------------
TEST_DIR=$1
CC=gcc
ptnum=0 #passed tests number
ftnum=0 #failed tests number

export PATH=$PATH:/home/dyu/git/vg_builded/usr/local/bin
export VALGRIND_LIB=/home/dyu/git/vg_builded/usr/local/lib/valgrind

cd $TEST_DIR

for tool in memcheck  #TODO add tools
do
  test_one_dir $tool
done
