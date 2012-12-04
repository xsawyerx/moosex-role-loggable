use strict;
use warnings;
package MooseX::Role::Loggable;
# ABSTRACT: Extensive, yet simple, logging role using Log::Dispatchouli

use Moo::Role;
use MooX::Types::MooseLike::Base qw<Bool Str>;
use Sub::Quote 'quote_sub';
use Log::Dispatchouli;
use namespace::autoclean;

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has logger_facility => (
    is      => 'ro',
    isa     => Str,
    default => sub {'local6'},
);

has logger_ident => (
    is      => 'ro',
    isa     => Str,
    default => sub { ref shift },
);

has log_to_file => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_to_stdout => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_to_stderr => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_file => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_log_file',
);

has log_path => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_log_path',
);

has log_pid => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

has log_fail_fatal => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

has log_muted => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_quiet_fatal => (
    is      => 'ro',
    isa     => quote_sub(q{
        use Safe::Isa;
        $_[0] || $_[0]->$_isa( ref [] )
            or die "$_[0] must be a string or arrayref"
    }),
    default => sub {'stderr'},
);

has logger => (
    is      => 'lazy',
    isa     => quote_sub(q{
        use Safe::Isa;
        $_[0]->$_isa('Log::Dispatchouli')        ||
        $_[0]->$_isa('Log::Dispatchouli::Proxy')
            or die "$_[0] must be a Log::Dispatchouli object";
    }),

    handles => [ qw/
        log log_fatal log_debug
        set_debug clear_debug set_prefix clear_prefix set_muted clear_muted
    / ],
);

sub _build_logger {
    my $self     = shift;
    my %optional = ();

    foreach my $option ( qw<log_file log_path> ) {
        my $method = "has_$option";
        if ( $self->$method ) {
            $optional{$option} = $self->$option;
        }
    }

    my $logger = Log::Dispatchouli->new( {
        debug       => $self->debug,
        ident       => $self->logger_ident,
        facility    => $self->logger_facility,
        to_file     => $self->log_to_file,
        to_stdout   => $self->log_to_stdout,
        to_stderr   => $self->log_to_stderr,
        log_pid     => $self->log_pid,
        fail_fatal  => $self->log_fail_fatal,
        muted       => $self->log_muted,
        quiet_fatal => $self->log_quiet_fatal,
        %optional,
    } );

    return $logger;
}

1;

__END__

=head1 SYNOPSIS

    package My::Object;

    use Moose; # or Moo
    with 'MooseX::Role::Loggable';

    sub do_this {
        my $self = shift;
        $self->set_prefix('[do_this] ');
        $self->log_debug('starting...');
        ...
        $self->log_debug('more stuff');
        $self->clear_prefix;
    }

=head1 DESCRIPTION

This is a role to provide logging ability to whoever consumes it using
L<Log::Dispatchouli>. Once you consume this role, you have attributes and
methods for logging defined automatically.

    package MyObject;
    use Moose # Moo works too
    with 'MooseX::Role::Loggable';

    sub run {
        my $self = shift;

        $self->log('Trying to do something');

        # this only gets written if debug flag is on
        $self->log_debug('Some debugging output');

        $self->log(
            { level => 'critical' },
            'Critical log message',
        );

        $self->log_fatal('Log and die');
    }

This module uses L<Moo> so it takes as little resources as it can by default,
and can seamlessly work with both L<Moo> or L<Moose>.

=head1 Propagating logging definitions

Sometimes your objects create additional object which might want to log
using the same settings. You can simply give them the same logger object.

    package Parent;
    use Moose;
    with 'MooseX::Role::Loggable';

    has child => (
        is      => 'ro',
        isa     => 'Child',
        lazy    => 1,
        builder => '_build_child',
    );

    sub _build_child {
        my $self = shift;
        return Child->new( logger => $self->logger );
    }

=head1 ATTRIBUTES

=head2 debug

A boolean for whether you're in debugging mode or not.

Default: B<no>.

Read-only.

=head2 logger_facility

The facility the logger would use. This is useful for syslog.

Default: B<local6>.

=head2 logger_ident

The ident the logger would use. This is useful for syslog.

Default: B<calling object's class name>.

Read-only.

=head2 log_to_file

A boolean that determines if the logger would log to a file.

Default location of the file is in F</tmp>.

Default: B<no>.

Read-only.

=head2 log_to_stdout

A boolean that determines if the logger would log to STDOUT.

Default: B<no>.

=head2 log_to_stderr

A boolean that determines if the logger would log to STDERR.

Default: B<no>.

=head2 log_file

The leaf name for the log file.

Default: B<undef>

=head2 log_path

The path for the log file.

Default: B<undef>

=head2 log_pid

Whether to append the PID to the log filename.

Default: B<yes>

=head2 log_fail_fatal

Whether failure to log is fatal.

Default: B<yes>

=head2 log_muted

Whether only fatals are logged.

Default: B<no>

=head2 log_quiet_fatal

From L<Log::Dispatchouli>:
I<'stderr' or 'stdout' or an arrayref of zero, one, or both fatal log messages
will not be logged to these>.

Default: B<stderr>

=head2 logger

A L<Log::Dispatchouli> object.

=head1 METHODS

All methods here are imported from L<Log::Dispatchouli>. You can read its
documentation to understand them better.

=head2 log

Log a message.

=head2 log_debug

Log a message only if in debug mode.

=head2 log_fatal

Log a message and die.

=head2 set_debug

Set the debug flag.

=head2 clear_debug

Clear the debug flag.

=head2 set_prefix

Set a prefix for all next messages.

=head2 clear_prefix

Clears the prefix for all next messages.

=head2 set_muted

Sets the mute property, which makes only fatal messages logged.

=head2 clear_muted

Clears the mute property.

=head1 DEBUGGING

Occassionally you might encounter the following error:

    no ident specified when using Log::Dispatchouli at Loggable.pm line 117.

The problem does not stem from L<MooseX::Role::Loggable>, but from a builder
calling a logging method before the logger is built. Since L<Moo> and L<Moose>
do not assure order of building attributes, which means that some attributes
might not exist by the time you need them.

This specific error happens when the C<ident> attribute isn't built by the
time a builder runs. In order to avoid it, the attribute which uses the builder
should be made lazy, and then called in the C<BUILD> method. Here is an
example:

    package Stuff;

    use Moose;
    with 'MooseX::Role::Logger';

    has db => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_db',
    }

    sub _build_db {
        my $self = shift;
        $self->log_debug('Building DB');
        ...
    }

    sub BUILD {
        my $self = shift;
        $self->db;
    }

This makes the C<db> attribute non-lazy, but during run-time. This will assure
that all the logging attributes are created B<before> you build the C<db>
attribute and call C<log_debug>.

