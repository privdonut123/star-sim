#!/usr/bin/perl

use strict;
use warnings;
use lib '/star/u/dkap7827/Tools2/Tools/PerlScripts';
use CondorJobWriter;
use Cwd qw(abs_path);
use Getopt::Long qw(GetOptions);
use Getopt::Long qw(HelpMessage);
use Pod::Usage;

=pod

=head1 NAME

MakeJob - Handy script for submitting condor jobs for FCS analysis and checking job output

=head1 SYNOPSIS

MakeJob.pl [-a I<path{.}>] E<lt>-d I<path>E<gt> [-o I<path{.}>] [-m I<type{mudst}>] [-u I<name>] [-p I<"Message">] [-n I<nevents>] [-t] [-w] [-e] [--old] [-v I<level{1}>] [E<lt>-c stringE<gt> [-r I<int>]] [-h]

=over 4

=item B<-a> anlaysis code directory

=item B<-d> data file or directory with files (not needed for I<simflat> and I<simflatbfc>)

=item B<-o> directory to store output

=item B<-m> I<type>s: I<mudst>, I<multimudst>, I<simflat>, I<simflatbfc>, I<simbfc>, I<daq> 

=item B<-u> the I<name> of the directory to create in output directory (default is random UID)

=item B<-p> I<"Message"> to put in Summary file

=item B<-n> I<number> of events to process for a single file

=item B<-t> test mode

=item B<-w> no stdout

=item B<-e> no stderr

=item B<--old> force to write condor job files in old format

=item B<-v> set print out I<level>

=item B<-c> search string to check job

=item B<-r> I<int> recreated job level to be used with checking output option B<-c> in job folder B<-d>

=item B<-f> dont check if condor, log, and Output directories are empty

=item B<-h> ignore all other options, print this help, and exit; for more information do C<perldoc MakeJob.pl>

=back

=head1 OPTIONS

=over 4

=item B<-a> I<path>, B<--ana>=I<path>

Directory where analysis code is (files checked: F<runMudst.C>, F<runSimFlat.C>, F<runSimBfc.C>, may also need .$STAR_HOST_SYS) (default is current directory)

=item B<-d> I<path/file>, B<--data>=I<path>

Directory where data is located or file that contains file locations for the data (i.e. daq files, mudst files, fzd files). Note that only modes I<simflat> and I<simflatbfc> do need to specify this. For mudst, input file should be a new line seperated list of files in the format I<path/name/events/size>.

=item  B<-o> I<path> B<--out>=I<path>

Directory where to create files for the job, creates a seperate ID for each job so only need a generic location (default is current directory)

=item B<-c> I<string>, B<--check>=I<string>

Check if all files in the summary match the ones in the output folder. The string is the prefix of the output file name to use. The file name is expected to look like string_runnumber_iteration.root. The directory checked is the one passed to B<-d>.

=item B<-r> I<int>, B<--missing>=I<int>

Option to generate a new condor job file based on missing output files in job folder B<-d>. I<int> specifies recreation level. Output file prefix must be specified from B<-c>. Option B<-w> and B<-e> can be used to turn on and off output and error files

=item B<-m> I<type>, B<--mode>=I<type>

Kind of job to submit: daq, mudst, multimudst, simflat, simflatbfc, simbfc (default is mudst) (simflat is just single particle gun, simflatbfc is particle gun and BFC analysis, simbfc is just BFC analysis on preexisting fzd files). multimudst is a special mode where you pass a directory containing a set of list files and it creates jobs for each list file. Since it generates a perl script instead of a csh script, you need to be in the proper environment before submitting jobs

=item B<-p> I<"Message">, B<--msg>=I<"Message">

Print a message into the summary file about the job

=item B<-n> I<number>, B<--nevents>=I<number>

Number of events to process (default is 1000 except when testing in which case it is 10)

=item B<-t>, B<--test>

Test only, creates a test directory and only processes 5 data files

=item B<-u> I<name>, B<--uuid>=I<name>

Overwrite the UUID tag to use a custom folder name where everything will go

=item B<-w>, B<--noout>

Don't write to stdout

=item B<-e>, B<--noerr>

Don't write to stderr

=item B<--old>

Flag to force the code to use #CondorJobWriter::WriteJobOld()

=item B<-v> I<level>, B<--verbose>=I<level>

Set the printout level (default is 1)

=item B<-h>, B<--help>

Print this help and ignore all other options

=back

=head1 VERSION

0.5.1

=head1 DESCRIPTION

This program will create job files for submitting FCS jobs. It will then use "CondorJobWriter" to generate folders and files for submitting the executable for the Fms Qa to condor batch system to be executed.

=head1 CAVEATS

This software was designed to work with only very specific kinds of ROOT macros in the FCS framework. The macros listed above had very specific kinds of arguments and this software assumes that you are using a macro with those very specific arguements.

=head1 AUTHOR

David Kapukchyan

=cut

=begin comment

@[December 1,2022](David Kapukchyan)
> First instance

@[October 19, 2023](David Kapukchyan)
> Added histogram collection classes from MyTools to be written to the generated rootmap file. Also no longer removing fzd file in #WriteSimFlatMacro()

@[October 31, 2023](David Kapukchyan)
> [Version 0.2] Modified how the sim option works to be able to run either runSimFlat.C (simflat), runSimBfc.C (simbfc), or both runSimFlat.C and runSimBfc.C (simflatbfc). Option 'simbfc' requires a data directory to be specified with '-d'. Option 'simflatbfc' will delete any fzd files that have been generated. Also fixed issue where relative paths did not work with '-d' option and '-o' option. Got rid of ".rootmap" generation since that should happen at the cmake building and installing step.

@[Novemeber 2, 2023](David Kapukchyan)
> Fixed an issue where the simbfc option was not picking up pid's that contain '+' or '-' characters from the fzd file name. Also changed it to use '+' for matching so that it looks for at least 1 occurence in the file name

@[November 9, 2023](David Kapukchyan)
> If a matching UUID is found in #OUTDIR asks to delete it rather than throwing an error

@[December 14, 2023](David Kapukchyan)
> Added capability to work with with files on xrootd servers

@[January 9, 2024](David Kapukchyan)
> Modified the Perl doc text

@[January 16, 2024](David Kapukchyan)
> Modified the "WriteCShell" scripts to check if the file being processes has zero size

@[February 19, 2024](David Kapukchyan)
> Now prints the command to the summary file.

@[March 4, 2024](David Kapukchyan)
> Added a way to extract the file size as well as events. This can be used to skip files with zero size. Also changed "-c" option for which previously you had to specifiy the search directory. Now "-c" will be used to specify the search strings for the missing files and you should use option "-d" to specify the directory in which to search for those files. Also when re-generating condor job files for missing files options "-w" and "-e" can be used to turn on or off writing to stdout and stderr respectively.

@[April 12, 2024](David Kapukchyan)
> Changed some daq options for testing them on a production request for Run 2022 data with no TPC tracking, fcs, ftt, and fst options. Also fixed the daq option because the newer version of this program uses the output name as the second argument and the daq option has no output name only an input which needs to provided as a second argument. I changed the #WriteBfcShellMacro() to use the third argument for the input file.

@[July 10, 2025](Kwuzhere)
> Added additional options for reading in Pythia files in the simbfc mode. Specifically, pythia_dy_vz0_run$RUN_NUMBER.fzd 

@[April 16, 2024](David Kapukchyan)
> Cleaned up #WriteBfcShellMacro() so it is easier to read and change the chain options.

@[May 23, 2024](David Kapukchyan)
> Implemented #MakeJobDirs() in CondorJobWriter.pm and use it here so that it creates all the directories at once then retrieves the condor folder name after it creates it.

