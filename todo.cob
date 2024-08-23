        >> SOURCE FORMAT IS FREE

identification division.
program-id. todo.

environment division.
configuration section.
      repository.
            function isStatusOneOf
            function all intrinsic.



data division.


working-storage section.

copy da_defs.
copy cp_task_defs replacing ==:prefix:== by ==ws-==.
copy cp_task_note_defs replacing ==:prefix:== by ==ws-==.


78 task-count-max value 9999.

01 file-names.
    05 tasks-file-name pic X(50).
    05 task-notes-file-name pic X(50).

01 data-dir pic X(50).
01 show-task-id pic 9999 value zero.
01 new-task-status pic X.
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

*> ------------------------------------------------------------------
*> Main program elements
*> ------------------------------------------------------------------
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
    *> perform ensureFileExists.
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


*> ---------------------------------------------------------
*> Task maitenance routines
*> ---------------------------------------------------------
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
        
        perform start_tasks_read.
        initialize ws-da-defs.
        move 'getAll' to ws-file-action.
        call 'da_tasks' using ws-file-action, ws-task-rec.

        perform until DA_END_OF_FILE
            if isStatusOneOf(ws-task-status, task-statuses-to-list) = 'Y'
                perform displayTaskRow
            end-if
            move 'getNext' to ws-file-action
            call 'da_tasks' using ws-file-action, ws-task-rec
        end-perform.
        perform end_tasks_read.

    findTask.
        perform start_tasks_read.
        initialize ws-da-defs.
        move show-task-id to ws-task-id.
        move 'getOne' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.
        perform end_tasks_read.

    showTask.
        if cmd-flag-done then
            display "Task id to show: " with no advancing
            accept show-task-id
        else
            perform cmdGetNextToken
            move cmd-tok to show-task-id
        end-if.

        perform findTask.

        perform displayTask.

        display " Notes:"
        perform start_task_notes_read.

        initialize ws-da-defs.
        move ws-task-id to ws-task-note-task-id.
        move 'getForTask' to ws-file-action.
        call 'da_comments' using ws-da-defs ws-task-note-rec.

        perform until DA_END_OF_FILE
            move ws-task-note-created-at to temp-date
            display '  [', 
                temp-date-year, 
                '/', temp-date-month, 
                '/', temp-date-day,
                '] ', 
                function trim(ws-task-note-text)
            initialize ws-da-defs
            move 'getNext' to ws-file-action   
            call 'da_comments' using ws-da-defs ws-task-note-rec
        end-perform.

        perform end_task_notes_read.


    addTask.
        initialize ws-task-rec.
        move 'N' to ws-task-status.
        move function current-date(1:8) to ws-task-created-at.

        if cmd-flag-available then
                move function trim(cmd(cmd-ptr:)) to ws-task-description
        else
                display "New Task: " with no advancing
                accept ws-task-description
        end-if.

        perform start_tasks_write.
        initialize ws-da-defs.
        move 'create' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.
        display 'file status: ' ws-result.
        perform end_tasks_read.
           
    addNote.
        if cmd-flag-done then
            display "Task id to show: " with no advancing
            accept show-task-id
        else
            perform cmdGetNextToken
            move cmd-tok to show-task-id
        end-if.

        perform findTask.

        if DA_KEY_INVALID then  
            display 'Invalid Key'
            goback
        end-if.
        
        perform start_task_notes_read.
        initialize ws-da-defs.
        move 'create' to ws-file-action.
        move ws-task-id to ws-task-note-task-id.
        move function current-date(1:8) to ws-task-note-created-at.
        if cmd-flag-available then
            move function trim(cmd(cmd-ptr:)) to ws-task-note-text
        else
            display "New Note: " with no advancing
            accept ws-task-note-text
        end-if.
        call 'da_comments' using ws-da-defs, ws-task-note-rec.
        perform end_task_notes_read.


    displayTaskRowHeader.
        display "   ID   | Status |  Description".
        display "  ------+--------+----------------------------".

    displayTaskRow.
        display "  " ws-task-id 
                " |    " ws-task-status 
                "   |  " function trim(ws-task-description)
        .

    displayTask.
        display " ".
        display " ID: " ws-task-id "   Status: " ws-task-status.
        display " Description: ", ws-task-description.
        move ws-task-created-at to temp-date.
        display " Created on: ", temp-date-month, "/", 
                temp-date-day, "/", temp-date-year.
        if ws-task-status = 'P' then
            initialize temp-date
            move ws-task-started-at to temp-date
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
        
        perform start_tasks_write.
        initialize ws-task-rec.
        initialize ws-da-defs.
        move show-task-id to ws-task-id.
        move 'getOne' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.

        if DA_SUCCESS then
            move new-task-status to ws-task-status
            evaluate new-task-status
                when = 'P'
                    move function current-date(1:8) to ws-task-started-at
                when = 'C'
                    move function current-date(1:8) to ws-task-completed-at
            end-evaluate
            move 'update' to ws-file-action
            call 'da_tasks' using ws-file-action, ws-task-rec
        else
            display "Invalid key provided."
        end-if.
        perform end_tasks_read.

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

fileHelpers section.
    start_tasks_read.
        initialize ws-da-defs.
        move '/home/charlvj/.todo_cobol/tasks.data' to ws-file-name.
        move 'r' to ws-file-mode.
        move 'open' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.

    start_tasks_write.
        initialize ws-da-defs.
        move '/home/charlvj/.todo_cobol/tasks.data' to ws-file-name.
        move 'rw' to ws-file-mode.
        move 'open' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.

    end_tasks_read.
        initialize ws-da-defs.
        move 'close' to ws-file-action.
        call 'da_tasks' using ws-da-defs, ws-task-rec.

    start_task_notes_read.
        initialize ws-da-defs.
        move '/home/charlvj/.todo_cobol/task-notes.data' to ws-file-name.
        move 'r' to ws-file-mode.
        move 'open' to ws-file-action.
        call 'da_comments' using ws-da-defs, ws-task-note-rec.

    end_task_notes_read.
        initialize ws-da-defs.
        move 'close' to ws-file-action.
        call 'da_comments' using ws-da-defs, ws-task-note-rec.


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

