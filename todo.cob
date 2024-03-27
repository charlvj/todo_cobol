       identification division.
       program-id. todo.

       environment division.
       input-output section.
       file-control.
           select tasks-file assign to "tasks.data"
                 organization is indexed
                 access mode is random
                 record key is task-id
                 alternate record key is task-status with duplicates
                 file status is tasks-file-status.


       data division.
       file section.
       fd tasks-file.
       01 task-rec.
              05 task-id pic 99999.
              05 task-status pic X.
              05 task-description pic X(79).

       working-storage section.
       copy cmdparser-vars.

       78 task-count-max value 9999.
       01 tasks-file-status  pic X(02) value zero.
       01 show-task-id pic 9999 value zero.
       01 next-task-id pic 9999 value zero.
       01 new-task-status pic X.
       01 file-status pic 9.
             88 eof  value 1.
             88 not-eof value 0.
       01 exit-program pic X value 'N'.


      * ------------------------------------------------------------------
      * Main program elements
      * ------------------------------------------------------------------
       procedure division.

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
                  perform resetCmdVars
                  display "> " with no advancing
                  accept cmd

                  perform performCommand
           end-perform.

       singleLoop.
           perform performCommand.

       performCommand.
           perform parseCmd.
           perform nextCmdToken.
           evaluate cmd-tok-current
                 when = "list"
                       display "All tasks..."
                       perform showTasks
                 when = "add"
                       display "Adding a task"
                       perform addTask
                 when = "show"
                       perform showTask
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
                       display "Invalid Command. Use help for more."
           end-evaluate.
 

       showHelp.
           display "----------------"
           display "list  -  Show tasks  "
           display "add   -  Add task    "
           display "show  -  Show Task   "
           display "help  -  Show this help"
           display "exit  -  Quit        "
           .


       ensureFileExists.
           open input tasks-file.
           if tasks-file-status = '35' then
                 open output tasks-file
           end-if.
           close tasks-file.


      * ---------------------------------------------------------
      * Task maitenance routines
      * ---------------------------------------------------------
       showTasks.
           perform displayTaskRowHeader.
           open input tasks-file.
           set not-eof to true.
           read tasks-file next record.
           perform until tasks-file-status = '10'
                 if task-status = 'N' or task-status = 'P' then
                       perform displayTaskRow
                 end-if
                 read tasks-file next record 
           end-perform.
           close tasks-file.

       showTask.
           perform nextCmdToken.
           if cmd-no-more-toks then
                 display "Task id to show: " with no advancing
                 accept show-task-id
           else
                 move cmd-tok-current to show-task-id
           end-if.

           open input tasks-file.
           move show-task-id to task-id.
           read tasks-file key is task-id
                 invalid key display "Invalid Key: ",
                 tasks-file-status.
           perform displayTask.
           close tasks-file.

       addTask.
           perform getNextTaskId.

           open i-o tasks-file.
           move 'N' to task-status.
           move next-task-id to task-id.
           display "New Task: " with no advancing.
           accept task-description.
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
           


       displayTaskRowHeader.
           display "   ID   | Status |  Description".
           display "  ------+--------+----------------------------".

       displayTaskRow.
           display "  " task-id 
                   " |    " task-status 
                   "   |  " task-description
           .

       displayTask.
           display " ".
           display " ID: " task-id "   Status: " task-status
           display " Description: ", task-description
           display " ".

       updateTaskStatus.
           display "Starting task".
           add 1 to cmd-current.
           if cmd-current >= cmd-count then
                 display "Task ID to start: " with no advancing
                 accept show-task-id
           else
                 move cmd-tok(cmd-current) to show-task-id
           end-if.
           
           open i-o tasks-file.
           move show-task-id to task-id.
           read tasks-file key is task-id
                 invalid key 
                       display "Invalid Key: ", tasks-file-status.
           if tasks-file-status = '00' then
                 move new-task-status to task-status
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


       copy cmdparser-routines.

       end program todo.
