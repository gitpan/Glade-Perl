#!/usr/bin/perl -w
#
# <SS>This is an example of a subclass of the generated application</SS>
#
# <SS>You can safely edit this file, any changes that you make will be preserved</SS>
# <SS>and this file will not be overwritten by the next run of</SS> Glade::PerlGenerate
#

#==============================================================================
#=== <SS>This is the</SS> 'SubBusFrame' class                              
#==============================================================================
package SubBusFrame;
require 5.000; use strict 'vars', 'refs', 'subs';
# UI class 'SubBusFrame' (<SS>version</SS> 0.01)
# 
# <SS>Copyright</SS> (c) <SS>Date</SS> Tue Feb 29 17:46:24 GMT 2000
# <SS>Author</SS> Dermot Musgrove <dermot.musgrove\@virgin.net>
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
# author  Dermot Musgrove <dermot.musgrove\@virgin.net>
#
#==============================================================================
# <SS>This perl source file was automatically generated by</SS> Glade::PerlGenerate
# <SS>from Glade file</SS> /home/dermot/Devel/Glade-Perl-0.51/Example/Bus/Bus.glade
# <SS>Date</SS> Tue Feb 29 17:46:24 GMT 2000
#
# Glade::PerlGenerate       - <SS>version</SS> 0.51
# <SS>Copyright</SS> (c) <SS>Date</SS> Fri Feb 25 02:27:53 GMT 2000
# <SS>Author</SS> Dermot Musgrove <dermot.musgrove\@virgin.net>
#==============================================================================

BEGIN {
    use vars    qw( 
                     @ISA
                     %fields
                 );
    # Existing signal handler modules
    use Generated::Bus;
    use Bus_mySUBS;
    # Tell interpreter who we are inheriting from
    @ISA      = qw( BusFrame );
    # Inherit the AUTOLOAD dynamic methods from BusFrame
    *AUTOLOAD = \&BusFrame::AUTOLOAD;
}

%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
    USERDATA    => undef,
    VERSION     => '0.01',
);

#==============================================================================
#=== <SS>Below are the overloaded class constructors</SS>
#==============================================================================
sub new {
    my $that  = shift;
    # Allow indirect constructor so that we can call eg. 
    #   $window1 = BusFrame->new; $window2 = $window1->new;
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

sub run {
    my ($class) = @_;
    Gtk->init;
    my $window = $class->new;
    # Insert your subclass user data key/value pairs 
    $window->USERDATA({
#        'Key1'   => 'Value1',
#        'Key2'   => 'Value2',
#        'Key3'   => 'Value3',
    });
    $window->TOPLEVEL->show;
#    my $window2 = $window->new;
#    $window2->TOPLEVEL->show;
    Gtk->main;
    return $window;
}
#===============================================================================
#=== <SS>Below are (overloaded) default signal handlers for</SS> 'BusFrame' class 
#===============================================================================
sub about_Form {
    my ($class) = @_;
    my $gtkversion = 
        Gtk->major_version.".".
        Gtk->minor_version.".".
        Gtk->micro_version;
    my $name = $0;
    my $message = 
        __PACKAGE__." ("._("version")." 0.01 - Tue Feb 29 17:46:24 GMT 2000)\n".
        _("Written by")." Dermot Musgrove <dermot.musgrove\@virgin.net> \n\n".
        _("This is an example generated by the Glade-Perl
source code generator")." \n\n".
        "Gtk ".     _("version").": $gtkversion\n".
        "Gtk-Perl "._("version").": $Gtk::VERSION\n".
        _("run from file").": $name";
    __PACKAGE__->message_box($message, _("About")." \u".__PACKAGE__, [_('Dismiss'), _('Quit Program')], 1,
        "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm", 'left' );
}

sub destroy_Form {
    my ($class, $data, $object, $instance) = @_;
    Gtk->main_quit; 
}

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }


#==============================================================================
#=== <SS>Below are (overloaded) signal handlers for</SS> 'BusFrame' class 
#==============================================================================
sub on_Contents_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Contents_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Contents_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Contents_activate(@_);

} # End of sub on_Contents_activate

sub on_Copy_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Copy_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Copy_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Copy_activate(@_);

} # End of sub on_Copy_activate

sub on_Cut_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Cut_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Cut_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Cut_activate(@_);

} # End of sub on_Cut_activate

sub on_Index_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Index_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Index_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Index_activate(@_);

} # End of sub on_Index_activate

sub on_Mail_to_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Mail_to_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Mail_to_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Mail_to_activate(@_);

} # End of sub on_Mail_to_activate

sub on_Paste_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Paste_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Paste_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Paste_activate(@_);

} # End of sub on_Paste_activate

sub on_Save_As_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Save_As_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Save_As_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Save_As_activate(@_);

} # End of sub on_Save_As_activate

sub on_Save_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Save_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Save_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Save_activate(@_);

} # End of sub on_Save_activate

sub on_Search_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Search_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Search_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Search_activate(@_);

} # End of sub on_Search_activate

sub on_Undo_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_Undo_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_Undo_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_Undo_activate(@_);

} # End of sub on_Undo_activate

