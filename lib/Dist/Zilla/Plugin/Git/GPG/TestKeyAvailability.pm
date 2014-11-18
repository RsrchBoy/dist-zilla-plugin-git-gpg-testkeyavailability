package Dist::Zilla::Plugin::Git::GPG::TestKeyAvailability;

# ABSTRACT: The great new Dist::Zilla::Plugin::Git::GPG::TestKeyAvailability!

use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;
use autobox::Junctions;

use aliased 'Dist::Zilla::Stash::Store::Git' => 'GitStore';

use Try::Tiny;

with
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::RegisterStash',
    ;

has _git => (
    is              => 'lazy',
    isa_instance_of => GitStore,
    builder         => sub { shift->_register_or_retrieve_stash('%Store::Git') },
);

has _git_config => (
    is              => 'lazy',
    isa_instance_of => 'Git::Raw::Config',
    builder         => sub { shift->_git->config },
);

=attr git_config_key_set

=cut

has git_config_key_set => (
    is         => 'lazy',
    isa        => 'Str',
    constraint => sub { [qw{ warn fatal quiet }]->any eq $_ },
    builder    => sub { 'warn' }, 
);

=attr live_git_tag_create_test

Boolean.  Live git tag creation test.

=cut

has live_git_tag_create_test => (
    is      => 'lazy',
    isa     => 'Bool',
    builder => sub { 1 }, 
);

=method before_release

Tests to ensure we can create a signed tag before going through the release
process.

=cut

sub before_release {
    my $self = shift @_;

    my $repo = $self->_git->repo_raw;

    my $key = $self->_git_config->str('user.signingkey');

    ### user.signingkey: $key
    $self->_check_git_config($key);
    $self->_test_tag_creation;

    return;
}

sub _check_git_config {
    my ($self, $key) = @_;

    ### git_config_key_set: $self->git_config_key_set
    my $complaint_level = $self->git_config_key_set;
    return if $complaint_level eq 'quiet';

    my $_debug = sub { $self->zilla->log_debug(@_) };
    my $_log
        = $complaint_level eq 'warn'
        ? sub { $self->zilla->log(@_)       }
        : sub { $self->zilla->log_fatal(@_) }
        ;

    defined $key
        ? $_debug->("user.signingkey is set: $key")
        : $_log->('git config key "user.signingkey" is not set')
        ;

    return;
}

sub _test_tag_creation {
    my $self = shift @_;

    return unless $self->live_git_tag_create_test;

    my $git = $self->_git->repo_wrapper;
    my $tag = 'aslkdjsdlaksjkjdksjallll';
    try {
        $git->tag('-m' => 'testing...', '-s', $tag);
    }
    catch {
        $self->zilla->log_fatal("git tag failed!: $_");
    };
    $git->tag('-d' => $tag);

    return;
}

__PACKAGE__->meta->make_immutable;
!!42;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut
