#! /bin/sh

die(){
  printf "$*" 1>&2 ;
  exit 1;
}

# --------------------------- main part ----------------------------------------
#$1 - test name
do_one_test(){
  tname=$1
  pref=$2
  printf "\n-------------------------\ndo $pref/$tname test...\n\n"

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


  # --------------------- call valgrind on test binary -------------------------

  if [ -f $pref/$tname.stdout.exp ] && [ -f $pref/$tname.stderr.exp ]; then
    printf "$pref/$tname.stdout.exp exist\n"
    printf "$pref/$tname.stderr.exp exist\n"
    exp_out=$(cat $pref/$tname.stdout.exp);
    exp_err=$(cat $pref/$tname.stderr.exp);
    printf "VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname\n"
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stdout.exp ];then
    printf "$pref/$tname.stdout.exp exist\n"
    exp_out=$(cat $pref/$tname.stdout.exp);
    printf "VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname\n"
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>/dev/null 1>$pref/$tname.stdout.res
  elif [ -f $pref/$tname.stderr.exp ];then
    printf "$pref/$tname.stderr.exp exist\n"
    exp_err=$(cat $pref/$tname.stderr.exp);
    printf "VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname\n"
    VALGRIND_LIB=$vg_lib $vg $vgopts $pref/$tname 2>$pref/$tname.stderr.res 1>/dev/null
  else
    printf "no exp_out or exp_err files, exiting...\n"
  fi
  vg_excode=$?
  printf "valgrind instrumentation done\n"

  # ----------------------- check results of instrumentation --------------------
  if [ $vg_excode = 0 ];then
    printf "vg exiting code is okay = $vg_excode\n"

    # --------------------- diff stdout files ------------------------------------
    if [ -f $pref/$tname.stdout.exp ]; then
      old_addr=$(pwd) # neccesary cause vg filters use relative path
      cd $pref
      if [ -f $stdout_filter ] && [ "$stdout_filter" != "" ]; then
        printf "call $stdout_filter\n"
        cat $tname.stdout.res | ./$stdout_filter $tname.stdout.res > $tname.stdout.filt
      elif [ ! -f $stdout_filter ]; then die "filter $stdout_filter does't exist\n"; fi
      diff $tname.stdout.exp $tname.stdout.filt > $tname.stdout.diff
      cd $old_addr
    fi
    # -------------------- check stdout diff -------------------------------------
    if [ -f $pref/$tname.stdout.diff ];then
      if [ ! -s $pref/$tname.stdout.diff ]; then
        pouttnum=$((pouttnum+1));
        pouttlist="$pouttlist $tname, "
        rm $pref/$tname.stdout.diff
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
        cat $tname.stderr.res | ./$stderr_filter $tname.stderr.res > $tname.stderr.filt
      elif [ ! -f $stderr_filter ]; then die "filter $stderr_filter does't exist\n"; fi
      diff $tname.stderr.exp $tname.stderr.filt > $tname.stderr.diff
      cd $old_addr
    fi
    # -------------------- check stderr diff -------------------------------------
    if [ -f $pref/$tname.stderr.diff ];then
      if [ ! -s $pref/$tname.stderr.diff ]; then
        perrtnum=$((perrtnum+1));
        perrlist="$perrlist $tname, "
        rm $pref/$tname.stderr.diff
      else
        ferrtnum=$((ferrtnum+1));
        ferrlist="$ferrlist $tname, "
      fi
    fi

  else
    printf "vg instrumentation failed with unexpected exiting code = $vg_excode\n";
    finstnum=$((finstnum+1));
    finstlist="$finstlist $tname, "
  fi


  # --------------------- rm out files -----------------------------------------
  # rm $pref/$tname $pref/$tname.*.res $pref/$tname.*.diff 2>/dev/null
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
    if [ -d $pref/$f ] && [ $f != '.' ] && [ $f != '..' ]; then
      # test_one_dir $pref/$f
      printf "dir $pref/$f founded\n"
    else
      if [ $(echo $f | cut -d . -f2) = "vgtest" ];then
        tname=$(cat $pref/$f | grep 'prog:' | sed -e 's/prog: //' -e 's/ //g' )
        do_one_test $tname $pref
      fi
    fi
  done

}

# --------------------------- main ---------------------------------------------
# $1 - PATH FOR LOG FILE
# ------------------------------------------------------------------------------

#--------------------------- parsing arguments ---------------------------------

LOG_FILE=""
ARCH=""
TOOLS=memcheck
while getopts "l:a:t:" opt; do
    case "$opt" in
    l)
        LOG_FILE=$OPTARG
        ;;
    a)  ARCH=$OPTARG
        ;;
    t)  TOOLS=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [[ $LOG_FILE = "" ]];then die "option -l (LOG_FILE) wasn't passed, exiting...\n";else printf "LOG_FILE = $LOG_FILE\n";fi
if [[ $ARCH = ""  ]];then die "option -a (ARCH) wasn't passed , exiting...\n";else printf "ARCH = $ARCH\n";fi
printf "TOOLS = $TOOLS\n"

# ---------------------------- variables ---------------------------------------
pouttnum=0 #passed out tests number
pouttlist=""

perrtnum=0 #passed error tests number
perrlist=""

fouttnum=0 #failed out tests number
foutlist=""

ferrtnum=0 #failed error tests number
ferrlist=""

finstnum=0 # failed while instrumentation
finstlist=""


def_locat=$(pwd)
cd $(dirname $0)


vg_lib=/opt/valgrind/$ARCH/usr/lib/valgrind
vg=/opt/valgrind/$ARCH/usr/bin/valgrind

ln -sP /lib/libc.so.3 /proc/boot/libc.so.3

for tool in $TOOLS;do  #TODO add tools
  test_one_dir ../$tool/tests
done

cd $def_locat

printf "\n--------------------- tests finished ------------------------------\n" 1 > $LOG_FILE
printf "Passed: stdout = $pouttnum, stderr = $perrtnum\n\n" 1 >> $LOG_FILE
printf "Passed stdout list:$pouttlist\n" 1 >> $LOG_FILE
printf "Passed stderr list:$perrlist\n" 1 >> $LOG_FILE

printf "\n----------------------------------------\n" 1 >> $LOG_FILE

printf "Failed: stdout = $fouttnum, stderr = $ferrtnum\n\n" 1 >> $LOG_FILE
printf "Failed stdout list:$foutlist\n" 1 >> $LOG_FILE
printf "Failed stderr list:$ferrlist\n" 1 >> $LOG_FILE

printf "\n----------------------------------------\n" 1 >> $LOG_FILE

printf "Failed while instrumentation num  = $finstnum\n" 1 >> $LOG_FILE
printf "Failed while instrumentation list = $finstlist\n"  1 >> $LOG_FILE
