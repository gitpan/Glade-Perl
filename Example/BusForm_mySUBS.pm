package Example::BusForm_mySUBS;
require 5.000; use English; use strict 'vars', 'refs', 'subs';

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
    use Exporter    qw (  );
    use Glade::PerlRun;
    use vars        qw( @ISA  @EXPORT );
    # Tell interpreter who we are inheriting from
    @ISA = qw( Glade::PerlRun );
    # Tell interpreter what we are exporting
    @EXPORT =       qw( 
                        on_New_activate
                        on_Open_activate
                        on_Print_activate
                        on_BusFrame_delete_event
                        on_BusFrame_destroy_event
                        on_fileselection1_delete_event
                        on_ok_button1_clicked
                    );
}

#===============================================================================
#==== Below are all the signal handlers supplied by the programmer          ====
#===============================================================================
sub Skeleton_Handler {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->Skeleton_Handler";
    # REPLACE the line below with the actions to be taken when $me is called
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

sub on_New_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_New_activate";
    my $filesel = fileselection1->new->TOPLEVEL;
    $filesel->set_title("New file selection triggered in $me");
    $filesel->show;
}

sub on_Open_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_Open_activate";
    my $filesel = fileselection1->new->TOPLEVEL;
    $filesel->set_title("Open file selection triggered in $me");
    $filesel->show;
}

sub on_Print_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_Print_activate";
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

sub on_BusFrame_delete_event {shift->destroy;Gtk->main_quit}
sub on_BusFrame_destroy_event {Gtk->main_quit}

sub on_fileselection1_delete_event {shift->destroy}
sub on_ok_button1_clicked {shift->get_toplevel->destroy}

1;

__END__

