package Glade::PerlRun;
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
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Exporter    qw(  );
    use POSIX       qw( isdigit );
    use Gtk;                             # For message_box
    use Cwd         qw( cwd chdir );
    use File::Basename;
    use Data::Dumper;
    use Text::Wrap  qw( wrap $columns ); # in options, diag_print
    use vars        qw( @ISA 
                        $AUTOLOAD
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE $VERSION $AUTHOR $DATE
                        @VARS @METHODS 
                        $Glade_Perl
                        $I18N
                        $all_forms
                        $project
                        $widgets 
                        $work
                        $seq
                        $data 
                        $forms 
                        $pixmaps_directory
                        $indent
                        $tab
                        $convert
                        @use_modules
                        %stat
                        $NOFILE
                        $permitted_fields
                      );
    # Tell interpreter who we are inheriting from
    @ISA          = qw( 
                        Exporter 
                        );

    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.58);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove\@virgin.net>);
    $DATE         = q(Tue Jun 12 12:39:37 BST 2001);
    $widgets      = {};
    $all_forms    = {};
    $convert      = {};
    $indent       = '';
    $pixmaps_directory = "pixmaps";
    $NOFILE = '__NOFILE';
    $permitted_fields = '_permitted_fields';

    # These vars are imported by all Glade-Perl modules for consistency
    @VARS         = qw(  
                        $PACKAGE $VERSION $AUTHOR $DATE
                        $Glade_Perl
                        $I18N
                        $indent
                        $tab
                        @use_modules
                        $NOFILE
                        $permitted_fields
                    );
    @METHODS      = qw( 
                        _
                        S_
                        D_
                        typeKey
                        QuoteXMLChars
                        keyFormat
                        start_checking_gettext_strings
                        create_image 
                        create_pixmap 
                        missing_handler 
                        message_box 
                        message_box_close 
                        show_skeleton_message 
                        reload_any_altered_modules
                    );
    # These symbols (globals and functions) are always exported
    @EXPORT       = qw( 
                    );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS );
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                    );
}

%fields = (
    # These are the data fields that you can set/get using the dynamic
    # calls provided by AUTOLOAD (and their initial values).
    # eg $class->FORMS($new_value);      sets the value of FORMS
    #    $current_value = $class->FORMS; gets the current value of FORMS
    'app'   => {
        'name'          => undef,
        'author'        => undef,
        'version'       => '0.01',
        'date'          => undef,
        'copying'       =>          # Copying policy to appear in generated source
            '# Unspecified copying policy, please contact the author\n# ',
        'description'   => undef,   # Description for About box etc.
#        'pixmaps_directory' => undef,
        'logo'          => 'Logo.xpm', # Use specified logo for project
    },
    'data'  => {
        'directory' => undef,
    },
    'diag'  => {
        'verbose'       => undef,   # Show errors and main diagnostics
        'wrap_at'       => 0,       # Max diagnostic line length (approx)
        'autoflush'     => undef,   # Dont change the policy
        'indent'        => '    ',  # Diagnostics indent to lay out messages
        'benchmark'     => undef,   # Dont add time to the diagnostic messages
        'log'           => undef,   # Write diagnostics to STDOUT 
#        'log'           => "\&STDOUT",# Write diagnostics to STDOUT 
                                    # or Filename to write diagnostics to
        'LANG'          => ($ENV{'LANG'} || ''),
                                        # Which language we want the diagnostics
    },
    'run_options'   => {
        'name'          => __PACKAGE__,
        'version'       => $VERSION,   # Version of Glade-Perl used
        'author'        => $AUTHOR,
        'date'          => $DATE,
        'logo'          => 'glade2perl_logo.xpm', # Our logo
        'start_time'    => undef,   # Time that this run started
        'mru'           => undef,
        'prune'         => undef,
        'proto'   => {
            'site'          => undef,
            'user'          => undef,
            'project'       => undef,
            'params'        => undef,
            'app_defaults'  => undef,
            'base_defaults' => undef,
        },
        'xml'  => {
            'site'          => undef,
            'user'          => undef,
            'project'       => undef,
            'params'        => undef,
            'app_defaults'  => "Application defaults",
            'base_defaults' => __PACKAGE__." defaults",
            'set_by'        => 'DEFAULT',   # Who set the options
            'encoding'      => undef,       # Character encoding eg ('ISO-8859-1') 
        },
    },
);


%stubs = (
);

my $option_hashes = " ".
join(" ",
    'app',
    'diag',
    'glade',
    'glade2perl',
    'glade_helper',
    'source',
    'xml',
    'dist',
    'helper',
    'test'
)." ";

=pod

=head1 NAME

Glade::PerlRun - Utility methods for Glade-Perl (and generated applications).

=head1 SYNOPSIS

 use vars qw(@ISA);
 use Glade::PerlRun qw(:METHODS :VARS);
 @ISA = qw( Glade::PerlRun 

 my $Object = Glade::PerlRun->new(%params);
 
 $Object->glade->file($supplied_path);
 
 $path = $Object->full_Path($Object->glade->file, $dir);

 $Object->save_app_options($path);

=head1 DESCRIPTION

Glade::PerlRun provides some utility methods that Glade-Perl modules and 
also the generated classes need to run. These methods can be inherited and 
called in any app that use()s Glade::PerlRun and quotes Glade::PerlRun
in its @ISA array.

Broadly, the utilities are of seven types.

 1) Class methods
 2) Options handling
 3) Diagnostic message printing
 4) I18N
 5) UI methods
 6) General methods

=head1 1) CLASS METHODS

The class methods provide an object constructor and data accessors.

=over 4

=cut
sub new {

=item new(%params)

Construct a Glade::PerlRun object

e.g. my $Object = Glade::PerlRun->new(%params);

=cut

    my $that  = shift;
    my %params = @_;
    my $class = ref($that) || $that;
    # Call our super-class constructor to get an object and reconsecrate it
    my $self = bless {}, $class;

    $self->merge_into_hash_from($self, \%fields, (__PACKAGE__." defaults"));
    $self->run_options->proto->base_defaults(\%fields);
    $self->merge_into_hash_from($self, \%params, ("$class app defaults"));
    $self->run_options->proto->app_defaults(\%params);

    return $self;
}

sub AUTOLOAD {

=item AUTOLOAD()

Accesses all class data

e.g. my $glade_filename = $Object->glade->file;
 or  $Object->glade->file('path/to/glade/file');

=cut
  my $self = shift;
  my $class = ref($self)
      or die "$self is not an object so we cannot '$AUTOLOAD'\n",
          "We were called from ".join(", ", caller),"\n\n";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;       # strip fully-qualified portion

  if (exists $self->{$permitted_fields}->{$name} ) {
    # This allows dynamic data methods - see %fields above
    # eg $class->UI('new_value');
    # or $current_value = $class->UI;
    if (@_) {
      return $self->{$name} = shift;
    } else {
      return $self->{$name};
    }

  } elsif (exists $stubs{$name} ) {
    # This shows dynamic signal handler stub message_box - see %stubs above
    __PACKAGE__->show_skeleton_message(
      $AUTOLOAD."\n ("._("AUTOLOADED by")." ".__PACKAGE__.")", 
      [$self, @_], 
      __PACKAGE__, 
      'pixmaps/Logo.xpm');
    
  } else {
    die "Can't access method `$name' in class $class\n",
        "We were called from ",join(", ", caller),"\n\n";

  }
}

#===============================================================================
#=========== Options utilities                                      ============
#===============================================================================

=back

=head1 2) OPTIONS HANDLING METHODS

These methods will load, merge, reduce and save a hierarchical options
structure that is stored in one or more XML files and accessed with
AUTOLOAD methods.

=over

=cut

