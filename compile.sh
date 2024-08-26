#!/bin/bash

COPYBOOKS=.
BIN_DIR=./bin

mkdir -p $BIN_DIR

rm -f bin/*

MODULES=(
    "da_tasks"
    "da_comments"
    )

EXECUTABLE="todo"
FILELIST=""
for module in ${MODULES[@]}; do
    OBJ_NAME=${BIN_DIR}/${module}.so
    cobc -I ${COPYBOOKS} -c -o ${OBJ_NAME} ${module}.cob
    FILELIST="$FILELIST $OBJ_NAME"
done

cobc -I ${COPYBOOKS} -fstatic-call -o ${BIN_DIR}/${EXECUTABLE} -x ${EXECUTABLE}.cob $FILELIST