@[July 9, 2024](David Kapukchyan)
> Option to quit at remove files prompt. Added total number of events to summary. File cap at 5000. Also now adds "raw" if it exists to output file name and appropriately adds it to the check option. Small fix to run macros for printout.

@[July 30, 2024](David Kapukchyan)
> Fixed documentation for script. Added #totalevents to count total events to process. Improved how to get hash for condor job file when remaking job file with option "r".

@[August 29, 2024](David Kapukchyan)
> Mode *daq* now copies the .$STAR_HOST_SYS folder in the specified *analysis* directory if it exists

@[September 16, 2024](David Kapukchyan)
> Mode *mudst* now copies the trigger map file "FcsSortedTrig.txt" for #StFcsRun22TriggerMap if it exists

@[January 30, 2025](David Kapukchyan)
> Made a new mode *multimudst* as well as related additions like a new script writing function #WriteMultiMudst() which generates a perl script for the job rather than a csh script. Added some code for cross-checking spin results; they are commented out because it is hacky but I will keep the code in case it is ever needed in the future. Haven't tested if the check job part of the script will work on jobs submitted using *multimudst* mode.

@[March 18, 2025](David Kapukchyan)
> Added Run 22 polarization file to jobs. Changed regex expression in main loop to handle single mudsts or mulitimusts which don't use the 7 digit format. Could be misused if not careful because now checks using one or more digits condition ("+").

@[July 23, 2025](David Kapukchyan)
> Modifications for submitting jobs from alma 9 nodes. Modified shell scripts to explicity use the $SCRATCH environment variable. Modified to be compatible with new #CondorJobWriter.

@[July 30, 2025](David Kapukchyan)
> Added a dummy csh file to the jobs generated in the multimudst mode because perl runs system commands as bash so when running perl the normal csh login doesn't get executed and the environment is all wrong. Running in a dummy csh script sets up the enviorment for perl to run correctly. This is particularly important for the Alma 9 nodes that run the STAR code in the `singularity` container.

=cut

#Here is the setup to check if the submit option was given
my $LOC = $ENV{'PWD'};
my $ANADIR = $LOC;
my $DATA = "";
my @DATAFILES;
#$DATADIR = "/gpfs01/star/pwg_tasks/FwdCalib/DAQ/23080044";
my $OUTDIR = $LOC;
my $CHECKSTR = "";
my $DOMISSING = 0;
my $VERBOSE = 1;
my $NEVENTS = -1;
my $UUID;
my $TEST;
my $NOWRITESTDOUT;
my $NOWRITESTDERR;
my $MODE = "mudst";
my $MSG = "";
my $FORCE;
my $SIM = 0; #Boolean for simulations
#my $DEBUG;
my $OLDJOB = 0;   #Boolean to indicate writing condor jobs using old condor format
my $ALMA9JOB = 0; #Boolean for indicating jobs submitted through Alma 9, checks internally if host contains 'starsub'

my $thiscommand = "$0";
foreach my $arg (@ARGV){ $thiscommand = "$thiscommand" . " $arg"; }

GetOptions(
    'ana|a=s'     => \$ANADIR,
    'data|d=s'    => \$DATA,
    'out|o=s'     => \$OUTDIR,
    'check|c=s'   => \$CHECKSTR,
    'missing|r=i' => \$DOMISSING,
    'mode|m=s'    => \$MODE,
    'msg|p=s'     => \$MSG,
    'nevent|n=i'  => \$NEVENTS,
    'test|t'      => \$TEST,
    'noout|w'     => \$NOWRITESTDOUT,
    'noerr|e'     => \$NOWRITESTDERR,
    'old'         => \$OLDJOB,
    'uuid|u=s'    => \$UUID,
    'verbose|v=i' => \$VERBOSE,
    'force|f'     => \$FORCE,
    'help|h'      => sub { HelpMessage(0) }
    ) or HelpMessage(1);


if( $CHECKSTR ne "" ){
    if( -d "$DATA" ){
	$DATA = abs_path($DATA);
	my $char = chop $DATA; #Get last character of DATA
	while( $char eq "/" ){$char = chop $DATA;} #Remove all '/'
	$DATA = $DATA.$char; #Append removed character which was not a '/'
    }
    else{ print "ERROR:DataDir:'$DATA' is not a directory or does not exist: $!\n";  HelpMessage(0); }
}

if( $CHECKSTR ne "" && !$DOMISSING ){
    CompareOutput($DATA,$CHECKSTR,2); #Force print
    exit(0);
}

if( $DOMISSING ){
    if( ! $DATA ){ print "ERROR:Please provide directory using option 'd'"; HelpMessage(0); }
    
    my %MissingJobs = CompareOutput($DATA,$CHECKSTR,$VERBOSE);   #Print only when verbose>=2

    my $hash = "";
    opendir my $dh, "$DATA/condor/" or die "Could not open '$DATA/condor' for reading '$!'\n";
    while( my $file = readdir $dh ){
	if( $file =~ m/condor_(\w*).job/ ){
	    $hash = $1;
	    last;
	}
    }
    closedir $dh;
    if( $hash eq "" ){ die "Could not find the job hash(name)\n"; }

    open( my $oldcondor_fh, '<', "$DATA/condor/condor_$hash.job" ) or die "Could not open file '$DATA/condor/condor_$hash.job' for reading: $!";
    if( -f "$DATA/condor/condor${DOMISSING}_$hash.job" ){
	print "WARNING:condor${DOMISSING}_$hash.job exists!\nOverwrite(Y/n): ";
	my $input = <STDIN>; chomp $input;
	if( $input ne "Y" ){ die "Quitting to prevent overwrite of condor${DOMISSING}_$hash.job\n"; }
    }
    open( my $newcondor_fh, '>', "$DATA/condor/condor${DOMISSING}_$hash.job" ) or die "Could not open file '$DATA/condor/condor${DOMISSING}_$hash.job' for writing: $!";

    while( my $oldline = <$oldcondor_fh> ){
	if( $oldline =~ /##### \d*/ ){
	    my $jobnumber = $oldline;
	    $jobnumber =~ s/##### //;
	    $jobnumber += 0;
	    #chomp $oldline; print "$oldline | $jobnumber\n";
	    if( $MissingJobs{$jobnumber} ){
		print $newcondor_fh $oldline;
		while( $oldline = <$oldcondor_fh> ){
		    print $newcondor_fh $oldline;
		    if( $oldline =~ m/Log/ ){
			my $logline = $oldline;
			chomp $logline;
			$logline = substr($logline, 3);     #prefix "Log" is length 3
			$logline = substr($logline, 0, -3); #suffix "log" is length 3 at the end
			#print "$logline\n";
			if( ! $NOWRITESTDOUT ){ print $newcondor_fh "Output${logline}out\n"; }
			if( ! $NOWRITESTDERR ){ print $newcondor_fh "Error${logline}err\n";  }
		    }
		    if( $oldline =~ m/Output/ ){ next; } #This is being written in the check for the "Log" line
		    if( $oldline =~ m/Error/  ){ next; } #This is being written in the check for the "Log" line
		    if( $oldline eq "\n" ){ last; } #The condor job file always has a new line separting different job indexes
		}
	    }
	}
    }
    
    exit(0);
}
    

if( !(-d "$ANADIR") ){ HelpMessage(0); }#die "Directory $ANADIR is not a directory or does not exist: $!"; }
else{
    my $char = chop $ANADIR; #Get last character of ANA
    while( $char eq "/" ){$char = chop $ANADIR;} #Remove all '/'
    $ANADIR = $ANADIR.$char; #Append removed character which was not a '/'
}
if( $VERBOSE>=1 ){ print "ANADIR=$ANADIR\n"; }
if( $VERBOSE>=2 ){ print "Contents ANADIR\n"; `ls $ANADIR`; }

my $CshellMacro = "";
if(    $MODE eq "daq"     ){ $CshellMacro = "RunBfc.csh";     }
elsif( $MODE eq "mudst"   ){ $CshellMacro = "RunMuDst.csh";   }
elsif( $MODE eq "multimudst"){ $CshellMacro = "RunMultiMuDst.csh"; }
elsif( $MODE eq "simflat" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = 1;}
elsif( $MODE eq "simflatbfc" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = 1;}
elsif( $MODE eq "simbfc" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = -1}  #It is still sim files but the directory or list of files should be specfied with -d
elsif( $MODE eq "picodst" ){ $CshellMacro = "RunPicoDst.csh"; }
# TESTING: adding option for pythia sim fzd files
elsif( $MODE eq "pythia" ){ $CshellMacro = "RunSimBfc.csh"; $SIM = 1; }
else{ print "Invalid Mode: $MODE\n"; HelpMessage(0); }

if( $ENV{'HOST'} =~ /starsub\d+/ ){
    $ALMA9JOB = 1;
}
#@[July 23, 2025] > Hack to fix the star environment to use the rcas compilied library because STAR doesn't compile on Alma 9 which has a different STAR_HOST_SYS
if( $ALMA9JOB ){ $ENV{'STAR_HOST_SYS'} = "sl73_x8664_gcc485"; }

if( $SIM > 0 ){
    #Create simulation files
    foreach my $i (0..99){
	#This will be the argument list use by job writer. Number of events will be added in the for loop that writes the job file so it is missing here
	#seed pid energy pt vz npart
	push @DATAFILES, "$i mu- 30 0 0 1";
	#push @DATAFILES, "$i pi0 10 0 0 1";
    }
}
else{
    if( !(-e "$DATA") ){ print "ERROR:DataDir:'$DATA' does not exist: $!\n";  HelpMessage(0); }
    else{
	if( -f "$DATA" ){
	    open( my $data_fh, '<', $DATA ) or die "Could not open file '$DATA' for reading: $!";
	    while( my $line = <$data_fh> ){
		chomp $line;
		push @DATAFILES, $line;
		if( $VERBOSE>=3 ){ print "$line\n"; }
	    }
	}
	elsif( -d "$DATA" ){
	    $DATA = abs_path($DATA);
	    my $char = chop $DATA; #Get last character of DATA
	    while( $char eq "/" ){$char = chop $DATA;} #Remove all '/'
	    $DATA = $DATA.$char; #Append removed character which was not a '/'
	    opendir my $dh, $DATA or die "Could not open '$DATA' for reading '$!'\n";
	    while( my $datafile = readdir $dh ){
		if( $VERBOSE>=3 ){ print "$datafile\n"; }
		if( $MODE eq "daq" ){
		    if( $datafile =~ m/st_fwd_\d{8}_\w*.daq/ ){
			push @DATAFILES, "$DATA/$datafile";
			if( $VERBOSE>=2 ){ print " - $datafile\n"; }
		    }
		}
		if( $MODE eq "mudst" ){
		    if( $datafile =~ m/st_fwd_\d{8}_\w*.MuDst.root/ ){
			push @DATAFILES, "$DATA/$datafile";
			if( $VERBOSE>=2 ){ print " - $datafile\n"; }
		    }
		}
		if( $MODE eq "multimudst" ){
		    if( $datafile =~ m/Files_\d{8}_\d+.list/ ){
			push @DATAFILES, "$DATA/$datafile";
			if( $VERBOSE>=2 ){ print " - $datafile\n"; }
		    }
		}
		if( $MODE eq "simbfc" ){
		    #Read the relevant parameters from the file name
		    if( $datafile =~ m/pythia\.([\w+-]+)\.vz(\d+)\.run(\d+)\.fzd/ ){
			my ($i, $pid, $vz ) = ($3, $1, $2);
			push @DATAFILES, "$i $pid 0 0 $vz 0 $DATA/$datafile"; #@[October 31, 2023] > Not tested
			if( $VERBOSE>=2 ){ print " - $i $pid $vz | $datafile\n"; }
		    }
            # TESTING: alternate pythia file name format
            if( $datafile =~ m/pythia\_([\w+-]+)\_vz(\d+)\_run(\d+)\.fzd/ ){
            my ($i, $pid, $vz ) = ($3, $1, $2);
            push @DATAFILES, "$i $pid 0 0 $vz 0 $DATA/$datafile"; #@[October 31, 2023] > Not tested
            if( $VERBOSE>=2 ){ print " - $i $pid $vz | $datafile\n"; }
            }
            # TESTING: another pythia file name format
            if( $datafile =~ m/pythia8\_mb\_run(\d+)\.fzd/ ){
            my ($i, $pid, $vz ) = ($1, "mb", 0);
            push @DATAFILES, "$i $pid 0 0 $vz 0 $DATA/$datafile"; #@[October 31, 2023] > Not tested
            if( $VERBOSE>=2 ){ print " - $i $pid $vz | $datafile\n"; }
            }
		    if( $datafile =~ m/([\w+-]+)\.e(\d+)\.vz(\d+)\.run(\d+)\.fzd/ ){
			my ($i, $pid, $e, $vz) = ($4, $1, $2, $3);
			push @DATAFILES, "$i $pid $e 0 $vz 1 $DATA/$datafile";
			if( $VERBOSE>=2 ){ print " - $i $pid $e $vz | $datafile\n"; }
		    }
		    if( $datafile =~ m/([\w+-]+)\.pt(\d+\.?\d*)\.vz(\d+)\.run(\d+)\.fzd/ ){
			my ($i, $pid, $pt, $vz) = ($4, $1, $2, $3);
			push @DATAFILES, "$i $pid 0 $pt $vz 1 $DATA/$datafile"; #@[October 31, 2023] > Not tested
			if( $VERBOSE>=2 ){ print " - $i $pid $pt $vz | $datafile\n"; }
		    }
		}
        if($MODE eq "picodst"){
            if( $datafile =~ m/st_physics_\d{8}_\w*.picoDst.root/ ){
                push @DATAFILES, "$DATA/$datafile";
                if( $VERBOSE>=2 ){ print " - $datafile\n"; }
            }
        }
	    }
	    closedir $dh;
	}
	else{ print "ERROR:DataDir:'$DATA' is not a directory or file:$!\n";  HelpMessage(0); }
    }
}

if( $VERBOSE>=1 ){ print "DATA=$DATA\n"; }

if( !(-d "$OUTDIR") ){ system("/bin/mkdir $OUTDIR") == 0 or die "Unable to make '$OUTDIR': $!"; }
$OUTDIR = abs_path($OUTDIR);
my $char = chop $OUTDIR; #Get last character of OUTDIR
while( $char eq "/" ){$char = chop $OUTDIR;} #Remove all '/'
$OUTDIR = $OUTDIR.$char; #Append removed character which was not a '/'
if( $VERBOSE>=1 ){ print "OUTDIR=$OUTDIR\n"; }
if( $VERBOSE>=2 ){ print "Contents OUTDIR\n"; `ls $OUTDIR`; }

#Get Time
my $epochtime = time();            #UNIX time (seconds from Jan 1, 1970)
my $localtime = localtime();       #Human readaable time

my $UUID_short = "";
if( ! $UUID ){
    $UUID = $TEST ? "TEST\n" : uc(`uuidgen`);#Command that generates a UUID in bash
    chomp($UUID);
    $UUID =~ s/-//g;
    $UUID_short = substr($UUID,0,7); #Shortened 7 character UUID for file location.
}
else{
    my $char = chop $UUID; #Get last character of UUID
    while( $char eq "/" ){$char = chop $UUID;} #Remove all '/'
    $UUID = $UUID.$char; #Append removed character which was not a '/'
    $UUID_short = $UUID;
}
if( $VERBOSE>=1 ){print "Job Id: $UUID\n"};
if( $VERBOSE>=2 ){ print "Shortened UUID: $UUID_short\n"; }

