#!/usr/bin/perl -w
require 5.000; use strict 'vars', 'refs', 'subs';

BEGIN     {
    use lib './';               # Force use of my dev version
    }

my $VERSION = "0.60";

# We expect to be supplied with parameter
#   $_[0] is name of a Glade <GTK-Interface> XML file
my $glade = $_[0] || 'Project.glade';
my $base = $glade;
# Strip off any suffix (if it exists)
$base =~ s/(.+)\..*$/$1/;
my $project_options_file = "$base.glade2perl.xml";
# Default $project_options_file is eg 'Bus.glade2perl.xml'

my $log_file = "$base.glade2perl.log";
# Default $log_file is eg 'Bus.glade2perl.log'

my $style;

sub main {
    # Build a UI from a string
    select STDOUT; $| = 1;
    my $i = 1;
    my $max = 3;

    print STDOUT "Test $i..$max Building a UI from a string of XML\n";
    &string_test || print "Not ";
    print STDOUT "Test $i..$max OK\n\n";
    print "OK\n\n"; $i++;
    
    undef $Glade::PerlSource::Glade_Perl;
    undef $Glade::PerlSource::first_form;
    # Generate source code for the example Glade file
    print STDOUT "Test $i..$max Generating AUTOLOAD code for the example Glade file\n";
    chdir "Example/Bus";
    print "Test $i..$max \n";
    &file_test("AUTOLOAD") || print $@, 'NOT ';
    print "OK\n\n"; $i++;

    # Use the Generated Subclass to run the generated code
    print "Test $i..$max Running the generated subclass code for the example Glade file\n";
    print "Test $i..$max ";
    {$^W=0; eval "use src::SubBus";}
    eval "SubBusFrame->app_run" || print $@, 'NOT ';
    print "OK\n\n"; $i++;
}

sub file_test {
    # Force diagnostics and source to be written line by line (autoflush)
    # I need this for my editor's shellout to report fully on failure
    select STDOUT; $| = 1;
    
    use Glade::PerlGenerate;
    # Choose the Generate run options. 
    #   These options override the project_options
    #   which override user_options 
    #   which override site_options 
    #   which override Glade::PerlProject defaults
    Glade::PerlGenerate->Form_from_Glade_File(
    # User option      Value       Meaning                         Default
    # -----------      -----       -------                         -------
    'app'   => {
        'author'        => 'Dermot Musgrove <dermot.musgrove@virgin.net>',
#   'author'        => undef,      # Author string for sources eg  values from Perl's
                                   # 'My Name <my.email@some.org>' (gethostbyname("localhost"))
#        'version'       => undef,      # Version number to use         0.01
        'date'          => undef,      # The date to show in sources   Build time of
        'copying'       => undef,      # Copying text to include     
        'description'   => "This is an example generated by the Glade-Perl source code generator",
        'use_modules'   => 'Bus_mySUBS',
        'allow_gnome'   => undef,      # Ignore/report Gnome widgets  Ignore Gnome
    },
    'diag'  => {
        'verbose'       => 2,          # Level of verbosity            1
                                   # 0 (quiet) to 10 (all)
        'indent'        => '    ',     # Indent for source code        4 spaces)
        'tabwidth'      => 4,          # Number of spaces to replace   8
                                       # with a tab in source code
    #   'wrap_at'     => 0,          # Wrap diagnostic messages      0 = no wrap
                                   # at this character (approx). 
                                   # 0 = no breaks (not easy to
                                   # read on 80 column displays)
#        'log'      => "$log_file",      # Write diagnostics to STDOUT
        'autoflush'     => 'True',
    },
    'source'    => {
        'indent'        => '    ',     # Indent for source code        4 spaces)
        'tabwidth'      => 4,          # Number of spaces to replace   8
                                       # with a tab in source code
        'write'  => 'True',     # Write to the default files    No source
    #    'write'  => 'STDOUT',   # Write sources to STDOUT
                                   # but there will be nothing 
                                   # to run later
    #    'write'  => 'File.pm',  # Write sources to File.pm
                                   # They will not run from here
                                   # you must cut-paste them
    #    'write'  => undef,      # Don't write source code
    #    'style'         => undef,      # Generate OO AUTOLOAD code    OO with subclass
    #    'style'         => 'Libglade', # Generate libglade type code
        'style'         => shift,      # Each class to separate file
    },
    'glade2perl'    => {
        'dont_show_UI'  => 'True',     # Show UI during the Build     Show UI
                                   # and wait for user action
    #   'my_perl_gtk'   => '0.6123',   # I have CPAN version 0.6123   Use Gtk-Perl's version no
    #   'my_perl_gtk'   => '19991001', # I have the gnome.org CVS     Use Gtk-Perl's version no
                                       # version of 'gnome-perl' that 
                                       # I downloaded on Oct 1st 1999
    #   'my_gnome_libs' => '19991001', # I have the gnome.org CVS     Use gnome-libs version no
                                       # version of 'gnome-libs' that 
                                       # I downloaded on Oct 1st 1999
        'xml'   => {
            'site'  => '__NOFILE',   # Site options file name       /etc/gpgrc.xml
            'user'  => '__NOFILE',   # User options file name       ~/.gpgrc.xml
            'project' => '__NOFILE',
#            'project' => $project_options_file, 
                                    # Project-specific options     Don't read file
        },
    },
    'glade' => {
        'file' => $glade 
    },
);
}

sub string_test {
    # Force diagnostics and source to be written line by line (autoflush)
    # I need this for my editor's shellout to report fully on failure
    select STDOUT; $| = 1;

    # Build UI from a Glade XML string
    Glade::PerlGenerate->Form_from_XML(
        'verbose'           => 1,
        'write_source'      => undef,
        'dont_show_UI'      => 'False',
        'site_options'      => '__NOFILE',
        'user_options'      => '__NOFILE',
        'project_options'   => '__NOFILE',
        'xml'               => &Test_XML_String )
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
  <gnome_support>False</gnome_support>
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
      <label>Close this window and run the next tests</label>
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

