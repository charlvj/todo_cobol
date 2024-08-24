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

for module in ${MODULES[@]}; do
    cobc -I ${COPYBOOKS} -o ${BIN_DIR}/${module}.so ${module}.cob
done

cobc -I ${COPYBOOKS} -o ${BIN_DIR}/${EXECUTABLE} -x ${EXECUTABLE}.cob
