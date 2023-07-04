package Dist::Zilla::Plugin::SyncCPANfile;

# ABSTRACT: Sync a cpanfile with the prereqs listed in dist.ini

#use v5.10;

use strict;
use warnings;

# VERSION

use version;

use Moose;
use namespace::autoclean;
use Path::Tiny;
use CPAN::Audit;

with qw(
  Dist::Zilla::Role::AfterBuild
);

has cpan_audit => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'cpanfile',
);
 
has comment => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub {
    [
      ( sprintf 'This file is generated by %s v%s', __PACKAGE__, __PACKAGE__->VERSION // '<internal>' ),
      'Do not edit this file directly. To change prereqs, edit the `dist.ini` file.',
    ]
  }
);

sub mvp_multivalue_args { qw( comment ) }
 
sub after_build {
    my ($self) = @_;

    my $content = $self->_get_cpanfile();

    # need to write it to disk if we're in a
    # phase that is not filemunge
    path( $self->filename )->spew_raw( $content );
}

sub _get_cpanfile {
    my ($self) = @_;

    my $audit = CPAN::Audit->new;

    my $zilla = $self->zilla;
    my $prereqs = $zilla->prereqs;
 
    my @types  = qw(requires recommends suggests conflicts);
    my @phases = qw(runtime build test configure develop);
 
    my $str = join "\n", ( map { "# $_" } @{ $self->comment } ), '', '';
    for my $phase (@phases) {
        my $prefix  = $phase eq 'runtime' ? '' : (sprintf "\non '%s' => sub {\n", $phase );
        my $postfix = $phase eq 'runtime' ? '' : "};\n";
        my $indent  = $phase eq 'runtime' ? '' : '    ';

        for my $type (@types) {
            my $req = $prereqs->requirements_for($phase, $type);

            next unless $req->required_modules;

            $str .= $prefix;
            
            for my $module ( sort $req->required_modules ) {
                my $version = $req->requirements_for_module( $module ) || 0;

                my ($min_version, $advisories);

                if ( $self->cpan_audit ) {
                    ($min_version, $advisories) = _audit( $audit, $module, $version );
                }

                if ( $advisories && $version =~ m{(>|<|>=|<=|!=|==)}  ) {

                    # this seems to be a version range, so check if the latest fixed version would be accepted
                    if ( defined $min_version && !$req->accepts_module( $module, $min_version ) ) {
                        $self->log( "Range '$version' for $module does not include latest fixed version ($min_version)!" );
                    }
                    elsif ( defined $min_version ) {
                        $self->log( "Current version range includes vulnerable versions. Consider updating the minimum to $min_version" ) #if $affected_version_allowed;
                    }
                }
                elsif ( $advisories ) {

                    # this branch is used when no version range is given but a version number
                    my $vuln_version_requested = $min_version && (
                        version->new( $version ) < version->new( $min_version )
                    );

                    if ( $version == 0 && $vuln_version_requested ) {
                        $version = $min_version;
                    }
                    elsif ( $vuln_version_requested ) {
                        $self->log( "Prereq $module $version is vulnerable" );
                    }
                }

                $str .= sprintf qq~%s%s "%s" => "%s";\n~,
                    $indent,
                    $type,
                    $module,
                    $version;
            }

            $str .= $postfix;
        }
    }

    return $str;
}

sub _audit {
    my ($audit, $module, $version) = @_;

    my $result        = $audit->command( 'module', $module, $version );
    my ($module_data) = values %{ $result->{dists} || {} };
    my @advisories    = @{ $module_data->{advisories} || [] };

    my @versions;
    for my $advisory ( @advisories ) {
        my ($fixed_version) = ( $advisory->{fixed_versions} // '' ) =~ m{(v?[0-9]+(?:\.[0-9]+){0,2})};
        next if !$fixed_version;

        my $version_object = version->new( $fixed_version );
        push @versions, $version_object;
    }

    my ($min_version) = sort { $b <=> $a } @versions;
    return ( $min_version, scalar @advisories );
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

Unlike L<Dist::Zilla::Plugin::CPANFile> this plugin does not
add a I<cpanfile> to the distribution but to the "disk".

=head1 SYNOPSIS

    # in dist.ini
    [SyncCPANfile]

    # configure it yourself
    [SyncCPANfile]
    filename = my-cpanfile
    comment  = This is my cpanfile

=head1 CONFIG

=head2 filename

With this config you can change the filename for the file. It defaults
to I<cpanfile>.

    [SyncCPANfile]
    filename = my-cpanfile

=head2 comment

The default comment says, that the I<cpanfile> was generated by this plugin.
You can define your own comment.

    [SyncCPANfile]
    comment  = This is my cpanfile
    comment  = line 2

=head2 cpan_audit

When I<cpan_audit> is enabled, the required module version is not defined (or 0),
and the module has vulnerabilities, the "fixed version" storied in L<CPAN::Audit>
is used as a minimum version.

  [SyncCPANfile]
  cpan_audit = 1

  [Prereqs]
  ExtUtils::MakeMaker = 0

L<ExtUtils::MakeMaker> has a vulnerability in versions E<lt>= 7.21. As the minimum
version in the I<dist.ini> is 0 and I<cpan_audit> is enabled, the I<cpanfile>
will use 7.22 as the minimum version (as of June 2023).

As this depends on the I<CPAN::Audit> database, you should update I<CPAN::Audit>
regularly.

For dependencies where a minimum version is defined and the defined version is
vulnerable a warning is shown.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::CPANFile>, L<Dist::Zilla::Plugin::GitHubREADME::Badge>

=for Pod::Coverage after_build mvp_multivalue_args

=cut
