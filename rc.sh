#remote commander

#listen for call
while true; do
    #save current directory
    ppwd=`pwd`
    #move to mail directory
    cd ~/Maildir/new/
    #if new mail, do
    if [ -f *\.mail ]; then
        #print local time and processing message 
        echo `date | grep -o "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]"`": processing..."
        #get oldest query mail
        qmail=`ls -t | tail -1`
        #strip $querist from mail
        querist=`cat $qmail | grep -o "Return-Path:\ <.*>" | sed s/\>// | sed s/Return-Path:\ \<//`
        #strip $query from mail
        query=`cat $qmail | grep -o "\.rc.*" | tail -1 | sed s/\.rc\ //`
        echo $query
        #strip command $qcom from $query
        qcom=`echo $query | sed s/\ .*//`
        echo $qcom
        #strip argument $qarm from $query
        qarg=`echo $query | sed s/[^\ ]*\ //`
        echo $qarg
        #move back to previous directory
        cd `echo $ppwd`
        #if query is a remote command, do
        if [ -n "$query" ]; then
            #move to remote command directory
            cd ~/rc/
            #set error to false
            error="false"
            #branch on command $qcom
            if [ "$qcom" = "evaluate" ]; then
                #move to evaluate directory
                cd evaluate
                #evaluate common lisp expression $qarg
                clisp -on-error abort -x "$qarg" | sed '1,18d' | sed '$d' | mail $querist
            elif [ "$qcom" = "define" ]; then
                #move to define directory
                cd define
                #normalize $qarg for look-up
                qarg=`echo $qarg | sed s/\ /\+/g`
                #if $query is not local, pull page
                if [ ! -f $qarg ]; then
                    #pull definition of $qarg from dictionary
                    wget -q http://dictionary.reference.com/browse/$qarg
                fi
                #strip-mine $definition of $qarg from page
                definition=`cat $qarg | grep -P -o "<span class=\"dnindex\">.\.</span><div class=\"dndata\">(.*?)</div>" | sed s/\<[^\>]*\>//g | sed s/[0-9]*\\./\\.\ /g`
                #if $defintion exists, do
                if [ -n "$definition" ]; then
                    #mail defintion to $querist
                    cat $qarg | grep -P -o "<span class=\"dnindex\">.\.</span><div class=\"dndata\">(.*?)</div>" | sed s/\<[^\>]*\>//g | sed s/[0-9]*\\./\\.\ /g | mail $querist
                else
                    #mail error to $querist
                    echo "no definition for $qarg" | mail $querist
                fi
            elif [ "$qcom" = "measure" ]; then
                #move to measure directory
                cd measure                 
                #pull measurement of $qarg from weather station
                wget -q http://www.weather.com/weather/right-now/$qarg
                #strip-mine temperature of $qarg from page and mail to $querist
                cat $qarg | grep -P -o "\"og:description\" content=\".*?F" | sed s/\&deg\;/\ degrees\ / | sed s/\".*\'s\ // | mail $querist
                #remove page
                rm $qarg
            elif [ "$qcom" = "lol" ]; then
                cat lol.lol | mail $querist
            else
                #set error to true
                error="true"
                #mail error to $querist
                echo "command $qcom does not compute" | mail $querist
            fi
            #move back to previous directory
            cd `echo $ppwd`
            #move to mail directory
            cd ~/Maildir/new/
            #archive query mail
            if [ "$error" = "true" ]; then
                mv $qmail ~/Maildir/arch/error/$qmail
            else
                mv $qmail ~/Maildir/arch/$qcom/$qmail
            fi
            #print processed message
            echo `date | grep -o "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]"`": processed $query for $querist"
        else
            #move to mail directory
            cd ~/Maildir/new/
            #junk error mail
            mv $qmail ~/Maildir/junk/$qmail
            #print processed message
            echo `date | grep -o "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]"`": processed error mail from $querist"
        fi
    fi
    #move back to previous directory
    cd `echo $ppwd`
    #snorlax
    sleep 10                  
done   
