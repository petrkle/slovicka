#!/bin/bash

export IFS='
'

for foo in `cat nove`
do
	SLOVO=`echo "$foo" | cut -d: -f1`
	sed -i "s/^$SLOVO:.*/$foo/" 3000.txt
done
