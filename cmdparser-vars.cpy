       01 cmd pic X(999).
       01 cmd-ptr pic 999.
       01 cmd-tok-tmp pic X(20).
       77 cmd-count usage binary-long unsigned.
       78 cmd-count-max value 10.
       01 cmd-current pic 99 value 0.
       01 cmd-toks.
             05 cmd-tok pic X(20) 
                 occurs 0 to cmd-count-max 
                 depending on cmd-count.
       01 cmd-tok-current pic X(20).
       01 cmd-flags.
             05 cmd-string-empty pic X value 'N'.
                 88 cmd-no-more-toks value 'Y'.
