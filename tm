#!/usr/bin/env bash

options=":"    # handle errors manually
functions=()
options+="l";  listSessions="";  functions+=(listSessions)
options+="a:"; attachSession=""; functions+=(attachSession)
options+="e:"; endSession="";    functions+=(endSession)
options+="n:"; newSession="";    functions+=(newSession)
options+="d";  oneSession="";    functions+=(oneSession)
options+="p";  pickSession="";   functions+=(pickSession)
while getopts $options opt; do
    case $opt in
        l) listSessions="yes"       ;;
        a) attachSession="$OPTARG"  ;;
        e) endSession="$OPTARG"     ;;
        n) newSession="$OPTARG"     ;;
        d) oneSession="yes"         ;;
        p) pickSession="yes"        ;;
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
    tmp) pickSession="yes"      ;;
esac

declare -i setFunctions=0
for function in "${functions[@]}"; do
    declare -n varCheck="$function"
    [[ $varCheck ]] && ((setFunctions++))
done
((setFunctions == 0)) && { >&2 echo "An option is required"; exit 1; }
((setFunctions != 1)) && { >&2 echo "Only a single option is permitted"; exit 1; }

pickSession () {
    local pick=""; local dflt="";
    OPTIND=1; while getopts :pd opt; do case $opt in
        p) pick="yes" ;;
        d) dflt="yes" ;;
    esac; done; shift $((OPTIND - 1))
    [[   $pick &&   $dflt ]] && dflt="yes"
    [[ ! $pick && ! $dflt ]] && dflt="yes"

    local -a sessions=()
    readarray -t sessions < <(tmux list-sessions)
    if [[ ${#sessions[@]} -eq 0 ]]; then
        >&2 echo "Can neither attach nor list, there are no sessions active"
        >&2 read -r -t 10 -p "Press enter to start 'default', anything else to exit: "
        if [[ $? -gt 128 || $REPLY != "" ]]; then
            exit 1
        else
            tmux new-session -s default
            exit 0
        fi
    fi
    if [[ ${#sessions[@]} -eq 1 ]]; then
        if [[ $pick ]]; then
            >&2 printf "There is only one session, '%s';\n" "${sessions[0]}"
            >&2 read -r -p "Press enter to attach to it, anything else to quit: "
            [[ $? -ne 0 || $REPLY ]] && exit 1
        fi
        tmux attach-session -t "${sessions[0]%%:*}"
        exit 0
    fi
    if [[ $dflt ]]; then
        >&2 cat << EOF

There are multiple sessions, cannot attach to a default:

$(tmux list-sessions)
EOF
        exit 1
    fi
    # if we get here, $pick is set and there are multiple sessions
    local index;
    for index in "${!sessions[@]}"; do
        printf "\t%s\t\t%s\n" "$index" "${sessions[$index]}"
    done
    read -r -p "Enter a session number or anything else to quit: "
    if [[ $REPLY =~ [0-9]+ && $REPLY -ge 0 && $REPLY -lt "${#sessions[@]}" ]]; then
        tmux attach-session -t "${sessions[$REPLY]%%:*}"
        exit 0
    else
        exit 1
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
        oneSession)    pickSession -d                           ;;
        pickSession)   pickSession -p                           ;;
    esac
done

