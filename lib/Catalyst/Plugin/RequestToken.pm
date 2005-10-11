package Catalyst::Plugin::RequestToken;

use strict;
use NEXT;

require Data::UUID;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::RequestToken - Handling transaction token for Catalyst

=head1 SYNOPSIS

in your application class:

    use Catalyst qw/Session::FastMmap RequestToken FillForm/;
    
    sub input : Local {
        my ( $self, $c ) = @_;

        $c->stash->{template} = 'input.html';
        $c->forward('MyApp::V::TT');
    }

    sub confirm : Local {
        my ( $self, $c ) = @_;

        $c->create_token;
        $c->stash->{template} = 'confirm.html';
        $c->forward('MyApp::V::TT');
        $c->fillform;
    }

    sub complete : Local {
        my ( $self, $c ) = @_;

        if ($c->validate_token) {
            $c->res->output('Complete');
        } else {
            $c->res->output('Invalid Token');
        }
        $c->remove_token;
    }

F<root/input.html> TT template:

    <html>
    <body>
    <form action="confirm" method="post">
    <input type="submit" name="submit" value="confirm"/>
    </form>
    </body>
    </html>

F<root/confirm.html> TT template:

    <html>
    <body>
    <form action="complete" method="post">
    <input type="hidden" name="token"/>
    <input type="submit" name="submit" value="complete"/>
    </form>
    </body>
    </html>

=head1 DESCRIPTION

This plugin create, remove and validate transaction token, to be used for enforcing a single request for some transaction, for exapmle, you can prevent duplicate submits.

Note:
This plugin uses L<Data::UUID> for creating transaction token for each request.  Also this plugin requires a session plugin like L<Catalyst::Plugin::Session::FastMmap> to store server side token.

=head1 EXTENDED METHODS

=over 4

=item setup

You can configure name both of session and request.
Default name is 'token'.

=cut

sub setup {
    my $c = shift;

    $c->config->{token}->{session_name} ||= 'token';
    $c->config->{token}->{request_name} ||= 'token';
	
    return $c->NEXT::setup(@_);
}

=back

=head1 METHODS

=over 4

=item create_token

Create new token.

=cut

sub create_token {
    my $c = shift;

    my $token = new Data::UUID->create_str();
    $c->log->debug("start create token : $token");
    $c->session->{$c->config->{token}->{session_name}} = $token;
    $c->req->param($c->config->{token}->{request_name} => $token);
}

=item remove_token

Remove token from server side session.

=cut

sub remove_token {
    my $c = shift;

    undef $c->session->{$c->config->{token}->{session_name}};
}

=item validate_token

Validate token.

=cut

sub validate_token {
    my $c = shift;

    my $session = $c->session->{$c->config->{token}->{session_name}};
    my $request = $c->req->param($c->config->{token}->{request_name});

    return 0 if (!defined ($session) && !defined ($request));

    if ($session eq $request) {
        return 1;
    } else {
        return 0;
    }
}

=back

=head1 SEE ALSO

L<Catalyst>, L<Data::UUID>, L<Catalyst::Plugin::Session::FastMmap>

=head1 AUTHOR

Hideo Kimura, E<lt>hide@hide-k.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Hideo Kimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__

