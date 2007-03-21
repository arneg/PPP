
my $string;

while(defined(my $line = readline(*STDIN))) {
    $string .= $line;
}
$string =~ tr/\[\{\}\]/\{\[\]\}/;
$string =~ s/\{/({/g;
$string =~ s/\}/})/g;
$string =~ s/\[/([/g;
$string =~ s/\]/])/g;

print $string;
