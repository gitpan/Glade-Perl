%define version     0.57

%define name        Glade-Perl
%define real_name   %{name}
%define release     1
%define url         http://www.glade.perl.connectfree.co.uk
%define packager    Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>
%define group       Development/Languages
%define copying     GPL or Artistic
%define prefix      /usr

Name: %{name}
Version: %{version}
Release: %{release}
Summary: Perl module to generate Gtk-Perl source from a Glade file.
Copyright: %{copying}
Packager: %{packager}
Source: %{url}/%{real_name}-%{version}.tar.gz
Group: %{group}
BuildRoot: /tmp/%{real_name}-%{version}-root/
Prefix: %{_prefix}
BuildRequires: perl >= 5.004, XML-Parser >= 2.27, Gtk-Perl >= 0.6123

%description
Glade-Perl will read a Glade-Interface XML file, build the UI and/or
write the perl source to create the UI later and handle signals. 
It also creates an 'App' and a 'Subclass' that you can edit.

%prep
%setup -n %{real_name}-%{version}

%build
perl Makefile.PL --lazy-load
make OPTIMIZE="$RPM_OPT_FLAGS"

%install
rm -rf "$RPM_BUILD_ROOT"
make install PREFIX="$RPM_BUILD_ROOT%{_prefix}"

%files
%defattr(-,root,root)
#%dir /%{prefix}/lib/perl5/site_perl/5.005/%{_arch}-linux/auto/Gtk
#%{prefix}/lib/perl5/site_perl/5.005/Glade/PerlGenerate.pm
#%{prefix}/lib/perl5/man/man3/Glade::PerlGenerate.3.bz2
%doc README Documentation/COPYING Documentation/Changelog Documentation/TODO Documentation/NEWS Documentation/Gtk-Perl-Docs

%changelog
* Wed Sep 13 16:56:20 BST 2000 Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>
- First go at a spec file.

