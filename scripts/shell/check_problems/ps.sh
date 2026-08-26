#!/bin/bash

if [ -n "$1" ]; then 
	if [ "$1" == "co" ]; then
		tail - fn 1000 logs/core-app/core-app-default.log
	elif  [ "$1" == "-l" ]; then
		logpath=$(grep validateLogFilePath ../scripts/start.py |head -n 1 )
		appname=$(grep  app.name  config/application.properties | sed 's/app.name=//' | sed 's/#//g'  |head -n 1 )
		hostname=$(hostname)
		logpath1=${logpath#*\'}
		logpath2=${logpath1%\'*}
		logpath3=`echo $logpath2 |sed 's/App/Biz/g'`
		logpath4=`echo $logpath2 |sed 's/App/Dao/g'`
		if [ -n "$2" ]; then
			if [ "$2" == "0" ]; then
				cd logs/${appname}
			elif [ "$2" == "1" ]; then
				if [  -f ${logpath3} ];then
					tail -fn 1000 ${logpath3}
				else
					tail -fn 1000 logs/${appname}/${hostname}-${appname}-Biz.log
				fi
			elif [ "$2" == "2" ]; then
				if [  -f ${logpath4} ];then
					tail -fn 1000 ${logpath4}
				else
					tail -fn 1000 logs/${appname}/${hostname}-${appname}-Dao.log
				fi
			fi
		else
			cd logs/${appname} && ll
			
		fi
	elif  [ "$1" == "-e" ]; then
		logpath=$(grep validateLogFilePath ../scripts/start.py |head -n 1 )
		appname=$(grep  app.name  config/application.properties | sed 's/app.name=//' | sed 's/#//g'  |head -n 1 )
		hostname=$(hostname)
		logpath1=${logpath#*\'}
		logpath2=${logpath1%\'*}
		logpath3=`echo $logpath2 |sed 's/App/Biz/g'`
		logpath4=`echo $logpath2 |sed 's/App/Dao/g'`
		if [  -f ${logpath3} ];then
			tac ${logpath3} | grep -100 -m 1 "Exception:"
		else
			tac logs/${appname}/${hostname}-${appname}-Biz.log | grep -100 -m 1 "Exception:"
		fi
	elif  [ "$1" == "-p" ]; then
		netstat -apn|grep $pid
	elif  [ "$1" == "-lib" ]; then
		cp  -v /home/lib/jreslog-1.0-SNAPSHOT.jar  appUnzip/WEB-INF/lib/
	elif  [ "$1" == "-doff" ]; then
		sed -i 's/fs.common.logconfig.custom.dao.enable=true/fs.common.logconfig.custom.dao.enable=false/' config/log4j2.config.properties 
                grep  "fs.common.logconfig.custom.dao.enable"  config/log4j2.config.properties
	elif  [ "$1" == "-don" ]; then
		sed -i 's/fs.common.logconfig.custom.dao.enable=false/fs.common.logconfig.custom.dao.enable=true/' config/log4j2.config.properties 
                grep  "fs.common.logconfig.custom.dao.enable"  config/log4j2.config.properties
	elif  [ "$1" == "-debug" ]; then
		sed -i 's/logging.level.root=info/logging.level.root=debug/' config/log4j2.config.properties 
                grep  "logging.level.root" config/log4j2.config.properties 
	elif  [ "$1" == "-info" ]; then
		sed -i 's/logging.level.root=debug/logging.level.root=info/' config/log4j2.config.properties  
                grep  "logging.level.root" config/log4j2.config.properties
	elif  [ "$1" == "-k" ]; then
		cd ..  &&  python2 scripts/stop.py && cd -
	elif  [ "$1" == "-r" ]; then
		cd .. &&  python2 scripts/stop.py && sleep 3 && python2 scripts/start.py && cd -
	elif  [ "$1" == "-c" ]; then
		cat startFSDPL_BOOT.sh
	elif  [ "$1" == "-n" ]; then
		param=$2
		pids=$(ps aux | grep -E "java|-jar|WarLauncher"  |grep $param | grep -v grep )
		if [  -z "$pids" ];then
			echo "没找到此进程,参考：1.trade交易，2.query查询，3.control清算，4.process交易清算，5.uot运营，6.ftc柜台"
		else
			pid=$(echo $pids| awk {'print $2'} |head -n 1)
			path=$(cd /proc/$pid/cwd;/bin/pwd)
			cd $path && pwd
		fi
	elif  [ "$1" == "-fl" ]; then
		var=$2
		var=${var//,/ }
		mand=""
		for i in $var; do
			pid=$(ps aux | grep -E "java|-jar|WarLauncher" | grep -v grep | awk {'print $2'}  |tail -n +$i |head -n 1)
			path=$(cd /proc/$pid/cwd;/bin/pwd)
			cd $path && pwd
			logpath=$(grep validateLogFilePath ../scripts/start.py |head -n 1 )
			appname=$(grep  app.name  config/application.properties | sed 's/app.name=//' | sed 's/#//g'  |head -n 1 )
			logpath1=${logpath#*\'}
			logpath2=${logpath1%\'*}
			hostname=$(hostname)
			logpath3=`echo $logpath2 |sed 's/App/Biz/g'`
			echo ${logpath3}
			if [  -f ${logpath3} ];then
				mand1= ${logpath3}
			else
				mand1="logs/${appname}/${hostname}-${appname}-Biz.log"
			fi
			mand2=${mand}
			echo ${mand2}
			mand="${path}/${mand1} ${mand2}"
			echo  ${mand}
		done
		tail -fn 1000  ${mand}
	elif [ "$1" -gt 0 ] 2>/dev/null ;  then
		if [ 20 -ge $1 ]; then 
			pid=$(ps aux | grep -E "java|-jar|WarLauncher" | grep -v grep | awk {'print $2'}  |tail -n +$1 |head -n 1)
			path=$(cd /proc/$pid/cwd;/bin/pwd)
			cd $path && pwd
		else
			path=$(cd /proc/$1/cwd;/bin/pwd)
			cd $path && pwd
		fi
		

		if [ -n "$2" ]; then 
			logpath=$(grep validateLogFilePath ../scripts/start.py |head -n 1 )
			appname=$(grep  app.name  config/application.properties | sed 's/app.name=//' | sed 's/#//g'  |head -n 1 )
			hostname=$(hostname)
			logpath1=${logpath#*\'}
			logpath2=${logpath1%\'*}
			logpath3=`echo $logpath2 |sed 's/App/Biz/g'`
			logpath4=`echo $logpath2 |sed 's/App/Dao/g'`
			if [ "$2" == "co" ]; then
				tail -fn 1000 logs/core-app/core-app-default.log
			elif  [ "$2" == "-l" ]; then
				if [ -n "$3" ]; then
					if [ "$3" == "1" ]; then
						if [  -f ${logpath3} ];then
							tail -fn 1000 ${logpath3}
						else
							tail -fn 1000 logs/${appname}/${hostname}-${appname}-Biz.log
						fi
					elif [ "$3" == "2" ]; then
						if [  -f ${logpath2} ];then
							tail -fn 1000 ${logpath2}
						else
							tail -fn 1000 logs/${appname}/${hostname}-${appname}-App.log
						fi
					fi
				else
					cd logs/${appname}
				fi
			elif  [ "$2" == "-e" ]; then
				if [  -f ${logpath3} ];then
					tac ${logpath3} | grep -100 -m 1 "Exception:"
				else
					tac logs/${appname}/${hostname}-${appname}-Biz.log | grep -100 -m 1 "Exception:"
				fi
			elif  [ "$2" == "-p" ]; then
				netstat -apn|grep $pid
			elif  [ "$2" == "-k" ]; then
				cd ..  &&  python2 scripts/stop.py && cd -
			elif  [ "$2" == "-r" ]; then
				cd .. &&  python2 scripts/stop.py && sleep 3  &&  python2 scripts/start.py && cd -
			elif  [ "$2" == "-c" ]; then
				cat startFSDPL_BOOT.sh
			else
				echo  "-l 查看日志，-p 查看端口 ，-k 停止服务(停止后请重新查看进程序号)，-r 重启 ，-c 查看启动脚本"
			fi
		fi
	else
		echo  "-l 查看日志，-p 查看端口 ，-k 停止服务(停止后请重新查看进程序号)，-r 重启 ，-c 查看启动脚本"
	fi
else
	pid=$(ps aux | grep -E "java|-jar|WarLauncher" | grep -v grep | awk {'print $2'})
	pids=(${pid//\n/ }) 
		let count=0
	for i in ${pids[@]} 
	do
		let count+=1
		path=$(cd /proc/$i/cwd;/bin/pwd)
		echo  "`printf "%2d\n" $count`" "`printf "%7d\n" $i`"  "`printf "%25s\n" $(echo $path |awk -F "/" '{print $(NF-1)}')`  "  "$path"
		echo  "———  ——————   ——————————————————————   ——————————————————————————————————————————————"
	done
fi

