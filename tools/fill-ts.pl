# fill-ts.pl <file.ts> <translations.txt>
# translations.txt: "id<TAB>text" per line, id = position of the message in the .ts (1-based),
# "\n" for line breaks, plural forms separated by " || ".
use utf8;
use strict;
binmode STDOUT, ':utf8';
my ($ts, $tr) = @ARGV;
my %t;
open my $f, '<:utf8', $tr or die "$tr: $!";
while (<$f>) {
    s/\r?\n$//;
    next unless /^(\d+)\t(.*)$/;
    $t{$1} = $2;
}
close $f;
open my $g, '<:utf8', $ts or die "$ts: $!";
local $/; my $x = <$g>; close $g;
sub esc { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/\\n/\n/g; return $s; }
my $i = 0; my $filled = 0;
$x =~ s{(<message(?: numerus="yes")?>.*?)<translation type="unfinished">(.*?)</translation>}{
    my ($head, $old) = ($1, $2);
    # count every message, also finished ones in between
    my $n = () = $head =~ /<message/g; $i += $n;
    if (exists $t{$i}) {
        $filled++;
        if ($head =~ /numerus="yes"/) {
            my @forms = split / \|\| /, $t{$i};
            $head . "<translation>" . join('', map { "\n            <numerusform>" . esc($_) . "</numerusform>" } @forms) . "\n        </translation>";
        } else {
            $head . "<translation>" . esc($t{$i}) . "</translation>";
        }
    } else { $head . "<translation type=\"unfinished\">$old</translation>"; }
}gse;
open my $o, '>:utf8', $ts or die; print $o $x; close $o;
my $total = () = $x =~ /<message/g;
my $left = () = $x =~ /type="unfinished"/g;
print "$ts: filled $filled, unfinished left $left of $total\n";
