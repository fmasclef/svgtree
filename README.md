# svgtree

Render a git-like tree as SVG from a text file

# Usage

    ./svgtree.pl -i <.tree file> -o <.svg file>

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
