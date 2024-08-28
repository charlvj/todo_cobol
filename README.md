# Todo_Cobol

This is a small test program I am using to learn the basics of Cobol.

If by any chance you know Cobol and are looking at this project and you see something that can be improved, please create a PR and help me learn!


## Usage

The program is command based. When you run the program it will just give you a prompt and let you enter a command, or alternatively you can provide the same command on the command line as parameters when running the program.

For example:

```
$ ./todo
> list
All tasks...
   ID   | Status |  Description
  ------+--------+----------------------------
  00001 |    N   |  Test 1                                                                         
  00002 |    N   |  Test 2                                                                         
> add
Adding a task
New Task: Test 3
> list
All tasks...
   ID   | Status |  Description
  ------+--------+----------------------------
  00001 |    N   |  Test 1                                                                         
  00002 |    N   |  Test 2                                                                         
  00003 |    N   |  Test 3                                                                         
> start 2
Starting task
Task Started
> list
All tasks...
   ID   | Status |  Description
  ------+--------+----------------------------
  00001 |    N   |  Test 1                                                                         
  00002 |    P   |  Test 2                                                                         
  00003 |    N   |  Test 3                                                                         
> q
Quitting
$ 
```

OR

```
$ ./todo list
All tasks...
   ID   | Status |  Description
  ------+--------+----------------------------
  00001 |    N   |  Test 1                                                                         
  00002 |    N   |  Test 2
$
```


## Changing your bash prompt

You can use the `stats` command to get a short summary of the totals in a specific format. For example:

```
$ todo stats New=%N,Process=%P
New=6,Process=3
```

You can use this in the `PS1` variable to put a short summary in your prompt. I have prefix my prompt with the summary in gray:
```
PS1="\[\033[90m \$(todo stats [%N\;%P]) $PS1"
```
(At the end of my .bashrc)
