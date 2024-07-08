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

MakeJob.pl [-a I<path{.}>] E<lt>-d I<path>E<gt> [-o I<path{.}>] [-m I<type{mudst}>] [-u I<name>] [-p I<"Message">] [-t] [-w] [-e] [-v I<level{1}>] [E<lt>-c stringE<gt> [-r I<int>]] [-h]

=over 4

=item B<-a> anlaysis code directory

=item B<-d> data file or directory with files (not needed for I<simflat> and I<simflatbfc>)

=item B<-o> directory to store output

=item B<-m> I<type>s: I<mudst>, I<simflat>, I<simflatbfc>, I<simbfc>, I<daq> 

=item B<-u> the I<name> of the directory to create in output directory (default is random UID)

=item B<-p> I<"Message"> to put in Summary file

=item B<-t> test mode

=item B<-w> no stdout

=item B<-e> no stderr

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

Kind of job to submit: daq, mudst, simflat, simflatbfc, simbfc (default is mudst) (simflat is just single particle gun, simflatbfc is particle gun and BFC analysis, simbfc is just BFC analysis on preexisting fzd files)

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

=item B<-v> I<level>, B<--verbose>=I<level>

Set the printout level (default is 1)

=item B<-h>, B<--help>

Print this help and ignore all other options

=back

=head1 VERSION

0.4.2

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

    my $hash = substr($DATA,-6);

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
elsif( $MODE eq "simflat" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = 1;}
elsif( $MODE eq "simflatbfc" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = 1;}
elsif( $MODE eq "simbfc" ){ $CshellMacro = "RunSimFlat.csh"; $SIM = -1}  #It is still sim files but the direcotyr or list of files should be specfied with -d
else{ print "Invalid Mode: $MODE\n"; HelpMessage(0); }

