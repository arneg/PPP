
my $string;

while(defined(my $line = readline(*STDIN))) {
    $string .= $line;
}
$string =~ s/([^\\])"/$1\\"/g;
$string =~ s/\n/\\\n/g;

print '#"' . $string . '"';
