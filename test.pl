#!/usr/bin/perl -w
require 5.000; use English; use strict 'vars', 'refs', 'subs';

BEGIN     {
    use lib './';               # Force use of my dev version
    use Glade::PerlGenerate;
    }

# We expect to be supplied with parameter
#   $ARGV[0] is name of a Glade <GTK-Interface> XML file
my $glade = (shift @ARGV || "Example/BusForm.glade");
my $project_options_file = $glade;
$project_options_file =~ s/(xml|glade)$/glade2perl.xml/;
# Default $project_options_file is eg 'Example/BusForm.glade2perl.xml'
my $log_file = $glade;
$log_file =~ s/(xml|glade)$/glade2perl.log/;
# Default $log_file is eg 'Example/BusForm.glade2perl.log'

sub main {
    # Build a UI from a string
    open SAVOUT, ">&STDOUT";
    print SAVOUT "Test 1..3 Building a UI from a string of XML\n";
    &string_test || print "Not ";
    open STDOUT, ">&SAVOUT";
    close(SAVOUT) || die "can't close stdout: $!" ;
    print "Test 1..3 OK\n\n";

    # Generate source code for the example Glade file
    print "Test 2..3 Generating source code for the example Glade file\n";
    $Glade::PerlSource::first_form = '';
    bless $main::Glade_Perl_Generate_options, '';
    &file_test || print "Not ";
    print "Test 2..3 OK\n\n";

    # Subclass the generated code
    print "Test 3..3 Subclassing the generated source code for the example Glade file\n";
    eval "use Generated::SubBusForm;SubBusFrame->run || print 'Not' ";
    print "Test 3..3 OK\n\n";
}

sub file_test {
    # Force diagnostics and source to be written line by line
    # I need this for my editor's shellout to report fully on failure
    select STDOUT; $OUTPUT_AUTOFLUSH = 1;
    
    # Choose the Generate run options. 
    #   These options override the project_options
    #   which override user_options 
    #   which override site_options 
    #   which override Glade::PerlProject defaults
    Glade::PerlGenerate->options( 
    # User option      Value       Meaning                         Default
    # -----------      -----       -------                         -------
    'author'        => 'Dermot Musgrove <dermot.musgrove\@virgin.net>',
#   'author'        => undef,      # Author string for sources eg  values from Perl's
                                   # 'My Name <my.email@some.org>' (gethostbyname("localhost"))
#   'version'       => undef,      # Version number to use         0.0.1
#   'date'          => undef,      # The date to show in sources   Build time of
#   'copying'       => undef,      # Copying text to include     
    'description'   => "This is an example of the Glade-Perl
source code generator",
    'verbose'       => 2,          # Level of verbosity            1
                                   # 0 (quiet) to 10 (all)
    'indent'        => '    ',     # Indent for source code        4 spaces)
    'tabwidth'      => 4,          # Number of spaces to replace   8
                                   # with a tab in source code
    'diag_wrap'     => 0,          # Wrap diagnostic messages      0 = no wrap
                                   # at this character (approx). 
                                   # 0 = no breaks (not easy to
                                   # read on 80 column displays)
    'log_file'      => undef,      # Write diagnostics to STDOUT
#    'log_file'      => 
    'write_source'  => 'True',     # Write to the default files    No source
#   'write_source'  => 'STDOUT',   # Write sources to STDOUT
                                   # but there will be nothing 
                                   # to run later
#   'write_source'  => 'File.pm',  # Write sources to File.pm
                                   # They will not run from here
                                   # you must cut-paste them
#   'write_source'  => undef,      # Don't write source code
    'style'         => undef,     # Generate OO AUTOLOAD code    OO with subclass
#    'style'         => 'Libglade', # Generate libglade type code

    'dont_show_UI'  => 'True',     # Show UI during the Build     Show UI
                                   # and wait for user action
    'autoflush'     => 'True',
    'use_modules'    => 'Example::BusForm_mySUBS',
#   'site_options'  => 'File.xml', # Site options file name       /etc/gpgrc.xml
#   'user_options'  => 'File.xml', # User options file name       ~/.gpgrc.xml
    'project_options' => $project_options_file, 
                                   # Project-specific options     Don't read file
    'allow_gnome'   => undef,      # Ignore/report Gnome widgets  Ignore Gnome
#   'my_perl_gtk'   => '0.6123',   # I have CPAN version 0.6123   Use Gtk-Perl's version no
#   'my_perl_gtk'   => '19991001', # I have the gnome.org CVS     Use Gtk-Perl's version no
                                   # version of 'gnome-perl' that 
                                   # I downloaded on Oct 1st 1999
#   'my_gnome_libs' => '19991001', # I have the gnome.org CVS     Use gnome-libs version no
                                   # version of 'gnome-libs' that 
                                   # I downloaded on Oct 1st 1999
    );
        
    # Uncomment all this to read and build the example Glade file
    Glade::PerlGenerate->Form_from_Glade_File( 'glade_filename' => $glade ) 
}

