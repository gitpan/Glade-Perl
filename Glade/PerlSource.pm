package Glade::PerlSource;
require 5.000; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to the
# author, who can be contacted at dermot.musgrove@virgin.net
#                              or dermot@glade.perl.connrctfree.co.uk

BEGIN {
    use File::Copy; # for copying generated files
    use Glade::PerlRun qw( :METHODS :VARS !&_); 
                                            # Our run-time methods and vars
                                            # but not &_ since we do that ourselves.
    use File::Basename qw( basename );      # in check_gettext_strings
    use Text::Wrap     qw( wrap $columns ); # in write_gettext_strings
    use subs        qw(
                        _
                        start_checking_gettext_strings
                    );
    use vars        qw( 
                        @ISA 
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE 
                        $VERSION
                        @VARS @METHODS 
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $Glade_Perl
                        $encoding
                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs
                        @use_modules
                        $indent
                        $tab

                        $radiobuttons 
                        $radiomenuitems 
                        $current_data
                        $current_name
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                      );
    $PACKAGE      = __PACKAGE__;
    $VERSION        = q(0.54);
    @VARS         = qw( 
                        $VERSION
                        $AUTHOR
                        $DATE
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $Glade_Perl
                        $encoding
                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs
                        @use_modules
                        $indent
                        $tab

                        $radiobuttons 
                        $radiomenuitems 
                        $current_data
                        $current_name
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                    );
    @METHODS      = qw( 
                        _
                        S_
                        D_
                        start_checking_gettext_strings
                        missing_handler
                    );
    $subs =             '';
    $autosubs =         ' destroy_Form about_Form '.
                        ' toplevel_hide toplevel_close toplevel_destroy ';
    $LOOKUP       = 2;
    $BOOL         = 4;
    $DEFAULT      = 8;
    $KEYSYM       = 16;
    $LOOKUP_ARRAY = 32;
    # Tell interpreter who we are inheriting from
    @ISA          = qw( Exporter Glade::PerlRun );
    # These symbols (globals and functions) are always exported
    @EXPORT       = qw(  );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @VARS, @METHODS );
    # Tags (groups of symbols) to export        
    %EXPORT_TAGS  = (   'METHODS'   => [@METHODS],
                        'VARS'      => [@VARS]  );
}

%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
    USERDATA    => undef,
);

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

sub new {
    my $that  = shift;
    # Allow indirect constructor so that we can call eg. 
    #   $window1 = BusForm_mySUBS->new; # and then
    #   $window2 = $window1->new;
    my $class = ref($that) || $that;

    # Call our super-class constructor to get an object and reconsecrate it
    my $self = bless $that->SUPER::new(), $class;

    # Add our own data access methods to the inherited constructor
    my($element);
    foreach $element (keys %fields) {
        $self->{_permitted_fields}->{$element} = $fields{$element};
    }
    @{$self}{keys %fields} = values %fields;
    return $self;
}

#===============================================================================
#=========== Gettext Utilities                                              ====
#===============================================================================
# These are defined within a no-warning block to avoid warnings about redefining
# They override the subs in Glade::PerlRun during your development
{   
    local $^W = 0;
    eval "sub _ {_check_gettext('__', \@_);}";
}
# Translate into source language
sub S_ { _check_gettext('__S', @_)}

# Translate into diagnostics language
sub D_ { _check_gettext('__D', @_)}

sub start_checking_gettext_strings {
    # Ask for translations to be checked and stored if missing
    my ($class, $key, $file) = @_;
    $I18N->{($key || '__')}{'__SAVE_MISSING'} = ($file || "&STDOUT");
}

sub stop_checking_gettext_strings {
    # Ask for translation checking to be stopped
    my ($class, $key) = @_;
    undef $I18N->{($key || '__')}{'__SAVE_MISSING'};
}

sub _check_gettext {
    # If check_gettext_strings() has been called and there is no translation
    # we store the original string for later output by write_gettext_strings
    my ($key, $text, $depth) = @_;
    $depth ||= 1;
    if (defined $I18N->{$key}{$text}) {
        return $I18N->{$key}{$text};
    } else {
        if ($I18N->{$key}{'__SAVE_MISSING'}) {
            my $called_at = 
                basename((caller $depth)[1]). ":".(caller $depth)[2];
            unless ($I18N->{$key}{'__MISSING_STRINGS'}{$text} && 
                $I18N->{$key}{'__MISSING_STRINGS'}{$text} =~ / $called_at /) {
                $I18N->{$key}{'__MISSING_STRINGS'}{$text} .= " $called_at ";
            }
        }
        return $text;
    }
}