sub options {
    my ($class, %params) = @_;
    my $me = $class."->options";

=item options(%params)

Loads and merges all app options.

e.g. Glade::PerlRun->options(%params);
     my options = $Object->options(%params);

=cut
    my ($self, $global, $type, $key, $defaults, $I18N_name, $log, $report);
    $global     = delete $params{'options_global'}    || "\$Glade_Perl";
    $defaults   = delete $params{'options_defaults'}  || \%Glade::PerlProject::app_fields;
    $type       = delete $params{'options_key'}       || $defaults->{type} || 'glade2perl';
    $I18N_name  = delete $params{'options_I18N_name'} || $type || 'Glade-Perl';
    $report     = delete $params{'options_report'};

    unless (ref $class eq $class) {
        # This is first time through so construct object and load options
        @use_modules = ();
        
        $self = bless __PACKAGE__->new(%$defaults), $class;
#        $self = bless $class->new(%$defaults), $class;

        eval "$global = \$self";

        # Now set element $type to point to our options hash
        $self->{$type} = $self->{run_options};
        push @{$self->{$permitted_fields}{$type}}, $me;

        $self->load_all_options(%params);

        print "PerlRun defaults ", Dumper(\%fields) if $report;
        print "App defaults supplied ", Dumper($defaults) if $report;
        print "App params passed ", Dumper(\%params) if $report;
        eval "print \"\$report Initial state with app defaults and options loaded \", ".
            "Dumper($report),\"\n\n\"" if $report;

        # Merge in all options available
        foreach $key ('site', 'user', 'project', 'params') {
            eval "print \"".$self->{$type}->xml->{$key}.
                " options supplied \", "."Dumper($report),\"\n\n\"" if $report;
            $self->merge_into_hash_from($self, 
                $self->{$type}->proto->{$key},
                $self->{$type}->xml->{$key});
            eval "print \"\$report After \$key options from '".
                $self->{$type}->xml->{$key}."' merged \", ".
                "Dumper($report),\"\n\n\"" if $report;
        }

        $self->{$type}->start_time($class->get_time);
        $self->{$type}->name($class);
        $self->{$type}->version($VERSION);
        $self->{$type}->author($AUTHOR);
        $self->{$type}->date($DATE);


        # Load the diagnostics gettext translations
        $self->load_translations($I18N_name, $self->diag->LANG, undef, 
            undef, '__D', undef);
#        $self->load_translations($I18N_name, $self->diag->LANG, undef, 
#            '/home/dermot/Devel/$I18N_name/ppo/en.mo', '__D', undef);
#        $self->check_gettext_strings("__D");

        if ($type eq 'glade2perl') {
            # Find out what versions of software we have
            unless ($self->{$type}->my_gtk_perl &&
                    ($self->{$type}->my_gtk_perl > $Gtk::VERSION)) {
                $self->{$type}->my_gtk_perl($Gtk::VERSION);
            }
            if ( $self->{$type}->dont_show_UI && !$self->source->write) {
                die "$me - Much as I like an easy life, please alter options ".
                    "to, at least, show_UI or write_source\n    Run abandoned";
            }
            $indent = $self->source->indent; 
            $tab = (' ' x $self->source->tabwidth);
            $self->source->tab($tab);
        }

        if ($self->diag->wrap_at == 0) {
            $columns = 1500;
        } else {
            $columns = $self->diag->wrap_at;
        }

    } else {
        $self = $class;
        $self->{$type}->xml->params(
            $params{$type}{'xml'}{'set_by'} ||
            $params{'options_set'} || 
            $self->{$type}->xml->set_by ||
            $me);
        $self->{$type}->proto->params($self->convert_old_options(\%params));
        $self->merge_into_hash_from($self, 
            $self->{$type}->proto->params,
            $self->{$type}->xml->params);
    }

    $self->diag_print (4, $self->{$type}->proto->params);
    $self->diag_print (5, $self->{$type}->xml);
    $self->diag_print (6, $self->{$type});
    $self->diag_print (7, $self);
    
    $self->{$type}->xml->set_by (
        $self->{$type}->proto->params->{$type}{xml}{set_by} || $me);

    return $self;
}

sub load_all_options {
    my ($class, %params) = @_;
    my $me = (ref $class || $class)."->load_all_options";

#print Dumper(\@_);
    my $type = $class->{type} || $params{type};
    $class->{$type}->xml->encoding(
        $params{$type}{xml}{encoding} ||
        $params{$type."_encoding"} ||
        $params{glade}{encoding} ||
        $params{glade_encoding} ||
        'ISO-8859-1'
        );

    # PARAMS supplied
    $class->{$type}->xml->params(
        $params{$type}{'xml'}{'set_by'} ||
        $params{'foptions_set'} || 
        $class->{$type}->xml->set_by ||
        $me);
    $class->{$type}->proto->params(
        $class->convert_old_options(\%params));

    # USER options file
    $class->{$type}->xml->user(
        $class->{$type}->proto->params->{$type}{xml}{user} ||
        "$ENV{'HOME'}/.$type.xml");

    $class->{$type}->get_options('user');
    $class->{$type}->proto->user(
        $class->convert_old_options($class->{$type}->proto->user, 
            $class->{$type}->xml->user));

    # PROJECT options file (from user mru if not specified in params)
    my $base = $class->{$type}->proto->user->{$type}{mru} || '';
    $base =~ s/(.+)\..*$/$1/;
    $base =~ s/(.+)\..*$/$1/;
    $base .= ".$type.xml";
    $class->{$type}->xml->project(
        $class->{$type}->xml->project ||
        $class->{$type}->proto->params->{$type}{xml}{project} ||
        $base
    );
    unless ($class->{$type}->xml->project eq $NOFILE) {
        $class->{$type}->xml->project(
            $class->full_Path($class->{$type}->xml->project, `pwd`));
    }

    $class->{$type}->get_options('project');
    $class->{$type}->proto->project(
        $class->convert_old_options($class->{$type}->proto->project, $me));
    
    # SITE options file
    $class->{$type}->xml->site(
        $class->{$type}->proto->params->{$type}{xml}{site} ||
        $class->{$type}->proto->project->{$type}{xml}{site} ||
        $class->{$type}->proto->user->{$type}{xml}{site} ||
        "/etc/$type.xml");

    $class->{$type}->get_options('site');
    $class->{$type}->proto->site(
        $class->convert_old_options($class->{$type}->proto->site, 
            $class->{$type}->xml->site));

    $class->diag_print (5, $class) if ref $class;
    return $class->{$type};
}

sub get_options {
    my ($class, $type, $file) = @_;

    my $pwd = `pwd`;
    my ($encoding);
    $file ||= $class->xml->{$type} || $NOFILE;

    if ($file eq $NOFILE) {
#        $class->diag_print (4, "Not reading %s options from file", $type);
        $class->xml->{$type} = $file;
        $class->proto->{$type} = {};
        return;
    }
    if ($file && -r $file) {
#        $class->xml->{$type} = $class->full_Path($file, $pwd);
#        print sprintf("Reading %s options from file %s\n", $type, $class->xml->{$type});
        ($encoding, $class->proto->{$type}) = $class->simple_Proto_from_File(
#        ($encoding, $class->proto->{$type}) = Glade::PerlXML->Proto_from_File(
            $class->xml->{$type}, 
            '', $option_hashes, 
            $class->xml->encoding);
        $class->xml->encoding($encoding);

    } else {
#        print "File '$file' could NOT be read\n";
        $class->proto->{$type} = {};
    }
}

sub simple_Proto_from_File {
    my ($class, $filename, $repeated, $special, $encoding) = @_;
    my $me = __PACKAGE__."->new_Proto_from_File";

    my $pos = -1;
    my $xml = $class->string_from_File($filename);
    return $class->simple_Proto_from_XML(\$xml, 0, \$pos, $repeated, $special, $encoding);
}

sub simple_Proto_from_XML {
    my ($class, $xml, $depth, $pos, $repeated, $special, $encoding) = @_;
    my $me = __PACKAGE__."->simple_Proto_from_XML";

    # Loads hash from XML string using regexps (not XML::Parser).
    my ($self, $tag, $use_tag, $prev_contents, $work);
    my ($found_encoding, $new_pos);
    while (($new_pos = index($$xml, "<", $$pos)) > -1) {
        $prev_contents = substr($$xml, $$pos, $new_pos-$$pos);
        $$pos = $new_pos;
        $new_pos = index($$xml, ">", $$pos);
        $tag = substr($$xml, $$pos+1, $new_pos-$$pos-1);
        $$pos = $new_pos+1;
        if ($tag =~ /^\?/) {
#print "$depth - We are working on tag '$tag'\n";
            if ($tag =~ s/\?xml.*\s*encoding\=["'](.*?)['"]\?\n*//) {
                $found_encoding = $1;
            } else {
                $found_encoding = $encoding;
            }
            next;
        }
        if ($tag =~ s|^/||) {
            # We are an endtag so return the $prev_contents
            if  (ref $self) {
                return $self;

            } else {
                return &UnQuoteXMLChars($prev_contents);
            }

        } else {
            # We are a starttag so recurse
            if ($tag =~ s|/$||) {
                # We are also an endtag (empty eg. <tagname /> so ignore
#print "Found empty tag <$tag />\n";
            } else {
                $work = $class->simple_Proto_from_XML(
                    $xml, $depth + 1, $pos, $repeated);
                if (" $repeated " =~ / $tag /) {
                    # Store as a numbered key
                    $use_tag = "~$tag-".sprintf(&keyFormat, $seq++);
                    $self->{$use_tag}{&typeKey} = $tag ;
                } else {
                    # Store as key
                    $use_tag = $tag;
                }
                $self->{$use_tag} = $work;
            }
        }
    }
#print "Encoding '$found_encoding'\n", Dumper($self);
    return ($found_encoding, values %$self);
}