sub string_test {
    # Force diagnostics and source to be written line by line
    # I need this for my editor's shellout to report fully on failure
    select STDOUT; $OUTPUT_AUTOFLUSH = 1;

    Glade::PerlGenerate->options( 
        'verbose'       => 0,
        'write_source'  => undef,
        'dont_show_UI'  => 'False',
    );
    
    # Build UI from a Glade XML string
    Glade::PerlGenerate->Form_from_XML( 'xml' => &Test_XML_String )
}

sub Test_XML_String {
    return 
"<?xml version=\"1.0\"?>
<GTK-Interface>

<project>
  <name>Form_from_XML</name>
  <directory></directory>
  <source_directory></source_directory>
  <pixmaps_directory>pixmaps</pixmaps_directory>
  <language>C</language>
  <gettext_support>False</gettext_support>
  <use_widget_names>False</use_widget_names>
  <main_source_file>gladesrc.c</main_source_file>
  <main_header_file>gladesrc.h</main_header_file>
  <handler_source_file>gladesig.c</handler_source_file>
  <handler_header_file>gladesig.h</handler_header_file>
</project>

<widget>
  <class>GtkWindow</class>
  <name>window1</name>
  <width>350</width>
  <height>50</height>
  <title>Progressbar and button from XML string</title>
  <type>GTK_WINDOW_TOPLEVEL</type>
  <position>GTK_WIN_POS_MOUSE</position>
  <allow_shrink>True</allow_shrink>
  <allow_grow>True</allow_grow>
  <auto_shrink>False</auto_shrink>

  <widget>
    <class>GtkVBox</class>
    <name>vbox1</name>
    <homogeneous>False</homogeneous>
    <spacing>0</spacing>

    <widget>
      <class>GtkProgressBar</class>
      <name>progressbar1</name>
      <value>50</value>
      <lower>0</lower>
      <upper>100</upper>
      <child>
        <padding>0</padding>
        <expand>True</expand>
        <fill>True</fill>
      </child>
      <bar_style>GTK_PROGRESS_CONTINUOUS</bar_style>
      <orientation>GTK_PROGRESS_LEFT_TO_RIGHT</orientation>
      <activity_mode>False</activity_mode>
      <show_text>True</show_text>
      <format>%P %%</format>
      <text_xalign>0.5</text_xalign>
      <text_yalign>0.5</text_yalign>
    </widget>

    <widget>
      <class>GtkButton</class>
      <name>button1</name>
      <child>
        <padding>0</padding>
        <expand>True</expand>
        <fill>True</fill>
      </child>
      <can_default>True</can_default>
      <has_default>True</has_default>
      <can_focus>True</can_focus>
      <accelerator>
        <modifiers>GDK_CONTROL_MASK</modifiers>
        <key>GDK_Q</key>
        <signal>clicked</signal>
      </accelerator>
      <signal>
        <name>clicked</name>
        <handler>destroy_Form</handler>
        <last_modification_time>Fri, 18 Jun 1999 00:52:51 GMT</last_modification_time>
      </signal>
      <label>Close this window and run next test</label>
    </widget>
  </widget>
</widget>

</GTK-Interface>
";
}

main && exit 0;

END {
    close(STDOUT) || die "can't close stdout: $!" 
    }

1;

__END__

