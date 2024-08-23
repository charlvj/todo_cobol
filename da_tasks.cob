       >> SOURCE FORMAT IS FREE

identification division.
program-id. da_tasks.

environment division.
configuration section.

input-output section.
      file-control.
      select tasks-file assign to tasks-file-name
       organization is indexed
          access mode is random
          record key is task-id
          alternate record key is task-status with duplicates
          file status is tasks-file-status.


data division.

file section.
fd tasks-file.
copy cp_task_defs replacing ==:prefix:== by == ==.


working-storage section.

01 tasks-file-status pic 99.
01 tasks-file-name pic X(50).
01 filter-task-id pic 99999.
01 next-task-id pic 99999.

linkage section.

copy da_defs.
copy cp_task_defs replacing ==:prefix:== by ==ws-==.


procedure division using ws-da-defs ws-task-rec.

evaluate ws-file-action
    when 'open' perform doFileOpen
    when 'close' perform doFileClose
    when 'getAll' perform doGetAll
    when 'getOne' perform doGetOne
    when 'getNext' perform doGetNext
    when 'create' perform doCreate
    when 'update' perform doUpdate
    when 'delete' perform doDelete
    when other perform doBadFileAction
end-evaluate.

goback.


doBadFileAction.
    move 'badAction' to ws-result.
    display "Bad Action: " ws-file-action.

doFileOpen.
    move ws-file-name to tasks-file-name.
    open i-o tasks-file.
    perform setResult.
    if     DA_NOT_EXISTS then
              open output  tasks-file
              close tasks-file
              open i-o tasks-file
    end-if.
    set DA_SUCCESS to TRUE.

doFileClose.
    close tasks-file.
    set DA_SUCCESS to TRUE.

setResult.
    move tasks-file-status to ws-result.

doGetAll.
    move zero to filter-task-id.
    read tasks-file next record.
    move task-rec to ws-task-rec.
    perform setResult.

doGetNext.
    read tasks-file next record.
    move task-rec to ws-task-rec.
    perform setResult.

doGetOne.
    move ws-task-id to task-id.
    read tasks-file key is task-id.
    move task-rec to ws-task-rec.
    perform setResult.

doCreate.
    perform getNextTaskId.
    move next-task-id to ws-task-id.
    initialize task-rec.
    move ws-task-rec to task-rec.
    write task-rec.
    perform setResult.

getNextTaskId.
    if next-task-id = 0 then
        *> open input tasks-file
        read tasks-file next record
        perform until tasks-file-status = '10'
            if task-id > next-task-id then
                move task-id to next-task-id
            end-if
            read tasks-file next record 
        end-perform
        *> close tasks-file
    end-if.
    add 1 to next-task-id.

doUpdate.
    move ws-task-id to task-id.
    read tasks-file key is task-id
        not invalid key
            move ws-task-rec to task-rec
            rewrite task-rec.
    perform setResult.

doDelete.
    move ws-task-id to task-id.
    read tasks-file key is task-id
        not invalid key
            delete tasks-file.
    perform setResult.

