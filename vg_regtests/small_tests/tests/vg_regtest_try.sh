#! /bin/sh

die(){
  echo "$*" 1>&2 ;
  exit 1;
}
#---------------------------- filters ------------------------------------------
default_filter(){
  sed -i 's/==.*== //g' $1
  sed -i '/Memcheck, a memory.*$/d' $1
  sed -i '/Copyright (C).*$/d' $1
  sed -i '/Using Valgrind.*$/d' $1
  sed -i '/Command: .*$/d' $1

  ns="\([0-9]\+\)" #ns - numbers sequence
  sed -i "s/.c:$ns)/.c:\.\.\.)/g" $1 # delete links to code

}

# check_filter_defined(){
#   if [ $1 ];then
#     for dfilter in $(ls $FILT_DIR | grep '^filter')
#     do
#       if [ "z_$dfilter" = "z_$1" ]; then filt_defined=true; fi
#     done
#   else
#     filt_defined=true
#   fi
# }


# --------------------------- main part ----------------------------------------
#$1 - test name
do_one_test(){
  tname=$1
  pref=$2
  printf "________________\ndo $pref/$tname test...\n"

  # --------------------- check test files -------------------------------------
  if [ -f $pref/$tname.stdout.exp ];then
    printf "exp out exist\n"
    exp_out=$(cat $pref/$tname.stdout.exp);
  fi

  if [ -f $pref/$tname.stderr.exp ];then
    printf "exp_err exist\n"
    exp_err=$(cat $pref/$tname.stderr.exp);
  fi

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


  # check_filter_defined $stdout_filter;
  # if [ $filt_defined != true ];then die "out filter '$stdout_filter' undef in '$tname'"; fi
  # filt_defined=false;

  # check_filter_defined $stderr_filter;
  # if [ $filt_defined != true ];then die "err filter '$stderr_filter' undef in '$tname'"; fi
  # filt_defined=false;


  # --------------------- do test ----------------------------------------------
  printf "$CC -o $pref/$tname $pref/$tname.c... "
  $CC -o $pref/$tname $pref/$tname.c
  printf "done\n"

  if [ -f $pref/$tname.stdout.exp ] && [ -f $pref/$tname.stderr.exp ]; then
    valgrind $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stdout.exp ];then
    valgrind $vgopts $pref/$tname 2>/dev/null 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stderr.exp ];then
    valgrind $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>/dev/null
  else
    die "no exp_out or exp_err files, exiting...\n"
  fi

  if [ -f $pref/$tname.stdout.exp ]; then
    # default_filter $tname.stdout.res
    old_addr=$(pwd)
    cd $pref
    if [ -f $stdout_filter ]; then $stdout_filter $tname.stdout.res; fi
    diff -u $tname.stdout.exp $tname.stdout.res > $tname.stdout.diff
    cd $old_addr
  fi

  if [ -f $pref/$tname.stderr.exp ]; then
    # default_filter $pref/$tname.stderr.res
    old_addr=$(pwd)
    cd $pref
    if [ -f $stdout_filter ]; then $stdout_filter $tname.stderr.res; fi
    if [ -f $stderr_filter ]; then $stderr_filter $tname.stderr.res; fi
    diff -u $tname.stderr.exp $tname.stderr.res > $tname.stderr.diff
    cd $old_addr
  fi

  if [ -f $tname.stderr.diff ];then
    if [ ! -s $tname.stderr.diff ]; then
      perrtnum=$((perrtnum+1));
    else
      ferrtnum=$((ferrtnum+1));
      ferrlist="$ferrlist $tname, "
    fi
  fi

  if [ ! -f $tname.stdout.diff ];then
    if [ ! -s $tname.stdout.diff ]; then
      pouttnum=$((pouttnum+1));
    else
      fouttnum=$((fouttnum+1));
      foutlist="$foutlist $tname, "
    fi
  fi

  # --------------------- rm out files -----------------------------------------
  #rm $tname $tname.*.res $tname.*.diff
  rm $tname $tname.*.diff


}

# --------------------------- find tested dir ----------------------------------
#$1 - dir
test_one_dir(){
  pref=$1

  printf "dir = $pref\n"

  for f in $(ls $pref/ -l | awk '{ print $9 }')
  do
    if [ -d $pref/$f ]; then
      test_one_dir $pref/$f
    else
      if [ $(echo $f | tail -c 3) = ".c" ];then
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

export PATH=$PATH:/home/dyu/git/vg_builded/usr/local/bin
export VALGRIND_LIB=/home/dyu/git/vg_builded/usr/local/lib/valgrind

for tool in memcheck  #TODO add tools
do
  test_one_dir ../$tool
done

printf "______________________________________________\n"
printf "Passed: stdout = $pouttnum, stderr = $perrtnum\n\n"
printf "Failed: stdout = $fouttnum, stderr = $ferrtnum\n\n"
printf "Failed stdout list:$foutlist\n"
printf "Failed stderr list:$ferrlist\n"