sub typeKey     { return ' type'; }
#sub keyFormat  { if (shift) {return '%04u-%s' } else {return '%04u' } }
sub keyFormat   { return '%04u' } 

sub QuoteXMLChars {
    my $text = shift;
    # Suggested by Eric Bohlman <ebohlman@netcom.com> on perl-xml mailling list
    my %ents=('&'=>'amp','<'=>'lt','>'=>'gt',"'"=>'apos','"'=>'quot');
    $text =~ s/([&<>'"])/&$ents{$1};/g;
    # Uncomment the line below if you don't want to use European characters in 
    # your project options
#    $text =~ s/([\x80-\xFF])/&XmlUtf8Encode(ord($1))/ge;
    return $text;
}

sub UnQuoteXMLChars {
    my $text = shift;
    my %ents=('&lt;'=>'<','&gt;'=>'>','&apos;'=>"'",'&quot;'=>'"', '&amp;'=>'&');
    $text =~ s/(&lt;|&gt;|&apos;|&quot;|&amp;)/$ents{$1}/g;
    return $text;
}

sub XmlUtf8Encode {
    # This was ripped from XML::DOM - thanks to
    # Enno Derksen (official maintainer), enno@att.com
    # and Clark Cooper, coopercl@sch.ge.com
    my $n = shift;
    my $me = "XmlUtf8Encode";
    if ($n < 0x80)    { 
        return chr ($n);

    } elsif ($n < 0x800) {
        return pack ("CC", (($n >> 6) | 0xc0), 
                    (($n & 0x3f) | 0x80));

    } elsif ($n < 0x10000) {
        return pack ("CCC", (($n >> 12) | 0xe0), 
                    ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));

    } elsif ($n < 0x110000) {
        return pack ("CCCC", (($n >> 18) | 0xf0), 
                    ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), 
                      (($n & 0x3f) | 0x80));
    }
    __PACKAGE__->diag_print(1, 
        "error Number is too large for Unicode [%s] in %s ", $n, $me);
    return "#";
}

sub convert_old_options {
    my ($class, $old, $file) = @_;
    my $me = __PACKAGE__."->convert_old_options";
    my $new = {};

    my $key;
    my $converted = 0;
    for $key (keys %$old) {
        # Normalise any True/False values to 1/0
        $old->{$key} = $class->normalise($old->{$key});
        if ($convert->{$key}) {
#            print "Converting '$key' = '$old->{$key}'\n";
            eval $convert->{$key};
            die @! if @!;
            $converted++;
        } elsif (ref $old->{$key}) {
#            print "Merging '$key' = '$old->{$key}'\n";
            $new->{$key} = $class->merge_into_hash_from(
                $new->{$key}, $old->{$key}, $file);
        } else {
#            print "Copying '$key' = '$old->{$key}'\n";
            $new->{$key} = $old->{$key};
        }
    }

#print "OLD - ", Dumper($old);
#print "NEW - ", Dumper($new);
    if ($file and $converted and $class->diagnostics(2)) {
        if (-w $file) {
            # We can rewrite the options file
            print sprintf("$me has converted options in file %s\n",
                 $file);
            $class->write_options($new, $file);
        } else {
            print "$me cannot rewrite file '$file'\n".
                sprintf(
                "You may want to edit '$file' yourself to read: \n%s\n",
                $class->XML_from_Proto('', '  ', 'G2P-Options', $new));
        }
    }
    return $new;
}

sub normalise {
    my ($class, $value) = @_;

=item normalise($value)

Return a normalised value ie. convert 'True'|'Yes'|'y'|'On' to 1
and 'False'|'No'|'n'|'Off' to 0. 
The comparisons are case-insensitive.

e.g. my $normalised_value = Glade::PerlRun->normalise('True');

=cut
    if (defined $value) {
        if ($value =~ /^(true|y|yes|on)$/i) {
            return 1;
        } elsif ($value =~ /^(false|n|no|off)$/i) {
            return 0;
        } else {
            return $value;
        }
    }
}

sub merge_into_hash_from {
    my ($class, $to_hash, $from_hash, $autoload) = @_;
    my $me = $class."->merge_into_hash_from";

=item merge_into_hash_from($to_hash, $from_hash, $autoload)

Recursively merge a hash into an existing one - overwriting any keys with 
a defined value. It will also optionally set accessors for the keys to be
used via AUTOLOAD().

e.g. $new_hash_ref = Glade::PerlRun->merge_into_hash_from(
         $to_hash_ref,      # Hash to be updated
         $from_hash_ref,    # Input data to be merged
         'set accessors');  # Any value will add AUTOLOAD() accessors
                            # for these keys.

=cut
    my ($key, $value);
    $autoload ||= '';
    foreach $key (keys %$from_hash) {
        next if $key eq $permitted_fields;
        if (ref $from_hash->{$key} eq 'HASH') {
#            print "    Merging HASH '$key' in $autoload\n";
            $to_hash->{$key} ||= bless {}, ref $to_hash;
            $class->merge_into_hash_from(
                $to_hash->{$key},
                $from_hash->{$key},
                $autoload);

        } else {
            # Check that we are not overwriting a hash with a scalar
            unless (ref $to_hash->{$key}) {
                $to_hash->{$key} = $class->normalise($from_hash->{$key});
            }
        }
#        push @{$to_hash->{$permitted_fields}{$key}}, $autoload if $autoload;
        $to_hash->{$permitted_fields}{$key}++ if $autoload;
    }
    return $to_hash;
}

sub save_app_options {
    my ($class, $mru, %defaults) = @_;
    my $me = $class."->save_app_options";

=item save_app_options($mru, %defaults)

Updates mru and saves all app/user options. This will save the mru file
in the user options file (if one is named in 
$class->{$class->type}->xml->user).

e.g. Glade::PerlRun->save_app_options($mru_filename);

=cut
    %defaults = %{$class->{$class->type}->proto->app_defaults} 
        unless keys %defaults;
    
    # Store new mru file name and start_time
    $class->{$class->type}->proto->user->{$class->type}{mru} = $mru;
    $class->{$class->type}->proto->user->{$class->type}{start_time} = 
        ($class->{$class->type}->start_time);
    undef $class->{$class->type}{mru};

    # Save project options
    $class->diag_print(6, $class, "Options to be saved");
    $class->save_options(
        undef, 
        %Glade::PerlRun::fields, 
        %defaults
    );

    if ($class->{$class->type}->xml->user) {
        # Save new user options
        $class->write_options(
            $class->reduce_hash(
                $class->{$class->type}->proto->user,
                {},
                {},
                {},
                {},
                $class->{$class->type}->prune
                ), 
            $class->{$class->type}->xml->user);
    }
}

sub save_options {
    my ($class, $filename, %app_defaults) = @_;
    my $me = __PACKAGE__."->save_options";

=item save_options($filename, %app_defaults)

Reduce and save the supplied options to the file specified.

e.g. $Object->save_options;

=cut
    my $type = $class->type;
    %app_defaults = %{$class->{$class->type}->proto->app_defaults}
        unless keys %app_defaults;
    
    if ($filename) {
        $class->{$type}->xml->{project} = ($filename);
    } else {
        $filename = $class->{$type}->xml->{project};
    }

    if ($filename eq $NOFILE) {
        $class->diag_print(2, "%s- Not saving %s project options", 
            $indent, $type);
        return;
    }
    $class->diag_print(4, $class, "Project options");

    my $options = $class->reduce_hash(
        $class,
        $class->{$type}->proto->user,
        $class->{$type}->proto->site,
        \%app_defaults,
        \%__PACKAGE__::fields,
        $class->{$type}->prune,
    );

    if (ref $options) {
        bless $options, ref $class;
        $options->{'type'} = $type;
        $options->{$type}{start_time} = ($class->{$type}->start_time);
        $class->write_options($options, $filename);
    } else {
        $class->diag_print(2, "%s- No project options need saving", 
            $indent);
    }
}

