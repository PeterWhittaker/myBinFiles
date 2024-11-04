#!/usr/bin/env bash

options=":"    # handle errors manually
functions=()
options+="l";  listSessions="";  functions+=(listSessions)
options+="a:"; attachSession=""; functions+=(attachSession)
options+="e:"; endSession="";    functions+=(endSession)
options+="n:"; newSession="";    functions+=(newSession)
options+="d";  oneSession="";    functions+=(oneSession)
while getopts $options opt; do
    case $opt in
        l) listSessions="yes"       ;;
        a) attachSession="$OPTARG"  ;;
        e) endSession="$OPTARG"     ;;
        n) newSession="$OPTARG"     ;;
        d) oneSession="yes"         ;;
        *) >&2 echo "Invalid option '$opt'"; exit 1;;
    esac
done
shift $((OPTIND - 1))
case $(basename $0) in
    tml) listSessions="yes"     ;;
    tme) endSession="$1"        ;;
    tma) attachSession="$1"     ;;
    tmn) newSession="$1"        ;;
    tmd) oneSession="yes"       ;;
esac

declare -i setFunctions=0
for function in "${functions[@]}"; do
    declare -n varCheck="$function"
    [[ $varCheck ]] && ((setFunctions++))
done
((setFunctions == 0)) && { >&2 echo "An option is required"; exit 1; }
((setFunctions != 1)) && { >&2 echo "Only a single option is permitted"; exit 1; }

doOnlySession () {
    local -a sessions=()
    readarray -t sessions < <(tmux list-sessions)
    echo ${#sessions[@]}
    if [[ ${#sessions[@]} -eq 1 ]]; then
        tmux attach-session -t "${sessions[0]%%:*}"
    else
        >&2 cat << EOF

There are multiple sessions, cannot attach to a default:

$(tmux list-sessions)
EOF
    fi
}

for function in "${functions[@]}"; do
    declare -n varCheck="$function"
    [[ ! $varCheck ]] && continue
    case $function in
        listSessions)  tmux list-sessions                       ;;
        attachSession) tmux attach-session -t "$attachSession"  ;;
        endSession)    tmux kill-session -t "$endSession"       ;;
        newSession)    tmux new-session -s "$newSession"        ;;
        oneSession)    doOnlySession                            ;;
    esac
done




