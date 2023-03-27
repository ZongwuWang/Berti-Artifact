##########################################################################
# File Name: test.sh
# Author: Wang Zongwu
# mail: wangzongwu@outlook.com
# Created Time: Tue 28 Feb 2023 08:00:21 PM CST
# Description: 
#########################################################################
#!/bin/bash
if [ x$2 != 'x' ];
then
	l1d_pref=$2
else
	l1d_pref="no"
fi
echo ${l1d_pref}

if [ x$1 == "xbuild" ];
then
	echo "Start building"
	./build_champsim.sh hashed_perceptron no ${l1d_pref} no no no no no lru lru lru srrip drrip lru lru lru 1 no
fi
if [ x$1 == "xrun" ];
then
	echo "Start running"
	./run_champsim.sh hashed_perceptron-no-${l1d_pref}-no-no-no-no-no-lru-lru-lru-srrip-drrip-lru-lru-lru-1core-no 1 10 600.perlbench_s-210B.champsimtrace.xz
fi
