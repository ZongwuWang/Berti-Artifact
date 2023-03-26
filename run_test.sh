#!/bin/bash

#
# Run the Berti's artifact
#
# @Author: Navarro Torres, Agustín
# @Date: 25/07/2022
#

################################################################################
#                            Configuration Vars                              #
################################################################################
VERBOSE=""
PARALLEL=""
GCC="N"
NUM_THREAD="1"
DOCKER="N"
REMOVE_ALL="N"
LOGGED="N"
DOWNLOAD="N"
BUILD="Y"
FULL="N"
MULTI="N"

################################################################################
#                                Global Vars                                 #
################################################################################

CONTAINER="docker"
DIR=$(pwd)
BERTI="./ChampSim/Berti"
PF="./ChampSim/Other_PF"
BERTI=$PF
TRACES_SPEC="traces/spec2k17"
TRACES_GAP="traces/gap"
TRACES_CS="traces/cs"
OUT_BASE="output"
OUT="output"
LOG=$(pwd)/stderr.log

################################################################################
#                                Terminal Colors                             #
################################################################################

# Terminal colors
GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'

################################################################################
#                           Auxiliary functions                              #
################################################################################
run_command () 
{
    # Run command 
    if [[ "$VERBOSE" == "Y" ]]; then
        # Without stdout/stderr redirect
        $1
    elif [[ "$LOGGED" == "Y" ]]; then
        # Log
        $1 >> $LOG 2>&1
    else
        # With stdout/stderr redirect
        $1 >/dev/null 2>&1
    fi
    
    # Command error
    if [ $? -ne 0 ]; then
        echo " ${RED}ERROR${NC}"
        exit
    fi
    echo " ${GREEN}done${NC}"
}

