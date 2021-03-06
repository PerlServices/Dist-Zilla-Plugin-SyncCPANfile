package Dist::Zilla::Plugin::SyncCPANfile;

# ABSTRACT: Sync a cpanfile with the prereqs listed in dist.ini

#use v5.10;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Path::Tiny;

with qw(
  Dist::Zilla::Role::AfterBuild
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
                my $version = $req->requirements_for_module( $module );

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

=head1 SEE ALSO

L<Dist::Zilla::Plugin::CPANFile>, L<Dist::Zilla::Plugin::GitHubREADME::Badge>

=for Pod::Coverage after_build mvp_multivalue_args

=cut
