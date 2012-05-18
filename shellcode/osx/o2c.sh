#!/bin/sh
# Object file to C shellcode.

otool -t "$@" | awk 'NR > 2' | cut -d' ' -f 2- | perl -pe's/ $//; s/ /\\x/g' |
	awk 'BEGIN { printf "char shellcode[] =" } { printf "\n\t\"\\x%s\"", $0 } END { print ";" }'