my $FileLoc = "$OUTDIR/$UUID_short";  #Main location for files

if (! -e "$FileLoc") {system("/bin/mkdir $FileLoc") == 0 or die "Unable to make '$FileLoc': $!";}
else{
    if( $FORCE ){
        print "Force option is on. Removing all files in folder $FileLoc\n";
        system("/bin/rm -r $FileLoc/*") == 0 or die "Unable to remove files in '$FileLoc': $!";}
    else{ 
        print "Remove all files in folder $FileLoc (Y/n) or Q/q to quit:";
        my $input = <STDIN>; chomp $input;
        if( $input eq "Q" || $input eq "q" ){ print "Quitting\n"; exit 0; }
        elsif( $input eq "Y" ){system("/bin/rm -r $FileLoc/*") == 0 or die "Unable to remove files in '$FileLoc': $!";}
        else{ print "WARNING: No files removed from existing folder:${UUID_short}\n"; }
    }
}

if( $VERBOSE>=1 ){print "All Files to be written in '$FileLoc'\n";}

my $JobWriter = new CondorJobWriter($FileLoc,"${CshellMacro}","","${UUID_short}");  #Writes the condor job files
if( $NOWRITESTDOUT ){ $JobWriter->WriteStdOut(0); }
if( $NOWRITESTDERR ){ $JobWriter->WriteStdErr(0); }
if( $ALMA9JOB ){ $JobWriter->SetAlmaJob(1); }
#Need to create directory here since this is where executable gets installed
$JobWriter->MakeJobDirs($FORCE);  #if it doesn't exist: create condor directory, if it does exist:prompt for removal if not testing
my $CondorDir = $JobWriter->GetCondorDir();
#Because of the way condor job submission works the executable and the job file must be in the same directory, which is why most everything is set with respect to the condor directory

my $FileSummary = "$FileLoc/Summary_${UUID}.list";  #This file will describe the kind of job that was submitted and what the data it will contain
open( my $fh_sum, '>', $FileSummary ) or die "Could not open file '$FileSummary' for writing: $!";

print $fh_sum "UUID: $UUID\n";               #print UUID for job
print $fh_sum "Epoch Time: $epochtime\n";    #print UNIX time
print $fh_sum "Time: $localtime\n";          #print local time
print $fh_sum "Main directory: $LOC\n";      #print directory job was created on
print $fh_sum "Ana: $ANADIR\n";              #print analysis directory
print $fh_sum "Data: $DATA\n";               #print data directory/file
print $fh_sum "Out: $OUTDIR\n";              #print directory where the folder with the job UUID will go
print $fh_sum "Mode: $MODE\n";               #Print Mode (daq,mudst,simflat)
print $fh_sum "Macro: ${CshellMacro}\n";     #print Macro
print $fh_sum "Verbose: $VERBOSE\n";         #print verbose option
print $fh_sum "Node: $ENV{HOST}\n";          #print node job was submitted on
if( $MSG ){ print $fh_sum "$MSG\n"; }        #print a message about the job

#WriteRootMap("${ANADIR}");  #Creates a .rootmap file for autoloading classes in StFcsTreeManager

print "Making ${CshellMacro}\n";
if( $MODE eq "daq" ){
    WriteBfcShellMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
if( $MODE eq "mudst" ){
    #WriteMuDstShellMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    WriteCshellMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    system("/bin/cp $ANADIR/runMudst.C $CondorDir") == 0 or die "Unable to copy 'runMudst.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runMudst.C");
    if( system("/bin/cp $ANADIR/fcsgaincorr.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/fcsgaincorr.txt"); }
    else{ print "WARNING:Unable to copy 'fcsgaincorr.txt'"; }
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
    if( system("/bin/cp $ANADIR/FcsSortedTrig.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/FcsSortedTrig.txt"); }
    else{ print "WARNING:Unable to copy 'FcsSortedTrig.txt' - Fcs Trigger information will not be available"; }
    if( system("/bin/cp $ANADIR/Run22PolForJobs.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/Run22PolForJobs.txt"); }
    else{ print "WARNING:Unable to copy 'Run22PolForJobs.txt' - Run 22 Polarization information is missing"; }
}
if( $MODE eq "multimudst" ){
    #WriteMuDstShellMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    WriteMultiMudst( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    $JobWriter->AddInputFiles("$CondorDir/RunMultiMuDst.pl");
    system("/bin/cp $ANADIR/runMudst.C $CondorDir") == 0 or die "Unable to copy 'runMudst.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runMudst.C");
    if( system("/bin/cp $ANADIR/fcsgaincorr.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/fcsgaincorr.txt"); }
    else{ print "WARNING:Unable to copy 'fcsgaincorr.txt'"; }
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
    if( system("/bin/cp $ANADIR/FcsSortedTrig.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/FcsSortedTrig.txt"); }
    else{ print "WARNING:Unable to copy 'FcsSortedTrig.txt' - Fcs Trigger information will not be available"; }
    if( system("/bin/cp $ANADIR/Run22PolForJobs.txt $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/Run22PolForJobs.txt"); }
    else{ print "WARNING:Unable to copy 'Run22PolForJobs.txt' - Run 22 Polarization information is missing"; }
}
if( $MODE eq "simflat" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 0 );
    system("/bin/cp $ANADIR/runSimFlat.C $CondorDir") == 0 or die "Unable to copy 'runSimFlat.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimFlat.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
# TESTING: Option for pythia fzd files
if( $MODE eq "pythia" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 3 );
    system("/bin/cp $ANADIR/starsim.C $CondorDir") == 0 or die "Unable to copy 'starsim.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/starsim.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    system("/bin/mkdir $CondorDir/$starlibloc") == 0 or die "Could not create"; #-L to follow symlinks
    if( system("/bin/cp -r -L $ANADIR/$starlibloc/lib $CondorDir/$starlibloc") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
if( $MODE eq "simflatbfc" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 1 );
    system("/bin/cp $ANADIR/runSimFlat.C $CondorDir") == 0 or die "Unable to copy 'runSimFlat.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimFlat.C");
    system("/bin/cp $ANADIR/runSimBfc.C $CondorDir") == 0 or die "Unable to copy 'runSimBfc.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimBfc.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
if( $MODE eq "simbfc" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 2 );
    system("/bin/cp $ANADIR/runSimBfc.C $CondorDir") == 0 or die "Unable to copy 'runSimBfc.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimBfc.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
if( $MODE eq "picodst" ){
    WritePicoDstMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}" );
    system("/bin/cp $ANADIR/runPicoDst.C $CondorDir") == 0 or die "Unable to copy 'runPicoDst.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runPicoDst.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    else{ print "WARNING:Unable to copy '$starlibloc'"; }
}

#File paths need to relative to 'InitialDir'
#$JobWriter->AddInputFiles("condor/RunLibMudst.C,condor/libRunMudst.so");
#$JobWriter->AddInputFiles("/star/data03/daq/2022/040/23040001/st_fwd_23040001_raw_0000003.daq");

