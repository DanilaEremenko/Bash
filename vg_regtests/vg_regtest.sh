#! /bin/bash


#$1 - test name
do_test(){
  tname=$1
  printf "________________\ndo $tname test...\n"


  is_exp_out=false;
  if [[ -f $tname.stdout.exp ]];then
    exp_out=$(cat $tname.stdout.exp);
    is_exp_out=true;
  fi

  is_exp_err=false;
  if [[ -f $tname.stderr.exp ]];then
    exp_err=$(cat $tname.stderr.exp);
    is_exp_err=true;
  fi

  $CC -o $tname $tname.c


  valgrind ./$tname 2>$tname.stderr.res 1>$tname.stdout.res

  diff -u $tname.stderr.exp $tname.stderr.res > $tname.stderr.diff
  diff -u $tname.stdout.exp $tname.stdout.res > $tname.stdout.diff


  rm $tname $tname.*.res $tname.*.diff



}

#$1 - dir
do_test_dir(){
  cd $1

  for f in $(ls -l | awk '{ print $9 }')
  do

    if [ -d $f ]; then do_test_dir $f
    else
      if [[ $(echo $f | tail -c 3) = ".c" ]];then
        tname=$(echo $f | cut -d . -f1)
        do_test $tname
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

export PATH=$PATH:/home/dyu/git/vg_builded/usr/local/bin
export VALGRIND_LIB=/home/dyu/git/vg_builded/usr/local/lib/valgrind

cd $TEST_DIR

for tool in memcheck  #TODO add tools
do
  do_test_dir $tool
done


do_test_dir $TEST_DIR
