#!/bin/bash
# 遍历../ROB_stall_result文件夹中的文件名

for file in ../ROB_stall_result/*
do
	# 提取文件名
	filename=${file##*/}
	echo $filename
	echo "python bin_analysis.py -f $filename" >> batch_cmd.txt
done

# 并行执行
cat batch_cmd.txt | xargs -P 40 -I {} sh -c {}