if( $VERBOSE>=1 ){
    print "Job Summary\n";
    if( $VERBOSE>=2 ){ print  "- Verbose: $VERBOSE\n"; }
    print "- UUID: ${UUID}\n";
    if( $VERBOSE>=2 ){ print "- ShortID: $UUID_short\n"; }
    if( $VERBOSE>=2 ){ print "- Submit Dir: $LOC\n"; }
    print "- Analysis Dir: $ANADIR\n";
    print "- Data: $DATA\n";
    print "- Output Dir: $OUTDIR\n";
    if( $VERBOSE>=2 ){
	print "  - Main Dir: ${FileLoc}\n";
        print "  - Condor Dir: ${CondorDir}\n";
    }
    print "- Mode: $MODE\n";
    print "- Condor Macro: ${CshellMacro}\n";
    print "- Date: $localtime\n";
    if( $VERBOSE>=2 ) {print  "- Epoch Time: $epochtime\n"; }
    print "- Node: $ENV{HOST}\n";
    if( $MSG ){ print "- MSG: $MSG\n"; }
}

if( $VERBOSE>=1 ){print "Making job file\n";}

my $numfiles = 0;
my $nevents = 0;
my $totalevents = 0;
my $input = $JobWriter->SetInputFiles();  #@[January 26, 2026] > Hack to grab input argument (and keep it constant) needed for mode multimudst because looping over all the files and adding them as input adds the file list to every subsequent job.
if( $NEVENTS<=0 ){ $nevents = $TEST ? 10 : 1000; }
else{ $nevents = $NEVENTS; }
foreach my $datafile (@DATAFILES){
    if( $numfiles==5 && $TEST ){last;}
    if( $numfiles==50000 ){ last; } #@[February 10, 2025] > Hack:Condor job writer cannot handle more than 50k
    #$JobWriter->SetArguments("100 st_fwd_23040001_raw_0000003.daq" );
    #$JobWriter->SetArguments("10000 st_fwd_23080044_raw_1000002.daq" );
    #$JobWriter->SetArguments("$nevents $datafile" ); //for simulations this is sufficient

    if( $VERBOSE>=2 ){ print "$datafile\n"; }
    if( $MODE ne "multimudst" ){
	my $name = $datafile;
	my $events = $nevents;
	my $runnum = "";    #STAR RunNumber
	my $segment = "";   #Segment number for a given STAR file with a given RunNumber
	my $extra = "";     #Any extra text between runnumber and iteration number like "raw"
	if( $name =~ m/\/\w*_(2[23]\d{6})_(\w*)_(\d{7}).MuDst.root\/?(\d*)\/?(\d*)/ ){
	    $runnum = $1;
	    $extra = $2;
	    $segment = $3;
	    my $size = -1;
	    if( $4 ){
		$events = $4;
		#$totalevents += $events;
		$events++; #Add one extra event buffer
		$name =~ s/\/$4//;
		if( $NEVENTS<=0 ){ if( $TEST ){ $events = 100; } } #For MuDsts use 100 events when testing, need nested if statements so $events will only happen when $NEVENTS<=0 which is the correct logic
		else{ $events = $NEVENTS; }
	    }
	    #if $5 is equal to empty string then match was not found so $size will stay -1, otherwise $4 is a non-empty string so process it
	    if( $5 ne "" ){
		$size = $5;
		$name =~ s/\/$size//; #@[March 4, 2024] > This doesn't quite remove the '/0' from the file name if the size match was zero but for some reason running it twice with the line below does work in removing the '/0'.
		if( $size==0 ){ $name =~ s/\/0//; }
	    }
	    if( $VERBOSE>=2 ){
		print "|runnum:${runnum}|extra:${extra}|segment:${segment}|nevents:${events}|size:${size}\n";
		print "|name:${name}\n";
	    }
	    if( $size == 0 ){ next; }
	}
	#if( $runnum ){ print "WARNING:Unable to get a run number from file: ${datafile}\n"; }
	#if( $segment ){ print "WARNING:Unable to get a segment number from file: ${datafile}\n"; }
	$totalevents += $events;
	if( $SIM ){ $JobWriter->SetArguments( "$events $name xrd_${numfiles}_${runnum}_${segment}" ); }
	else{
	    if( $extra eq "" ){ $JobWriter->SetArguments( "$events outname $name xrd_${numfiles}_${runnum}_${segment}" ); }
	    else{ $JobWriter->SetArguments( "$events outname $name xrd_${numfiles}_${runnum}_${extra}_${segment}" ); }
	}
    }
    else{
	my $name = $datafile;
	if( $name =~ m/(Files_\d{8}_\d+.list)/ ){
	    my $arg = $1;
	    my $newinput = "$input" . "," . "$datafile";
	    $JobWriter->SetInputFiles("$newinput");
	    $JobWriter->SetArguments( "$arg" );
	}
    }
    
    print $fh_sum "$datafile\n";
    #Directories created above so can safely ignore the check
    if( $OLDJOB ){ $JobWriter->WriteJobOld($numfiles,1); }
    else{ $JobWriter->WriteJob($numfiles,1); }
    $numfiles++;
}

if( ! $OLDJOB ){ $JobWriter->CloseJob($numfiles); }

print $fh_sum "Total files: $numfiles\n";
print $fh_sum "Total events: $totalevents\n";
print $fh_sum "Command:$thiscommand\n";
close $fh_sum;

print "Total files: $numfiles\n";
print "Total events: $totalevents\n";
print "Short ID: ${UUID_short}\n";

if( $FORCE ){
    print "Force option is on. Submitting job\n";
    $JobWriter->SubmitJob();
}
else{
    print "Submit Job (Y/n):";
    my $submitinput = <STDIN>; chomp $submitinput;
    if( $submitinput eq "Y" ){
    $JobWriter->SubmitJob();
    }
}

sub WriteBfcShellMacro
{
    my( $FullFileName, $AnaDir ) = @_;
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";

    #my $chainopt = DbV20221012,pp2022,-picowrite,-hitfilt,-evout
    #my $chainopt = DBV20221012, ry2022, in, UseXgeom, CorrY, AgML, tpcDB, tags, Tree, ITTF, BAna, ppOpt, ImpBToFt0Mode, VFPPVnoCTB, beamline3D, l3onl, emcDY2, fstRawHit, fstHit, FttDat, FttHitCalib, fcsDat, fcsWFF, fcsCluster, trgd ZDCvtx analysis
    #my $chainopt = pp2022a,ftt,fst,fstMuRawHit,-ITTF,-sti,-stica,-TpcIT,BEmcChkStat,-evout,-hitfilt
    my $chainopt = 'B2022a,BAna,ppOpt,trgd,ZDCvtx,fcs,fst,ftt,fstMuRawHit,-ITTF,-TpcIT,-iTpcIT,-tpx,-tpcx,-TpcHitMover,BEmcChkStat,-EventQA,-picoWrite';

    my $macro_text = <<"EOF";
\#!/bin/csh

stardev
echo \$STAR_LEVEL
#Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
#cd $AnaDir
\#\$1=number of events
\#\$2=dead
\#\$3=inputfile

echo "NumEvents:\${1}\\ninputfile:\${3}"
#Files should be copied to temp directory in /home/tmp/$ENV{USER} or \$SCRATCH. Since each node has its own temporary disk space, a folder with my username directory may not exist in \$SCRATCH or /home/tmp/$ENV{USER}

set tempdir = "\$SCRATCH"
if( ! -d \$tempdir ) then
    mkdir -p \$tempdir
endif

set name = `echo \$3 | awk '{n=split ( \$0,a,"/" ) ; print a[n]}'`
echo \$name
if( ! -f \$tempdir/\$name ) then
    echo "Copying file"
    cp -v \$3 \$tempdir/\$name
endif
ls \$tempdir

if( -f \$tempdir/\$name ) then
    ln -s \$tempdir/\$name
    ls -a \$PWD
    echo "root4star -b -q bfc.C'(\$1,"\\"$chainopt\\"","\\"\$name\\"")'"
    root4star -b -q bfc.C'('\$1',"$chainopt","'\$name'")'
    #Remove copied file since temp disks vary from node to node
    rm \$name
    rm \$tempdir/\$name
else
    echo "ERROR:copy failed or file '\$tempdir/\$name' does not exist!"
endif
EOF
    print $fh $macro_text;
    close $fh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";
}

sub WriteMuDstShellMacro
{
    my( $FullFileName, $AnaDir ) = @_;
    print "$FullFileName\n";
    print "$AnaDir\n";
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $macro_text = <<"EOF";
\#!/bin/csh

stardev
echo \$STAR_LEVEL
#Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
#cd $AnaDir
\#\$1=number of events
\#\$2=inputfile

echo "NumEvents:\${1}\\ninputfile:\${2}"
#Files should be copied to temp directory in /home/tmp/$ENV{USER} or \$SCRATCH. Since each node has its own temporary disk space, a folder with my username directory may not exist in \$SCRATCH or /home/tmp/$ENV{USER}

set tempdir = "\$SCRATCH"
if( ! -d \$tempdir ) then
    mkdir -p \$tempdir
endif

set name = `echo \$2 | awk '{n=split ( \$0,a,"/" ) ; print a[n]}'`
echo \$name
if( ! -f \$tempdir/\$2 ) then
    echo "Copying file"
    cp -v \$2 \$tempdir/\$name
endif
ls \$tempdir

if( -f \$tempdir/\$name ) then
    if( -z \$tempdir/\$name ) then
        echo "ERROR:file '\$copyname' has zero size!"
    else
        ln -s \$tempdir/\$name
        ls -a \$PWD
        echo "root4star -b -q runMudst.C'("\\"\$name\\"",-1,\$1)'"
        root4star -b -q runMudst.C'('\\"\$name\\"',-1,'\$1')'
        #Remove copied file since temp disks vary from node to node
        echo "Removing symlink"
        rm \$name
    endif
    echo "Removing copied file from temp space"
    rm \$tempdir/\$name
    ls -a
else
    echo "ERROR:copy failed or file '\$tempdir/\$name' does not exist!"
endif
EOF

    print $fh $macro_text;
    close $fh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";
}

sub WriteCshellMacro
{
    my( $FullFileName, $AnaDir ) = @_;
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $macro_text = <<"EOF";
\#!/bin/csh

stardev
#Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
#cd $AnaDir
\#\$1=number of events
\#\$2=outfile
\#\$3=inputfile
\#\$4=copyname
echo "NumEvents:\${1}\\nOutFile:\${2}\\ninputfile:\${3}\\ncopyname:\${4}"
#Files from Xrootd server should be copied to temp directory in /home/tmp/$ENV{USER} or \$SCRATCH. Since each node has its own temporary disk space, a folder with your username directory may not exist in \$SCRATCH or /home/tmp/$ENV{USER}
#Since my "FileList" automatically prepends the xrd server location for files on distributed disk need to check for this before doing xrd copy. Other files don't need to be copied
set xrdcheck = 0
set copyname = \${3}
set xrdname = "root://xrdstar.rcf.bnl.gov:1095"
#String manipulation in C-shell
#https://xwfaivre.blogspot.com/2011/07/csh-string-manipulation-length.html
#http://star-www.rl.ac.uk/docs/sc4.htx/sc4se11.html
set xrdnchar = `echo \$xrdname | awk '{print length(\$0)}'`
#This is for how to use script variables in awk:https://superuser.com/questions/346065/use-variables-in-awk-substr-function
set sub1 = `echo \$3 | awk -v l="\$xrdnchar" '{print substr(\$0,0,l)}'`
echo "xrdname:\$xrdname | FilePrefix:\$sub1"
if( \$xrdname == \$sub1 ) then
    set tempdir = "\$SCRATCH"
    if( ! -d \$tempdir ) then
        mkdir -p \$tempdir
    endif
    set copyname = "\${tempdir}/\${4}.MuDst.root"
    echo "newcopyname:\$copyname"
    xrdcp --retry 3 \$3 \$copyname
    ls \$tempdir
    set xrdcheck = 1
endif
#The above code sets 'copyname' such that everything below uses 'copyname' as input file which is now either the file copied from distributed disk or as the given input file name.
if( -f \$copyname ) then
    if( -z \$copyname ) then
        echo "ERROR:file '\$copyname' has zero size!"
    else
        echo "root4star -b -q runMudst.C'("\\"\$copyname\\"",-1,\$1)'"
        root4star -b -q runMudst.C'('\\"\$copyname\\"',-1,'\$1')'
    endif
    #Remove copied file since temp disks vary from node to node
    if( \$xrdcheck ) then 
        echo "removing \$copyname"
        rm \$copyname
    endif
    #Condor will copy output file to the directory in which the submit was called. For this reason there is a move command specific for my condor job writer since it creates an 'Output' directory where result files should go. This way when condor finishes job and puts it into the condor submit directory I move it Output directory where it should go
else
    echo "ERROR:xrdcopy failed or file '\$copyname' does not exist!"
endif
EOF

    print $fh $macro_text;
    close $fh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";
}

sub WriteMultiMudst
{
    my( $FullFileName, $AnaDir ) = @_;

    #Need to make a csh dummy script so that it can run on Alma 9 nodes
    open( my $cshfh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    print $cshfh "#!/bin/csh\n";
    print $cshfh "stardev\n";
    print $cshfh "./RunMultiMuDst.pl \$1\n\n";
    close $cshfh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";

    #Get rid of the "csh" to add pl extension
    chop $FullFileName;
    chop $FullFileName;
    chop $FullFileName;
    $FullFileName = $FullFileName . "pl";
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $macro_text = <<"EOF";
\#!/usr/bin/perl

use strict;
use warnings;

my \$VERBOSE = 0;

my (\$filename) = \@ARGV;
if( not defined \$filename ){ die "Please provide a file name\\n"; }
open( my \$list_fh, '<', \$filename ) or die "Could not open file '\$filename': \$!";

my \$tempdir = \$ENV{'SCRATCH'};
if( ! -d \$tempdir ){
    system("mkdir -p \$tempdir")==0 or die "Could not create directory '\$tempdir': \$!";
}

\#Do this so that it always has the right format for runMudst.C even if runnum is not found in filename
my \$runnum = "00000000";
my \$iternum = "0";      
if( \$filename =~ m/Files_(\\d{8})_(\\d+).list/ ){
    \$runnum = \$1;
    \$iternum = \$2;
}
my \$filelist = "justfiles_\${runnum}_\${iternum}.list";
open( my \$fh, '>', \$filelist ) or die "Could not open '\$filelist' for writing: \$!";

my \%XrdFiles;  #Hash to keep track of which files were copied or not
my \%XrdFileNames;  #Hash to keep track of copied file names which will be everything but the path
my \$nfiles = 0;
my \$srcfiles = "";
while( my \$datafile = <\$list_fh> ){
    chomp \$datafile;
    my \$name = \$datafile;
    if( \$name =~ m/(\\w*_2[23]\\d{6}_\\w*_\\d{7}.MuDst.root)\\/?\\d*\\/?\\d*/ ){
	\$nfiles++;
	my \$justfilename = \$1;
	my \$mudstidx = index(\$name,".MuDst.root");
	if( \$mudstidx == -1 ){ die "\\\$datafile does not contain .MuDst.root\\n"; }
	else{
	    \$name = substr \$name, 0, \$mudstidx+11; \#Add 11 since index returned is at the starting point of .MuDst.root
	    \$srcfiles = \$srcfiles . \$name . " ";
	}
	\#print "|name:\$name\\n";
	\#print " + 1:\$justfilename\\n";
    	\$XrdFiles{\$name} = 0;
	\$XrdFileNames{\$justfilename} = 0;
    }
}

close \$list_fh;

if( \$nfiles>0 ){
    if( \$nfiles==1 ){
    	\#After the for loop there should be an extra space in 'srcfiles'
	print "xrdcp --nopbar --retry 3 \${srcfiles} \${tempdir}\\n";
	system( "xrdcp --nopbar --retry 3 \${srcfiles} \${tempdir}" );
    }
    else{
    	\#After the for loop there should be an extra space in 'srcfiles'
	print "xrdcp --nopbar --parallel 4 --retry 3 \${srcfiles} \${tempdir}\\n";
	system( "xrdcp --nopbar --parallel 4 --retry 3 \${srcfiles} \${tempdir}" );
    }
    opendir my \$dh, \$tempdir  or die "Unable to read '\$tempdir': \$!";
    my \$nfilescopied = 0;
    while( my \$content = readdir \$dh ){
	\#print " + \$content\\n";
	if( exists \$XrdFileNames{\$content} ){
	    \$XrdFileNames{\$content} = 1;
	    \$nfilescopied++;
	    \#print "  - \$content | \$XrdFileNames{\$content}\\n";
	    print \$fh "\${tempdir}/\${content}\\n";
	}
    }
    print \$fh "\\n"; \#Add an extra newline
    close \$fh;
    closedir \$dh;
    
    system("cat \$filelist"); #print contents of files.list
    system("ls \$tempdir");  #print contents of tempdir after datafile loop
    if( \$nfilescopied>0 ){
    	print "root4star -b -q runMudst.C'(\\"\$filelist\\",-1,-2)'\\n";
	system( "root4star -b -q runMudst.C'(\\"\$filelist\\",-1,-2)'" ); #Process all events in all files
    }
    else{ print "Unable to xrdcp any files skipping running root\n"; }

    foreach my \$processed (keys \%XrdFileNames){
	if( \$XrdFileNames{\$processed}==1 ){
	    print "removing \${tempdir}/\$processed\\n";
	    system("/bin/rm \${tempdir}/\${processed}");
	}
    }
}

print "removing \$filelist\\n";
system("/bin/rm \$filelist");

system("/bin/ls .");
system("/bin/ls \$tempdir");

EOF

    print $fh $macro_text;
    close $fh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";
}

sub WriteSimMacro
{
    my( $FullFileName, $AnaDir, $Level ) = @_;
    if ($VERBOSE>=2 ){
	print "$FullFileName\n";
	print "$AnaDir\n";
	print "RunSimFlat.csh level: $Level (";
	if( $Level==0 ){ print "simflat)\n"; }
	if( $Level==1 ){ print "simflatbfc)\n"; }
	if( $Level==2 ){ print "simbfc)\n"; }
    if( $Level==3 ){ print "pythia)\n"; }
    }
    if( !($Level==0 || $Level==1 || $Level==2 || $Level==3 ) ){ die "Oops for some reason mode did not get set to the write level ($Level)"; }
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $sim_text = <<"EOF";
\#!/bin/csh

stardev
echo \$STAR_LEVEL
setup 64b
echo \$STAR_HOST_SYS
#Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
#cd $AnaDir
\#\$1=number of events
\#\$2=run(seed)
\#\$3=pid as string
\#\$4=energy if==0 then use pt
\#\$5=pt if==0 then use energy
\#\$6=vz z-vertex
\#\$7=npart (number of particles)
EOF
    print $fh $sim_text;
    if( $Level==2 ){print $fh "\#\$8=inputfile\n\n";}
    print $fh "echo \"NumEvents:\${1}\\nRun:\${2}\\nPid:\${3}\\nEn:\${4}\\nPt:\${5}\\nVz:\${6}\\nNPart:\${7}\\n\"\n";
    if( $Level==2 ){print $fh "echo \"inputfile=\${8}\"\n";}

    # print $fh "set fzdname = \"\$3.e\$4.vz\$6.run\$2.fzd\"\n";
    # HACK for pythia
    print $fh "set fzdname = \"pythia.\$3.vz\$6.run\$2.fzd\"\n"; 
    # print $fh "echo \$fzdname\n";

    if( $Level==0 || $Level==1 ){
	print $fh "ls -a \$PWD\n";
	print $fh "echo \"root4star -b -q runSimFlat.C'(\$1,\$2,\"\\\"\${3}\\\"\",\$4,\$5,\$6,\$7)'\"\n";
	print $fh "root4star -b -q runSimFlat.C'('\$1','\$2','\\\"\$3\\\"','\$4','\$5','\$6','\$7')'\n";
    }
    if( $Level==3 ){ #Pythia
        print $fh "ls -a \$PWD\n";
        print $fh "echo \"root4star -b -q starsim.C'(\$1,\$2)'\"\n";
        print $fh "root4star -b -q starsim.C'('\$1','\$2')'\n";
    }
    if( $Level==2 ){
	my $copy_text = <<"EOF";
#Files should be copied to temp directory in /home/tmp/$ENV{USER} or \$SCRATCH. Since each node has its own temporary disk space, a folder with your username directory may not exist in \$SCRATCH or /home/tmp/$ENV{USER}
set tempdir = "\$SCRATCH"
if( ! -d \$tempdir ) then
    mkdir -p \$tempdir
endif

if( ! -f \$tempdir/\$fzdname ) then
    echo "Copying file"
    cp -v \$8 \$tempdir/\$fzdname
endif
ls \$tempdir
if( -f \$tempdir/\$fzdname ) then
    ln -s \$tempdir/\$fzdname
else
    echo "ERROR:copy failed or file '\$tempdir/\$fzdname' does not exist!"
    exit
endif
EOF
	print $fh $copy_text;
    }
    
    if( $Level==1 || $Level==2 ){
	my $dosimbfc_text = <<"EOF";
ls -a
if( -f \$fzdname ) then
    echo "root4star -b -q runSimBfc.C'(\$1,\$2,"\\"\${3}\\"",202209,0,\$4,\$5,\$6)'"
    root4star -b -q runSimBfc.C'('\$1','\$2','\\"\$3\\"',202209,0,'\$4','\$5','\$6')'
    ls \$PWD
    #Remove copied file since temp disks vary from node to node
    echo "removing fzd file"
    rm \$fzdname
EOF
	print $fh $dosimbfc_text;
	if( $Level==2 ){ print $fh "    rm \$tempdir/\$fzdname\n";}
	my $end_text = <<"EOF";
    ls \$PWD
else
    echo "ERROR:failed to find fzd file: \$fzdname !"
endif
EOF
	print $fh $end_text;
    }
    
    close $fh;
    #Need to give execute permissions otherwise condor won't be able to run it
    system( "/usr/bin/chmod 755 $FullFileName" )==0 or die "Unable to give execute permisions to CshellMacro: $!\n";
}

sub WritePicoDstMacro
{
    my( $FullFileName, $AnaDir ) = @_;
    if ($VERBOSE>=2 ){
	print "$FullFileName\n";
	print "$AnaDir\n";}
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $macro_text = <<"EOF";
    
        \#!/bin/csh
        stardev
        echo \$STAR_LEVEL
        setup 64b
        echo \$STAR_HOST_SYS
        #Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
        #cd $AnaDir

        \#\$8=inputfile
        echo "inputfile:\${8}"
        set tempdir = "\$SCRATCH"
        if( ! -d \$tempdir ) then
            mkdir -p \$tempdir
        endif
        root4star -b -q runPicoDst.C'("\\"\$8\\"")'



EOF
    }
    
    

sub WriteRootMap
{
    my ( $AnaDir ) = @_;
    my $FullFileName = $AnaDir . "/." . $ENV{'STAR_HOST_SYS'} . "/lib/StFcsTreeManager.rootmap";
    if( -s $FullFileName ){ print "Exists: $FullFileName\n"; return; }  #File exists and is non-zero size don't create it again
    
    print "Generating: $FullFileName\n";
#@[April 21, 2023] > It turns out you can auto load classes in ROOT using a rootmap file like this one. This is different from a rootlogon script
#                  > This is important when trying to merge root files using hadd so that ROOT can load the appropriate library that is defining your classes
#                  > This rootmap file must be somewhere in $LD_LIBRARY_PATH and the library must be in the same folder as this rootmap file
#                  > Format is Library.ClassName: libClass.so
#                  > [Merging Custom Classes](https://root-forum.cern.ch/t/use-hadd-with-custom-classes/30720)
#                  > [More on using rootmap](https://root-forum.cern.ch/t/rootmap-file/9121)
#                  > [ROOT manual see section on Library Autoloading](https://root.cern.ch/root/html534/guides/users-guide/Introduction.html)

    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $rootmap_text = <<"EOF";
Library.StFcsPicoHit: libStFcsTreeManager.so
Library.StFcsPicoCluster: libStFcsTreeManager.so
Library.StFcsPicoPoint: libStFcsTreeManager.so
Library.StPicoG2tTrack: libStFcsTreeManager.so
Library.StFcsPicoTree: libStFcsTreeManager.so
Library.Rtools\@\@ClonesArrTree: /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libDataTools.so /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libCRtools.so
Library.Rtools\@\@HistColl1F: /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libDataTools.so /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libCRtools.so
Library.Rtools\@\@HistColl2F: /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libDataTools.so /star/u/dkap7827/Tools2/Tools/MyTools/install_NoPeak/lib/libCRtools.so
EOF
    print $fh $rootmap_text;
    close $fh;	
}

sub CompareOutput
{
    my $DirHash = shift;
    my $SearchString = shift;
    my $print = shift;
    #Remove trailing '/'
    my $char = chop $DirHash;
    while( $char eq "/" ){$char = chop $DirHash;}
    $DirHash = $DirHash.$char;

    opendir my $dh, $DirHash or die "Could not open '$DirHash' for reading '$!'";

    #Hack to check which jobs are missing the spin database
    #print "$DirHash/log/\n";
#    my $missingspinfiles = `grep -L --text "dump of spin bits" $DirHash/log/job_spincheckall_9834909_*.out`; #@[January 21, 2025] > From job spincheckall
#    my $missingspinfiles = `grep -L --text "dump of spin bits" $DirHash/log/job_spincheckall2_9857654_*.out`; #@[January 22, 2025] > From job spincheckall2
    #print "$missingspinfiles\n";
#    my @missingspinfileslist = split(/\s+/,$missingspinfiles);
#    my %MissingSpinIter;
#    foreach my $missingfile (@missingspinfileslist){
	#print "spinmissing: ${missingfile}\n";
	#if( $missingfile =~ m/job_spincheckall_\d+_(\d+)\.out/ ){
#	if( $missingfile =~ m/job_spincheckall2_\d+_(\d+)\.out/ ){
#	    $MissingSpinIter{$1} = 1;
#	    print "printcheck:$1\n";
#	}
#    }End Hack

    my %AllIters;
    my %OutIters;
    while( my $item = readdir $dh ){
	#print "$item\n";
	if( $item =~ m/Summary_\w*\.list/ ){
	    open( my $summary_fh, '<', "$DirHash/$item" ) or die "Could not open file '$item' for reading: $!";
	    my $joblevel = 0;
	    while( my $line = <$summary_fh> ){
		chomp $line;
		if( $line =~ m/\_(\d{8})_(?:raw_)?(\d+)(\.MuDst\.root|\.list)/ ){
		    #my $iter = substr($line,-18);
		    #$iter =~ s/.MuDst.root//;
		    my $check = $1 . "_" . $2;
		    $AllIters{$check} = $joblevel;
		    #$AllIters{$joblevel} = $check; # @[Jan 22, 2025] > Hack to check spin jobs
		    #print "$line | $check | $joblevel\n";
		    $joblevel++;
		}
	    }
	}
	if( $item eq "Output" && -d "$DirHash/Output" ){  #Output directory for job
	    opendir my $output_dh, "$DirHash/Output" or die "Could not open '$DirHash' for reading '$!'";
	    while( my $outfile = readdir $output_dh ){
		if( $outfile =~ m/${SearchString}_(\d{8})_(?:raw_)?(\d+).root/ ){
		#if( $outfile =~ m/${SearchString}_(\d{8})_(\d+).root/ ){
		    #my $outiter = $outfile;
		    #$outiter =~ s/StFcsPi0Maker//;
		    #$outiter =~ s/.root//;
		    my $crossref = $1 . "_" . $2;
		    #print "$outfile | $crossref\n";
		    $OutIters{$crossref} = 1;
		}
	    }
	    closedir $output_dh;
	}
    }
    
    closedir $dh;

    if( $print>=2 ){ print "Missing iterations\n #. iteration number | job number\n"; }
    my %MissingJobs;
    foreach my $iter (keys %AllIters){
	#if( $AllIters{$iter}<10000 ){
	if( ! $OutIters{$iter} ){
	    $MissingJobs{ $AllIters{$iter} } = 1;
	    if( $print>=2  ){ print " ".scalar(keys %MissingJobs).". $iter | $AllIters{$iter}\n"; }
	}
	#}
    }

    #Hack to print jobs with missing spin database
#    print "|MissingJobs:".scalar(keys %MissingJobs). "|MissingSpin:".scalar(keys %MissingSpinIter). "\n";
#    foreach my $joblevel (keys %MissingSpinIter){
	#print "|iter:$iter|Jobs:$MissingJobs{$iter}\n";
#	if( ! $MissingJobs{ $joblevel } ){
#	    print "spin-cross-check: $joblevel | ref: $AllIters{$joblevel} \n";
#	}
#    } End Hack
    
    return %MissingJobs;
}

=begin
    my \$name = \$datafile;
    my \$runnum = "";    #STAR RunNumber
    my \$segment = "";   #Segment number for a given STAR file with a given RunNumber
    my \$extra = "";     #Any extra text between runnumber and iteration number like "raw"
    if( \$name =~ m/\/\\w*_(2[23]\\d{6})_(\\w*)_(\\d{7}).MuDst.root\/?(\\d*)\/?(\\d*)/ ){
	\$runnum = \$1;
	\$extra = \$2;
	\$segment = \$3;
	my \$size = -1;
	if( \$4 ){
	    \$events = \$4;
	    \#\$totalevents += \$events;
	    \$events++; #Add one extra event buffer
	    \$name =~ s/\/\$4//;
	}
	\#if \$5 is equal to empty string then match was not found so \$size will stay -1, otherwise \$4 is a non-empty string so process it
	if( \$5 ne "" ){
	    \$size = \$5;
	    \$name =~ s/\/\$size//; \#@[March 4, 2024] > This doesn't quite remove the '/0' from the file name if the size match was zero but for some reason running it twice with the line below does work in removing the '/0'.
	    if( \$size==0 ){ \$name =~ s/\/0//; }
	}
	if( \$VERBOSE>=2 ){
	    print "|runnum:\${runnum}|extra:\${extra}|segment:\${segment}|nevents:\${events}|size:\${size}\n";
	    print "|name:\${name}\n";
	}
	if( \$size == 0 ){ next; }
    }
    \$totalevents += \$events;

    my \$copyname = "\${tempdir}/xrd_\${numfiles}_\${runnum}_\${segment}.MuDst.root";
    print"newcopyname:\$copyname";
    if( system( xrdcp --nopbar --retry 3 \$datafile \$copyname )==0 ){
       \$XrdFiles{\$copyname} = 1;
    }
    else{ \$XrdFiles{\$copyname} = 0; }
=cut


