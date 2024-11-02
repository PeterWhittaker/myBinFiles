#!/usr/bin/env bash

options=":"	# handle errors manually
functions=()
options+="l"; listSessions="";   functions+=(listSessions)
options+="a:"; attachSession=""; functions+=(attachSession)
options+="d:"; deleteSession=""; functions+=(deleteSession)
options+="n:"; newSession="";    functions+=(newSession)
while getopts $options opt; do
	case $opt in
        l) listSessions="yes"       ;;
        a) attachSession="$OPTARG"  ;;
        d) deleteSession="$OPTARG"  ;;
        n) newSession="$OPTARG"     ;;
        *) >&2 echo "Invalid option '$opt'"; exit 1;;
    esac
done
shift $((OPTIND - 1))
case $(basename $0) in
    tml) listSessions="yes"     ;;
    tmd) deleteSession="$1"     ;;
    tma) attachSession="$1"     ;;
    tmn) newSession="$1"        ;;
esac

declare -i setFunctions=0
for function in "${functions[@]}"; do
    declare -n varCheck="$function"
    [[ $varCheck ]] && ((setFunctions++))
done
((setFunctions == 0)) && { >&2 echo "An option is required"; exit 1; }
((setFunctions != 1)) && { >&2 echo "Only a single option is permitted"; exit 1; }

for function in "${functions[@]}"; do
    declare -n varCheck="$function"
    [[ ! $varCheck ]] && continue
    case $function in
        listSessions)  tmux list-sessions                       ;;
        attachSession) tmux attach-session -t "$attachSession"  ;;
        deleteSession) tmux kill-session -t "$deleteSession"    ;;
        newSession)    tmux new-session -s "$newSession"        ;;
    esac
done