sub on_WWW_activate {
    my ($class, $data, $object, $instance, $event) = @_;
    my $me = __PACKAGE__."->on_WWW_activate";
    # <SS>Get ref to hash of all widgets on our form</SS>
    my $form = $__PACKAGE__::all_forms->{$instance};

    # <SS>REPLACE the line below with the actions to be taken when</SS> __PACKAGE__."->on_WWW_activate." is called
#    __PACKAGE__->show_skeleton_message($me, \@_, __PACKAGE__, "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm");
    shift->SUPER::on_WWW_activate(@_);

} # End of sub on_WWW_activate











#==============================================================================
#=== <SS>This is the</SS> 'Subfileselection1' class                              
#==============================================================================
package Subfileselection1;
require 5.000; use strict 'vars', 'refs', 'subs';
# UI class 'Subfileselection1' (<SS>version</SS> 0.01)
# 
# <SS>Copyright</SS> (c) <SS>Date</SS> Tue Feb 29 17:46:24 GMT 2000
# <SS>Author</SS> Dermot Musgrove <dermot.musgrove\@virgin.net>
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
# author  Dermot Musgrove <dermot.musgrove\@virgin.net>
#
#==============================================================================
# <SS>This perl source file was automatically generated by</SS> Glade::PerlGenerate
# <SS>from Glade file</SS> /home/dermot/Devel/Glade-Perl-0.51/Example/Bus/Bus.glade
# <SS>Date</SS> Tue Feb 29 17:46:24 GMT 2000
#
# Glade::PerlGenerate       - <SS>version</SS> 0.51
# <SS>Copyright</SS> (c) <SS>Date</SS> Fri Feb 25 02:27:53 GMT 2000
# <SS>Author</SS> Dermot Musgrove <dermot.musgrove\@virgin.net>
#==============================================================================

BEGIN {
    use vars    qw( 
                     @ISA
                     %fields
                 );
    # Existing signal handler modules
    use Generated::Bus;
    use Bus_mySUBS;
    # Tell interpreter who we are inheriting from
    @ISA      = qw( fileselection1 );
    # Inherit the AUTOLOAD dynamic methods from fileselection1
    *AUTOLOAD = \&fileselection1::AUTOLOAD;
}

%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
    USERDATA    => undef,
    VERSION     => '0.01',
);

#==============================================================================
#=== <SS>Below are the overloaded class constructors</SS>
#==============================================================================
sub new {
    my $that  = shift;
    # Allow indirect constructor so that we can call eg. 
    #   $window1 = BusFrame->new; $window2 = $window1->new;
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

sub run {
    my ($class) = @_;
    Gtk->init;
    my $window = $class->new;
    # Insert your subclass user data key/value pairs 
    $window->USERDATA({
#        'Key1'   => 'Value1',
#        'Key2'   => 'Value2',
#        'Key3'   => 'Value3',
    });
    $window->TOPLEVEL->show;
#    my $window2 = $window->new;
#    $window2->TOPLEVEL->show;
    Gtk->main;
    return $window;
}
#===============================================================================
#=== <SS>Below are (overloaded) default signal handlers for</SS> 'fileselection1' class 
#===============================================================================
sub about_Form {
    my ($class) = @_;
    my $gtkversion = 
        Gtk->major_version.".".
        Gtk->minor_version.".".
        Gtk->micro_version;
    my $name = $0;
    my $message = 
        __PACKAGE__." ("._("version")." 0.01 - Tue Feb 29 17:46:24 GMT 2000)\n".
        _("Written by")." Dermot Musgrove <dermot.musgrove\@virgin.net> \n\n".
        _("This is an example generated by the Glade-Perl
source code generator")." \n\n".
        "Gtk ".     _("version").": $gtkversion\n".
        "Gtk-Perl "._("version").": $Gtk::VERSION\n".
        _("run from file").": $name";
    __PACKAGE__->message_box($message, _("About")." \u".__PACKAGE__, [_('Dismiss'), _('Quit Program')], 1,
        "$Glade::PerlRun::pixmaps_directory/glade2perl_logo.xpm", 'left' );
}

sub destroy_Form {
    my ($class, $data, $object, $instance) = @_;
    Gtk->main_quit; 
}

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }


#==============================================================================
#=== <SS>Below are (overloaded) signal handlers for</SS> 'fileselection1' class 
#==============================================================================










1;

__END__

#===============================================================================
#==== <SS>Documentation</SS>
#===============================================================================
=pod

=head1 NAME

SubBus - <SS>version</SS> 0.01 Tue Feb 29 17:46:24 GMT 2000

<SS>This is an example generated by the Glade-Perl
source code generator</SS>

=head1 SYNOPSIS

 use SubBus;

 if ($<SS>we_want_to_subclass_this_class</SS>) {
   # <SS>Inherit the AUTOLOAD dynamic methods from</SS> SubBusFrame
   *AUTOLOAD = \&SubBusFrame::AUTOLOAD;

   # <SS>Tell interpreter who we are inheriting from</SS>
   use vars qw( @ISA ); @ISA = qw( SubBusFrame );
 }
 
 <SS>To construct the window object and show it call</SS>
 
 Gtk->init;
 my $window = SubBusFrame->new;
 $window->TOPLEVEL->show;
 Gtk->main;
 
 <SS>OR use the shorthand for the above calls</SS>
 
 SubBusFrame->run;

=head1 DESCRIPTION

<SS>Unfortunately, the author has not yet written any documentation :-(</SS>

=head1 AUTHOR

Dermot Musgrove <dermot.musgrove\@virgin.net>

=cut
