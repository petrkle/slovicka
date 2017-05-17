#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';
use Template;
use File::Slurper 'read_lines';
use File::Basename qw(dirname fileparse);
use File::Copy;
use Digest::MD5::File qw(dir_md5_base64);
use Digest::CRC qw(crc32);
use Cwd;

my @dir = split(/\//, getcwd);
my $dir = pop(@dir);

my $OUT = 'www';
my $IN = 'src';
my $appname = 'Anglická slovíčka';
my $appshortname = 'Slovíčka';
my $appdesc = 'Základní anglická slovíčka';

my @content = read_lines('3000.txt');

my %abeceda;
my %slovicka;

my $md5 = dir_md5_base64($IN);
my $cachebuster = crc32(join('', sort values %{$md5}));
my $cacheversion = scalar time;

foreach my $line (@content){
	my ($en, $cz) = split /:/, $line;
	my $fl = lc($en);
	$fl =~ s/^(.).*/$1/;
	if($abeceda{$fl}){
		$abeceda{$fl}++;
	}else{
		$abeceda{$fl} = 1;
	}
	$slovicka{$fl}{$en} = $cz;
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
		 domain => 'https://kle.cz',
   },
});

for my $pismeno (sort keys %slovicka) {
	$t->process('pismeno.html',
		{ 
			'title' => $appname . ' - '. uc $pismeno,
			'slovicka' => $slovicka{$pismeno},
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

my @files = (
	'slovicka.css',
	'browserconfig.xml',
	'manifest.json',
	'slovicka.js',
	'sw.js',
	'app.js',
);

for my $file (@files){
	$t->process($file ,{
		'abeceda' => \%abeceda,
	},
		"$OUT/$cachebuster-$file",
		{ binmode => ':utf8' }) or die $t->error;
}

foreach my $file (glob("src/img/*")){
	my ($name,$path) = fileparse($file);
	copy("$path$name", "$OUT/$cachebuster-$name");
}
