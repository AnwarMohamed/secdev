#!/bin/sh
# atbash.sh -- err.. atbash cipher

if [[ -z "$@" ]]; then
	tr a-zA-Z zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA
else
	echo "$@" | tr a-zA-Z zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA
fi