sub write_options {
    my ($class, $options, $filename) = @_;
    my $me = __PACKAGE__."->write_options";

=item write_options($options, $filename)

Write an options hash to XML file.

e.g. my options = $Object->write_options($hash_ref, '/path/to/file');

=cut
    my $type = $class->type;
    my $xml;

    if ($class->{$type}->xml->encoding) {
        $xml = "<?xml version=\"1.0\" encoding=\"".
            $class->{$type}->xml->encoding."\"?>\n";
    } else {
        $xml = "<?xml version=\"1.0\"?>\n";
    }
    $xml .= $class->XML_from_Proto('', '  ', "$type-Options", $options);
    
    if ($filename eq $NOFILE) {
        $class->diag_print(2, "%s- Not saving %s options", $indent, $type);
        $class->diag_print(2, "%s", "$indent- XML would have been\n'$xml'\n"); 
        return;
    }
    $class->diag_print(5, $xml, 'DONT_TRANSLATE');

    $class->save_file_from_string($filename, $xml);

    $class->diag_print(2, "%s- %s options saved to %s", 
        $class->diag->indent, $type, $filename);
}

sub reduce_hash {
    my ($class, 
        $all_options, $user_options, $site_options, 
        $app_defaults, $base_defaults,
        $prune, $hashtypes) = @_;
    my $me = __PACKAGE__."->reduce_hash";

=item reduce_hash($all_options, $user_options, $site_options, 
$app_defaults, $base_defaults, $prune, $hashtypes)

Removes any options that are equivalent to site/user/project options
or that are specified to be pruned. We will descend into any hash types
specified.

e.g. my options = $Object->reduce_hash(
    $options_to_reduce, 
    $user_options, 
    $site_options, 
    $app_defaults,
    $base_defaults
    '*work*proto*', 
    '*My::Class*');

=cut
    my ($key, $default, $from, $return, $reftype);
    my $verbose = 5;
    $user_options  ||= {};
    $site_options  ||= {};
    $app_defaults  ||= {};
    $base_defaults ||= {};
    $prune ||= "*".
        join("*", 
            $permitted_fields, 
            &typeKey, 
            'run_options', 
            'PARTYPE',
            'module', 
            'tab', 
            'proto',
            'gtk_style', 
            'generate',
            ).
        "*";
    $hashtypes ||= "*".join("*",
        (ref $class || $class), 
        'Glade::PerlGenerate', 
        'Glade::PerlProject',
        'Glade::PerlRun',
    )."*";

    $class->diag_print($verbose, "Prune     is '$prune'");
    $class->diag_print($verbose, "Hashtypes is '$hashtypes'");
    foreach $key (keys %{$all_options}) {
        $reftype = ref $all_options->{$key};
        $class->diag_print($verbose+1, "%s- Reducing %s object '%s'",
            $class->diag->indent, $reftype, $key) if $reftype;
        if ($reftype and "*ARRAY*" =~ /\*$reftype\*/) {
            $class->diag_print($verbose, "--------------------------------");
            $all_options->{$key} = join("\n", @{$all_options->{$key}});
            $class->diag_print($verbose, 
                "%s- Joining '%s' object {'%s'} into newline-separated string '%s'", 
                $class->diag->indent, $reftype, $key, $all_options->{$key});
        }            
        if (!defined $all_options->{$key}) {
            $class->diag_print ($verbose, 
                "%s- Removing option '%s' (%s)", 
                $class->diag->indent, $key, 'no value defined');

        } elsif ($prune =~ /\*$key\*/) {
            # Ignore the specified keys
            $class->diag_print ($verbose, 
                "%s- Removing option '%s' (%s)", 
                $class->diag->indent, $key, 'pruned');

        } elsif ($reftype and "*HASH*$hashtypes*" =~ /\*$reftype\*/) {
            $class->diag_print($verbose, "--------------------------------");
            $class->diag_print($verbose, "%s- Descending into '%s' object {'%s'}", 
                $class->diag->indent, $reftype, $key);
            $class->diag_print($verbose+1, $all_options->{$key}, 
                $class->diag->indent."- {'$key'} which is a ");
            $class->diag_print($verbose+1, $all_options->{$key}, 
                "Project option element {'$key'}");
            $class->diag_print($verbose+1, $user_options->{$key}, 
                "User options element {'$key'}") if $user_options->{$key};
            $class->diag_print($verbose+1, $site_options->{$key}, 
                "Site options element {'$key'}") if $site_options->{$key};
            $class->diag_print($verbose+1, $app_defaults->{$key}, 
                "App defaults element {'$key'}") if $app_defaults->{$key};
            $class->diag_print($verbose+1, $base_defaults->{$key}, 
                __PACKAGE__." defaults element {'$key'}") if $base_defaults->{$key};
            $return->{$key} = $class->reduce_hash(
                $all_options->{$key},
                $user_options->{$key}, 
                $site_options->{$key}, 
                $app_defaults->{$key}, 
                $base_defaults->{$key}, 
                $prune, $hashtypes);
            unless (keys %{$return->{$key}}) {
                delete $return->{$key};
                $class->diag_print($verbose, "%s- Losing empty hash {'%s'}",
                    $class->diag->indent, $key);
            } else {
                $class->diag_print($verbose, $return->{$key}, 
                    "$me reduced {'$key'} so that");
            }

        } else {
            if (defined $user_options->{$key}) {
                $default = $user_options->{$key};
                $from = "user options file";

            } elsif (defined $site_options->{$key}) {
                $default = $site_options->{$key};
                $from = "site options file";

            } elsif (defined $app_defaults->{$key}) {
                $default = $app_defaults->{$key};
                $from = (ref $all_options)." app defaults";

            } elsif (defined $base_defaults->{$key}) {
                $default = $base_defaults->{$key};
                $from = __PACKAGE__." defaults";

            } else {
                $default = '__NO_DEFAULT_OPTION_AVAILABLE__';
                $from = "no default";
            }
            if ($all_options->{$key} eq $class->normalise($default)) {
                $class->diag_print ($verbose, 
                    "%s- Removing {'%s'} => '$all_options->{$key}' (equals default in %s)", 
                    $class->diag->indent, $key, $from);
            } elsif (!$all_options->{$key} and $default eq '__NO_DEFAULT_OPTION_AVAILABLE__') {
                $class->diag_print ($verbose, 
                    "%s- Removing option '%s' (no default and no value)", 
                    $class->diag->indent, $key, $from);
            } else {
                $return->{$key} = $all_options->{$key};
#                $class->diag_print ($verbose, 
#                    "%s- saving option '%s'", 
#                    $class->diag->{'indent'}, $key);
            }
        }
    }
    return $return;
}

sub XML_from_Proto {
    # usage my $xmlstring = 
    #   XML::UTIL->XML_from_Proto($prefix, '  ', $tag, $protohashref);
    # This proc will compose XML from a proto hash in 
    #   Proto_from_XML's return format
    my ($class, $prefix, $tab, $tag, $proto) = @_;
	my $me = "$class->XML_from_Proto";
	my ($key, $val, $xml, $limit);
	my $typekey = &typeKey;
    my $prune = "*$typekey*$permitted_fields*";
	my $contents = '';
	my $newprefix = "$tab$prefix";

	# make up the start tag 
	foreach $key (sort keys %$proto) {
#		unless ($key eq $typekey or $key eq $permitted_fields) {
		unless ($prune =~ /\*$key\*/) {
			if (ref $proto->{$key} eq 'ARRAY') {
                print "error- Key '$key' is an ARRAY !!! and has been ignored\n";
                next;
			} elsif (ref $proto->{$key}) {
				# call ourself to expand nested xml
				$contents .= "\n".
                    $class->XML_from_Proto(
                        $newprefix, $tab, 
                        ($proto->{$key}{$typekey} || $key), 
                        $proto->{$key}, $prune).
                    "\n";
			} else {
				# this is a vanilla string so trim and add to output
				if (defined $proto->{$key}) {
                    $contents .= "\n$newprefix<$key>".
                        &QuoteXMLChars($proto->{$key})."</$key>";
				} else {
					$contents .= "\n$newprefix<$key></$key>";
#					$contents .= "\n$newprefix<$key />";
				}
			}
		}
	}

	# make up the string to return
	if ($contents eq '') {
		if ($tag ne '') {
			$xml .= "\n$prefix<$tag />";
		}
	} else {
		if ($tag ne '') {
			$xml .= "$prefix<$tag>$contents\n$prefix</$tag>";
		} else {
			$xml .= "\n$contents\n";
		}
	}
	return $xml
}
	
