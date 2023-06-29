[![Kwalitee status](https://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-SyncCPANfile.png)](https://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-SyncCPANfile)
[![GitHub issues](https://img.shields.io/github/issues/perlservices/Dist-Zilla-Plugin-SyncCPANfile.svg)](https://github.com/perlservices/Dist-Zilla-Plugin-SyncCPANfile/issues)
[![CPAN Cover Status](https://cpancoverbadge.perl-services.de/Dist-Zilla-Plugin-SyncCPANfile-0.03)](https://cpancoverbadge.perl-services.de/Dist-Zilla-Plugin-SyncCPANfile-0.03)
[![Cpan license](https://img.shields.io/cpan/l/Dist-Zilla-Plugin-SyncCPANfile.svg)](https://metacpan.org/release/Dist-Zilla-Plugin-SyncCPANfile)

# NAME

Dist::Zilla::Plugin::SyncCPANfile - Sync a cpanfile with the prereqs listed in dist.ini

# VERSION

version 0.03

# SYNOPSIS

```perl
# in dist.ini
[SyncCPANfile]

# configure it yourself
[SyncCPANfile]
filename = my-cpanfile
comment  = This is my cpanfile
```

Unlike [Dist::Zilla::Plugin::CPANFile](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3ACPANFile) this plugin does not
add a _cpanfile_ to the distribution but to the "disk".

# CONFIG

## filename

With this config you can change the filename for the file. It defaults
to _cpanfile_.

```perl
[SyncCPANfile]
filename = my-cpanfile
```

## comment

The default comment says, that the _cpanfile_ was generated by this plugin.
You can define your own comment.

```perl
[SyncCPANfile]
comment  = This is my cpanfile
comment  = line 2
```

## cpan\_audit

When _cpan\_audit_ is enabled, the required module version is not defined (or 0),
and the module has vulnerabilities, the "fixed version" storied in [CPAN::Audit](https://metacpan.org/pod/CPAN%3A%3AAudit)
is used as a minimum version.

```
[SyncCPANfile]
cpan_audit = 1

[Prereqs]
ExtUtils::MakeMaker = 0
```

[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils%3A%3AMakeMaker) has a vulnerability in versions <= 7.21. As the minimum
version in the _dist.ini_ is 0 and _cpan\_audit_ is enabled, the _cpanfile_
will use 7.22 as the minimum version (as of June 2023).

As this depends on the _CPAN::Audit_ database, you should update _CPAN::Audit_
regularly.

For dependencies where a minimum version is defined and the defined version is
vulnerable a warning is shown.

# SEE ALSO

[Dist::Zilla::Plugin::CPANFile](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3ACPANFile), [Dist::Zilla::Plugin::GitHubREADME::Badge](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AGitHubREADME%3A%3ABadge)



# Development

The distribution is contained in a Git repository, so simply clone the
repository

```
$ git clone git://github.com/perlservices/Dist-Zilla-Plugin-SyncCPANfile.git
```

and change into the newly-created directory.

```
$ cd Dist-Zilla-Plugin-SyncCPANfile
```

The project uses [`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) to
build the distribution, hence this will need to be installed before
continuing:

```
$ cpanm Dist::Zilla
```

To install the required prequisite packages, run the following set of
commands:

```
$ dzil authordeps --missing | cpanm
$ dzil listdeps --author --missing | cpanm
```

The distribution can be tested like so:

```
$ dzil test
```

To run the full set of tests (including author and release-process tests),
add the `--author` and `--release` options:

```
$ dzil test --author --release
```

# AUTHOR

Renee Baecker <reneeb@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Renee Baecker.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
