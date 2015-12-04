#!/usr/bin/perl -w
#############################################################################
#                                  aligner                                  #
$VERSION = "version 2.0";    #

#                                                                           #
#                             By Dennis Lavrov                              #
#                        last modified 08/27/2010,                          #
#############################################################################

use strict;
use warnings;

# Perl libraries.
require "/usr/local/lib/perl/ogmp/subarray.pl";
use File::Copy;

#librairie
my $aaLIBPATH = "/research/seqlib/lib/";
my $ntLIBPATH = "/research/seqlib/ntlib/";
my $PEPPATH   = "/research/seqlib/pepfiles/";
my $NTPATH    = "/research/seqlib/ntfiles/";

# Main program
my $choice     = 0;
my $i          = 0;
my $sauveguard = "./sauveguard";
die "Cannot create new directory:$!\n"
  unless ( -e $sauveguard || mkdir $sauveguard );
die "You don't have scl progam installed in /usr/local/bin\n"
  unless ( -x "/usr/local/bin/scl" );

print "\nWelcome to soapalign!\n";

# Menu
while ($choice != 1
    || $choice != 2
    || $choice != 3
    || $choice != 4
    || $choice != 5
    || $choice != 6 )
{
    print "\n
What do you want to do?\n
(1) Create new nt libraries
(2) Create new aa libraries
(3) Copy selected sequences to the current directory
(4) Run soapalign for aa sequences
(5) Run codonalign for nt sequences
(6) Filter out variable regions
(7) Translate first and third codon position in fasta.pir file (for nt data)
(8) Translate fasta.pir file using the quasineutral model (for nt data)
(9) Translate fasta.pir file using Dayhoff groups (for aa data)
(0) Exit the program\n\n";

    $choice = <STDIN>;

    if ( $choice == 1 ) {
        Remove('nt');
        GeneFile('nt');
        Create('nt');
        CheckLibs();

        #my $n=0;
        #use File::Copy;
        #if(!copy("./species.list","./sauveguard/species1.list")){
        #	        print "Cannot copy file:$!\n";
        #		                               }
        #	unlink "species.list";
        #	Create ('local'); #argument is needed to get local files
        #	CheckLibs();
    }

    elsif ( $choice == 2 ) {
        Remove();
        GeneFile();
        Create();
        CheckLibs();
    }
    elsif ( $choice == 3 ) {
        CheckLibs();
        GetSeqs();
	GetSeqs("nt");
    }

    elsif ( $choice == 4 ) {
        CheckLibs();
        my $ref2userfiles = GetSeqs();
        CheckFiles($ref2userfiles);
        SoapAlign($ref2userfiles);
        Missing();
    }
    elsif ( $choice == 5 ) {
        CheckLibs();

        #unlink <*.pir>;
        my $ref2ntfiles = GetSeqs("nt");
        ChangeName($ref2ntfiles);
        my $ref2aafiles = GetSeqs();
        SoapAlign( $ref2aafiles, "yes", $ref2ntfiles );

        RunCodonAlign($ref2ntfiles, $ref2aafiles);
    }
    elsif ( $choice == 6 ) {
        unlink <*.pir>;
        filtre();
    }

    elsif ( $choice == 7 ) {
        Translate();
    }

    elsif ( $choice == 8 ) {
        Translate('quasineutral');
    }

    elsif ( $choice == 9 ) {
        Translate_aa();
    }

    elsif ( $choice == 0 ) {
        CheckLibs();
        exit;
    }

    else { print "$choice is not a valid option!" }
}    # End of while loop

# End of program

#
# Subroutine
#============================================
sub Remove {
    my ($is_nt) = @_;

    #This subroutine deletes species.list in local and aaLIBPATH directory
    #It also deletes all gene.seq files in $aaLIBPATH directory
    my $LIBPATH   = $aaLIBPATH;
    my $extension = ".seq";
    if ($is_nt) {
        $LIBPATH   = $ntLIBPATH;
        $extension = ".nt";
        print
"PLEASE NOTE THAT THE LOCAL SPECIES.LIST IS NOT UPDATED WHEN YOU UPDATE THE NT LIBRARIES!!!\n";
    }
    else {
        my $timestamp = time();
        my $new_name  = "species." . $timestamp;
        move( "species.list", "$new_name" );
    }
    unlink $LIBPATH . "species.list";
    unlink <$LIBPATH*$extension>;
    my $lib = "species.list";
    open( OUT, ">$LIBPATH$lib" ) or die "Can't open the file $LIBPATH$lib:$!\n";
    close(OUT) or die "Can't close $LIBPATH$lib:$!\n";
}

