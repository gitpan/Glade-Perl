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
# but not required, to pay what you feel is a reasonable fee to the
# author, who can be contacted at dermot.musgrove@virgin.net

BEGIN {
    use Exporter    qw(  );
    use Gtk;             # For message_box
    use Cwd         qw( cwd chdir );
    use vars        qw( @ISA 
                        $AUTOLOAD
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE 
                        $VERSION $AUTHOR $DATE
                        @VARS @METHODS 
                        $I18N
                        $all_forms
                        $project
                        $widgets 
                        $work
                        $data 
                        $forms 
                        $pixmaps_directory
                      );
    # Tell interpreter who we are inheriting from
    @ISA          = qw( Exporter );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.56);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove\@virgin.net>);
    $DATE         = q(Wed Apr 19 02:28:58 BST 2000);
    $widgets      = {};
    $all_forms    = {};
    $pixmaps_directory = "pixmaps";
#print "\$pixmaps_directory is '$pixmaps_directory'\n";
    # These vars are imported by all Glade-Perl modules for consistency
    @VARS         = qw(  
                        $VERSION
                        $AUTHOR
                        $DATE
                        $I18N
                    );
    @METHODS      = qw( 
                        full_Path 
                        create_image 
                        create_pixmap 
                        missing_handler 
                        new_message_box 
                        message_box 
                        message_box_close 
                        show_skeleton_message 
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
    PACKAGE  => __PACKAGE__,
    PARTYPE  => [],
    VERSION  => $VERSION,
    AUTHOR   => $AUTHOR,
    DATE     => $DATE,
    LOGO     => undef,
    DATA     => undef,
    LOOKUP   => 2,
    BOOL     => 4,
    DEFAULT  => 8,
    KEYSYM   => 16,
    LOOKUP_ARRAY => 32,
);

%stubs = (
);

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
      or die "$self is not an object so we cannot '$AUTOLOAD'\n",
          "We were called from ".join(", ", caller),"\n\n";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;       # strip fully-qualified portion

  if (exists $self->{_permitted_fields}->{$name} ) {
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
    die "Can't access method `$name' in class $type\n",
        "We were called from ",join(", ", caller),"\n\n";

  }
}

sub new {
#
# This sub will create the UI window
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self  = {
        _permitted_fields   => \%fields, %fields,
        _permitted_stubs    => \%stubs,  %stubs,
    };
    bless $self, $class;
#$class->PARTYPE = [];
    $self->PARTYPE->[$self->LOOKUP]         = "Lookup ";
    $self->PARTYPE->[$self->BOOL]           = "Bool   ";
    $self->PARTYPE->[$self->DEFAULT]        = "Default";
    $self->PARTYPE->[$self->KEYSYM]         = "KeySym";
    $self->PARTYPE->[$self->LOOKUP_ARRAY]   = "Lookup Array";
    return $self;
}

#===============================================================================
#=========== Gettext Utilities                                              ====
#=========== 'borrowed' from the gettext dist and recoded to house style    ====
#===============================================================================
sub _ {gettext(@_)}

sub gettext {
    defined $I18N->{'__'}{$_[0]} ? $I18N->{'__'}{$_[0]} : $_[0];
}

