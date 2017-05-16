#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';
use Template;
use File::Slurper 'read_lines';
use File::Basename;
use File::Copy;
use File::Find::Rule;
use Digest::MD5::File qw(dir_md5_base64);
use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc crc8);

my $OUT = 'www';
my $IN = 'src';

my @content = read_lines('3000.txt');

my %abeceda;
my %slovicka;

my $md5 = dir_md5_base64($IN);
my $cachebuster = crc32(join('', sort values %{$md5}));

foreach my $line (@content){
	my ($en, $cz) = split /:/, $line;
	my $fl = $en;
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
   },
});

my $appname = 'Anglická slovíčka';

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

my @files = ('slovicka.css', 'browserconfig.xml', 'manifest.json', 'slovicka.js');

for my $file (@files){
	$t->process($file ,{},
		"$OUT/$cachebuster-$file",
		{ binmode => ':utf8' }) or die $t->error;
}

foreach my $dir ('img', 'js'){
	foreach my $file (glob("src/$dir/*")){
		my ($name,$path) = fileparse($file);
		copy("$path$name", "$OUT/$cachebuster-$name");
	}
}
