#!/usr/bin/perl

use strict;
use warnings;

no warnings 'redefine';

use utf8;
use open ':std', ':encoding(UTF-8)';
use Template;
use File::Slurper 'read_lines';
use File::Basename qw(dirname fileparse);
use File::Copy;
use Digest::MD5::File qw(dir_md5_base64);
use Digest::CRC qw(crc32);
use Cwd;
use Getopt::Long;
use List::Compare;

my @dir = split(/\//, getcwd);
my $dir = pop(@dir);

my $IN = 'src';
my $appname = 'Anglická slovíčka';
my $appshortname = 'Slovíčka';
my $appdesc = 'Základní anglická slovíčka';

my $domain = undef;
my $OUT = undef;

GetOptions (
	  "domain=s" => \$domain,
	  "out=s" => \$OUT,
)
 or die("Error in command line arguments\n");

my @content = read_lines('3000.txt');

use TeX::Hyphen;

sub TeX::Hyphen::visualize {
        my ($self, $word, $separator) = (shift, shift, shift);
        my $number = 0;
        my $pos;

        for $pos ($self->hyphenate($word)) {
                substr($word, $pos + $number, 0) = $separator;
                $number = $number + length($separator);;
        }
        return $word;
}

my $hypcz = new TeX::Hyphen 'file' => 'czhyph.tex',
        'style' => 'czech', leftmin => 2,
        rightmin => 2;

my $hypen = new TeX::Hyphen 'file' => 'ukhyphen.tex',
        'style' => 'czech', leftmin => 2,
        rightmin => 2;

my %abeceda;
my %pridat;
my %slovicka;

my $md5 = dir_md5_base64($IN);
my $cachebuster = crc32(join('', sort values %{$md5}));
my $cacheversion = scalar time;
my $wbr = '&shy;';

foreach my $line (@content){
	my ($en, $cz) = split /:/, $line;
	my $fl = lc($en);
	$fl =~ s/^(.).*/$1/;
	if($abeceda{$fl}){
		$abeceda{$fl}++;
	}else{
		$abeceda{$fl} = 1;
	}
	$slovicka{$fl}{$hypen->visualize($en, $wbr)} = $hypcz->visualize($cz, $wbr);
	my $zbytek = $abeceda{$fl} % 6;
}

for my $pismeno (sort keys %abeceda) {
	my $zbytek = $abeceda{$pismeno} % 6;
	$pridat{$pismeno} = 6 - $zbytek;
}

my $t = Template->new({
		INCLUDE_PATH => $IN,
		ENCODING => 'utf8',
		VARIABLES => {
		 version => 1,
		 cachebuster => $cachebuster,
		 cacheversion => $cacheversion,
		 appname => $appname,
		 appshortname => $appshortname,
		 appdesc => $appdesc,
		 dir => $dir,
		 domain => $domain,
   },
});

for my $pismeno (sort keys %slovicka) {
	$t->process('pismeno.html',
		{ 
			'title' => $appname . ' - '. uc $pismeno,
			'slovicka' => $slovicka{$pismeno},
			'pismeno' => $pismeno,
			'pridat' => \%pridat,
		},
		"$OUT/$pismeno.html",
		{ binmode => ':utf8' }) or die $t->error;
}

$t->process('index.html',
	{ 
		'title' => $appname,
		'abeceda' => \%abeceda,
	},
	"$OUT/index.html",
	{ binmode => ':utf8' }) or die $t->error;

$t->process('404.html',
	{ 
		'title' => 'Stránka nenalezena',
	},
	"$OUT/404.html",
	{ binmode => ':utf8' }) or die $t->error;

my @files = (
	'slovicka.css',
	'browserconfig.xml',
	'manifest.json',
	'slovicka.js',
	'sw.js',
	'app.js',
);

for my $file (@files){

	my @staresoubory = glob("$OUT/*-$file");
	my $novysoubor = "$OUT/$cachebuster-$file";
	my @nove = ($novysoubor);

	$t->process($file ,{
		'abeceda' => \%abeceda,
	},
		$novysoubor,
		{ binmode => ':utf8' }) or die $t->error;

	my $lc = List::Compare->new( { lists => [\@nove, \@staresoubory] } );
	my @smazat = $lc->get_complement;
	unlink @smazat;
}

foreach my $file (glob("$IN/img/*")){
	my ($name,$path) = fileparse($file);

	my @staresoubory = glob("$OUT/*-$name");
	my $novysoubor = "$OUT/$cachebuster-$name";
	my @nove = ($novysoubor);

	copy("$path$name", $novysoubor);

	my $lc = List::Compare->new( { lists => [\@nove, \@staresoubory] } );
	my @smazat = $lc->get_complement;
	unlink @smazat;
}
