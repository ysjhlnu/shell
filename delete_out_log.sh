#!/bin/bash
#by tansi
# 2020.2.6
# delete erc20.out file

OUT_LOG=/opt/delete_nohup.log
PATH=/opt
FILE_NAME=yy

# 判断文件所在目录是否存在
if [ -d "$PATH" ];then
	cd "$PATH"
	
	# 判断文件是否存在
	if [ -f "$FILE_NAME" ];then
		size=`/usr/bin/du -h "$FILE_NAME" | /usr/bin/awk '{print $1}' | /usr/bin/cut -d "G" -f 1`
		echo `/usr/bin/date +%F_%T`----"$FILE_NAME"----"$size" >> "$OUT_LOG"
		
		# 判断当前文件大小单位是G还是M
		judge=`echo $size| /usr/bin/awk '{print($0~/^[-]?([0-9])+[.]?([0-9])+$/)?"number":"string"}'`
		
		# 文件大小是G
		if [ $judge == "number" ];then
			
			# 判断文件大小是否超出5G
			flag=`echo "$size > 4" | /usr/bin/bc`
			
			# 文件大小超出5G
			if [ "$flag" -eq 1 ];then
			#	echo "1" >> test.txt
				/usr/bin/cat /dev/null > "$FILE_NAME"
			fi
			
			new_size=`/usr/bin/du -h "$FILE_NAME" | /usr/bin/awk '{print $1}' | /usr/bin/cut -d "G" -f 1`
			echo `/usr/bin/date +%F_%T`---"$FILE_NAME"---"$new_size" >> "$OUT_LOG"
		fi
	
	fi
fi

