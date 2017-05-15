#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';
use Template;
use File::Slurper 'read_lines';
use File::Basename;
use File::Copy;

my $OUT = "www";

my @content = read_lines('3000.txt');

my %abeceda;
my %slovicka;

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
		INCLUDE_PATH => 'src',
		ENCODING => 'utf8',
		VARIABLES => {
		 version => 1
   },
});

use Data::Printer;

for my $pismeno (sort keys %slovicka) {
#p $slovicka{$pismeno};
	$t->process('pismeno.html',
		{ 
			'title' => $pismeno,
			'slovicka' => $slovicka{$pismeno},
		},
		"$OUT/$pismeno.html",
		{ binmode => ':utf8' }) or die $t->error;
}

$t->process('index.html',
	{ 
		'title' => 'Slovíčka',
		'abeceda' => \%abeceda,
	},
	"$OUT/index.html",
	{ binmode => ':utf8' }) or die $t->error;

foreach my $dir (('css', 'img', 'font', 'js')){
	foreach my $file (glob("src/$dir/*")){
		my ($name,$path) = fileparse($file);
		copy("$path$name", "$OUT/$name");
	}
}
