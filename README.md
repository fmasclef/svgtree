# svgtree

> Render a git-like tree as SVG from a text file

![sample](sample/fix.svg)

# Usage

    ./svgtree.pl --input <.tree file> --output <.svg file>

Parameters `-i|--input` and `-o|--output` are mandatory. All others are optionals. None are excluding. Please refer to the following table for supported paramters:

|short|long|description|
|---|---|---|
|d|debug|show debug messages|
|h|hspace|horizontal spacing between steps|
|i|input|input file with full path|
|l|labels|add labels for steps references|
|o|output|output file with full path (will be overwritted)|
|r|radius|bubble radius|
|s|stroke|line width|
|v|vspace|vertical spacing between branches|

# .tree file format

    # comment
    > STDOUT printable comment

    branch.x.name Name of branch
    branch.x.color HTML color code of branch x

    <data>

data

    <space> this brach does not exists
    . node (commit)
    - line (nothing)
    x checkout/merge branch x

# sample

    # this is a sample `fix` tree
    branch.0.name master
    branch.0.color 000000
    branch.1.name fix
    branch.1.color dd0000
    ...--..--.1.
           0..


___
![CC-BY-ND 4.0](https://i.creativecommons.org/l/by-nd/4.0/88x31.png)