sub write_missing_gettext_strings {
    # Write out the strings that need to be translated in .pot format
    my ($class, $key, $file, $no_header, $copy_to) = @_;
    $key ||= "__";
    my ($string, $called_at);
    my $me = __PACKAGE__."->write_translatable_strings";
    my $saved = $I18N->{$key}{'__MISSING_STRINGS'};
    $key  ||= "__";
    $file ||= $I18N->{$key}{'__SAVE_MISSING'};
    return unless keys %$saved;
    open POT, ">$file" or 
        die sprintf(("error %s - can't open file '%s' for output"),
                $me, $file);
    my $date = `date +"%Y-%m-%d %H:%M%z"`; chomp $date;
    my $year = `date +"%Y"`; chomp $year;
    # Print header
    print POT "# ".sprintf(S_("These are strings that had no gettext translation in '%s'"), $key)."\n";
    print POT "# ".sprintf(S_("Automatically generated by %s"),__PACKAGE__)."\n";
    print POT "# ".S_("Date")." ".`date`;
    print POT "# ".sprintf(S_("Run from class %s in file %s"), $class->PACKAGE, (caller 0)[1])."\n";
    unless ($no_header && $no_header eq "NO_HEADER") {
        print POT "
# SOME DESCRIPTIVE TITLE.
# Copyright (C) $year ORGANISATION
# ".$class->AUTHOR.",
#
# , fuzzy
msgid \"\"
msgstr \"\"
\"Project-Id-Version:  ".$class->PACKAGE." ".$class->{'VERSION'}."\\n\"
\"POT-Creation-Date: $date\\n\"
\"PO-Revision-Date:  YEAR-MO-DA HO:MI+ZONE\\n\"
\"Last-Translator:  ".$class->AUTHOR."\\n\"
\"Language-Team:  LANGUAGE \<LL\@li.org\>\\n\"
\"MIME-Version:  1.0\\n\"
\"Content-Type: text/plain; charset=CHARSET\\n\"
\"Content-Transfer-Encoding:  ENCODING\\n\"

# Generic replacement
msgid  \"\%s\"
msgstr \"\%s\"

";  }

    # Print definition for each string
    foreach $string (%$saved) {
        next unless $string and $saved->{$string};
        print POT wrap("#", "#",$saved->{$string}), "\n";
        if ($string =~ s/\n/\\n\"\n\"/g) {$string = "\"\n\"".$string}
        print POT "msgid  \"$string\"\n";
        if ($copy_to && $copy_to eq 'COPY_TO') {
            print POT "msgstr \"$string\"\n\n";
        } else {
            print POT "msgstr \"\"\n\n";
        }
    }
    close POT;
}

#===============================================================================
#=========== Utilities to write output file                         ============
#===============================================================================
sub Stop_Writing_to_File { shift->Write_to_File('-1') }

sub Write_to_File {
    my ($class) = @_;
    my $me = "$class->Write_to_File";
    my $filename = $Glade_Perl->{'options'}->write_source;
    if (fileno UI or fileno SIGS or fileno SUBCLASS or $class->Building_UI_only) {
        # Files are already open or we are not writing source
        if ($class->Writing_to_File) {
            if ($filename eq '-1') {
                close UI;
                close SUBCLASS;
                close SIGS;
                $class->diag_print (2, "%s- Closing output file in %s",
                    $indent, $me);
                $Glade_Perl->{'options'}->write_source(undef);
            } else {
                $class->diag_print (2, "%s- Already writing to %s in %s",
                    $indent, $class->Writing_to_File, $me);
            }
        }

    } elsif ($filename && ($filename eq '1')) {
        $class->diag_print (2, "%s- Using default output files ".
            "in Glade <project><source_directory> in %s", 
            $indent, $me);

    } elsif ($filename && ($filename ne '-1') ) {
        # We want to write source
        if ($filename eq 'STDOUT') {
            $Glade_Perl->{'options'}->write_source('>&STDOUT');
        }
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'UI  ', $filename, $me);
        open UI,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBS', $filename, $me);
        open SIGS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBCLASS', $filename, $me);
        open SUBCLASS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        UI->autoflush(1);
        SIGS->autoflush(1);
        SUBCLASS->autoflush(1);
    } else {
        # Nothing to do
    }
}