file_trace () 
{
    # Generate temporal files to run simulations in parallel
    for i in $2/*;
    do
        trace=$(echo $i | rev | cut -d'/' -f1 | rev)
        if [[ "$LOGGED" == "Y" ]]; then
            echo -n "$1 -warmup_instructions 50000000 -simulation_instructions"
            echo " 200000000 -traces $i > $OUT/$3---$trace 2>>$LOG"
        else
            echo -n "$1 -warmup_instructions 50000000 -simulation_instructions"
            echo " 200000000 -traces $i > $OUT/$3---$trace 2>/dev/null"
        fi
    done
}

file_4core_trace () 
{
    idx=0
    >&2 echo $1
    # Generate temporal files to run simulations in parallel
    while read -r line
    do
        trace="$trace $line"
        if [[ ! -z $line ]]; then
            continue
        fi

        if [[ "$LOGGED" == "Y" ]]; then
            echo -n "$1 -warmup_instructions 50000000 -simulation_instructions"
            echo " 200000000 -traces $trace > $OUT/$3.out---$idx.out 2>>$LOG"
        else
            echo -n "$1 -warmup_instructions 50000000 -simulation_instructions"
            echo " 200000000 -traces $trace > $OUT/$3.out---$idx.out 2>/dev/null"
        fi
        idx=$(($idx + 1))
        trace=""
    done < $2
}

run_compile ()
{
    # Build ChampSim with the given prefetcher
    if [[ "$GCC" == "Y" ]]; then
        # Use GCC building from scratch
        run_command "$1 $CCX"
    elif [[ "$DOCKER" == "Y" ]]; then
        # Use Docker GCC
        if [[ "$VERBOSE" == "Y" ]]; then
            if ! command -v getenforce &> /dev/null
            then
                # System without SELinux
                $CONTAINER run -it -v$(pwd):/mnt --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1"
            else
                # System wit SELinux
                $CONTAINER run -it -v$(pwd):/mnt:Z --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1"
            fi
        elif [[ "$LOGGED" == "Y" ]]; then
            if ! command -v getenforce &> /dev/null
            then
                # System without SELinux
                $CONTAINER run -it -v$(pwd):/mnt --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1" >> $LOG 2>&1
            else
                # System with SELinux
                $CONTAINER run -it -v$(pwd):/mnt:Z --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1" >> $LOG 2>&1
            fi
        else
            if ! command -v getenforce &> /dev/null
            then
                # System without SELinux
                $CONTAINER run -it -v$(pwd):/mnt --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1" > /dev/null 2>&1
            else
                # System with SELinux
                $CONTAINER run -it -v$(pwd):/mnt:Z --rm gcc:7.5.0 /bin/bash -c "cd mnt; $1" > /dev/null 2>&1
            fi
        fi
        if [ $? -ne 0 ]; then
            echo " ${RED}ERROR${NC}"
            exit
        fi
        echo " ${GREEN}done${NC}"
    else
        # Use system GCC
        run_command "$1"
    fi
}

print_help ()
{
    echo "Run Berti Artificat"
    echo "Options: "
    echo " -h: help"
    echo " -v: verbose mode"
    echo " -p [num]: run using [num] threads"
    echo " -g: build GCC7.5 from scratch"
    echo " -d: compile with docker" 
    echo " -c: clean all generated files (traces and gcc7.5)" 
    echo " -l: generate a log for debug purpose" 
    echo " -r: always download SPEC CPU2K17 traces" 
    echo " -n: no build the simulator" 
    echo " -f: execute GAP, CloudSuite, and Multi-Level prefetcher" 
    echo " -m: execute 4-Core" 
    exit
}
################################################################################
#                                Parse Options                               #
################################################################################

while getopts :mfvlrcdhngp: opt; do
    case "${opt}" in
          v) VERBOSE="Y"
              echo -e "\033[1mVerbose Mode\033[0m"
              ;;
          l) LOGGED="Y"
              echo -e "\033[1mLog Mode\033[0m"
              echo -n "" > $LOG
              ;;
          g) GCC="Y"
              echo -e "\033[1mDownloading and Building with GCC 7.5\033[0m"
              ;;
          p) PARALLEL="Y"
              NUM_THREAD=${OPTARG}
              echo -e "\033[1mRunning in Parallel\033[0m"
              ;;
          d) DOCKER="Y"
              echo -e "\033[1mBuilding with Docker\033[0m"
              ;;
          c) REMOVE_ALL="Y"
              echo -e "\033[1m${RED}REMOVING ALL TEMPORAL FILES (traces and gcc7.5)${NC}\033[0m"
              ;;
          r) DOWNLOAD="Y"
              echo -e "\033[1mAlways download SPEC CPU2K17 traces\033[0m"
              ;;
          n) BUILD="N"
              echo -e "\033[1mNOT build the simulator\033[0m"
              ;;
          f) FULL="Y"
              echo -e "\033[1mFull execution\033[0m"
              ;;
          m) MULTI="Y"
              echo -e "\033[1mMulti-Core execution\033[0m"
              ;;
          h) print_help;;
     esac
done

################################################################################
#                                Scripts Body                                #
################################################################################

# Just in case, fix execution permission
chmod +x Python/*.py
chmod +x *.sh
chmod +x ChampSim/Berti/*.sh
chmod +x ChampSim/Other_PF/*.sh
    
echo ""

# Build GCC 7.5.0 from scratch
if [[ "$GCC" == "Y" ]]; then
    echo -n "Building GCC 7.5 from scratch..."

    if [[ "$VERBOSE" == "Y" ]]; then
        ./compile_gcc.sh $PARALLEL $NUM_THREAD
    elif [[ "$LOGGED" == "Y" ]]; then
        ./compile_gcc.sh $PARALLEL $NUM_THREAD >> $LOG 2>&1
    else
        ./compile_gcc.sh $PARALLEL $NUM_THREAD >/dev/null 2>&1
    fi

    echo " ${GREEN}done${NC}"
    CCX=$(pwd)/gcc7.5/gcc-7.5.0/bin/bin/g++
fi

#----------------------------------------------------------------------------#
#                            Download SPEC2K17 Traces                        #
#----------------------------------------------------------------------------#


if [[ "$LOGGED" == "Y" ]]; then
    echo "DOWNLOAD TRACES" >> $LOG
    echo "============================================================" >> $LOG
fi

if [ ! -d "$TRACES_SPEC" ] || [ "$DOWNLOAD" == "Y" ]; then
    ./download_spec2k17.sh $TRACES_SPEC
fi

#----------------------------------------------------------------------------#
#                                Build ChampSim                              #
#----------------------------------------------------------------------------#
if [[ "$BUILD" == "Y" ]]; then
    if [[ "$LOGGED" == "Y" ]]; then
        echo "Building" >> $LOG
        echo "============================================================" >> $LOG
    fi

    echo -n "Building Berti..."
    cd $BERTI
    run_compile "./build_champsim.sh hashed_perceptron no no no no no no no\
            lru lru lru srrip drrip lru lru lru 1 no"
    cd $DIR
    
fi

#----------------------------------------------------------------------------#
#                                Running Simulations                         #
#----------------------------------------------------------------------------#
mkdir $OUT > /dev/null 2>&1

if [[ "$LOGGED" == "Y" ]]; then
    echo "RUNNING" >> $LOG
    echo "============================================================" >> $LOG
fi

# Prepare to run in parallel
echo -n "Making everything ready to run..."

echo -n "" > tmp_par.out

for i in $(ls $BERTI/bin/*1core*); do
    if [[ "$LOGGED" == "Y" ]]; then
        echo "$BERTI/bin/$i" >> $LOG
        strings -a $BERTI/bin/$i | grep "GCC: " >> $LOG 2>&1
    fi
    name=$(echo $i | rev | cut -d/ -f1 | rev)

    OUT=$OUT_BASE/spec2k17
    aux=$i
    mkdir $OUT > /dev/null 2>&1
    file_trace $i $TRACES_SPEC $name >> tmp_par.out

    if [[ "$FULL" == "Y" ]]; then
        OUT=$OUT_BASE/gap
        mkdir $OUT > /dev/null 2>&1
        file_trace $aux $TRACES_GAP $name >> tmp_par.out
        OUT=$OUT_BASE/cloudsuite
        mkdir $OUT > /dev/null 2>&1
        file_trace $aux $TRACES_CS $name >> tmp_par.out
    fi
done


# Run in parallel

if [[ "$MULTI" == "Y" ]]; then
    for i in $(ls $BERTI/bin/*4core*); do
        if [[ "$LOGGED" == "Y" ]]; then
            echo "$i" >> $LOG
            strings -a $BERTI/bin/$i | grep "GCC: " >> $LOG 2>&1
        fi
        name=$(echo $i | rev | cut -d/ -f1 | rev)
    
        OUT=$OUT_BASE/4core
        mkdir $OUT > /dev/null 2>&1
        file_4core_trace $i 4core.in $name >> tmp_par.out
    done
    
    for i in $(ls $PF/bin/*4core*); do
        if [[ "$LOGGED" == "Y" ]]; then
            echo "$i" >> $LOG
            strings -a $PF/bin/$i | grep "GCC: " >> $LOG 2>&1
        fi
        name=$(echo $i | rev | cut -d/ -f1 | rev)
    
        OUT=$OUT_BASE/4core
        mkdir $OUT > /dev/null 2>&1
        file_4core_trace $i 4core.in 4core >> tmp_par.out
    done
    
fi
echo " ${GREEN}done${NC}"

echo -n "Running..."
cat tmp_par.out | xargs -I CMD -P $NUM_THREAD bash -c CMD
echo " ${GREEN}done${NC}"
