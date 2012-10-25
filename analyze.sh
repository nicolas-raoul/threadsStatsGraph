#!/bin/sh
#
# Analyze a log of thread dumps, and write statistics to a CSV file.
# The CSV file shows for each time how many threads of each type was running.
#
# To convert to an histogram, use LibreOffice's pivot feature
# Open LibreOffice, load CSV, Data > Pivot Table > Create, use
# TIME as column, ID as row, QUANTITY as data, then select pivot table
# and generate graph (series on rows).
#
# Usage: ./analyze.sh <threaddumps.log>
#
# Author: Nicolas Raoul
#
# TODO
# Parallelize analysis: seq $NB_OF_DUMPS | xargs --max-procs=4 -n 1 command (write CSV in second pass to keep order)

INPUT=${1:-threaddumps.log}

# Cleaning. Using "find" because rm complains that too many arguments
#find data -name 'threaddump*-*' -print0 | xargs -0 rm -f
rm -rf data
mkdir data

# Initialize output file
echo "'TIME','ID','QUANTITY'" > stats.csv

# Split catalina log (that contains many thread dumps) into individual thread dump files
echo "Parsing input"
tools/split-log-to-individual-dumps.pl $INPUT
# remove the first file, which contains no dump
rm -f data/threaddump0
TIME=0
# For each dump (time order)
for DUMP in `ls data/threaddump* | sort -k2 -tp -n` #| head -n 50`
do

# Analyse each dump
echo "Analyzing $DUMP"
java -jar jtda/build/jars/jtda.jar $DUMP > $DUMP-analysed

# Split each stack
tools/split-log-to-individual-stacks.pl $DUMP-analysed $DUMP-stack

#########################################
# Threads belonging to ThreadPool
#########################################
for STACK in `grep -l TP-Processor $DUMP-stack*`
do

# Isolate the trace part
sed "1,/Stack/d" < $STACK > $STACK-trace

# Get a text that best describes this thread
ID=`cat $STACK-trace | grep -v IGNORED | \
grep -v "java.lang.Object" | \
grep -v "sun.misc.Unsafe" | \
grep -v "java.util.concurrent" | \
grep -v "java.net.SocketInputStream" | \
grep -v "org.springframework.transaction" | \
head -n 1 | sed -e "s/ - //" -e "s/(.*//"`

# If empty, try again, being less restrictive
if [ -z "$ID" ]; then
ID=`cat $STACK-trace | grep -v IGNORED | \
grep -v "java.lang.Object.wait" | \
grep -v "sun.misc.Unsafe.park" | \
grep -v "java.util.concurrent.locks" | \
head -n 1 | sed -e "s/ - //" -e "s/(.*//"`
fi

# Get the quantity of threads of this kind
QUANTITY=`grep " threads with trace:" $STACK | sed -e "s/ .*//g"`

# Output
echo "'$TIME','TP_$ID','$QUANTITY'" >> stats.csv

# End stack
done

#########################################
# Threads not belonging to ThreadPool
#########################################
for STACK in `grep -L TP-Processor $DUMP-stack*`
do

# Isolate the trace part
sed "1,/Stack/d" < $STACK > $STACK-trace

# Get the text that best describes this thread
ID=`cat $STACK-trace | grep -v IGNORED | \
grep -v "java.lang.Object" | \
grep -v "sun.misc.Unsafe" | \
grep -v "java.util.concurrent" | \
grep -v "java.lang.Thread" | \
grep -v "java.net" | \
grep -v "java.io" | \
head -n 1 | sed -e "s/ - //" -e "s/(.*//"`

# If empty, try again, being less restrictive
if [ -z "$ID" ]; then
ID=`cat $STACK-trace | grep -v IGNORED | \
grep -v "java.lang.Object.wait" | \
grep -v "sun.misc.Unsafe.park" | \
grep -v "java.util.concurrent.locks" | \
head -n 1 | sed -e "s/ - //" -e "s/(.*//"`
fi

# Get the quantity of threads of this kind
QUANTITY=`grep " threads with trace:" $STACK | sed -e "s/ .*//g"`

# Output
echo "'$TIME','NONTP_$ID','$QUANTITY'" >> stats.csv

# End stack
done


# End dump
TIME=$(($TIME+1))
done