sub add_to_UI {
    my ($class, $depth, $expr, $tofileonly, $notabs) = @_;
    my $me = "$class->add_to_UI";
    my $mydebug = ($class->verbosity >= 6);
    if ($depth < 0) {
        $mydebug = 1;
        $depth = -$depth;
    }
    if ($class->Writing_to_File) {
        my $UI_String = ($indent x ($depth)).$expr;
        if (!$notabs && $tab) {
            # replace multiple spaces with tabs
            $UI_String =~ s/$tab/\t/g;
        }
        eval "push \@{${current_form}\{'UI_Strings'}}, \$UI_String";
    }
    unless ($tofileonly) {
        eval $expr or 
            ($@ && die  "\n\nin $me\n\twhile trying to eval".
                "'$expr'\n\tFAILED with Eval error '$@'\n");
    }
    if ($mydebug) {
        $expr =~ s/\%/\%\%/g;
        $class->diag_print (2, "UI%s'%s'", $indent, $expr);
    }
}

#===============================================================================
#=========== Source code templates                                  ============
#===============================================================================
sub warning {
    my ($class, $oktoedit) = @_;
    if ($oktoedit && $oktoedit eq 'OKTOEDIT') {
        return "#
# ".S_("You can safely edit this file, any changes that you make will be preserved")."
# ".S_("and this file will not be overwritten by the next run of")." $class
#
";

    } else {
        return "#
# ".S_("DO NOT EDIT THIS FILE, ANY CHANGES THAT YOU MAKE WILL BE LOST WHEN")."
# ".S_("THIS FILE WILL BE OVERWRITTEN BY THE NEXT RUN OF")." $class
#
";
    }
}

sub perl_preamble {
    my ($class, $package, $project, $proto, $name, $oktoedit) = @_;
    my $localtime = localtime;
    my $warning_string;
    return 
"#==============================================================================
#=== ".S_("This is the")." '$name' class                              
#==============================================================================
package $name;
require 5.000; use strict \'vars\', \'refs\', \'subs\';
# UI class '$name' (".S_("version")." $project->{'version'})
# 
# ".S_("Copyright")." (c) ".S_("Date")." $project->{'date'}
# ".S_("Author")." $project->{'author'}
#
$project->{'copying'} $project->{'author'}
#
#==============================================================================
# ".S_("This perl source file was automatically generated by")." 
# $class ".S_("version")." $VERSION - $DATE
# ".S_("Copyright")." (c) ".S_("Author")." $AUTHOR
#
# ".S_("from Glade file")." $project->{'glade_filename'}
# $project->{'date'}
#==============================================================================

";
}