sub save_file_from_string {
    my ($class, $filename, $string) = @_;
    my $me = __PACKAGE__."->save_file_from_string";

=item save_file_from_string($filename, $string)

Write a string to a file.

e.g. Glade::PerlRun->save_file_from_string('/path/to/file', $string);

=cut
    $class->diag_print(5, $string, 'DONT_TRANSLATE');

    open OUTPUT, ">".($filename) or 
        die sprintf("error %s - can't open file '%s' for output", 
            $me, $filename);
    print OUTPUT $string;
    close OUTPUT or
        die sprintf("error %s - can't close file '%s'", 
            $me, $filename);
    $class->diag_print(3, "%s- %s string saved to %s", 
        $class->diag->indent, $me, $filename);
}

#===============================================================================
#=========== Diagnostics utilities                                  ============
#===============================================================================


=back

=head1 3) DIAGNOSTIC MESSAGE METHODS

These methods will start logging diagnostic messages, produce standardised 
I18N messages and then stop logging and close any open files.

=over

=cut

sub verbosity            { shift->diag->verbose }
sub Writing_to_File      { shift->source->write }
sub Building_UI_only     {!defined shift->source->write }

sub diagnostics { 
    ($_[1] || 1) <= (shift->diag->verbose);
}

sub diag_print {
    my $class = shift;
    my $level = shift;
    my $message = shift;

=item diag_print()

Prints diagnostics message (I18N translated) if verbosity is >= level specified

e.g. $Object->diag_print(2, "This is a diagnostics message");
     $Object->diag_print(2, $hashref, "Prefix to message");

=cut
    return unless $class->diagnostics($level);
    my $time='';
    if ($class->diag->benchmark) {
        my @times = times;
        $time = int( $times[0] + $times[1] );
    }
    unless (ref $message) {
        # Make up message from all remaining args
        $message = sprintf(D_($message, 2), @_) unless 
            $_[0] && $_[0] eq 'DONT_TRANSLATE';
        print STDOUT wrap($time, 
            $class->diag->indent.$class->diag->indent, "$message\n");

    } else {
        my $prefix = shift || '';
        print $class->diag->indent."- $prefix ", Dumper($message);
#        $class->diag_ref_print($level, $message, @_);
    }
}

sub diag_ref_print {
    my ($class, $level, $message, $desc, $pad) = @_;

    return unless $class->diagnostics($level);
    my ($key, $val, $ref);
    my $padkey = $pad || 17;
    my $title = D_($desc || "");
    my @times = times;
    my $time='';
    $ref = ref $message;
    if ($class->diag->benchmark) {
        $time = int( $times[0] + $times[1] );
    }
    unless ($ref) {
         print STDOUT wrap($time, 
            $time.$class->diag->indent.$class->diag->indent, "$message\n");

    } elsif (($ref eq 'HASH') or ( $ref =~ /Glade::/)) {
        print STDOUT "$title $ref ",D_("contains"), ":\n";
        foreach $key (sort keys %$message) {
            my $ref = ref $message->{$key};
            if (ref $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => '$message->{$key}'\n";
            } else {
                print STDOUT "        {'$key'}\n";
            }
            $val = (ref ) || $message->{$key} || 'undef';
        }

    } elsif ($ref eq 'ARRAY') {
        print STDOUT "$title $ref ", D_("contains"), ":\n";
		my $im_count = 0;
	    foreach $val (@$message) {
			$key = sprintf "[%d]", $im_count;
			$ref = ref $val;
            if ($ref) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->[$im_count]) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = '$message->[$im_count]'\n";
            } else {
                print STDOUT "        $key\n";
            }
			$im_count++;
	   	}

    } else {
        # Unknown ref type
        print STDOUT wrap($time, $time.$class->diag->indent.$class->diag->indent, 
            D_("Unknown reference type"), " '$ref'\n");
    }
}

sub start_log {
    my ($class, $filename) = @_;
    my $me = (ref $class || $class)."->start_log";

=item start_log()

Opens the log files and starts writing diagnostics

e.g. $Object->start_log('log_filename');

=cut
    my $type = $class->type;
    # Check for log file names
    $filename ||=
        $class->diag->log ||
        $class->{$type}->proto->{params}{$type}{diag}{log} ||
        $class->{$type}->proto->{project}{$type}{diag}{log} ||
        $class->{$type}->proto->{user}{$type}{diag}{log} ||
        $class->{$type}->proto->{site}{$type}{diag}{log} ||
        "STDOUT";
    $filename = $class->normalise($filename);

    if ($class->diag->autoflush) {
        select STDOUT; 
        $|=1;
        }
    if ('*STDOUT*1*' =~ /\*$filename\*/) {
        $filename = '&STDOUT';
    } else {
        $class->diag->log($filename);
    }
    if ($class->diag->verbose == 0 ) { 
        $class->diag_print (2, "Redirecting output to /dev/null");
        open STDOUT, ">/dev/null"; 

    } elsif ($class->diag->log) {
        unless ('*&STDOUT*STDOUT*1*' =~ /\*$filename\*/) {
            # Set full paths
            $class->diag->log($class->full_Path($class->diag->log, `pwd`));
            $class->diag_print (3, "%s- Opening log file '%s'", 
                $class->diag->indent, $class->diag->log);
            open STDOUT, ">".$class->diag->log or
                die sprintf("error %s - can't open file '%s' for output", 
                    $me, $class->diag->log);
        }
        open STDERR, ">&1" or
            die sprintf("error %s - can't redirect STDERR to file '%s'",
                $me, $class->diag->log);
    }
    $class->diag_print (2, 
        "--------------------------------------------------------");
    $class->diag_print (2, 
        "%s  DIAGNOSTICS - %s (locale <%s> verbosity %s) ".
        "started by %s (version %s)", 
        $class->diag->indent, $class->{$type}->start_time,
        $class->diag->LANG, $class->diag->verbose, 
        $class->{$type}->name, $class->{$type}->version, 
    );
}

sub stop_log {
    my ($class, $type) = @_;
    my $me = (ref $class || $class)."->stop_log";

=item stop_log()

Loads site/user/project/params options

e.g. $Object->stop_log;

=cut
    $type ||= $class->type;
    if ($class->diag->log and $class->diagnostics(2)) {
        $class->diag_print (2, 
            "%s  RUN COMPLETED - %s diagnostics stopped by %s (version %s)",
            $class->diag->indent, $class->get_time, 
            $class->{$type}->name, $class->{$type}->version);
        $class->diag_print (2, 
            "-----------------------------------------------------------------------------");
        close(STDERR) || die "can't close stderr: $!"; 
        close(STDOUT) || die "can't close stdout: $!" ;
    }
}

#===============================================================================
#=========== Gettext Utilities                                              ====
#=========== 'borrowed' from the gettext dist and recoded to house style    ====
#===============================================================================

=back

=head1 4) INTERNATIONALISATION (I18N) METHODS

These methods will load translations, translate messages, check for any
missing translations and write a .pot file containing these missing messages.

=over

=cut

=item _()

Translate a string into our current language

e.g. sprintf(_("A message '%s'"), $value);

=cut
sub _ {gettext(@_)}

=item gettext()

Translate into a preloaded language (eg '__S' or '__D')

e.g. C<sprintf(gettext('__S', "A message '%s'"), $value);>

=cut
sub gettext {
    defined $I18N->{'__'}{$_[0]} ? $I18N->{'__'}{$_[0]} : $_[0];
}

#===============================================================================
#=========== Gettext Utilities                                              ====
#===============================================================================
# These are defined within a no-warning block to avoid warnings about redefining
# They override the subs in Glade::PerlRun during your development
{   
    local $^W = 0;
    eval "sub x_ {_check_gettext('__', \@_);}";
}