if( $SIM > 0 ){
    #Create simulation files
    foreach my $i (0..99){
	#This will be the argument list use by job writer. Number of events will be added in the for loop that writes the job file so it is missing here
	#seed pid energy pt vz npart
	push @DATAFILES, "$i pi- 90 0 0 1";
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
		if( $MODE eq "simbfc" ){
		    #Read the relevant parameters from the file name
		    if( $datafile =~ m/pythia\.([\w+-]+)\.vz(\d+)\.run(\d+)\.fzd/ ){
			my ($i, $pid, $vz ) = ($3, $1, $2);
			push @DATAFILES, "$i $pid 0 0 $vz $DATA/$datafile"; #@[October 31, 2023] > Not tested
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
        print "Remove all files in folder $FileLoc (Y/n):";
        my $input = <STDIN>; chomp $input;
        if( $input eq "Y" ){system("/bin/rm -r $FileLoc/*") == 0 or die "Unable to remove files in '$FileLoc': $!";}
        else{ print "WARNING: No files removed from existing folder:${UUID_short}\n"; }
    }
}

if( $VERBOSE>=1 ){print "All Files to be written in '$FileLoc'\n";}

my $JobWriter = new CondorJobWriter($FileLoc,"${CshellMacro}","","${UUID_short}");  #Writes the condor job files
if( $NOWRITESTDOUT ){ $JobWriter->WriteStdOut(0); }
if( $NOWRITESTDERR ){ $JobWriter->WriteStdErr(0); }
#Need to create directory here since this is where executable gets installed
$JobWriter->MakeJobDirs($FORCE);
my $CondorDir = $JobWriter->GetCondorDir();  #if it doesn't exist: create condor directory, if it does exist:prompt for removal if not testing
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
}
if( $MODE eq "simflat" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 0 );
    system("/bin/cp $ANADIR/runSimFlat.C $CondorDir") == 0 or die "Unable to copy 'runSimFlat.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimFlat.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    system("/bin/mkdir $CondorDir/$starlibloc") == 0 or die "Could not create"; #-L to follow symlinks
    # $JobWriter->AddInputFiles("$ANADIR/$starlibloc");
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
    $JobWriter->AddInputFiles("$ANADIR/$starlibloc");
    # if( system("/bin/cp -L -r $ANADIR/$starlibloc $CondorDir") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
    # else{ print "WARNING:Unable to copy '$starlibloc'"; }
}
if( $MODE eq "simbfc" ){
    WriteSimMacro( "${CondorDir}/${CshellMacro}", "${CondorDir}", 2 );
    system("/bin/cp $ANADIR/runSimBfc.C $CondorDir") == 0 or die "Unable to copy 'runSimBfc.C': $!";
    $JobWriter->AddInputFiles("$CondorDir/runSimBfc.C");
    my $starlibloc = "." . $ENV{'STAR_HOST_SYS'};
    system("/bin/mkdir $CondorDir/$starlibloc") == 0 or die "Could not create"; #-L to follow symlinks
    # $JobWriter->AddInputFiles("$ANADIR/$starlibloc");
    if( system("/bin/cp -r -L $ANADIR/$starlibloc/lib $CondorDir/$starlibloc") == 0 ){ $JobWriter->AddInputFiles("$CondorDir/$starlibloc"); }#-L to follow symlinks
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
if( $NEVENTS<=0 ){ $nevents = $TEST ? 10 : 10000; }
else{ $nevents = $NEVENTS; }
foreach my $datafile (@DATAFILES){
    if( $numfiles==5 && $TEST ){last;}
    #$JobWriter->SetArguments("100 st_fwd_23040001_raw_0000003.daq" );
    #$JobWriter->SetArguments("10000 st_fwd_23080044_raw_1000002.daq" );
    #$JobWriter->SetArguments("$nevents $datafile" ); //for simulations this is sufficient

    if( $VERBOSE>=2 ){ print "$datafile\n"; }
    my $name = $datafile;
    my $events = $nevents;
    my $runnum = "";    #STAR RunNumber
    my $segment = "";   #Segment number for a given STAR file with a given RunNumber
    if( $name =~ m/\/\w*_(2[23]\d{6})_\w*_(\d{7}).MuDst.root\/?(\d*)\/?(\d*)/ ){
	$runnum = $1;
	$segment = $2;
	my $size = -1;
	if( $3 ){#@[December 15, 2023]>Add a condition for test or if number of events is given as argument
	    $events = $3;
	    $events++; #Add one extra event buffer
	    $name =~ s/\/$3//;
	}
	#if $4 is equal to empty string then match was not found so $size will stay -1, otherwise $4 is a non-empty string so process it
	if( $4 ne "" ){
	    $size = $4;
	    $name =~ s/\/$size//; #@[March 4, 2024] > This doesn't quite remove the '/0' from the file name if the size match was zero but for some reason running it twice with the line below does work in removing the '/0'.
	    if( $size==0 ){ $name =~ s/\/0//; }
	}
	if( $VERBOSE>=2 ){
	    print "|runnum:${runnum}|segment:${segment}|nevents:${events}|size:${size}\n";
	    print "|name:${name}\n";
	}
	if( $size == 0 ){ next; }
    }
    #if( $runnum ){ print "WARNING:Unable to get a run number from file: ${datafile}\n"; }
    #if( $segment ){ print "WARNING:Unable to get a segment number from file: ${datafile}\n"; }
    if( $SIM ){ $JobWriter->SetArguments( "$events $name xrd_${numfiles}_${runnum}_${segment}" ); }
    else{ $JobWriter->SetArguments( "$events outname $name xrd_${numfiles}_${runnum}_${segment}" ); }
    
    print $fh_sum "$datafile\n";
    $JobWriter->WriteJob($numfiles,1); #Ensures it will check directory existence only once
    $numfiles++;
}

print $fh_sum "Total files: $numfiles\n";
print $fh_sum "Command:$thiscommand\n";
close $fh_sum;

print "Total files: $numfiles\n";
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

set tempdir = "/home/tmp/$ENV{USER}"
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

set tempdir = "/home/tmp/$ENV{USER}"
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
        echo "root4star -b -q runMuDst.C'("\\"\$name\\"",-1,\$1)'"
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
    set tempdir = "/home/tmp/$ENV{USER}"
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
        echo "root4star -b -q runMuDst.C'("\\"\$copyname\\"",-1,\$1)'"
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
    }
    if( !($Level==0 || $Level==1 || $Level==2) ){ die "Oops for some reason mode did not get set to the write level ($Level)"; }
    open( my $fh, '>', $FullFileName ) or die "Could not open file '$FullFileName' for writing: $!";
    my $sim_text = <<"EOF";
\#!/bin/csh

stardev
echo \$STAR_LEVEL
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

    print $fh "set fzdname = \"\$3.e\$4.vz\$6.run\$2.fzd\"\n";
    print $fh "echo \$fzdname\n";

    if( $Level==0 || $Level==1 ){
	print $fh "ls -a \$PWD\n";
	print $fh "echo \"root4star -b -q runSimFlat.C'(\$1,\$2,\"\\\"\${3}\\\"\",\$4,\$5,\$6,\$7)'\"\n";
	print $fh "root4star -b -q runSimFlat.C'('\$1','\$2','\\\"\$3\\\"','\$4','\$5','\$6','\$7')'\n";
    }
    if( $Level==2 ){
	my $copy_text = <<"EOF";
#Files should be copied to temp directory in /home/tmp/$ENV{USER} or \$SCRATCH. Since each node has its own temporary disk space, a folder with your username directory may not exist in \$SCRATCH or /home/tmp/$ENV{USER}
set tempdir = "/home/tmp/$ENV{USER}"
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

    my %AllIters;
    my %OutIters;
    while( my $item = readdir $dh ){
	#print "$item\n";
	if( $item =~ m/Summary_[\w+-]*\.list/ ){
	    open( my $summary_fh, '<', "$DirHash/$item" ) or die "Could not open file '$item' for reading: $!";
	    my $joblevel = 0;
	    while( my $line = <$summary_fh> ){
		chomp $line;
		if( $line =~ m/^(\d+)\s([\w+-]+)\s(\d+)\s0\s(\d)\s1/ ){
		    #my $iter = substr($line,-18);
		    #$iter =~ s/.MuDst.root//;
		    my $check = "seed_" . $1 . "_pid_" . $2 . "_energy_" . $3 . "_vz_" . $4 ;
		    $AllIters{$check} = $joblevel;
		    print "$line | $check | $joblevel\n";
		    $joblevel++;
		}
	    }
	}
	if( $item eq "Output" && -d "$DirHash/Output" ){  #Output directory for job
	    opendir my $output_dh, "$DirHash/Output" or die "Could not open '$DirHash' for reading '$!'";
	    while( my $outfile = readdir $output_dh ){
		if( $outfile =~ m/([\w+-]+)\.e(\d+)\.vz(\d+)\.run(\d+)\.fzd/ ){
		    #my $outiter = $outfile;
		    #$outiter =~ s/StFcsPi0Maker//;
		    #$outiter =~ s/.root//;
		    my $crossref = "seed_" . $4 . "_pid_" . $1 . "_energy_" . $2 . "_vz_" . $3 ;
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
	if( ! $OutIters{$iter} ){
	    $MissingJobs{ $AllIters{$iter} } = 1;
	    if( $print>=2 ){ print " ".scalar(keys %MissingJobs).". $iter | $AllIters{$iter}\n"; }
	}
    }
    return %MissingJobs;
}

