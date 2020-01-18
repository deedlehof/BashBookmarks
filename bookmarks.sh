#!/bin/bash

MARKS_DIR="/home/tanner/.scripts/BookMarks/marks"

add_mark() {
    # check for NAME argument
    if [[ -z $1 ]]; then
	echo "NAME argument is required"
	return 1
    fi

    # append directory to name for bookmark line
    value="$1"
    value+="    "
    value+=${PWD} 

    # search marks file for NAME
    mark=$(grep -m 1 -n -w ^$1 "$MARKS_DIR")
    IFS=':' read -r line string <<< "$mark"
    
    # if NAME exists, update it, else append it
    if [[ -n "$line" ]]; then 
	sed -i "${line}s|.*|$value|" "$MARKS_DIR"
    else
	echo "$value" >> "$MARKS_DIR"
    fi
}

remove_mark() {
    # check for NAME argument
    if [[ -z $1 ]]; then
	echo "NAME argument is required"
	return 1
    fi

    # matches for NAME in marks file
    # -n gets line numbers of matches
    matches=($(grep -n ^$1 $MARKS_DIR))

    # if no matches, stop
    if [[ -z $matches ]]; then
	echo "No matches!"
	return 0
    fi

    # display matches to the user for selection
    line=1
    prefix="[0-9]*:"
    for ((i=0;i<${#matches[@]};i+=2)); do 
	result=$line
	# remove line number from match
	result+=". "
	name=${matches[$i]}
	result+=${name#$prefix}
	result+="\t"
	result+=${matches[$i+1]}
	echo -e $result
	((line+=1))
    done

    # get user selection
    read -p "Which bookmark number matches? (1): " matchnum
    # default to 1
    if [[ -z $matchnum ]]; then
	matchnum="1"
    fi
    # check bounds
    if ((($matchnum > ${#matches[@]} / 2) || ($matchnum < 0))); then
	echo "Selection outside of range!"
	return 0
    fi
    # get file line for match and remove it
    index=$((($matchnum - 1) * 2))
    match=${matches[$index]}
    suffix=":*"
    sed -i "${match%$suffix}d" "$MARKS_DIR"
    echo "Bookmark removed"
}

go_to_mark() {
    # check for NAME argument
    if [[ -z $1 ]]; then
	echo "NAME argument is required"
	return 1
    fi

    # get the matching mark
    mark=$(grep -m 1 -w ^$1 "$MARKS_DIR")
    if [[ -z $mark ]]; then
	echo "No bookmark with that NAME"
	return 0
    fi
    parts=($mark)
    location=${parts[1]}
    # go to mark
    cd "$location"
}

display_marks() {
    # display marks in less pager
    less -K -m -c "$MARKS_DIR"
}

usage() {
    echo "Usage: ./bookmarks.sh [options] [NAME]"
}

help_msg() {
    usage
    echo -e "\nOPTIONS"
    echo -e "-a NAME \tbookmarks current directory with NAME"
    echo -e "-r NAME \tremoves the bookmark NAME"
    echo -e "-d	\tdisplays all bookmarks in a pager"
    echo -e "-s NAME \tsearches for a bookmark with NAME"
    echo -e "-h	\tprints this menu"
}

main() {
    if [[ -z $* ]]; then
	help_msg
	return 0
    fi
    while [ -n "$1" ]; do
	case $1 in 
	    -a | --add)
		add_mark $2
		shift
		;;
	    -r | --remove)
		remove_mark $2
		shift
		;;
	    -d | --display)
		display_marks
		;;
	    -s | --search)
		grep $2 "$MARKS_DIR" 
		shift
		;;
	    -h | --help)
		help_msg
		;;
	    -*)
		help_msg
		;;
	    *) 
		go_to_mark $1
		;;
	esac
	shift
    done
}

main $*