# Translate string into source language
sub S_ { _check_gettext('__S', @_)}

# Translate string into diagnostics language
sub D_ { _check_gettext('__D', @_)}

# Internal utility to note any untranslated strings
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

sub start_checking_gettext_strings {
    my ($class, $key, $file) = @_;

=item start_checking_gettext_strings()

Start checking and storing missing translations in language type

  eg. $class->start_checking_gettext_strings("__S");


=cut
    $I18N->{($key || '__')}{'__SAVE_MISSING'} = ($file || "&STDOUT");
}

sub stop_checking_gettext_strings {
    my ($class, $key) = @_;

=item stop_checking_gettext_strings()

Stop checking for missing translations in language type

  eg. $class->stop_checking_gettext_strings("__S");

=cut
    undef $I18N->{($key || '__')}{'__SAVE_MISSING'};
}

sub write_missing_gettext_strings {
    # Write out the strings that need to be translated in .pot format
    my ($class, $key, $file, $no_header, $copy_to) = @_;

=item write_missing_gettext_strings()

Write a .pot file containing any untranslated strings in language type

  eg. $object->write_missing_gettext_strings('__S');

=cut
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
\"Project-Id-Version:  ".$class->PACKAGE." ".$class->VERSION."\\n\"
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

sub load_translations {
    my ($class, $domain, $language, $locale_dir, $file, $key, $merge) = @_;

=item load_translations()

Load a translation file (.mo) for later use as language type

  e.g. To load translations in current LANG from default locations
        $class->load_translations('MyApp');
  
  OR    $class->load_translations('MyApp', 'pt_BR', undef, 
            '/home/dermot/Devel/Glade-Perl/ppo/en.mo');

  OR    $class->load_translations('MyApp', 'fr', '/usr/local/share/locale/',
           undef, '__D', 'Merge with already loaded translations');

=cut
    my $catalog_filename = $file;
    $key ||= '__';
    $I18N->{$key} = {} unless $merge and $merge eq "MERGE";;

    $language ||= $ENV{"LANG"};
    return unless $language;
    $locale_dir ||= "/usr/local/share/locale";
    $domain     ||= "Glade-Perl";
#print "Checking for I18N .mo file '$catalog_filename'\n";
    for $catalog_filename ( $file || 
        ("/usr/local/share/locale/$language/LC_MESSAGES/$domain.mo",
        "/usr/share/locale/$language/LC_MESSAGES/$domain.mo")) {
#print "Checking for I18N .mo file '$catalog_filename'\n";
        if ($catalog_filename and (-f $catalog_filename)) {
#print "Loading I18N .mo file '$catalog_filename'\n";
            $class->load_mo($catalog_filename, $key);
            last;
        }
    }
}

sub load_mo {
    my ($class, $catalog, $key) = @_;

    my ($reverse, $buffer);
    my ($magic, $revision, $nstrings);
    my ($orig_tab_offset, $orig_length, $orig_pointer);
    my ($trans_length, $trans_pointer, $trans_tab_offset);

    # Slurp in the catalog
    my $save = $/;
    open CATALOG, $catalog or return;
    undef $/; 
    $buffer = <CATALOG>; 
    close CATALOG;
    $/ = $save;
    
    # Check magic order
    $magic = unpack ("I", $buffer);
    if (sprintf ("%x", $magic) eq "de120495") {
    	$reverse = 1;

    } elsif (sprintf ("%x", $magic) ne "950412de") {
    	print STDERR "'$catalog' "._("is not a catalog file")."\n";
        return;
    }

    $revision = &mo_format_value (4, $reverse, $buffer);
    $nstrings = &mo_format_value (8, $reverse, $buffer);
    $orig_tab_offset = &mo_format_value (12, $reverse, $buffer);
    $trans_tab_offset = &mo_format_value (16, $reverse, $buffer);

    while ($nstrings-- > 0) {
	    $orig_length = &mo_format_value ($orig_tab_offset, $reverse, $buffer);
	    $orig_pointer = &mo_format_value ($orig_tab_offset + 4, $reverse, $buffer);
	    $orig_tab_offset += 8;

	    $trans_length = &mo_format_value ($trans_tab_offset, $reverse, $buffer);
	    $trans_pointer = &mo_format_value ($trans_tab_offset + 4,$reverse, $buffer);
	    $trans_tab_offset += 8;

    	$I18N->{$key}{substr ($buffer, $orig_pointer, $orig_length)}
	        = substr ($buffer, $trans_pointer, $trans_length);
    }

    # Allow for translation of really empty strings
    $I18N->{$key}{'__MO_HEADER_INFO'} = $I18N->{$key}{''};
    $I18N->{$key}{''} = '';
}

sub mo_format_value {
    my ($string, $reverse, $buffer) = @_;

    unpack ("i",
	    $reverse
	    ? pack ("c4", reverse unpack ("c4", substr ($buffer, $string, 4)))
	    : substr ($buffer, $string, 4));
}

#===============================================================================
#=========== Widget hierarchy Utilities                                     ====
#===============================================================================
sub WH {
    my ($class, $new) = @_; 
    if ($new) {
        return $class->{'__WH'} = $new;
    } else {
      return $class->{'__WH'};
    }
}

sub CH {
    my ($class, $new) = @_;
    if ($new) {
      return $class->{'__CH'} = $new;
    } else {
      return $class->{'__CH'};
    }
}

sub W {
    my ($class, $proto, $new) = @_;
    if ($new) {
      return $proto->{'__W'} = $new;
    } else {
      return $proto->{'__W'};
    }
}

sub C {
    my ($class, $proto, @new) = @_;
    if ($#new) {
      return push @{$proto->{'__C'}}, @new;
    } else {
      return $proto->{'__C'};
    }
}

#===============================================================================
#=========== UI utilities
#===============================================================================

=back

=head1 5) UI METHODS

These methods will provide some useful UI methods to load pixmaps and 
images and show message boxes of various types.

=over

=cut

