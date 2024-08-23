        >> SOURCE FORMAT IS FREE

identification division.
program-id. da_comments.

environment division.
configuration section.

input-output section.
      file-control.
      select task-notes-file assign to task-notes-file-name
           organization is indexed
              access mode is random
              record key is task-note-id
              alternate record key is task-note-task-id 
              with duplicates
              file status is task-notes-file-status.


data division.

file section.
fd task-notes-file.
copy cp_task_note_defs replacing ==:prefix:== by == ==.


working-storage section.

01 task-notes-file-status pic 99.
01 task-notes-file-name pic X(50).
01 filter-task-id pic 99999.
01 next-task-note-id pic 999999.

linkage section.

copy da_defs.
copy cp_task_note_defs replacing ==:prefix:== by ==ws-==.


procedure division using ws-da-defs ws-task-note-rec.

evaluate ws-file-action
    when 'open' perform doFileOpen
    when 'close' perform doFileClose
    when 'getAll' perform doGetAll
    when 'getForTask' perform doGetForTask
    when 'getNext' perform doGetNext
    when 'create' perform doCreate
    when other perform doBadFileAction
end-evaluate.

goback.


doBadFileAction.
    move 'badAction' to ws-result.
    display "Bad Action: " ws-file-action.

doFileOpen.
    move ws-file-name to task-notes-file-name.
    open i-o task-notes-file.
    perform setResult.
    if DA_NOT_EXISTS then
        open output  task-notes-file
        close task-notes-file
        open i-o task-notes-file
    end-if.
    set DA_SUCCESS to TRUE.

doFileClose.
    close task-notes-file.
    set DA_SUCCESS to TRUE.

setResult.
    move task-notes-file-status to ws-result.

doGetAll.
    move zero to filter-task-id.
    read task-notes-file next record.
    move task-note-rec to ws-task-note-rec.
    perform setResult.

doGetForTask.
    move ws-task-note-task-id to filter-task-id.
    move spaces to ws-task-note-rec.
    perform doGetNextForTask.

doGetNext.
    if filter-task-id > 0 perform doGetNextForTask
    else
        read task-notes-file next record
        move task-note-rec to ws-task-note-rec
        perform setResult
    end-if.

doGetNextForTask.
    read task-notes-file next record.
    perform setResult.
    perform until DA_END_OF_FILE
        if task-note-task-id = filter-task-id then
            move task-note-rec to ws-task-note-rec
            exit perform
        else
            read task-notes-file next record
            perform setResult
        end-if
    end-perform.

doCreate.
    perform getNextTaskNoteId.
    move next-task-note-id to ws-task-note-id.
    initialize task-note-rec.
    move ws-task-note-rec to task-note-rec.
    write task-note-rec.
    perform setResult.

getNextTaskNoteId.
    if next-task-note-id = 0 then
        read task-notes-file next record
        perform until task-notes-file-status = '10'
            if task-note-id > next-task-note-id then
                move task-note-id to next-task-note-id
            end-if
            read task-notes-file next record 
        end-perform
    end-if.
    add 1 to next-task-note-id.


