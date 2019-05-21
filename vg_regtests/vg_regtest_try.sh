#! /bin/sh

die() { echo "$*" 1>&2 ; exit 1; }

#----------------------------------------------------------------------------
# Process command line, setup
#----------------------------------------------------------------------------

# If $prog is a relative path, it prepends $dir to it.  Useful for two reasons:
#
# 1. Can prepend "." onto programs to avoid trouble with users who don't have
#    "." in their path (by making $dir = ".")
# 2. Can prepend the current dir to make the command absolute to avoid
#    subsequent trouble when we change directories.
#
# Also checks the program exists and is executable.
validate_program (){
    dir=$1
    prog=$2
    must_exist=$3
    must_be_executable=$4

    # If absolute path, leave it alone.  If relative, make it
    # absolute -- by prepending current dir -- so we can change
    # dirs and still use it.
    if [ $(echo $prog | cut -c 1) = "/" ]; then $prog = "$dir/$prog"; fi

    if [ $must_exist ]; then
        if [ ! -f $prog ]; then
          die "vg_regtest: $prog not found or not a file ($dir)\n";
        fi
    fi

    if [ $must_be_executable ]; then
        if [ ! -x $prog ];then
          die "vg_regtest: $prog not executable ($dir)\n";
        fi
    fi

    return $prog;
}

#----------------------------------------------------------------------------
# Read a .vgtest file
#----------------------------------------------------------------------------
read_vgtest_file($)
{
    my ($f) = @_;

    # Defaults.
    ($vgopts, $prog, $args)            = ("", undef, "");
    ($stdout_filter, $stderr_filter)   = (undef, undef);
    ($progB, $argsB, $stdinB)          = (undef, "", undef);
    ($stdoutB_filter, $stderrB_filter) = (undef, undef);
    ($prereq, $post, $cleanup)         = (undef, undef, undef);
    ($stdout_filter_args, $stderr_filter_args)   = (undef, undef);
    ($stdoutB_filter_args, $stderrB_filter_args) = (undef, undef);

    # Every test directory must have a "filter_stderr"
    $stderr_filter = validate_program(".", $default_stderr_filter, 1, 1);
    $stderrB_filter = validate_program(".", $default_stderr_filter, 1, 1);


    open(INPUTFILE, "< $f") || die "File $f not openable\n";

    while (my $line = <INPUTFILE>) {
      if ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
      next;
      } elsif ($line =~ /^\s*vgopts:\s*(.*)$/) {
          my $addvgopts = $1;
          $addvgopts =~ s/\$\{PWD\}/$ENV{PWD}/g;
          $vgopts = $vgopts . " " . $addvgopts;   # Nb: Make sure there's a space!
      } elsif ($line =~ /^\s*prog:\s*(.*)$/) {
          $prog = validate_program(".", $1, 0, 0);
      } elsif ($line =~ /^\s*prog-asis:\s*(.*)$/) {
          $prog = $1;
      } elsif ($line =~ /^\s*args:\s*(.*)$/) {
          $args = $1;
      } elsif ($line =~ /^\s*stdout_filter:\s*(.*)$/) {
          $stdout_filter = validate_program(".", $1, 1, 1);
      } elsif ($line =~ /^\s*stderr_filter:\s*(.*)$/) {
          $stderr_filter = validate_program(".", $1, 1, 1);
      } elsif ($line =~ /^\s*stdout_filter_args:\s*(.*)$/) {
          $stdout_filter_args = $1;
      } elsif ($line =~ /^\s*stderr_filter_args:\s*(.*)$/) {
          $stderr_filter_args = $1;
      } elsif ($line =~ /^\s*progB:\s*(.*)$/) {
          $progB = validate_program(".", $1, 0, 0);
      } elsif ($line =~ /^\s*argsB:\s*(.*)$/) {
          $argsB = $1;
      } elsif ($line =~ /^\s*stdinB:\s*(.*)$/) {
          $stdinB = $1;
      } elsif ($line =~ /^\s*stdoutB_filter:\s*(.*)$/) {
          $stdoutB_filter = validate_program(".", $1, 1, 1);
      } elsif ($line =~ /^\s*stderrB_filter:\s*(.*)$/) {
          $stderrB_filter = validate_program(".", $1, 1, 1);
      } elsif ($line =~ /^\s*stdoutB_filter_args:\s*(.*)$/) {
          $stdoutB_filter_args = $1;
      } elsif ($line =~ /^\s*stderrB_filter_args:\s*(.*)$/) {
          $stderrB_filter_args = $1;
      } elsif ($line =~ /^\s*prereq:\s*(.*)$/) {
          $prereq = $1;
      } elsif ($line =~ /^\s*post:\s*(.*)$/) {
          $post = $1;
      } elsif ($line =~ /^\s*cleanup:\s*(.*)$/) {
          $cleanup = $1;
      } elsif ($line =~ /^\s*env:\s*(.*)$/) {
          push @env,$1;
      } elsif ($line =~ /^\s*envB:\s*(.*)$/) {
          push @envB,$1;
      } else {
          die "Bad line in $f: $line\n";
      }
    }
    close(INPUTFILE);

    if (!defined $prog) {
        $prog = "";     # allow no prog for testing error and --help cases
    }
}


#$1 - test name
do_one_test(){
  tname=$1
  printf "________________\ndo $tname test...\n"


  is_exp_out=false;
  if [ -f $tname.stdout.exp ];then
    exp_out=$(cat $tname.stdout.exp);
    is_exp_out=true;
  fi

  is_exp_err=false;
  if [ -f $tname.stderr.exp ];then
    exp_err=$(cat $tname.stderr.exp);
    is_exp_err=true;
  fi

  printf "is_exp_out = $is_exp_out\n"
  printf "is_exp_err = $is_exp_err\n"


  $CC -o $tname $tname.c


  valgrind ./$tname 2>$tname.stderr.res 1>$tname.stdout.res

  diff -u $tname.stderr.exp $tname.stderr.res > $tname.stderr.diff
  diff -u $tname.stdout.exp $tname.stdout.res > $tname.stdout.diff


  rm $tname $tname.*.res $tname.*.diff



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

export PATH=$PATH:/home/dyu/git/vg_builded/usr/local/bin
export VALGRIND_LIB=/home/dyu/git/vg_builded/usr/local/lib/valgrind

cd $TEST_DIR

for tool in memcheck  #TODO add tools
do
  test_one_dir $tool
done