sub create_pixmap {
    my ($class, $widget, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_pixmap";

=item create_pixmap()

Create a gdk_pixmap and return it

e.g. my $pixmap = Glade::PerlRun->create_pixmap(
    $form, 'new.xpm', ['dir1', 'dir2']);

=cut
    my ($work, $gdk_pixmap, $gdk_mask, $testfile, $found_filename, $dir);
    # First look in specified $pixmap_dirs
    if (-f $filename) {
        $found_filename = $testfile;

    } else {
        foreach $dir (@{$pixmap_dirs}, $Glade::PerlRun::pixmaps_directory, cwd) {
            # Make up full path name and test
            $testfile = $class->full_Path($filename, $dir);
        	if (-f $testfile) {
                $found_filename = $testfile;
                last;
        	}
        }
    }
    unless ($found_filename) {
    	if (-f $filename) {
#            print STDERR "Pixmap file '$testfile' exists in $me\n";
            $found_filename = $filename;
    	} else {
            print STDERR sprintf(_(
                "error Pixmap file '%s' does not exist in %s\n"),
                $filename, $me);
            return undef;
    	}
    }
    if (Gtk::Gdk::Pixmap->can('colormap_create_from_xpm')) {
        # We have Gtk-Perl after CVS 19990911 so we don't need a realized window
        my $colormap = $widget->get_colormap;
        return new Gtk::Pixmap(
            Gtk::Gdk::Pixmap->colormap_create_from_xpm (
                undef, $colormap, undef, $found_filename));

    } else {
        # We have an old Gtk-Perl so we need a realized window
        $work->{'window'} 	    = $widget->get_toplevel->window	 ;
        $work->{'style'} = Gtk::Widget->get_default_style->bg('normal')	 ;
        unless ($work->{'window'}) {
    	    print STDOUT sprintf(_(
                "error Couldn't get_toplevel_window to construct pixmap from '%s' in %s\n"),
                $filename, $me);
        	$work->{'window'} = $widget->window	 ;
        }
        return new Gtk::Pixmap(
            Gtk::Gdk::Pixmap->create_from_xpm(
                $work->{'window'}, $work->{'style'}, $found_filename ) );
    }
}

sub create_image {
    my ($class, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_image";

=item create_image()

Create and load a gdk_imlibimage and return it

e.g. my $image = Glade::PerlRun->create_image(
    'new.xpm', ['dir1', 'dir2']);

=cut
    my ($work, $testfile, $found_filename, $dir);
    if (-f $filename) {
        $found_filename = $testfile;

    } else {
        foreach $dir (@{$pixmap_dirs}, $Glade::PerlRun::pixmaps_directory, cwd) {
            # Make up full path name and test
            $testfile = $class->full_Path($filename, $dir);
        	if (-f $testfile) {
                $found_filename = $testfile;
                last;
        	}
        }
    }
    unless ($found_filename) {
    	if (-f $filename) {
            $found_filename = $filename;
#            print STDERR "ImlibImage file '$testfile' exists in $me\n";
    	} else {
            print STDERR sprintf(_(
                "error ImlibImage file '%s' does not exist in %s\n"),
                $filename, $me);
            return undef;
    	}
    }

    return Gtk::Gdk::ImlibImage->load_image ($found_filename);
}

sub missing_handler {
    my ($class, $widgetname, $signal, $handler, $pixmap) = @_;
    my $me = __PACKAGE__."->missing_handler";

#=item missing_handler()
#
#This method pops up a message while the source code is being generated
#if there is no signal handler to call.
#It shows a pixmap (logo) and buttons to dismiss the box or quit the app
#
# $widgetname the widget that triggered the event
# $signal    the signal that was triggered
# $handler   the name of the signal handler that is missing
# $pixmap    pixmap to show
#
#e.g. Glade::PerlRun->missing_handler(
#        $widgetname, 
#        $signal, 
#        $handler, 
#        $pixmap);
#
#=cut
    print STDOUT sprintf(_("%s- %s - called with args ('%s')"),
        $indent, $me, join("', '", @_)), "\n";
    my $message = sprintf("\n"._("%s has been called because\n".
                    "a signal (%s) was caused by widget (%s).\n".
                    "When Perl::Generate writes the Perl source to a file \n".
                    "an AUTOLOADed signal handler sub called '%s'\n".
                    "will be specified in the ProjectSIGS class file. You can write a sub with\n".
                    "the same name in another module and it will automatically be called instead.\n"),
                    $me, $signal, $widgetname, $handler) ;
    my $widget = __PACKAGE__->message_box($message, 
        _("Missing handler")." '$handler' "._("called"), 
        [_("Dismiss"), _("Quit")." PerlGenerate"], 1, $pixmap);
    
    # Stop the signal before it triggers the missing one
    $class->signal_emit_stop($signal);
    return $widget;
}

sub show_skeleton_message {
    my ($class, $caller, $data, $package, $pixmap) = @_;

=item show_skeleton_message($class, $caller, $data, $package, $pixmap)

This method pops up a message_box to prove that a stub has been called.
It shows a pixmap (logo) and buttons to dismiss the box or quit the app

 $caller    where we were called
 $data      the args that were supplied to the caller
 $package
 $pixmap    pixmap to show

e.g. Glade::PerlRun->show_skeleton_message(
    $me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/Logo.xpm");

=cut
    $pixmap  ||= "$Glade::PerlRun::pixmaps_directory/Logo.xpm";
    $package ||= (caller);
    $data    ||= ['unknown args'];
#    $PACKAGE->message_box(sprintf(_("
    $class->message_box(sprintf(_("
A signal handler has just been triggered.

%s was
called with parameters ('%s')

Until the sub is fleshed out, I will show you 
this box to prove that I have been called
"), $caller, join("', '", @$data)), 
    $caller, 
    [_('Dismiss'), _("Quit")." Program"], 
    1, 
    $pixmap);
}

sub message_box {
    my ($class, $text, $title, $buttons, $default, 
        $pixmapfile, $just, $handlers, $entry) = @_;

=item message_box()

Show a message box with optional pixmap and entry widget.
After the dialog is closed, the data entered will be in
global $Glade::PerlRun::data.

e.g. Glade::PerlRun->message_box(
    $message,           # Message to display
    $title,             # Dialog title string
    [_('Dismiss'), _("Quit")." Program"],   
                        # Buttons to show
    1,                  # Default button is 1st
    $pixmap,            # pixmap filename
    [&dismiss, &quit],  # Button click handlers
    $entry_needed);     # Whether to show an
                        # widget for user data

=cut
    my ($i, $ilimit);
    my $justify = $just || 'center';
    my $mbno = 1;
    # Get a unique toplevel widget structure
    while (defined $widgets->{"MessageBox-$mbno"}) {$mbno++;}
    #
    # Create a GtkDialog called MessageBox
    $widgets->{"MessageBox-$mbno"} = new Gtk::Window('toplevel');
    $widgets->{"MessageBox-$mbno"}->set_title($title);
    $widgets->{"MessageBox-$mbno"}->position('mouse');
    $widgets->{"MessageBox-$mbno"}->set_policy('1', '1', '0');
    $widgets->{"MessageBox-$mbno"}->border_width('6');
    $widgets->{"MessageBox-$mbno"}->set_modal('1');
    $widgets->{"MessageBox-$mbno"}->realize;
    $widgets->{"MessageBox-$mbno"}{'tooltips'} = new Gtk::Tooltips;
        #
        # Create a GtkVBox called MessageBox-vbox1
        $widgets->{"MessageBox-$mbno"}{'vbox1'} = new Gtk::VBox(0, 0);
        $widgets->{"MessageBox-$mbno"}{'vbox1'}->border_width(0);
        $widgets->{"MessageBox-$mbno"}->add($widgets->{"MessageBox-$mbno"}{'vbox1'});
        $widgets->{"MessageBox-$mbno"}{'vbox1'}->show();
            #
            # Create a GtkHBox called MessageBox-hbox1
            $widgets->{"MessageBox-$mbno"}{'hbox1'} = new Gtk::HBox('0', '0');
            $widgets->{"MessageBox-$mbno"}{'hbox1'}->border_width('0');
            $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'hbox1'});
            $widgets->{"MessageBox-$mbno"}{'hbox1'}->show();

    		if ($pixmapfile) { 
                #
                # Create a GtkPixmap called pixmap1
    			$widgets->{"MessageBox-$mbno"}{'pixmap1'} = $class->create_pixmap($widgets->{"MessageBox-$mbno"}{'hbox1'}, $pixmapfile);
    			if ($widgets->{"MessageBox-$mbno"}{'pixmap1'}) {
                    $widgets->{"MessageBox-$mbno"}{'pixmap1'}->set_alignment('0.5', '0.5');
    	            $widgets->{"MessageBox-$mbno"}{'pixmap1'}->set_padding('0', '0');
        	        $widgets->{"MessageBox-$mbno"}{'hbox1'}->add($widgets->{"MessageBox-$mbno"}{'pixmap1'});
            	    $widgets->{"MessageBox-$mbno"}{'pixmap1'}->show();
    	            $widgets->{"MessageBox-$mbno"}{'hbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'pixmap1'}, '0', '0', '0', 'start');
    			}
    		}

                #
                # Create a GtkLabel called MessageBox-label1
                $widgets->{"MessageBox-$mbno"}{'label1'} = new Gtk::Label($text);
                $widgets->{"MessageBox-$mbno"}{'label1'}->set_justify($justify);
                $widgets->{"MessageBox-$mbno"}{'label1'}->set_alignment('0.5', '0.5');
                $widgets->{"MessageBox-$mbno"}{'label1'}->set_padding('0', '0');
                $widgets->{"MessageBox-$mbno"}{'hbox1'}->add($widgets->{"MessageBox-$mbno"}{'label1'});
                $widgets->{"MessageBox-$mbno"}{'label1'}->show();
    	        $widgets->{"MessageBox-$mbno"}{'hbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'label1'}, '1', '1', '10', 'start');
        	$widgets->{"MessageBox-$mbno"}{'vbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'hbox1'}, '1', '1', '0', 'start');
            #
            # Create a GtkHBox called MessageBox-action_area1
            $widgets->{"MessageBox-$mbno"}{'action_area1'} = new Gtk::HBox('1', '5');
            $widgets->{"MessageBox-$mbno"}{'action_area1'}->border_width('10');
            $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'action_area1'});
            $widgets->{"MessageBox-$mbno"}{'action_area1'}->show();
                if ($entry) {
                    #
                    # Create a GtkEntry called MessageBox-entry
                    $widgets->{"MessageBox-$mbno"}{'entry'} = new Gtk::Entry;
                    $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'entry'});
					$widgets->{"MessageBox-$mbno"}{'entry'}->show( );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_usize('160', '0' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->can_focus('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_text('' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_max_length('0' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_visibility('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_editable('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->grab_focus();
                }
                #
                # Create a GtkHButtonBox called MessageBox-hbuttonbox1
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'} = new Gtk::HButtonBox;
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->set_layout('default_style');
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->set_spacing('10');
                $widgets->{"MessageBox-$mbno"}{'action_area1'}->add($widgets->{"MessageBox-$mbno"}{'hbuttonbox1'});
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->show();
    			#
    			# Now add all the buttons that were requested (and check for default)
    			$ilimit = scalar(@$buttons);
    			for ($i = 0; $i < $ilimit; $i++) {
                    #
                    # Create a GtkButton called MessageBox-button2
                    $widgets->{"MessageBox-$mbno"}{'button'.$i} = new Gtk::Button($buttons->[$i]);
                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->can_focus('1');
    				if ($handlers->[$i]) {
    					$widgets->{"MessageBox-$mbno"}{'button'.$i}->signal_connect('clicked', $handlers->[$i], $mbno, $buttons->[$i]);
    				} else {
    					$widgets->{"MessageBox-$mbno"}{'button'.$i}->signal_connect('clicked', __PACKAGE__."::message_box_close", $mbno, $buttons->[$i]);
    				}
                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->border_width('0');
                    $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->add($widgets->{"MessageBox-$mbno"}{'button'.$i});
    				if ($i == ($default-1)) {
                        $widgets->{"MessageBox-$mbno"}{'button'.$i}->can_default('1');
    	                $widgets->{"MessageBox-$mbno"}{'button'.$i}->grab_default();
    				}
                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->show();
                }
    			$widgets->{"MessageBox-$mbno"}{'action_area1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}, '1', '1', '0', 'start');
    	    $widgets->{"MessageBox-$mbno"}{'vbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'action_area1'}, '0', '1', '0', 'end');
    $widgets->{"MessageBox-$mbno"}->show();
    return $widgets->{"MessageBox-$mbno"};
}

sub message_box_close {
    my ($class, $mbno, $button_label) = @_;

    # Close this message_box and tidy up
    $widgets->{"MessageBox-$mbno"}->get_toplevel->destroy;
    undef $widgets->{"MessageBox-$mbno"};
    if (_("*Quit Program*Quit PerlGenerate*Quit UI Build*Close Form*") =~ m/\*$button_label\*/) {
        Gtk->main_quit;
    }
    return $data;
}

sub destroy_all_forms {
    my $class = shift;
    my $hashref = shift || $__PACKAGE__::all_forms;
    my $myform;
    foreach $myform (keys %$hashref) {
#        print "We are destroying form '$myform'\n";
        $hashref->{$myform}->get_toplevel->destroy;
        undef $hashref->{$myform};
    }
}

#===============================================================================
#=========== Utilities 					                    	    ============
#===============================================================================

=back

=head1 6) GENERAL METHODS

These are some general purpose methods that are useful to Glade::PerlGenerate
and generated apps.

=over

=cut

sub get_time {
    # FIXME check that this is portable and always works
    #   why does it give BST interactively but UTC from Glade??
    #        $key = sprintf(" (%+03d00)", (localtime)[8]);
    #        $key = (localtime).$key;
    my $time = `date`;
    chomp $time;
    return $time
}

sub full_Path {
    my ($class, $rel_path, $directory, $default) = @_;
    my $me = "$class->full_Path";

=item full_Path()

Turn a relative path name into an absolute path

e.g. my $path = Glade::PerlRun->full_Path($relative_path, $directory);

=cut
    my $basename;
    my $slash = '/';
    my $updir = '/\.\./';
    # set to $default if not defined
    my $fullname = $rel_path || $default || '';
    # add $base unless we are absolute already
    if ($fullname !~ /^$slash/ && defined $directory) {
        # We are supposed to be relative to a directory so use Cwd->chdir to
        # change to specified directory and Cwd->cwd to get full path names
        my $save_dir = cwd;
        chdir($directory);
        my $fulldir = cwd;
        # Now change directory to where we were on entry
        $fullname = "$fulldir$slash$fullname"; 
        chdir($save_dir);
    } else {
        # Get the real path (not symlinks)
        my $dirname = dirname($fullname);
        my $basename = basename($fullname);
        my $save_dir = cwd;
        chdir($dirname);
        my $fulldir = cwd;
        # Now change directory to where we were on entry
        $fullname = "$fulldir$slash$basename"; 
        chdir($save_dir);
    }    
    # Remove double //s and /./s
    $fullname =~ s/$slash\.?$slash/$slash/g;
    # Remove /../ relative directories
    while ($fullname =~ /$updir/) {
        $fullname =~ s/(.+)(?!$updir)$slash.+?$updir/$1$slash/;
    }
    # Remove trailing /s
    $fullname =~ s/$slash$//;
    return $fullname;
}

sub relative_path {
    my ($class, $basepath, $path, $root) = @_;
    my $me = __PACKAGE__."::relative_path";

=item relative_Path($basepath, $path, $root)

Turn an absolute path name into a relative path

e.g. my $path = Glade::PerlRun->relative_Path($relative_path, $directory);

=cut
    return $path if $path =~ /:/;
    my $rel;
    # This loop is based on code from Nicolai Langfeldt <janl@ifi.uio.no>.
    # First we calculate common initial path components length ($li).
    my $li = 1;
    while (1) {
        my $i = index($path, '/', $li);
        last if $i < 0 ||
                $i != index($basepath, '/', $li) ||
                substr($path,$li,$i-$li) ne substr($basepath,$li,$i-$li);
        $li=$i+1;
    }
    # then we nuke it from both paths
    substr($path, 0,$li) = '';
    substr($basepath,0,$li) = '';

#    if ($path eq $basepath) {
#       &&
#        defined($rel->fragment) &&
#        !defined($rel->query)) {
        $rel = "";

#    } else {
        # Add one "../" for each path component left in the base path
        $path = ('../' x $basepath =~ tr|/|/|) . $path;
        $path = "./" if $path eq "";
        $rel = $path;
#    }

#    $rel;

    return $rel;
}

sub string_from_file {&string_from_File(@_);}
sub string_from_File {
    my ($class, $filename) = @_;
    my $me = __PACKAGE__."->string_from_File";

=item string_from_File()

Reads (slurps) a file into a string

e.g. my $string = Glade::PerlRun->string_from_file('/path/to/file');

=cut
    my $save = $/;
    undef $/;
    open INFILE, $filename or 
        die sprintf((
            "error %s - can't open file '%s' for input"),
            $me, $filename);    
    undef $/;
    my $string = <INFILE>;
    close INFILE;
    $/ = $save;
#print "File '$filename' contains '$string'\n";
    return $string;
}

sub reload_any_altered_modules {
    my ($class) = @_;
    my $me = __PACKAGE__."->reload_any_altered_modules";

=item reload_any_altered_modules()

Check all loaded modules and reload any that have been altered since the
app started. This saves restarting the app for every change to the signal
handlers or support modules. 

It is impossible to reload the UI module (called something like ProjectUI.pm)
while the app is running without crashing it so don't run glade2perl and then
call this method.
Similarly, any modules that construct objects in their 
own namespace will cause unpredictable failures.

I usually call this in a button's signal handler so that I can edit the
modules and easily reload the edited versions of modules.

e.g. Glade::PerlRun->reload_any_altered_modules;

=cut
    my $stat = \%stat;
    my $reloaded = 0;
    my ($prefix, $msg);
    if (ref $class) {
        $prefix = ($class->{diag}{indent} || $indent);
    } else {
        $prefix = $indent;
    }
    $prefix .= "- $me";
    while(my($key,$file) = each %INC) {
        local $^W = 0;
        my $mtime = (stat $file)[9];
        # warn and skip the files with relative paths which can't be
        # located by applying @INC;
        unless (defined $mtime and $mtime) {
            print "$prefix - Can't locate $file\n",next 
        }
        unless(defined $stat->{$file}) {
            # First time through so log process start time
            $stat->{$file} = $^T;
        }

        if($mtime > $stat->{$file}) {
            delete $INC{$key};
            require $key;
            $reloaded++;
            print "$prefix - Reloading $key in process $$\n";
        }
        # Log actual stat/checked time
        $stat->{$file} = $mtime;
    }
    return "Reloaded $reloaded module(s) in process $$";
}

1;

__END__

