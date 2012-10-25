# Create a threads dump every 5 seconds
PID=$1

> threaddumps.log
while [ true ]
do
  date >> threaddumps.log
  jstack $PID >> threaddumps.log
  sleep 5
done
