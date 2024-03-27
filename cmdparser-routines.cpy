      * Command related routines
       resetCmdVars.
           move spaces to cmd.
           move spaces to cmd-toks.
           move spaces to cmd-tok-current.
           move 'N' to cmd-string-empty.

       parseCmd.
           move 1 to cmd-ptr.
           perform varying cmd-count from 1 by 1 
                       until cmd-count > cmd-count-max
                 move spaces to cmd-tok-tmp
                 unstring cmd delimited by all space
                       into cmd-tok-tmp
                       with pointer cmd-ptr
                 end-unstring
                 if cmd-tok-tmp = spaces
                       exit perform
                 end-if
                 move cmd-tok-tmp to cmd-tok(cmd-count)
            end-perform.
           move 0 to cmd-current.

       nextCmdToken.
           add 1 to cmd-current.
           if cmd-current >= cmd-count then
                 move 'Y' to cmd-string-empty
           else
                 move cmd-tok(cmd-current) to cmd-tok-current
           end-if.