sub load_translations {
    my ($class, $domain, $language, $locale_dir, $file, $key, $merge) = @_;

    $key ||= '__';
    $I18N->{$key} = {} unless $merge and $merge eq "MERGE";;

    $language ||= $ENV{"LANG"};
    return unless $language;
    $locale_dir ||= "/usr/local/share/locale";
    $domain     ||= "Glade-Perl";
    my $catalog_filename = $file || 
        "$locale_dir/$language/LC_MESSAGES/$domain.mo";

    return unless -f $catalog_filename;
    $class->load_mo($catalog_filename, $key);
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
#=========== Hierarchy Utilities                                            ====
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
#=========== Utilities 					 	    ============
#===============================================================================
sub full_Path {
    my ($class, $file, $directory, $default) = @_;
    my $me = "$class->full_Path";
    my $leaning_toothpick = '/';
    # set to $default if not defined
    my $fullname = $file || $default || '';
    # add $base unless we are absolute already
    if ($fullname =~ /^$leaning_toothpick/) {
        # We are already an absolute filename so remove double //'s
        $fullname =~ s/$leaning_toothpick$leaning_toothpick/$leaning_toothpick/g;

    } elsif (defined $directory) {
        # We are supposed to be relative to a directory so use Cwd->chdir to
        # change to specified directory and Cwd->cwd to get full path names
        my $save_dir = cwd;
        chdir($directory);
        my $fulldir = cwd;
        # Now change directory to where we were on entry
        chdir($save_dir);
        $fullname = "$fulldir/$fullname"; 
#    } else {
#        # Nothing else to do
    }
    # remove any trailing /'s
    $fullname =~ s/$leaning_toothpick$//;
    return $fullname;
}

sub create_pixmap {
    my ($class, $widget, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_pixmap";
    # Usage is $pixmap = $class->create_pixmap(
    #   $widgets->{'name'}, 
    #   'pixmapfilename.xpm', 
    #   [$project->{'pixmaps_directory'}])
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

sub get_file  {
    my ($class, $filename) = @_;
    my $s;
    $filename or 
        die ("no filename for")." ".__PACKAGE__;         # we need a filename
    {   local $/;
        open CONFIG,"$filename" or
            die sprintf("Can't open file name '%s'"),$filename;
        $s = <CONFIG>;
        close CONFIG;
    }
    return $s;
}

sub message_box {
    my ($class, $text, $title, $buttons, $default, 
        $pixmapfile, $just, $handlers, $entry) = @_;
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
#    $widgets->{"MessageBox-$mbno"}->allow_shrink('1');
#    $widgets->{"MessageBox-$mbno"}->allow_grow('1');
#    $widgets->{"MessageBox-$mbno"}->auto_shrink('0');
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
#			            $widgets->{"MessageBox-$mbno"}{'tooltips'}->set_tip($widgets->{"MessageBox-$mbno"}{'button'.$i}, 'Click here to get rid of this message');
    					$widgets->{"MessageBox-$mbno"}{'button'.$i}->signal_connect('clicked', "${PACKAGE}::message_box_close", $mbno, $buttons->[$i]);
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
    # Close this message_box and undef the $widget->{'MessageBox-$mbno'} structure
    $widgets->{"MessageBox-$mbno"}->get_toplevel->destroy;
    undef $widgets->{"MessageBox-$mbno"};
    if (_("*Quit Program*Quit PerlGenerate*Quit UI Build*Close Form*") =~ m/\*$button_label\*/) {
        Gtk->main_quit;
    }
    return $data;
}

sub create_image {
    my ($class, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_image";
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

sub missing_handler {
    my ($class, $widgetname, $signal, $handler, $pixmap) = @_;
    my $me = "$PACKAGE->missing_handler";
    print STDOUT sprintf(_(" - %s - called with args ('%s')"),
        $me, join("', '", @_)), "\n";
    my $message = sprintf("\n"._("%s has been called because\n".
                    "a signal (%s) was caused by widget (%s).\n".
                    "When Perl::Generate writes the Perl source to a file \n".
                    "an AUTOLOADed signal handler sub called '%s'\n".
                    "will be specified in the ProjectSIGS class file. You can write a sub with\n".
                    "the same name in another module and it will automatically be called instead.\n"),
                    $me, $signal, $widgetname, $handler) ;
    my $widget = $PACKAGE->message_box($message, 
        _("Missing handler")." '$handler' "._("called"), 
        [_("Dismiss"), _("Quit")." PerlGenerate"], 1, $pixmap);
    
    # Stop the signal before it triggers the missing one
    $class->signal_emit_stop($signal);
    return $widget;
}

sub show_skeleton_message {
    # This proc pops up a message_box to prove that a stub has been called
    my ($class, $me, $data, $package, $pixmap) = @_;
    $PACKAGE->message_box(sprintf(_("
A signal handler has just been triggered.

%s was
called with parameters ('%s')

Until the sub is fleshed out, I will show you 
this box to prove that I have been called
"), $me, join("', '", @$data)), 
    $me, 
    [_('Dismiss'), _("Quit")." Program"], 
    1, 
    $pixmap);
}

#===============================================================================
#==== Documentation ============================================================
#===============================================================================

1;

__END__

