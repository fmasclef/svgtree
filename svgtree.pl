#!/usr/bin/perl

# svgtree
# by fmasclef

use strict;
use Data::Dumper;
use Getopt::Long;

# user settable variables
my $debug  = 0;  # defaults to false
my $input  = ''; # .tree file to parse
my $output = ''; # .svg to create
my $stroke = 2;  # path stroke
my $radius = 6;  # circle radius
my $hspace = 20; # horizontal spacing
my $vspace = 40; # vertical spacing
my $commit = 0;  # should commits ref be displayed

# inner variables
my %branch = (
  name  => [],
  color => [],
  data  => []
);
my $maxsteps = 0;
my $dataoffset = 0;
my $refsroom = 0;
my %svg = (
  size => {
    width => 0,
    height => 0
  },
  branch => ()
);

# parse command line args
GetOptions(
  "d|debug"    => \$debug,
  "h|hspace=i" => \$hspace,
  "i|input=s"  => \$input,
  "l|labels"   => \$commit,
  "o|output=s" => \$output,
  "r|radius=i" => \$radius,
  "s|stroke=i" => \$stroke,
  "v|vspace=i" => \$vspace
) or die("Oh no, something wrong happened with command line args");

# verbose log
sub verbose {
  my ($entry) = @_;
  print "D| $entry\n" if ($debug);
  return;
}

# parse input, feed the %branch hash
open(my $in, '<:encoding(UTF-8)', $input) or die ("Could not open '$input'");
while (my $row = <$in>) {
  chomp $row;
  local $_ = $row;
  if (m/^\s*#(.*)/) {
    # comment
  } elsif (m/^\s*>(.*)/) {
    # printable comment
    print "$1\n"
  } elsif (m/^\s*branch(.*)/) {
    # branch config
    my ($key, $value) = split / /, $row;
    my ($b, $bid, $param) = split /\./, $key;
    verbose("config $bid $param '$value'");
    $branch{$param}[$bid] = $value;
  } elsif (m/^([\.|\-|\d|\s]*)/) {
    # should be actual data
    verbose("data $row");
    push $branch{'data'}, $row
  }
}
close $in;

# compute svg size
foreach (my $i=0; $i<@{$branch{'data'}}; $i++) {
  if (length($branch{'data'}[$i]) > $maxsteps) {
    $maxsteps = length($branch{'data'}[$i]);
  }
}
# add some room for branch name
foreach (my $i=0; $i<@{$branch{'name'}}; $i++) {
  if ((length($branch{'name'}[$i]) +1)*10 > $dataoffset) {
    $dataoffset = (length($branch{'name'}[$i]) +1)*10;
  }
}
# if use wants to see commit refs...
if ($commit) {
  $refsroom = 10;
}
$svg{'size'}{'width'} = ($maxsteps * $hspace) + $radius*2 + $dataoffset;
$svg{'size'}{'height'} = (@{$branch{'data'}} - 1) * $vspace + $radius*2 + $stroke*2 + $refsroom;
verbose("SVG size: $svg{'size'}{'width'}x$svg{'size'}{'height'}");