sub perl_about {
    my ($class, $project, $name) = @_;
#use Data::Dumper;print Dumper($project);
    my $logo = "\$Glade::PerlRun::pixmaps_directory";
#    my $logo = $project->{'glade_proto'}{'project'}{'pixmaps_directory'};
    $logo .= '/' if $logo;
    $logo .= $project->{'logo'};

    if ($Glade_Perl->{'options'}->{'allow_gnome'}) {
        return
"sub about_Form {
${indent}my (\$class) = \@_;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}#
${indent}# ".S_("Create a")." Gnome::About '\$ab'
${indent}my \$ab = new Gnome::About(
${indent}${indent}\"$name\", 
${indent}${indent}\"$project->{'version'}\", 
${indent}${indent}_(\"Copyright\").\" $project->{'date'}\", 
${indent}${indent}\"$project->{'author'}\", 
${indent}${indent}_(\"$project->{'description'}\").\"\\n\".
${indent}${indent}\"Gtk \".     _(\"version\").\": \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl \"._(\"version\").\": \$Gtk::VERSION\\n\".
${indent}${indent}_(\"run from file\").\": \$name\\n\".
${indent}${indent}\"$project->{'copying'}\", 
${indent}${indent}\"$logo\", 
${indent});
${indent}\$ab->set_title(_(\"About\").\" $name\" );
${indent}\$ab->position('mouse' );
${indent}\$ab->set_policy(1, 1, 0 );
${indent}\$ab->set_modal(1 );
${indent}\$ab->show;
} # ".S_("End of sub")." about_Form";

    } else {
       return
"sub about_Form {
${indent}my (\$class) = \@_;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}my \$message = 
${indent}${indent}__PACKAGE__.\" (\"._(\"version\").\" $project->{'version'} - $project->{'date'})\\n\".
${indent}${indent}_(\"Written by\").\" $project->{'author'} \\n\\n\".
${indent}${indent}_(\"$project->{'description'}\").\" \\n\\n\".
${indent}${indent}\"Gtk \".     _(\"version\").\": \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl \"._(\"version\").\": \$Gtk::VERSION\\n\".
${indent}${indent}_(\"run from file\").\": \$name\";
${indent}__PACKAGE__->message_box(\$message, _(\"About\").\" \\u\".__PACKAGE__, [_('Dismiss'), _('Quit Program')], 1,
${indent}${indent}\"$logo\", 'left' );
} # ".S_("End of sub")." about_Form";
    }
}

sub perl_signal_handler {
    my ($class, $handler, $type) = @_;
    my ($body);
    if ($type eq 'SIGS') {
        $body = "
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# ".S_("Get ref to hash of all widgets on our form")."
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# ".S_("REPLACE the line below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$Glade_Perl->{'options'}{'logo'}\");

";
    } elsif ($type eq 'SUBCLASS') {
        $body = "
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# ".S_("Get ref to hash of all widgets on our form")."
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# ".S_("REPLACE the lines below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
#${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$Glade_Perl->{'options'}{'logo'}\");
${indent}shift->SUPER::$handler(\@_);

";
    } elsif ($type eq 'Libglade') {
        $body = "
${indent}my (\$class, \$data, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";

${indent}# ".S_("REPLACE the line below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$Glade_Perl->{'options'}{'logo'}\");

";
    }

    return "sub $handler {$body} # ".S_("End of sub")." $handler
";
}

sub perl_constructor_bottom {
    my ($class, $project, $formname) = @_;
    my $about_string = $class->perl_about($project, $project->{'name'});
    return "

${indent}#
${indent}# ".S_("Return the constructed UI")."
${indent}bless \$self, \$class;
${indent}\$self->FORM(\$forms->{'$formname'});
${indent}\$self->TOPLEVEL(\$self->FORM->{'$formname'});
${indent}\$self->INSTANCE(\"$formname-\$instance\");
${indent}\$self->CLASS_HIERARCHY(\$self->FORM->{'__WH'});
${indent}\$self->WIDGET_HIERARCHY(\$self->FORM->{'__CH'});
${indent}\$__PACKAGE__::all_forms->{\$self->INSTANCE} = \$self->FORM;
${indent}return \$self;
} # ".S_("End of sub")." new";
}

sub perl_doc {
    my ($class, $project, $name, $first_form) = @_;
# FIXME I18N
return 
"
1;

\__END__

#===============================================================================
#==== ".S_("Documentation")."
#===============================================================================
\=pod

\=head1 NAME

${name} - ".S_("version")." $project->{'version'} $project->{'date'}

".S_("$project->{'description'}")."

\=head1 SYNOPSIS

 use ${name};

 if (\$".S_("we_want_to_subclass_this_class").") {
   # ".S_("Inherit the AUTOLOAD dynamic methods from")." ${first_form}
   *AUTOLOAD = \\\&$first_form\::AUTOLOAD;

   # ".S_("Tell interpreter who we are inheriting from")."
   use vars qw( \@ISA ); \@ISA = qw( ${first_form} );
 }
 
 ".S_("To construct the window object and show it call")."
 
 Gtk->init;
 my \$window = ${first_form}->new;
 \$window->TOPLEVEL->show;
 Gtk->main;
 
 ".S_("OR use the shorthand for the above calls")."
 
 ${first_form}->run;

\=head1 DESCRIPTION

".S_("Unfortunately, the author has not yet written any documentation :-(")."

\=head1 AUTHOR

$project->{'author'}

\=cut
";
}

#===============================================================================
#=========== Base class using AUTOLOAD
#===============================================================================
sub write_UI {
    my ($class, $proto) = @_;
#$class->diag_print(2, $proto);
    my $me = "$class->write_UI";
    my @code;
    my ($permitted_stubs, $UI_String);
    my ($handler, $module, $form );
#$class->diag_print(2, $proto);
    unless (fileno UI) {            # ie user has supplied a filename
        # Open UI for output unless the filehandle is already open 
        open UI,     ">".($proto->{'UI_filename'})    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->{'UI_filename'});
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'UI  ', $proto->{'UI_filename'}, $me);
        if ($Glade_Perl->{'options'}->autoflush) {
            UI->autoflush(1);
        }
    }
    foreach $form (keys %$forms) {
#        next if $form =~ /^__/;
        $class->diag_print(4, "%s- Writing %s for class %s",
            $indent, 'source', $form);
        $permitted_stubs = '';
        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            $permitted_stubs .= "\n${indent}'$handler' => undef,";
        }
        # FIXME Now generate different source code for each user choice
        push @code, $class->perl_AUTOLOAD_top(
            $Glade_Perl->{'options'}, $proto, $form, $permitted_stubs)."\n";
#print "Working on form '$form'\n";
#use Data::Dumper; print Dumper($forms);
#print "'",join("'\n", @{$forms->{$form}{'UI_Strings'}}),"'\n";
        $UI_String = join("\n", @{$forms->{$form}{'UI_Strings'}});
        push @code, $UI_String;
        push @code, $class->perl_constructor_bottom($Glade_Perl->{'options'}, $form);
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc($Glade_Perl->{'options'}, $proto->{'UI_class'}, $first_form);

    print UI "#!/usr/bin/perl -w\n";
    print UI "#\n# ".S_("This is the (re)generated UI construction class.")."\n";
    print UI $class->warning;
    print UI join("\n", @code);
# FIXME write these files if necessary
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Changelog;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Makefile;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_README;
#    print STDOUT "-------------------------------------------\n";
}

sub perl_AUTOLOAD_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->AUTOLOAD_top";
    my $module;
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    my $use_string = '';
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    $init_string .= "${indent}\$class->load_translations('$project->{'name'}');
${indent}# ".S_("You can use the line below to load a test .mo file before it is")."
${indent}# ".S_("installed in the normal place")." (eg /usr/local/share/locale/".
    $Glade_Perl->{'options'}->source_LANG."/LC_MESSAGES/".$project->{'name'}.".mo)
#${indent}\$class->load_translations('$project->{'name'}', 'test', undef, ".
    "'$project->{'directory'}/ppo/$project->{'name'}.mo');\n";
    if ($Glade_Perl->{'options'}->{'allow_gnome'}) {
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
        $use_string .="\n${indent}# ".
                        S_("We need the Gnome bindings as well").
                        "\n${indent}use Gnome;"
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;

return $class->perl_preamble($module, $project, $proto, $name, undef).
"BEGIN {
${indent}# ".S_("Run-time utilities and vars")."
${indent}use Glade::PerlRun; 
${indent}# ".S_("Existing signal handler modules")."${use_string}
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \%stubs
${indent}             \$VERSION
${indent}             \$AUTOLOAD
${indent}         );
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( $isa_string );
${indent}\$VERSION = '$project->{'version'}';
} # ".S_("End of sub")." BEGIN

${indent}\$Glade::PerlRun::pixmaps_directory ||= '$Glade_Perl->{'options'}{'glade_proto'}{'project'}{'pixmaps_directory'}';

%fields = (
${indent}# ".S_("These are the data fields that you can set/get using the dynamic")."
${indent}# ".S_("calls provided by AUTOLOAD (and their initial values).")."
${indent}# eg \$class->FORMS(\$new_value);      ".S_("sets the value of FORMS")."
${indent}#    \$current_value = \$class->FORMS; ".S_("gets the current value of FORMS")."
${indent}TOPLEVEL => undef,
${indent}FORM     => undef,
${indent}PACKAGE  => '$module',
${indent}VERSION  => '$project->{'version'}',
${indent}AUTHOR   => '$project->{'author'}',
${indent}DATE     => '$project->{'date'}',
${indent}INSTANCE => '$first_form',
${indent}CLASS_HIERARCHY => undef,
${indent}WIDGET_HIERARCHY => undef,
);

\%stubs = (
${indent}# ".S_("These are signal handlers that will cause a message_box to be")."
${indent}# ".S_("displayed by AUTOLOAD if there is not already a sub of that name")."
${indent}# ".S_("in any module specified in 'use_modules'.")."
$permitted_stubs
);

sub AUTOLOAD {
${indent}my \$self = shift;
${indent}my \$type = ref(\$self)
${indent}${indent}or die \"\$self is not an object so we cannot '\$AUTOLOAD'\\n\",
${indent}${indent}${indent}\"We were called from \".join(\", \", caller).\"\\n\\n\";
${indent}my \$name = \$AUTOLOAD;
${indent}\$name =~ s/.*://;       # ".S_("strip fully-qualified portion")."

${indent}if (exists \$self->{_permitted_fields}->{\$name} ) {
${indent}${indent}# ".S_("This allows dynamic data methods - see hash fields above")."
${indent}${indent}# eg \$class->UI('".S_("new_value")."');
${indent}${indent}# or \$current_value = \$class->UI;
${indent}${indent}if (\@_) {
${indent}${indent}${indent}return \$self->{\$name} = shift;
${indent}${indent}} else {
${indent}${indent}${indent}return \$self->{\$name};
${indent}${indent}}

${indent}} elsif (exists \$stubs{\$name} ) {
${indent}${indent}# ".S_("This shows dynamic signal handler stub message_box - see hash stubs above")."
${indent}${indent}__PACKAGE__->show_skeleton_message(
${indent}${indent}${indent}\$AUTOLOAD.\"\\n (\"._(\"AUTOLOADED by\").\" \".__PACKAGE__.\")\", 
${indent}${indent}${indent}\[\$self, \@_], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'$project->{'logo'}');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method\ `\$name' in class \$type\\n\".
${indent}${indent}${indent}\"We were called from \".join(\", \", caller).\"\\n\\n\";

${indent}}
} # ".S_("End of sub")." AUTOLOAD

sub run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->TOPLEVEL->show;
${indent}Gtk->main;
} # ".S_("End of sub")." run

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

sub new {
#
# ".S_("This sub will create the UI window")."
${indent}my \$that  = shift;
${indent}my \$class = ref(\$that) || \$that;
${indent}my \$self  = {
${indent}${indent}_permitted_fields   => \\\%fields, \%fields,
${indent}${indent}_permitted_stubs    => \\\%stubs,  \%stubs,
${indent}};
${indent}my (\$forms, \$widgets, \$data, \$work);
${indent}my \$instance = 1;
${indent}# ".S_("Get a unique toplevel widget structure")."
${indent}while (defined \$__PACKAGE__::all_forms->{\"$name-\$instance\"}) {\$instance++;}
";
}

#===============================================================================
#=========== SIGS signal handler class
#===============================================================================
sub write_SIGS {
    my ($class, $proto) = @_;
    my $me = "$class->write_SIGS";
    my ($permitted_stubs);
    my ($handler, $module, $form );
    my @code;
    unless (fileno SIGS) {            # ie user has supplied a filename
        # Open SIGS for output unless the filehandle is already open 
        open SIGS,     ">".($proto->{'SIGS_filename'})    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->{'SIGS_filename'});
        $class->diag_print (2, "%s- Writing %s source to %s - in %s",
            $indent, 'SIGS', $proto->{'SIGS_filename'}, $me);
        if ($Glade_Perl->{'options'}->autoflush) {
            SIGS->autoflush(1);
        }
    }
    $autosubs &&
        $class->diag_print (4, "%s- Automatically generated SUBS are '%s' by %s",
            $indent, $autosubs, $me);

    $form = $first_form;
    $class->diag_print(4, "%s- Writing %s for class %s", 
        $indent, 'SIGS', $form);
    $permitted_stubs = '';
    foreach $form (keys %$forms) {
        push @code, $class->perl_SIGS_top(
            $Glade_Perl->{'options'}, $proto, $form, $permitted_stubs);
        push @code,  "
#==============================================================================
#=== ".S_("Below are the signal handlers for")." '$form' class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'SIGS');
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }

    print SIGS "#!/usr/bin/perl -w\n";
    print SIGS "#
# ".S_("This is the (re)generated signal handler class")."
# ".S_("You can cut and paste the skeleton signal handler subs from this file")."
# ".S_("into the relevant classes in your application or its subclasses")."\n";
    print SIGS $class->warning;
    print SIGS join("\n", @code);
    print SIGS $class->perl_doc(
        $Glade_Perl->{'options'}, $proto->{'SIGS_class'}, $first_form);
    close SIGS; # flush buffers

    unless (-f $proto->{'APP_filename'}) {
        open SIGS,     ">".($proto->{'APP_filename'})    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->{'APP_filename'});
        $class->diag_print(4, "%s- Creating %s file %s",
            $indent, 'app', $proto->{'APP_filename'});
        $class->diag_print (2, "%s- Writing %s to %s - in %s",
            $indent, 'App', $proto->{'APP_filename'}, $me);
        if ($Glade_Perl->{'options'}->autoflush) {
            SIGS->autoflush(1);
        }
        print SIGS "#!/usr/bin/perl -w\n";
        print SIGS "#
# ".S_("This is the basis of an application with signal handlers")."\n";
        print SIGS $class->warning('OKTOEDIT');
        print SIGS join("\n", @code);
        print SIGS $class->perl_doc(
            $Glade_Perl->{'options'}, $proto->{'APP_class'}, $first_form);
    }
}

sub perl_SIGS_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SIGS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my @code;
    my ($module, $super);
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($project, $project->{'name'});
    $super = $project->{'source_directory'};
    $super =~ s/$project->{'directory'}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    $module = $project->{'UI_class'};
    my $init_string = '';
#    my $isa_string = 'Glade::PerlRun';
    my $use_string = "${indent}use ${super}${module};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
#        $isa_string .= " $module";
    }
    if ($Glade_Perl->{'options'}->{'allow_gnome'}) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    # remove double spaces
#    $isa_string =~ s/  / /g;
# FIXME I18N
return $class->perl_preamble($module, $project, $proto, "$name").
"BEGIN {
$use_string
} # ".S_("End of sub")." BEGIN

#===============================================================================
#=== ".S_("Below are the default signal handlers for")." '$name' class
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

#===============================================================================
#=========== Derived class (subclass)
#===============================================================================
sub write_SUBCLASS {
    my ($class, $proto) = @_;
    my $me = "$class->write_SUBCLASS";
    return if (-f $proto->{'SUBAPP_filename'});
    my @code;
    my ($permitted_stubs);
    my ($handler, $module, $form );
    unless (fileno SUBCLASS) {            # ie user has supplied a filename
        open SUBCLASS,     ">".($proto->{'SUBAPP_filename'})    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->{'SUBAPP_filename'});
        $class->diag_print(4, 
            "%s- Creating %s file %s",
            $indent, 'App Subclass', $proto->{'SUBAPP_filename'});
        $class->diag_print (2, "%s- Writing %s to %s - in %s",
            $indent, 'Subclass', $proto->{'SUBCLASS_filename'}, $me);
        if ($Glade_Perl->{'options'}->autoflush) {
            SUBCLASS->autoflush(1);
        }
    }
#    $autosubs &&
#        $class->diag_print (4, "%s- Automatically generated SUBS are '%s' by %s",
#               $indent, $autosubs, $me);

    $form = $first_form;
    $class->diag_print(4, "%s- Writing %s for class %s",
        $indent, 'SUBCLASS', $form);
    $permitted_stubs = '';
    # FIXME Now generate different source code for each user choice
#    push @code, $class->perl_SUBCLASS_top(
#        $project, $proto, $form, $permitted_stubs)."\n";
    foreach $form (keys %$forms) {
        push @code, $class->perl_SUBCLASS_top(
            $Glade_Perl->{'options'}, $proto, $form, $permitted_stubs);
        push @code, "
#==============================================================================
#=== ".S_("Below are (overloaded) signal handlers for")." '$form' class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'SUBCLASS');
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc(
        $Glade_Perl->{'options'}, $proto->{'SUBAPP_class'}, "Sub".$first_form);

    print SUBCLASS "#!/usr/bin/perl -w\n";
    print SUBCLASS "#
# ".S_("This is an example of a subclass of the generated application")."\n";
    print SUBCLASS $class->warning('OKTOEDIT');
    print SUBCLASS join("\n", @code);
}

sub perl_SUBCLASS_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SUBCLASS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my ($module, $super);
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($project, "Sub$project->{'name'}");
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    $super = $project->{'source_directory'};
    $super =~ s/$project->{'directory'}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    my $use_string = "\n${indent}use $super$project->{'APP_class'};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($Glade_Perl->{'options'}->{'allow_gnome'}) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    # remove double spaces
    $isa_string =~ s/  / /g;
# FIXME I18N
return $class->perl_preamble($module, $project, $proto, "Sub$name").
"BEGIN {
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \$VERSION
${indent}         );
${indent}# ".S_("Existing signal handler modules")."${use_string}
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}use Glade::PerlSource;
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( $name );
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\@ISA      = qw( $name Glade::PerlSource );
${indent}\$VERSION = '$project->{'version'}';
${indent}# ".S_("Inherit the AUTOLOAD dynamic methods from")." $name
${indent}*AUTOLOAD = \\\&$name\::AUTOLOAD;
} # ".S_("End of sub")." BEGIN

\%fields = (
# ".S_("Insert any extra data access methods that you want to add to")." 
#   ".S_("our inherited super-constructor (or overload)")."
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

#==============================================================================
#=== ".S_("Below are the overloaded class constructors")."
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# ".S_("Allow indirect constructor so that we can call eg. ")."
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}# ".S_("Call our super-class constructor to get an object and reconsecrate it")."
${indent}my \$self = bless \$that->SUPER::new(), \$class;

${indent}# ".S_("Add our own data access methods to the inherited constructor")."
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{_permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
} # ".S_("End of sub")." new

sub run {
${indent}my (\$class) = \@_;
$init_string
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\$class->check_gettext_strings;
${indent}my \$window = \$class->new;
${indent}# ".S_("Insert your subclass user data key/value pairs ")."
${indent}\$window->USERDATA({
#${indent}${indent}'Key1'   => 'Value1',
#${indent}${indent}'Key2'   => 'Value2',
#${indent}${indent}'Key3'   => 'Value3',
${indent}});
${indent}\$window->TOPLEVEL->show;
#${indent}my \$window2 = \$window->new;
#${indent}\$window2->TOPLEVEL->show;
${indent}Gtk->main;
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\$window->write_gettext_strings(\"__\", '$project->{'POT_filename'}');
${indent}return \$window;
} # ".S_("End of sub")." run
#===============================================================================
#=== ".S_("Below are (overloaded) default signal handlers for")." '$name' class 
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

#===============================================================================
#=========== Libglade class
#===============================================================================
sub write_LIBGLADE {
    my ($class, $proto) = @_;
    my $me = "$class->write_LIBGLADE";
    my @code;
    my ($permitted_stubs);
    my ($handler, $module, $form );
    return if -f $proto->{'LIBGLADE_filename'};
    unless (fileno LIBGLADE) {            # ie user has supplied a filename
        # Open LIBGLADE for output unless the filehandle is already open 
        open LIBGLADE,     ">".($proto->{'LIBGLADE_filename'})    or 
            die sprintf(
                "error %s - can't open file '%s' for output",
                $me, $proto->{'LIBGLADE_filename'});
    }
    $autosubs &&
        $class->diag_print (4, "%s- Automatically generated %s are '%s' by %s",
            $indent, 'SUBS', $autosubs, $me);

    $form = $first_form;
    $class->diag_print(4, "%s- Writing %s for class %s", 
        $indent, 'LIBGLADE', $form);
    $permitted_stubs = '';
    # FIXME Now generate different source code for each user choice
    push @code, $class->perl_LIBGLADE_top(
        $Glade_Perl->{'options'}, $proto, $form, $permitted_stubs)."\n";
#    push @code, $class->perl_LIBGLADE_AUTOLOAD_new_bottom($project, $form);
    foreach $form (keys %$forms) {
    push @code, "
#==============================================================================
#=== ".S_("Below are the signal handlers for")." '$form' UI
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'Libglade');
            }
        }
    }
    push @code, $class->perl_doc(
        $Glade_Perl->{'options'}, $proto->{'LIBGLADE_class'}, $proto->{'LIBGLADE_class'});

    open LIBGLADE,     ">".($proto->{'LIBGLADE_filename'})    or 
        die sprintf((
            "error %s - can't open file '%s' for output"),
            $me, $proto->{'LIBGLADE_filename'});
    $class->diag_print(2, 
        "%s- Creating %s file %s",
        $indent, 'libglade app', $proto->{'LIBGLADE_filename'});
    $class->diag_print (2, "%s- Writing %s source to %s - in %s",
        $indent, 'LIBGLADE App', $proto->{'LIBGLADE_filename'}, $me);
    LIBGLADE->autoflush(1) if $Glade_Perl->{'options'}->autoflush;

    print LIBGLADE "#!/usr/bin/perl -w\n";
    print LIBGLADE "#\n# ".S_("This is the basis of a LIBGLADE application with signal handlers")."\n";
    print LIBGLADE $class->warning('OKTOEDIT');
    print LIBGLADE join("\n", @code);
    close LIBGLADE;
}

sub perl_LIBGLADE_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_LIBGLADE_Header";
#use Data::Dumper; print Dumper(\@_;); exit
    my ($module, $super);
    my $about_string = $class->perl_about($project, $project->{'LIBGLADE_class'});
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun Gtk::GladeXML';
    my $use_string = "
${indent}use Glade::PerlRun;
${indent}use Gtk::GladeXML;";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($Glade_Perl->{'options'}->{'allow_gnome'}) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "
${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');
${indent}Gtk::GladeXML->init();";
    } else {
        $init_string .= "
${indent}Gtk->init();
${indent}Gtk::GladeXML->init();";
    }
    $super = "$project->{'source_directory'}";
    $super =~ s/.*\/(.*)$/$1/;
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;
# FIXME I18N
return $class->perl_preamble($module, $project, $proto, $project->{'LIBGLADE_class'}, undef).
"BEGIN {
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \$AUTOLOAD
${indent}             \$VERSION
${indent}             );
${indent}\$VERSION = '$project->{'version'}';
$use_string
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( Glade::PerlRun Gtk::GladeXML);
} # ".S_("End of sub")." BEGIN

${indent}\$Glade::PerlRun::pixmaps_directory ||= '$Glade_Perl->{'options'}{'glade_proto'}{'project'}{'pixmaps_directory'}';

\%fields = (
# ".S_("Insert any extra data access methods that you want to add to")."
#   ".S_("our inherited super-constructor (or overload)")."
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

#==============================================================================
#=== ".S_("Below are the class constructors")."
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# ".S_("Allow indirect constructor so that we can call eg.")."
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}my \$glade_file = '$project->{'glade_filename'}';
${indent}unless (-f \$glade_file) {
${indent}${indent}die \"Unable to find Glade file '\$glade_file'\";
${indent}}
${indent}# ".S_("Call Gtk::GladeXML to get an object and reconsecrate it")."
${indent}my \$self = bless new Gtk::GladeXML(\$glade_file, '$first_form'), \$class;

${indent}# ".S_("Add our own data access methods to the inherited constructor")."
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{_permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
} # ".S_("End of sub")." new

sub run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->signal_autoconnect_from_package('$project->{'LIBGLADE_class'}');

${indent}Gtk->main;
${indent}return \$window;
} # ".S_("End of sub")." run
#===============================================================================
#=== ".S_("Below are the default signal handlers for")." '$name' class 
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

1;

__END__