#============================================
#This sub copies gene list from the library directory indicated in $aaLIBPATH
sub Get_gene_list {
    my @genenames;
    open( IN, $aaLIBPATH . "genes.list" )
      or die "Can't read from \"genes.list\": $!\n";
    while ( my $line = <IN> ) {
        chomp($line);    #extrait le gene de gene.list
        if ( $line =~ /^(\S+)/ ) {    #elimine les lignes vides
            push @genenames, $line;    #met le gene dans genename
        }
    }
    close(IN) or die "Can't close \"genes.list\": $!";
    return \@genenames;
}

#===========================================
sub GeneFile {

    #This sub create empty gene.seq files in library directory
    #Needed to make AddSpecies happy
    my $LIBPATH   = $aaLIBPATH;
    my $extension = ".seq";
    my ($is_nt)   = @_;
    if ($is_nt) {
        $LIBPATH   = $ntLIBPATH;
        $extension = ".nt";
    }
    my $ref2gene_list = Get_gene_list();
    my $gene;
    foreach $gene (@$ref2gene_list) {
        $gene = "$LIBPATH" . "$gene" . "$extension";
        open( OUT, "+>$gene" ) or die "Can't open the file $gene: $!\n";
        close(OUT) or die "Can't close the file $gene :$!\n";
    }
}

#===============================================
sub Create {

    #
    my ($is_nt)   = @_;
    my $extension = ".pep";
    my $PATH      = $PEPPATH;
    if ($is_nt) {
        $extension = ".nt";
        $PATH      = $NTPATH;
    }
    my @files = <$PATH*$extension>;    #if $local use local file
    my $n;
    for ( $n = 0 ; $n < @files ; $n++ ) {
        my $datafile = $files[$n];
        ( $datafile, my @new_file ) = &Open_a_file($datafile);
        print "Processing datafile: $datafile\n";
        @new_file = grep !/^;/, @new_file;
        my $new_species = AddSpecies( \@new_file, $is_nt );
        UpdateList($new_species) unless ($is_nt);
    }
}

#===========================================
sub AddSpecies {

    # This subroutine adds new sequences from a fasta file created by pepper
    my ( $ref2pepper, $is_nt ) = @_;
    my ( $old_species, $new_species );
    my $extension = ".seq";
    my $LIBPATH   = $aaLIBPATH;
    if ($is_nt) {
        $extension = ".nt";
        $LIBPATH   = $ntLIBPATH;
    }

    # Check species names in pepfile $datafile
    foreach my $line (@$ref2pepper) {
        if ( $line =~ /^>/ ) {
            $new_species = $line;
            $new_species =~ s/^>(\S{1,50}).*\n/$1/;
            if ( $old_species && ( $new_species ne $old_species ) ) {
                print
"Error: The pepfile seems to contain data for more than one species: ($old_species and $new_species)\n";
                return;
            }
            $old_species = $new_species;
        }
    }

    #  Extract sequences for each gene in gene.list file
    my $ref2genenames = Get_gene_list();
  FILE: for ( my $i = 0 ; $i < @$ref2genenames ; $i++ ) {
        my $filename = $LIBPATH . $$ref2genenames[$i] . $extension;

        #ouvre les fichiers .seq contenus dans libraries
        open( IN, "$filename" )
          or die "Can't read $filename: \n"
          . "if it's the first time you use aligner: Please start with the choice 2.\n"
          . "Else you've got a probleme.\n";
        my @library_file = <IN>;    #read gene.seq file to array @library_file
        close(IN) or die "Can't close $filename: $!\n";

        # check if the sequence is already exist
        if ( grep /^>$new_species/, @library_file ) {

            #foreach my $line (@library_file) {
            #if ($line =~ /^>$new_species/) {
            #print "$line\n";
            print
"Warning: Species $new_species is already present in file $filename! Ignored.\n";
            next FILE;

            #}
        }

        # Read all the lines for a single gene from a pepfile
        my $string = " " . $$ref2genenames[$i] . " ";
        my @current_gene =
          &ExtractSubArray( "^>.*$string", '^$', $ref2pepper, "extract", "" );
        if ( $#current_gene > 0 ) {    #if we are able to read a gene
            foreach my $line (@current_gene) {
                push @library_file, $line;
            }
        }
        else {
            my $variable = ">$new_species $$ref2genenames[$i] !@# ;\n*\n\n";
            push @library_file, $variable;
        }

#the following section makes sure the species names are in alphabetical (the same) order
        my $flat_file = join '',
          @library_file;               #join all alines in @library file
        @library_file = split />/,
          $flat_file;                  #split the line using  ">" character
        @library_file = sort by_lc @library_file;
        $flat_file = join '>', @library_file;
        open( OUT, ">$filename" ) or die "Can't write to $filename: $!\n";
        print OUT $flat_file;          #we write a new library gene.seq file
        close(OUT) or die "Can't close $filename: $!\n";
    }    #for
    return $new_species;
}    #sub

