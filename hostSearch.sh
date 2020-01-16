#!/bin/bash
###################################################
#        局域网IP探测
# 以下信息必须配置：
#   1、ip_prefix
#   
#  
# 结果文件为当前目录下的result.txt
#      free开头的指ping不通的，used指ping通的
#
#
# 后续：
#     支持多局域网，即 ip_prefix 可配置多个
#     支持检测某一段IP，如第四段IP的 55~198 网段
###################################################


## 配置信息，配置程序参数

# ip前三段地址，后续可以写成配置之类的，结合您所在局域网的地址设置此值
ip_prefix=10.204.145

# ping次数
ping_times=1

# 超时时间
time_out=3

# 并行度，即分成多少组同时探测，加快探测速度
parall=60




## 探测函数
function search(){

  # ip第四段地址起始地址
  index=$1

  # ip第四段地址截至地址
  end=$2

  while [ $index -le ${end} ]
  do
    ip=${ip_prefix}.${index}
    success_times=`ping -c ${ping_times} -w ${time_out} ${ip}|grep transmitted|awk -F ',' '{print $2}'|awk '{print $1}'`
    if [ ${success_times} -eq ${ping_times} ]
    then
       echo "used "${ip}>>ip.txt
    else
       echo "free "${ip}>>ip.txt
    fi
    index=`expr ${index} + 1`
  done
}


# 先删除旧的中间结果ip.txt文件
rm -f ip.txt

## 根据设定值划分探测组，调用探测函数
## 命令结尾加 &,使多个命令并行进行，然后wait防止主线程退出
function group(){
  length=$1
  parall=$2
  binSize=`expr ${length} / ${parall}`
  if [ ${binSize} -lt $((${length} % ${parall})) ]
  then
    group ${length} $((parall - 1))
    return
  fi
  if [ `expr ${length} % ${parall}` -eq 0 ]
  then
    i=0
    while [ ${i} -lt ${parall} ]
    do
       search $((${i} * ${binSize}+1)) $((${i} * ${binSize} +  ${binSize})) &
       i=`expr ${i} + 1`
    done
  else
    i=0
    while [ ${i} -lt ${parall} ]
    do
       search $((${i} * ${binSize}+1)) $((${i} * ${binSize} +  ${binSize})) &
       i=`expr ${i} + 1`
    done
    search $((${parall} * ${binSize})) ${length} &
  fi
}

length=254
group ${length} ${parall}

# 防止主进程退出
wait

# 结果修正，去重
cat ip.txt|sort|uniq>result.txt
# 删除中间结果ip.txt，这里先保留吧
#rm -f ip.txt
