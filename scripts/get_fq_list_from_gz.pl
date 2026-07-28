#!/usr/bin/perl -w
use warnings;
#Usage: 
#perl .pl
#this script will output all files and path in 'all_file_list.txt'

$sys = "\/\*";
$cjw = system("ls -d \"\$PWD\"$sys > all_file_list.txt"); #if 'system' runs successfully, $cjw == 0 else ==512
print "touch all files from $sys\n";
while($cjw == 0){
	$sys = "$sys\/\*";
	$cjw = system("ls -d \"\$PWD\"$sys >> all_file_list.txt");
	if($cjw == 0){print "touch all files from $sys\n";}
	if($cjw != 0){print "program stops at $sys\n";}
}

open II, "./all_file_list.txt";
open OU, ">./temp_cjw";
while (<II>) {
	chomp;
	if (m/\.gz$/) { #<------adjust to get target
	print OU "$_\n";
	}
}
close II;
close OU;

open OU1, ">./fq_list";
open II, "./temp_cjw";
while (<II>) {
	chomp;
	$odd = $_;
	$str1 = (split /\//,$_)[-1];
	$str = (split /\./,$str1)[0];
	print OU1 "$str\t";
	print OU1 "$odd\t";
	$even = <II>;
	chomp($even);
	print OU1 "$even\n";
	}
close II;
close OU1;

system("rm all_file_list.txt");
system("rm temp_cjw");
print "some warning from 'ls' is expected, pls check fq_list\n";