#============================================
sub Missing {
    my $ref2userfiles = GetUserfiles();
    my $ref2species   = GetSpecies();
    my $line;
    open( OUT, "+>Missing" ) or die "Can't open the file Missing: $!\n";
    foreach my $species (@$ref2species) {
        print OUT "\n$species\n";    #write species name
        print "\n$species\n";
        foreach my $localfile (@$ref2userfiles) {
            my $libfile = $aaLIBPATH . $localfile;
            open( IN, "$libfile" ) or die "Can't open the file $libfile: $!\n";
            while ( $line = <IN> ) {
                if ( $line =~ /^>$species/ and $line =~ /!@# ;$/ )
                {                    #repere la ligne grace au cigle !@#
                    $line =~ s/^>$species (\S+)/$1/;    #select genes name
                    print OUT "$1\n";                   #write genes name
                    print "$1\n";
                }
            }
            close(IN) or die "Can't close the file $libfile: $!\n";
        }
    }
    close(OUT) or die "Can't close the file Missing: $!\n";
}    #sub

#=====================================
sub CheckFiles {

#This subroutine checks the files to make sure that all of them have the same species
    my @oldspecies;
    my $n = 0;
    my ($ref2userfiles) = @_;
    foreach my $file (@$ref2userfiles) {
        my @species = ( "no_species", );
        open( FILE, $file ) or die "Can't open $file: $!";
        my $i = 0;
        while (<FILE>) {
            print "$i\n";
            chomp;

            if (/^>/) {
                $species[$i] = $_;
                $species[$i] =~ s/>([^ ]+).*/$1/;

                #verifie que les genes aligne appartiennent a la meme espece
                if ( $n > 0 && ( $species[$i] ne $oldspecies[$i] ) ) {
                    print "$species[$i] is not $oldspecies[$i]\n";
                    die("The species #$i+1 in $file is different!\n");
                }
                $i++;
            }
        }
        @oldspecies = @species;
        $n++;
    }
}    #sub CheckFiles

#============================================
sub by_lc {

    #This subroutine is used in sort function to ignore the case
    lc($a) cmp lc($b);
}

#===========================================
sub ChangeName {
    my ($ref2userfiles) = @_;
    foreach my $file (@$ref2userfiles) {
        open( IN, $file ) or die "Can't open file file \"$file\": $!\n";
        my @temp = <IN>;
        close IN;
        foreach my $line (@temp) {
            if ( $line =~ s/^>(.{10}).*/>$1/ ) {
            }    # unless line starts with a semicolan
            else {
                if ( $line =~ s/N/-/g ) { }
            }
        }
        open( OUT, ">$file" ) or die "Can't open file file \"$file\": $!\n";
        print OUT @temp;
        close OUT;
    }    #foreach
}

#===========================================
sub CheckLibs {

# This routine creates file for clustalw.
# It reads data from two datafiles: species.list and gene.list
# If they are not present in the current directory, the two files are copied from the library
    my $filename;

    #Check for the presence of files species.list and gene.list
    unless ( -e "species.list" && -e "genes.list" && -e "clustal.ctl" ) {
        if ( !-e "species.list" ) {
            print "Can't find species.list!  Creating local copy.\n"
              . "Please mark the species you want to ignore with a semicolon.\n";
            $filename = $aaLIBPATH . "species.list";
            copy( $filename, "species.list" );
        }
        if ( !-e "genes.list" ) {
            print "Can't find genes.list! Creating local copy.\n"
              . "Please mark the genes you want to ignore with a semicolon.\n";
            $filename = $aaLIBPATH . "genes.list";
            print "Here is \$filename: $filename\n";
            copy( $filename, "genes.list" );
        }

        if ( !-e "clustal.ctl" ) {
            $filename = $aaLIBPATH . "clustal.ctl";
            print "Can't find clustal.ctl!  Creating local copy.\n"
              . "You can modify the alignment parameters, if you wish\n";
            copy( "$filename", "clustal.ctl" );
        }
    }
}

#============================================
sub GetUserfiles {
    my $type      = shift(@_);
    my $extension = ".seq";
    if ($type) {
        $extension = ".nt";
    }
    my @userfiles;

    #get the genes to use from local genes.list
    open( IN, "genes.list" ) or die "Can't open \"genes.list\": $!\n";
    while ( my $line = <IN> ) {
        unless ( $line =~ /^\s*;/ ) {    # unless line starts with a semicolan
            if ( $line =~ s/^\s*(\S+)/$1/ ) {
                chomp($line);
                $line = $line . $extension;
                push @userfiles, $line;
            }
        }
    }
    close(IN) or die "Can't close \"genes.list\": $!\n";
    return \@userfiles;
}

#============================================
sub GetSpecies {
    my @species;

    #get the species to use from local species.list
    open( IN, "species.list" ) or die "Can't open \"species.list\": $!\n";
    while ( my $line = <IN> ) {
        unless ( $line =~ /^;/ || $line =~ /^ +;/ ) {
            if ( $line =~ s/^\s*(\S+)/$1/ ) {
                chomp($line);
                push @species, $line;
            }
        }
    }
    close(IN) or die "Can't close \"species.list\": $!\n";
    return \@species;
}

#============================================
sub GetSeqs {
    my $type = shift(@_);
    my $LIBPATH;
    if ($type) {
        $LIBPATH = $ntLIBPATH;
    }
    else {
        $LIBPATH = $aaLIBPATH;
    }
    my $ref2userfiles = GetUserfiles($type);
    my $ref2species   = GetSpecies();
    print "The following species will be used in the analysis:\n";
    print "@$ref2species\n";

    my $line = 0;
    foreach my $localfile (@$ref2userfiles) {
        my $libfile = $LIBPATH . $localfile;
        open( IN, "$libfile" ) or die "Can't opent the file $libfile: $!\n";
        open( OUT, ">$localfile" )
          or die "Can't opent the file $localfile: $!\n";
        my $in_record    = 0;    #tracks whether we are inside a gene sequence
        my $skip_warning = 0;
      LINE: while ( $line = <IN> ) {    #This loop should be rewritten!
            if ( $line =~ /^\s*$/ && $in_record ) {    #empty line = last line ?
                $in_record = 0;
                print OUT $line;
                next LINE;
            }
            elsif ($in_record) {    #print all lines but comments
                if ( $line =~ /^>/ ) {
                    print STDERR "\n unexpected line: $line in $libfile\n";
                    exit;
                }
                print OUT $line unless ( $line =~ /^;/ );
                next LINE;
            }
            elsif ( $line =~ /^>/ ) {    #new record
                $skip_warning = 0;
                for ( my $i = 0 ; $i < @$ref2species ; $i++ ) {
                    if ( $line =~ /^>$$ref2species[$i]/ ) {

                        #print STDERR "Match! Here is the line: $line\n";
                        print OUT $line;
                        $in_record = 1;
                        next LINE;
                    }
                }
                $line =~ s/^>(\w+).*$/$1/;
                print STDERR "$line is skipped!\n";
                $skip_warning = 1;
            }
            else {
                print STDERR
"Warning: Unexpected line \"$line\" in file \"$libfile\". Ignored.\n"
                  unless ($skip_warning);
            }
        }    #\LINE while
        close(IN)  or die "Can't close the file $libfile: $!\n";
        close(OUT) or die "Can't close the file $localfile: $!\n";
    }    #\foreach
    return $ref2userfiles;
}    #\sub Get Seqs

#==========================================
sub Open_a_file {

    #open file
    #this sub is mostly obsolete;
    my ( $filename, $request, $interactive ) = @_;
    if ($interactive) {
        print "Please enter the name of the $request ($filename):\n> ";
        chomp( my $answer = <STDIN> );
        $filename = $answer if $answer;
    }

    #read datafile
    open( IN, "$filename" ) || die "Can't read from \"$filename\": $!\n";
    my @RET = <IN>;
    close(IN) or die "Can't close  $filename: $!";
    return ( $filename, @RET );
}

#=========================================
sub SoapAlign {
    my ( $ref2aafiles, $codonalign, $ref2ntfiles ) = @_;
    my $n = 0;
    my $line;
    my @parameters;
    my $outformat = $codonalign ? "PHYLIP" : "PIR";

    unlink <*.pir>;

  #the next seven lines are used to get the clustalw parameters into @parameters
    open( IN, "clustal.ctl" ) or die "Can't open \"clustal.ctl\": $!\n";
    while ( $line = <IN> ) {
        if ( $line =~ /^\/outorder/ ) {
            $parameters[$n] = $line;
            $n++;
        }    #if
    }    #while
    my $filename;
    my @allseqs;
    my $i;

    # create clustalw alignments using different parameters
    for ( $n = 0 ; $n < @parameters ; $n++ ) {
        for ( $i = 0 ; $i < @$ref2aafiles ; $i++ ) {
            system
              "clustalw_old $$ref2aafiles[$i] /output=$outformat $parameters[$n]"
              ;    #clustalw command
        }    #for
        if ($codonalign) {    #I need this if to do a single clustalw run
            unlink <*.out.phylip>;
            RunCodonAlign( $ref2ntfiles, $ref2aafiles );
            my @nt_aligned = <*out.phylip>;
            foreach my $filename (@nt_aligned) {
                my $new_filename = $filename;
                $new_filename =~ s/^(.+)\.out\.phylip/$1.pir/;
                open( IN, $filename ) or die "Can't open \"$filename\": $!\n";
                open( OUT, ">$new_filename" )
                  or die "Can't write to \"$new_filename\": $!\n";
                while ( $line = <IN> ) {
                    next if ( $line =~ /^\d+\s\d+$/ );    #next if first
                    next if ( $line =~ /^$/ );            #next if empty
                    my ( $species, $sequence ) = $line =~ /^(.{10})(.+)$/;
                    $species  =~ s/(.+)/>N1;$1\n\n/;
                    $sequence =~ s/(.{60})/$1\n/g;
                    print OUT "$species" . "$sequence" . "\n*\n";
                }
                close IN  or die "Can't close $filename: $!\n";
                close OUT or die "Can't close $new_filename: $!\n";
            }    #foreach my $filename
        }
        Concatanate( $ref2aafiles, ".pir", "*\n", $n );
    }    #for all parameters
    unlink <*.dnd>;

    #	unlink <*.seq>;
    Sauveguard( \@parameters );
    foreach (<*.pir>) {

        #use File::Copy;
        if ( !copy( "./$_", "./sauveguard/$_" ) ) {
            print "Erreur dans la copie:$!\n";
        }
    }
    my @genename = @$ref2aafiles;
    for ( $i = 0 ; $i < @genename ; $i++ ) {
        $genename[$i] =~ s/(\w).seq/$1/;
        unlink <$genename[$i].pir>;
    }

    #system "scl -c -nexi";
    system "scl -c";

    #unlink <*.pir>;

}

#============================================
#This subroutine runs clustalw alignments with different parameters and combines all genes' alignments into
#a single file

sub Concatanate {
    my ( $ref2userfiles, $extension, $input_separator, $n ) = @_;
    my $save_input_separator = $/;
    my $filename;
    my $line;
    my @allseqs;
    my ( $i, $j );
    my $single = "";
    $/ = $input_separator
      ;    # Set input separator to "*\n" and read in a record to a scalar

    for ( $i = 0 ; $i < @$ref2userfiles ; $i++ )
    {      #Read seqs from the *.pir files into @allseqs
        $j        = 0;
        $filename = $$ref2userfiles[$i];
        $filename =~ s/(.*)\.seq/$1$extension/;
        open( IN, $filename ) or die "Can't open \"$filename\": $!\n";
        while ( $line = <IN> ) {
            if ( $i == 0 ) {    #if this gene is the first
                $line =~ s/(.*)\n\*/$1/s
                  if ( $i != $#$ref2userfiles )
                  ;             #remove return and star if more than one gene
                $allseqs[$j] = $line;    #add it to array
            }
            else {
                if ( $line =~ s/^>\w1.*\n\n(.*)\n\*/$1/s ) {

                    #if ($line =~ s/^>P1.*\n\n(."*")/$1/s) {};
                    $line = $line . "*\n"
                      if ( $i == $#$ref2userfiles )
                      ;                  #if $i is the last element in the array
                    $allseqs[$j] = $allseqs[$j] . $line;    #only one gene
                }
            }
            $j++;
        }    #while
        close(IN) or die "can't close  $filename: $!";
    }    #for ($i=0; $i<@userfiles; $i++)
    open( OUT, ">alignment$n.pir" )
      or die "Can't opent the file alignment$n.pir: $!\n";
    print OUT @allseqs;
    close(OUT) or die "Can't close the file alignment$n: $!\n";
    $/ = $save_input_separator;    # reset input separator
}

#============================================
sub RunClustal0 {
    my ( $ref2parameters, $ref2userfiles ) = @_;
    my $save_input_separator = $/;
    my $filename;
    my $line;
    my @allseqs;
    my ( $i, $j, $n );
    my $single = "";
    $single = "yes" if ( scalar(@$ref2parameters) == 1 );
    $/ = "*\n";  # Set input separator to "*\n" and read in a record to a scalar

# this is a long "for" loop that creates clustalw alignments using different parameters
    for ( $n = 0 ; $n < @$ref2parameters ; $n++ ) {
        for ( $i = 0 ; $i < @$ref2userfiles ; $i++ ) {
            system
              "clustalw_old $$ref2userfiles[$i] /output=PIR $$ref2parameters[$n]"
              ;    #clustalw command
        }    #for
        if ($single) {    #I need this if to do a single clustalw run
            $/ = $save_input_separator;    # reset input separator
            return;
        }
        for ( $i = 0 ; $i < @$ref2userfiles ; $i++ )
        {    #Read seqs from the *.pir files into @allseqs
            $j        = 0;                     #this keeps the count of species
            $filename = $$ref2userfiles[$i];
            $filename =~ s/(.*)\.seq/$1.pir/;
            open( IN, $filename ) or die "Can't open \"$filename\": $!\n";
            while ( $line = <IN> ) {
                if ( $i == 0 && $i != $#$ref2userfiles )
                {    #if the gene is first but not the last
                    $line =~ s/(.*)\n\*/$1/s;    #remove return and star
                    $allseqs[$j] = $line;        #add it to array
                }
                else {
                    if ( $line =~ s/^>P1.*\n\n(.*)\n\*/$1/s ) {
                        if ( $line =~ s/^>P1.*\n\n(."*")/$1/s ) {
                        }
                        $line = $line . "*\n"
                          if ( $i == $#$ref2userfiles )
                          ;    #if $i is the last element in the array
                        $allseqs[$j] = $allseqs[$j] . $line;

                        #$allseqs[$j] = $allseqs[$j] . "*\n";
                    }
                }
                $j++;          #we move to the next sequence in the file
            }    #while
            close(IN) or die "can't close  $filename: $!";
        }    #for ($i=0; $i<@userfiles; $i++)
        open( OUT, ">alignment$n.pir" )
          or die "Can't opent the file alignment$n.pir: $!\n";
        print OUT @allseqs;
        close(OUT) or die "Can't close the file alignment$n: $!\n";
    }    #for ($n=0; $n<@parameters; $n++)
    $/ = $save_input_separator;    # reset input separator
}

#============================================
#This subroutine runs codonalign

sub RunCodonAlign {
    my ( $ref2ntfiles, $ref2aafiles ) = @_;
    my $i;
    my $name;
    my $name_phy;
    my $name_out;
    die "files are missing!\n"
      if ( scalar(@$ref2ntfiles) != scalar(@$ref2aafiles) );
    for ( $i = 0 ; $i < @$ref2ntfiles ; $i++ ) {
        $name = $$ref2ntfiles[$i];
        $name =~ s/^(\w+).*/$1/;
        $name_phy = $name . ".phy";

        #system "perl -pi -e 's/X/A/g' $name_phy";
        $name_out = $name . ".out";
        die "files are missing!\n" if ( $$ref2aafiles[$i] !~ /$name/ );
        open( OUT, ">temp" ) or die "Can't opent the file temp: $!\n";
        print OUT "$name_phy\n$$ref2ntfiles[$i]\n$name_out\n";
        close(OUT) or die "Can't close the file temp: $!\n";
        system "CodonAlign2 < temp";
    }
}

#===========================================
#cette subroutine sert a sauveguarder les alignements avec un numero a chaque fois different (numero de l'alignement(0,1,2),annee,mois,jours,heures,minutes).
sub Sauveguard {
    my ($ref2parameters) = @_;
    my ( $sec, $min, $heure, $mjour, $mois, $annee, $sjour, $ajour, $isdst ) =
      gmtime(time)
      ; #transfert les valeurs de gmtime en variable facilement utilisable par la suite
    $annee += 1900;    #donne le chiffre de l'annee en cours
                       #definie le numero a rajouter aux fichiers
    my $date = ( $annee . $mois . $mjour . $heure . $min );

    #my $gene = "$1.pir";       #Not sure how this part is implemented
    #my $gene2 = "$1$date.pir";
    #rename ($gene, $gene2);

    for ( my $n = 0 ; $n < @$ref2parameters ; $n++ ) {

        #cette boucle renome les fichiers pour chaque parametres
        my $alignment0  = "alignment$n.pir";
        my $alignment10 = "alignment$n$date.pir";
        rename( $alignment0, $alignment10 );

    }
}

#============================================
sub UpdateList {

# This subroutine updates species list after a species was added to the database
    my $new_species = $_[0];
    my $libfile     = $aaLIBPATH . "species.list";
    my $localfile   = "species.list";
    open( IN, $libfile ) or die "Can't read from \"$libfile\": $!\n";
    my @species_list = <IN>;
    close(IN) or die "Can't close  $libfile: $!";
    foreach my $species (@species_list)
    {    #check whether the new species is already in the species list
            #print "$species\n";
        if ( $species =~ /^$new_species/ ) {
            print
"Species $new_species is already present in $libfile.  Ignored.\n";
            return;
        }
    }
    $new_species .= "\n";
    push @species_list, $new_species;
    @species_list = sort by_lc @species_list;    #classe le tableau
    open( OUT, ">$libfile" ) or die "Can't write to \"$libfile\": $!\n";
    print OUT @species_list;
    close(OUT) or die "Can't close  $libfile: $!";
}

#============================================
sub filtre {
    open( IN, "<outfile" ) or die "Can't open \"outfile\": $!\n";
    my ( $line, $first_field, $second_field, $gaps );
    my %main_hash;
    my ( @column_sum, @temp, @final, @column );
    my $num_alignments = 0;
    while ( $line = <IN> ) {
        chomp $line;
        if ( $line =~ /(\d) alignments./ ) {
            $num_alignments = $1;
        }
        if ( $line !~ /^#/ && $line !~ /^\s*$/ && $line !~ /^\s+\d+/ ) {
            my $first_field = substr( $line, 0, 15 );
            my $second_field = substr( $line, 17, );
            if ( $first_field !~ /alignment/ && $first_field !~ /column sum/ ) {
                @temp = split //, $second_field;
                push( @{ $main_hash{$first_field} }, @temp );
            }
            elsif ( $first_field =~ /column sum/ && $second_field !~ /^0+$/ ) {
                @temp = split //, $second_field;
                push( @column_sum, @temp );
            }
        }
    }
    close(IN) or die "Can't close \"outfile\": $!\n";
    my @species = sort keys %main_hash;
    print "SPECIES: @species\n";
    my $num_species = scalar @species;
    my $num_aa      = $num_species / 2;
    print
"There are $num_species species. Retain columns with how many amino acids? ($num_aa): ";
    my $temp = <STDIN>;

    if ( $temp =~ /^\d+$/ && $temp <= $num_species && $temp > 0 ) {
        $num_aa = $temp;
    }
    for ( $i = 0 ; $i < @column_sum ; $i++ ) {
        my $gaps = 0;
        if ( $column_sum[$i] == $num_alignments ) {
            my $n = 0;
            foreach my $key (@species) {
                $column[$n] = $main_hash{$key}->[$i];
                $gaps++ if ( $column[$n] =~ /-/ );
                $n++;
            }
            if ( $n - $gaps >= $num_aa ) {
                push @final, [@column];
            }
        }
    }

    open( OUT, ">fasta.pir" ) or die "Can't open \"fasta.pir\": $!\n";
    for ( $i = 0 ; $i < @species ; $i++ ) {
        if ( $i != 0 ) {
            print OUT "\n*\n";
        }
        print OUT ">$species[$i]\n";
        for ( my $j = 0 ; $j < @final ; $j++ ) {
            my $division = $j % 60;
            if ( $division == 0 ) {
                print OUT "\n";
            }
            print OUT $final[$j][$i];
        }
    }

    print OUT "\n*\n";
    close(OUT) or die "Can't close \"fasta.pir\": $!\n";
}

sub Translate {
    my $quasineutral = '';
    $quasineutral = $_[0];
    my $codon;
    open( IN,  "fasta.pir" )     or die "Can't open \"fasta.pir\": $!\n";
    open( OUT, ">fasta.pir.tr" ) or die "Can't open \"fasta.pir.tr\": $!\n";
    foreach my $line (<IN>) {
        if ( $line =~ /^>|^\*|^$/ ) { print OUT $line }
        else {
            chomp $line;
            for ( my $i = 0 ; $i < ( length($line) - 2 ) ; $i += 3 ) {
                $codon = substr( $line, $i, 3 );
                if ($quasineutral) {
                    $codon =~ s/^(C|T)T/YT/i;
                    $codon =~ s/^(A|G)(C|T)/RY/i;
                    $codon =~ s/(..)(A|G)/$1R/i;
                    $codon =~ s/(..)(T|C)/$1Y/i;
                }
                else {
                    $codon =~ s/^(A|G)/R/i;
                    $codon =~ s/^(T|C)/Y/i;
                    $codon =~ s/(..)(A|G)/$1R/i;
                    $codon =~ s/(..)(T|C)/$1Y/i;
                }
                print OUT $codon;
            }
            print OUT "\n";
        }
    }
    close(OUT) or die "Can't close \"fasta.pir.tr\": $!\n";
    close(IN)  or die "Can't close \"fasta.pir\": $!\n";
}

sub Translate_aa {
    open( IN,  "fasta.pir" )     or die "Can't open \"fasta.pir\": $!\n";
    open( OUT, ">fasta.pir.tr" ) or die "Can't open \"fasta.pir.tr\": $!\n";
    foreach my $line (<IN>) {
        if ( $line =~ /^>|^\*|^$/ ) { print OUT $line }
        else {
            $line =~ s/[A|S|T|G|P]/0/g;
            $line =~ s/[D|N|E|Q]/1/g;
            $line =~ s/C/2/g;
            $line =~ s/[R|K|H]/3/g;
            $line =~ s/[M|V|I|L]/4/g;
            $line =~ s/[F|Y|W]/5/g;
            print OUT $line;
        }
    }
}

