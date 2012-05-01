#!/usr/bin/perl

    local ($buffer, @pairs, $pair, $name, $value, %FORM);
    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    }else {
	$buffer = $ENV{'QUERY_STRING'};
    }
    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
	($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%(..)/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
    }
    $first_name = $FORM{first_name};
    $last_name  = $FORM{last_name};


my $sessionID = $FORM{'sessionID'};
my $email = $FORM{'email'};
my $rowColumn = $FORM{'rowColumn'};
my $manualFields = $FORM{'manualFields'};
my @lines = split('\n', $manualFields);

print "Content-type:text/html\r\n\r\n";
print '<html><head><meta HTTP-EQUIV="REFRESH" content="3; url=../GUAVA/output"></head>';
print '<body>';

if ($rowColumn == 1) { $rowColumn = "Row"; } else { $rowColumn = "Column"; }

# Generate the guava csv file
print "Generating <b>$sessionID.csv</b> ... ";

open(CSV, ">../GUAVA/output/$sessionID.csv") || die "Error opening $sessionID.csv";
my $header = " Sample ID, Sample well, Sample volume (ml), Dilution factor, Events to Acquire, Time Limit, Replicates, Autosave FCS 2.0 files, Mix Time (sec), Mix Speed (rpm),, General settings,\n";
$header = $header . ", T1, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Assay Type, InCyte\n";
$header = $header . ", T2, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Acquisition Order, by $rowColumn\n";
$header = $header . ", T3, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Do Clean,Every 24 samples\n";
$header = $header . ", T4, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Wash only capillary,Yes\n";
$header = $header . ", T5, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Wash both capillary and mixer,Yes\n";
$header = $header . ", T6, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Mixing,Yes\n";
$header = $header . ", T7, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Cleaning Option,Clean and Rinse\n";
$header = $header . ", T8, 10.000000, 1.000000, 5000, 600, No, No, 3, High,,Limit for high concentration warning (cells/uL),500\n";
$header = $header . ", T9, 10.000000, 1.000000, 5000, 600, No, No, 3, High\n, T10, 10.000000, 1.000000, 5000, 600, No, No, 3, High\n";

print CSV $header;
foreach $line (@lines) {
	chomp $line;
	$line =~ s///;		# When submitting a form, all browsers canonicalize newlines to \r\n
	print CSV "$line\n";
	}
close(CSV);

print "done!<br/>";
print "Generating <b>$sessionID.html</b> ... ";

my %well = ('1'=>'A', '2'=>'B', '3'=>'C', '4'=>'D', '5'=>'E', '6'=>'F', '7'=>'G', '8'=>'H');

open(HTML, ">../GUAVA/output/$sessionID.html") || die "Error opening $sessionID.html";
# Generate the html layout file here

print HTML '<html><head><style type="text/css">table { border-width: 0 0 1px 1px; border-style:solid; } td { border-color: #600; border-width: 1px 1px 0 0; border-style: solid; margin: 0; padding: 4px; text-align:center; } td.dark { background-color:#E3E3E3; } td.light { background-color:#FFFFFF; } td.empty {color:#999999; } </style></head>' . "\n";

print HTML "<body><h1>GUAVA LAYOUT</h1><h2>SessionID: $sessionID</h2>\n";
print HTML "<h2>Date: " . `date "+%Y-%m-%d%n"` . "</h2>\n";
print HTML '<table border="1">';
print HTML '<tr>    <td>*</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td>12</td></tr>' . "\n";

my $row = 1;
print HTML "<tr><td class=\"light\">" . $well{$row} . "</td>\t";

my $collumn = 0;

foreach $line (@lines) {
	chomp $line;
	$line =~ s///;
	my @fields = split(/,/,$line);
	my $css;

	if ($collumn++ == 12) { $row++; $collumn -= 12; print HTML "</tr>\n<tr><td class=\"$css\">$well{$row}</td>"; }

	if (($row <= 4) && ($collumn % 2 == 1)) { $css = "dark"; }
	elsif (($row <= 4) && ($collumn % 2 == 0)) { $css = "light"; }
	elsif (($row >= 4) && ($collumn % 2 == 1)) { $css = "light"; }
	else { $css = "dark"; }

	if ($fields[0] eq "") { print HTML "<td class=\"empty\"><i>empty</i></td>\t"; }
	else { print HTML "<td class=\"$css\">$fields[0]</td>\t"; }
	}
print HTML "</table></body></html>";

close(HTML);

print "done!<br/>";

print "Emailing <b>$email</b> ...";

use MIME::Lite;
use Net::SMTP;

my $destination = $email;
my $cc = 'zbrumme@sfu.ca, mark_brockman@sfu.ca';
my $subject = "GUAVA LAYOUT: $sessionID";
my $mainText = 	"SessionID: $sessionID (FILES ATTACHED)\n\nThis is an automatically generated email, please do not respond!\n\n" .
		"Note: all guava layout files can be found at http://brockman-srv.mbb.sfu.ca/~B_Team_iMac/GUAVA/output/";
my $csvPath = "../GUAVA/output/$sessionID" . ".csv";
my $csvName = $sessionID . ".csv";

my $layoutPath = "../GUAVA/output/$sessionID" . ".html";
my $layoutName = $sessionID . ".html";

$msg = MIME::Lite->new( From => 'guava.layout@sfu.ca', To => $destination, Cc => $cc, Subject => $subject, Type => 'multipart/mixed', );
$msg->attach( Type => 'TEXT', Data => $mainText );
$msg->attach( Type => 'application/zip', Path => $csvPath,Filename => $csvName,Disposition => 'attachment' );
$msg->attach( Type => 'application/zip', Path => $layoutPath, Filename => $layoutName, Disposition => 'attachment' );
$msg->send('smtp','mailhost.sfu.ca', Debug=>0 );

# Archive old files
print "done!<br/>";
print "Archiving old files (<b>> 30 days old</b>) ...";
my $oldFiles = `find /Users/B_Team_iMac/Sites/GUAVA/output/* -mtime +30`;
system("mv `find /Users/B_Team_iMac/Sites/GUAVA/output/* -mtime +30` /Users/B_Team_iMac/Sites/GUAVA/output/old/");

print "done!<br/></body></html>";
