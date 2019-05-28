#! /bin/sh

die(){
  echo "$*" 1>&2 ;
  exit 1;
}

# --------------------------- main part ----------------------------------------
#$1 - test name
do_one_test(){
  tname=$1
  pref=$2
  printf "___________________________\ndo $pref/$tname test...\n\n"

  # --------------------- check filters ----------------------------------------
  if [ -f $pref/$tname.vgtest ];then
    #                                  |            parse only filter name                | remove path if contains
    stdout_filter=$( cat $pref/$tname.vgtest | grep 'stdout_filter:' | sed 's/stdout_filter: //g' | sed 's/\(\.\.\/\)*.*\///g')
    stderr_filter=$( cat $pref/$tname.vgtest | grep 'stderr_filter:' | sed 's/stderr_filter: //g' | sed 's/\(\.\.\/\)*.*\///g')
    vgopts=$( cat $pref/$tname.vgtest | grep vgopts:  | sed 's/vgopts: //g')
    printf "stdout_filter = $stdout_filter\n"
    printf "stderr_filter = $stderr_filter\n"
    printf "vgopts = $vgopts\n"
  fi


  # --------------------- compile C-file test ----------------------------------
  $CC -o $pref/$tname $pref/$tname.c 1>/dev/null
  printf "$pref/$tname.c compilation "
  if [ -f $pref/$tname ];then printf "done\n"
  else die "failed\n";fi

  # --------------------- call valgrind on test binary -------------------------
  if [ -f $pref/$tname.stdout.exp ] && [ -f $pref/$tname.stderr.exp ]; then
    printf "$pref/$tname.stdout.exp exist\n"
    printf "$pref/$tname.stderr.exp exist\n"
    exp_out=$(cat $pref/$tname.stdout.exp);
    exp_err=$(cat $pref/$tname.stderr.exp);
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stdout.exp ];then
    printf "$pref/$tname.stdout.exp exist\n"
    exp_out=$(cat $pref/$tname.stdout.exp);
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>/dev/null 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stderr.exp ];then
    printf "$pref/$tname.stderr.exp exist\n"
    exp_err=$(cat $pref/$tname.stderr.exp);
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>/dev/null
  else
    die "no exp_out or exp_err files, exiting...\n"
  fi

  printf "valgrind instrumentation done\n"
  # --------------------- diff stdout files ------------------------------------
  if [ -f $pref/$tname.stdout.exp ]; then
    old_addr=$(pwd) # neccesary cause vg filters use relative path
    cd $pref
    if [ -f $stdout_filter ] && [ "$stdout_filter" != "" ]; then
      printf "call $stdout_filter\n"
      ./$stdout_filter $tname.stdout.res;
    elif [ ! -f $stdout_filter ]; then die "filter $stdout_filter does't exist\n"; fi
    diff -u $tname.stdout.exp $tname.stdout.res > $tname.stdout.diff
    cd $old_addr
  fi
  # -------------------- check stdout diff -------------------------------------
  if [ -f $pref/$tname.stdout.diff ];then
    if [ ! -s $pref/$tname.stdout.diff ]; then
      pouttnum=$((pouttnum+1));
    else
      fouttnum=$((fouttnum+1));
      foutlist="$foutlist $tname, "
    fi
  fi

  # --------------------- diff stderr files ------------------------------------
  if [ -f $pref/$tname.stderr.exp ]; then
    old_addr=$(pwd) # neccesary cause vg filters use relative path
    cd $pref
    if [ -f $stderr_filter ] && [ "$stderr_filter" != "" ]; then
      printf "call $stderr_filter\n"
      ./$stderr_filter $tname.stderr.res;
    elif [ ! -f $stderr_filter ]; then die "filter $stderr_filter does't exist\n"; fi
    diff -u $tname.stderr.exp $tname.stderr.res > $tname.stderr.diff
    cd $old_addr
  fi
  # -------------------- check stderr diff -------------------------------------
  if [ -f $pref/$tname.stderr.diff ];then
    if [ ! -s $pref/$tname.stderr.diff ]; then
      perrtnum=$((perrtnum+1));
    else
      ferrtnum=$((ferrtnum+1));
      ferrlist="$ferrlist $tname, "
    fi
  fi



  # --------------------- rm out files -----------------------------------------
  rm $pref/$tname $pref/$tname.*.res $pref/$tname.*.diff 2>/dev/null
  # rm $pref/$tname $pref/$tname.*.res 2>/dev/null
  printf "$tname test done\n"

}

# --------------------------- find tested dir ----------------------------------
#$1 - dir
test_one_dir(){
  pref=$1

  printf "dir = $pref\n"

  for f in $(ls $pref)
  do
    if [ -d $pref/$f ]; then
      test_one_dir $pref/$f
    else
      if [ $(echo $f | cut -d . -f2) = "vgtest" ];then
        tname=$(echo $f | cut -d . -f1)
        do_one_test $tname $pref
      fi
    fi
  done

}

# --------------------------- main ---------------------------------------------
#$1 = TEST_DIR

# ------------------------------------------------------------------------------
CC=gcc #TODO make building in download script

pouttnum=0 #passed out tests number
perrtnum=0 #passed error tests number

fouttnum=0 #failed out tests number
ferrtnum=0 #failed error tests number
foutlist=""
ferrlist=""

filt_defined=false

vg_lib=~/git/valgrind/vg_builded/usr/local/lib/valgrind
vg=~/git/valgrind/vg_builded/usr/local/bin/valgrind

for tool in memcheck;do  #TODO add tools
  test_one_dir ../$tool
done

printf "______________________________________________\n"
printf "Passed: stdout = $pouttnum, stderr = $perrtnum\n\n"
printf "Failed: stdout = $fouttnum, stderr = $ferrtnum\n\n"
printf "Failed stdout list:$foutlist\n"
printf "Failed stderr list:$ferrlist\n"
