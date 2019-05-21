#! /bin/bash



#$1 = checked dir
pull_check(){
cd $1

if [[ $(ls -l | grep ^d) ]]; then
  for next_dir in $(ls -l | grep ^d | awk '{ print $9 }')
  do
    if [[ $next_dir == $PULLED_PATTERN ]]; then
      printf "test found in $1\n\n"
      printf "cp -r $next_dir to $PATH_TO_TEST_DIR/$1...\n\n"

      cp -r $next_dir $PATH_TO_TEST_DIR/$1

      printf "__________________________________________\n"
    else
      pull_check $next_dir
    fi
  done

fi

cd ..
}


# --------------------------- main ---------------------------------------------
#
#$1 = PATH_TO_VG
#$2 = PATH_TO_TEST_DIR
#
# ------------------------------------------------------------------------------
CUR_DIR=$(pwd)

PATH_TO_VG=$1
PATH_TO_TEST_DIR=$CUR_DIR/$2

PULLED_PATTERN='tests'


pull_check $PATH_TO_VG
