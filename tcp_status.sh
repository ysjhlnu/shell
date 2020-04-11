# 2019/12/28 by tansi
# tcp status
tmp_file=/tmp/tcp_status.txt
/usr/sbin/ss -an | awk '/^tcp/{s[$2]++} END{for(i in s) {print i,s[i]}}' >${tmp_file}

case $1 in
        estab)
        output=$(awk '/ESTAB/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        closing)
        output=$(awk '/CLOSING/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        listen)
        output=$(awk '/LISTEN/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        Syn-sent)
        output=$(awk '/SYN-SENT/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        syn-recv)
        output=$(awk '/SYN-RECV/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        fin-wait1)
        output=$(awk '/FIN-WAIT-1/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        fin-wait2)
        output=$(awk '/FIN-WAIT-2/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        time-wait)
        output=$(awk '/TIME_WAIT/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        close-wait)
        output=$(awk '/CLOSE-WAIT/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        unconn)
        output=$(awk '/UNCONN/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        last-ack)
        output=$(awk '/LAST-ACK/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        closed)
        output=$(awk '/CLOSED/{print $2}' ${tmp_file})
        if [ "${output}" == "" ];then
                echo 0
        else
                echo ${output}
        fi
        ;;
        *)
        echo -e "\e[033mUsage: sh $0 [estab|closing|listen|Syn_sent|syn-recv|closed|last-ack|unconn|close-wait|time-wait|fin-wait2|fin-wait1]\e[0m"
esac