# generate SVG elements by looping thru branches
# this is where actual content will be generated
foreach (my $i=0; $i<@{$branch{'data'}}; $i++) {
  verbose("processing branch $branch{'data'}[$i]");
  my $segments  = "";
  my $bubbles   = "";
  my $checkouts = "";
  my $labels     = "";
  my $started   = 0;
  my $step      = 0;
  my $commits   = 0;
  my $offset_y = $i * $vspace + $radius + $stroke;
  my $text_x = $stroke * 2;
  my $text_y = $offset_y + $radius;
  $labels .= "<text x=\"$text_x\" y=\"$text_y\" text-anchor=\"start\" font-family=\"Verdana\" font-size=\"14\">$branch{'name'}[$i]</text>";
  foreach (split //, $branch{'data'}[$i]) {
    if (m/\./) {
      # bubble
      my $x = $dataoffset + $step * $hspace;
      $bubbles .= "<circle cx=\"$x\" cy=\"$offset_y\" r=\"$radius\" fill=\"#fff\" stroke=\"$branch{'color'}[$i]\" stroke-width=\"$stroke\" />";
      if ($started) {
        my $x2 = $x - $hspace;
        $segments .= "<line x1=\"$x2\" y1=\"$offset_y\" x2=\"$x\" y2=\"$offset_y\" stroke=\"$branch{'color'}[$i]\" stroke-width=\"$stroke\" />";
      }
      if ($commit) {
        my $ref = sprintf "%1d%02d", $i+1, ++$commits;
        my $ref_y = $offset_y + $radius + $refsroom;
        verbose("adding commit ref: $ref");
        $labels .= "<text x=\"$x\" y=\"$ref_y\" text-anchor=\"middle\" font-family=\"Verdana\" font-size=\"8\">$ref</text>";
      }
      $started = 1;
    } elsif (m/\-/) {
      # connecting segment
      my $x1 = $dataoffset + ($step-1) * $hspace + $radius;
      my $x2 = $dataoffset + ($step+1) * $hspace - $radius;
      $segments .= "<line x1=\"$x1\" y1=\"$offset_y\" x2=\"$x2\" y2=\"$offset_y\" stroke=\"$branch{'color'}[$i]\" stroke-width=\"$stroke\" />";
      $started = 1;
    } elsif (m/(\d)/) {
      my $color = $branch{'color'}[$i];
      if ($started) {
        # link
        my $x1 = $dataoffset + ($step-1) * $hspace;
        my $x2 = $dataoffset + ($step+1) * $hspace;
        $segments .= "<line x1=\"$x1\" y1=\"$offset_y\" x2=\"$x2\" y2=\"$offset_y\" stroke=\"$branch{'color'}[$i]\" stroke-width=\"$stroke\" />";
        $color = $branch{'color'}[$1];
      }
      # two arcs with control points
      my $start_x = $dataoffset + ($step-1) * $hspace + $radius;
      my $start_y = $1 * $vspace + $radius + $stroke;
      my $arc_1_start_x = $dataoffset + $step * $hspace - $radius*2;
      my $arc_1_start_y = $start_y;
      my $arc_1_ctrl_x = $dataoffset + $step * $hspace;
      my $arc_1_ctrl_y = $start_y;
      my $arc_1_end_x = $arc_1_ctrl_x;
      my $arc_1_end_y = $1 * $vspace + $radius + $stroke + ($i - $1)*$radius*2;
      my $arc_2_start_x = $arc_1_end_x;
      my $arc_2_start_y = $i * $vspace + $radius + $stroke + ($1-$i)*$radius*2;
      my $arc_2_ctrl_x = $arc_2_start_x;
      my $arc_2_ctrl_y = $i * $vspace + $radius + $stroke;
      my $arc_2_end_x = $dataoffset + $step * $hspace + $radius*2;
      my $arc_2_end_y = $i * $vspace + $radius + $stroke;
      my $end_x   = $dataoffset + ($step+1) * $hspace - $radius;
      my $end_y   = $i * $vspace + $radius + $stroke;
      $checkouts .= "<path d=\"M $start_x $start_y L $arc_1_start_x $arc_1_start_y C $arc_1_ctrl_x $arc_1_ctrl_y, $arc_1_ctrl_x $arc_1_ctrl_y, $arc_1_end_x $arc_1_end_y L $arc_2_start_x $arc_2_start_y C $arc_2_ctrl_x $arc_2_ctrl_y, $arc_2_ctrl_x $arc_2_ctrl_y, $arc_2_end_x $arc_2_end_y L $end_x $end_y\" stroke=\"$color\" stroke-width=\"$stroke\" fill=\"none\" />";
    } elsif (m/\s/) {
      $started = 0;
    }
    $step++;
  }
  $svg{'branch'}{$i} = {
    name => $branch{'name'}[$i],
    labels => $labels,
    segments => $segments,
    bubbles => $bubbles,
    checkouts => $checkouts
  };
}

# verbose(Dumper(\%svg));

# write SVG
open(my $out, '>:encoding(UTF-8)', $output) or die ("Could not open '$output'");
# descriptor
print $out "<?xml version=\"1.0\"?>\n";
print $out "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$svg{'size'}{'width'}\" height=\"$svg{'size'}{'height'}\">\n";
# content
foreach my $b (reverse sort keys($svg{'branch'})) {
  print $out "  <!-- branch $svg{'branch'}{$b}{'name'} -->\n";
  print $out "  <g>\n";
  print $out "    " . $svg{'branch'}{$b}{'checkouts'} . "\n";
  print $out "    " . $svg{'branch'}{$b}{'segments'} . "\n";
  print $out "    " . $svg{'branch'}{$b}{'bubbles'} . "\n";
  print $out "    " . $svg{'branch'}{$b}{'labels'} . "\n";
  print $out "  </g>\n";
}
# closing tag
print $out "<!-- thanks for using svgtree, see you soon -->\n";
print $out "<!-- at https://github.com/fmasclef/svgtree -->\n";
print $out "</svg>\n";
# release handle
close $out;
