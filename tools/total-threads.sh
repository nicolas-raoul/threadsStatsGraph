ls data/threaddump*-analysed | sort -k2 -tp -n | xargs grep "Total threads" | sed -e "s/.*dump//" -e "s/-.* /,/"
