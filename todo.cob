       identification division.
       program-id. todo.

       environment division.
       configuration section.
       repository.
            function isStatusOneOf
            function all intrinsic.

       input-output section.
       file-control.
           select tasks-file assign to tasks-file-name
                  organization is indexed
                  access mode is random
                  record key is task-id
                  alternate record key is task-status with duplicates
                  file status is tasks-file-status.

           select task-notes-file assign to task-notes-file-name
                  organization is indexed
                  access mode is random
                  record key is task-note-id
                  alternate record key is task-note-task-id 
                  with duplicates
                  file status is task-notes-file-status.



       data division.
       file section.
       fd tasks-file.
       01 task-rec.
          05 task-id pic 99999.
          05 task-status pic X.
          05 task-description pic X(79).
          05 task-created-at pic 9(8).
          05 task-started-at pic 9(8).
          05 task-completed-at pic 9(8).

       fd task-notes-file.
       01 task-note-rec.
          05 task-note-id pic 999999.
          05 task-note-task-id pic 99999.
          05 task-note-text pic X(200).
          05 task-note-created-at pic 9(8).


       working-storage section.

       78 task-count-max value 9999.
       01 data-dir pic X(50).
       01 tasks-file-name pic X(50).
       01 tasks-file-status  pic X(02) value zero.
       01 task-notes-file-status pic X(02) value zero.
       01 show-task-id pic 9999 value zero.
       01 next-task-id pic 9999 value zero.
       01 next-task-note-id pic 99999 value zero.
       01 new-task-status pic X.
       01 file-status pic 9.
          88 eof  value 1.
          88 not-eof value 0.
       01 exit-program pic X value 'N'.
       01 task-statuses-to-list pic X(5) value 'NP'.

       01 temp-date.
          05 temp-date-year pic 9(4).
          05 temp-date-month pic 9(2).
          05 temp-date-day pic 9(2).
          05 temp-date-hour pic 9(2).
          05 temp-date-minute pic 9(2).
          05 temp-date-second pic 9(2).
          05 temp-date-milliseconds pic 9(2).

       01 cmd-data.
            05 cmd pic X(9999).
            05 cmd-tok pic X(50).
            05 cmd-ptr pic 99.
            05 cmd-flag pic X.
                  88 cmd-flag-available value 'Y'.
                  88 cmd-flag-done value 'N'.

      * ------------------------------------------------------------------
      * Main program elements
      * ------------------------------------------------------------------
       procedure division.

           perform setFilename.
           perform cmdReset.

           accept cmd from command-line.
           if cmd = spaces then
              perform mainLoop
           else
              perform singleLoop
           end-if.

           stop run.

       mainLoop.
           perform ensureFileExists.
           perform until exit-program = 'Y'
              perform cmdReset
              display "> " with no advancing
              accept cmd

              perform performCommand
           end-perform.

       singleLoop.
           perform performCommand.

       performCommand.
           perform cmdGetNextToken.
           evaluate cmd-tok
           when = "list"
              display "All tasks..."
              perform showTasks
           when = "add"
              display "Adding a task"
              perform addTask
           when = "show"
              perform showTask
           when = "addnote"
              perform addNote
           when = "help"
              perform showHelp
           when = "start"
              perform startTask
           when = "complete"
              perform completeTask
           when = "delete"
              perform deleteTask
           when = "exit" or = 'quit' or = 'q'
              display "Quitting"
              move 'Y' to exit-program
           when other
              display "Invalid Command: " cmd-tok ". Use help for more."
           end-evaluate.
 

       showHelp.
           display "Available Commands:"
           display " list     -  Show tasks      ".
           display " add      -  Add task        ".
           display " show     -  Show Task       ".
           display " addnote  -  Add a task note ".
           display " start    -  Start a task    ".
           display " complete -  Complete a task ".
           display " delete   -  Delete a task   ".
           display " help     -  Show this help  ".
           display " quit     -  Quit            ".


       setFilename.
           accept data-dir from environment "HOME".
           string data-dir delimited by spaces
                  "/.todo_cobol" delimited by size
                  into data-dir.
           call 'CBL_CREATE_DIR' using data-dir.
           string data-dir delimited by spaces
                  "/tasks.data"
                  into tasks-file-name.
           string data-dir delimited by spaces
                  "/task-notes.data"
                  into task-notes-file-name.

       ensureFileExists.
           open input tasks-file.
           if tasks-file-status = '35' then
              open output tasks-file
           end-if.
           close tasks-file.
           open input task-notes-file.
           if task-notes-file-status = '35' then
              open output  task-notes-file
           end-if.
           close task-notes-file.


      * ---------------------------------------------------------
      * Task maitenance routines
      * ---------------------------------------------------------
       taskActions section.

       showTasks.
            if cmd-flag-available then
                  perform cmdGetNextToken
                  if cmd-tok = 'all' then
                        move 'NPC' to task-statuses-to-list
                  else
                        move 'NP' to task-statuses-to-list
                  end-if
            else
                  move 'NP' to task-statuses-to-list
            end-if.

           perform displayTaskRowHeader.
           open input tasks-file.
           set not-eof to true.
           read tasks-file next record.
           perform until tasks-file-status = '10'
              if isStatusOneOf(task-status, task-statuses-to-list) = 'Y'
                 perform displayTaskRow
              end-if
              read tasks-file next record 
           end-perform.
           close tasks-file.

       showTask.
           if cmd-flag-done then
              display "Task id to show: " with no advancing
              accept show-task-id
           else
              perform cmdGetNextToken
              move cmd-tok to show-task-id
           end-if.

           open input tasks-file.
           move show-task-id to task-id.
           read tasks-file key is task-id
              invalid key display "Invalid Key: ",
                         tasks-file-status.
           perform displayTask.
           close tasks-file.

           display " Notes:"
           open input task-notes-file.
           read task-notes-file  next record.
           perform until task-notes-file-status = '10'
              if task-note-task-id = task-id then
                 move task-note-created-at to temp-date
                 display '  [', 
                         temp-date-year, 
                         '/', temp-date-month, 
                         '/', temp-date-day,
                         '] ', 
                         function trim(task-note-text)
              end-if
              read task-notes-file next record
           end-perform.
           close task-notes-file.

       addTask.
           perform getNextTaskId.

           open i-o tasks-file.
           
           move 'N' to task-status.
           move next-task-id to task-id.
           move function current-date(1:8) to task-created-at.

           if cmd-flag-available then
                  move function trim(cmd(cmd-ptr:)) to task-description
           else
                  display "New Task: " with no advancing
                  accept task-description
           end-if.
           write task-rec
              invalid key display "Invalid Key: ", tasks-file-status.
           close tasks-file.

       getNextTaskId.
           if next-task-id = 0 then
              open input tasks-file
              read tasks-file next record
              perform until tasks-file-status = '10'
                 if task-id > next-task-id then
                    move task-id to next-task-id
                 end-if
                 read tasks-file next record 
              end-perform
              close tasks-file
           end-if.
           add 1 to next-task-id.
           
       addNote.
           if cmd-flag-done then
              display "Task id to show: " with no advancing
              accept show-task-id
           else
              perform cmdGetNextToken
              move cmd-tok to show-task-id
           end-if.

           open input tasks-file.
           move show-task-id to task-id.
           read tasks-file key is task-id
              invalid key display "Task not found: ", show-task-id.
           close tasks-file.

           if tasks-file-status = '23' then  *> Invalid Key
              goback
           end-if.
            
           perform getNextTaskNoteId.

           open i-o task-notes-file.
           move next-task-note-id to task-note-id.
           move task-id to task-note-task-id.
           move function current-date(1:8) to task-note-created-at.
           if cmd-flag-available then
                  move function trim(cmd(cmd-ptr:)) to task-note-text
           else
                  display "New Note: " with no advancing
                  accept task-note-text
           end-if
           write task-note-rec.
           close task-notes-file.


       getNextTaskNoteId.
           if next-task-note-id = 0 then
              open input task-notes-file
              read task-notes-file next record
              perform until task-notes-file-status = '10'
                 if task-note-id > next-task-note-id then
                    move task-note-id to next-task-note-id
                 end-if
                 read task-notes-file next record 
              end-perform
              close task-notes-file
           end-if.
           add 1 to next-task-note-id.

       displayTaskRowHeader.
           display "   ID   | Status |  Description".
           display "  ------+--------+----------------------------".

       displayTaskRow.
           display "  " task-id 
                   " |    " task-status 
                   "   |  " function trim(task-description)
           .

       displayTask.
           display " ".
           display " ID: " task-id "   Status: " task-status.
           display " Description: ", task-description.
           move task-created-at to temp-date.
           display " Created on: ", temp-date-month, "/", 
                   temp-date-day, "/", temp-date-year.
           if task-status = 'P' then
              initialize temp-date
              move task-started-at to temp-date
              display " Started on: ", temp-date-month, "/", 
                      temp-date-day, "/", temp-date-year
           end-if.
           display " ".

       updateTaskStatus.
           display "Starting task".
           if cmd-flag-done then
              display "Task ID to start: " with no advancing
              accept show-task-id
           else
              perform cmdGetNextToken
              move cmd-tok to show-task-id
           end-if.
           
           open i-o tasks-file.
           move show-task-id to task-id.
           read tasks-file key is task-id
              invalid key 
                 display "Invalid Key: ", tasks-file-status.
           if tasks-file-status = '00' then
              move new-task-status to task-status
              evaluate new-task-status
              when = 'P'
                 move function current-date(1:8) 
                   to task-started-at
              when = 'C'
                 move function current-date(1:8)
                   to task-completed-at
              end-evaluate
              rewrite task-rec end-rewrite
           else
              display "There was an error loading the record."
           end-if.
           close tasks-file.

       startTask.
           move 'P' to new-task-status.
           perform updateTaskStatus.
           display "Task Started".

       completeTask.
           move 'C' to new-task-status.
           perform updateTaskStatus.
           display "Task Completed".

       deleteTask.
           move 'D' to new-task-status.
           perform updateTaskStatus.
           display "Task Deleted".

       
       cmdParsing section.

       cmdReset.
            move spaces to cmd.
            move 1 to cmd-ptr.
            move spaces to cmd-tok.

       cmdGetNextToken.
            move spaces to cmd-tok.
            unstring cmd delimited by all space
                  into cmd-tok
                  with pointer cmd-ptr
            end-unstring.
            if cmd-tok = spaces or cmd-ptr = 0
                  move 'N' to cmd-flag
            else
                  move 'Y' to cmd-flag
            end-if.
       

       end program todo.


       identification division.
       function-id. isStatusOneOf.

       environment division.
       configuration section.
       repository.
            function all intrinsic.

       data division.
       working-storage section.
       01 idx pic 99.

       linkage section.
       01 status-to-check pic X.
       01 status-list pic X(10).
       01 found-flag pic X(1) value 'N'.

       procedure division using status-to-check status-list
                        returning found-flag.

            perform varying idx 
                  from 1 by 1 
                  until idx > length of status-list
                  if status-to-check = status-list(idx:1) then
                        move 'Y' to found-flag
                        exit perform
                  end-if
            end-perform.

            goback.
       end function isStatusOneOf.

