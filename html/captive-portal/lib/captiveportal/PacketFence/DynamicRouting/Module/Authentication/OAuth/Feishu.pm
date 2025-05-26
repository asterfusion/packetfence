package captiveportal::PacketFence::DynamicRouting::Module::Authentication::OAuth::Feishu;

=head1 NAME

captiveportal::DynamicRouting::Module::Authentication::OAuth::Feishu

=head1 DESCRIPTION

Feishu OAuth module

=cut
use pf::log;
use Moose;
use LWP::UserAgent;
use JSON;
use HTTP::Request;
use pf::error qw(is_error is_success);
extends 'captiveportal::DynamicRouting::Module::Authentication::OAuth';

has '+source' => (isa => 'pf::Authentication::Source::FeishuSource');

has '+token_scheme' => (default => "auth-header:token");

=head2 _extract_username_from_response

Create a generic username if no e-mail is in the response

=cut

sub _extract_username_from_response {
    my ($self, $info) = @_;
    # get_logger->error(sub { use Data::Dumper; "_extract_username_from_response info ".Dumper($info)});
    return $info->{email} || $info->{name};
}

=head2 redirect_to_provider

Redirects to the OAuth provider and registers the attempt in the authlog

=cut

sub redirect_to_provider {
    my ($self) = @_;
    pf::auth_log::record_oauth_attempt($self->source->id, $self->current_mac, $self->app->profile->name);
    my $url = $self->source->{'site'} . $self->source->{'authorize_path'} .
             "?client_id=" . $self->source->{'client_id'} .
             "&redirect_uri=" . $self->source->{'redirect_url'} .
             "&scope=" . $self->source->{'scope'} .
             "&state=pf";
    $self->app->redirect($url);
}

=head2 get_token

Get the OAuth2 token

=cut

sub get_token {
    my ($self) = @_;
    
    my $code = $self->app->request->parameters->{code};
    
    my $token;
    eval {
        my $ua = LWP::UserAgent->new;
        my $data = {
            grant_type  => "authorization_code",
            client_id   => $self->source->{'client_id'},
            client_secret => $self->source->{'client_secret'},
            code => $code,
            redirect_uri  => $self->source->{'redirect_url'}
        };
        my $response = $ua->post($self->source->{'site'} . $self->source->{'access_token_path'},
            'Content-Type' => 'application/json',
            Content        => encode_json($data)
        );

        if ($response->is_success) {
            my $content = $response->decoded_content;
            my $rep_data = decode_json($content);
            $token = $rep_data->{access_token};
        }
        else {
            return;
        }

    };
    if ($@) {
        get_logger->warn("OAuth2: failed to receive the token from the provider: $@");
        pf::auth_log::change_record_status($self->source->id, $self->current_mac, $pf::auth_log::FAILED, $self->app->profile->name);
        $self->app->flash->{error} = "OAuth2 Error: Failed to get the token";
        $self->landing();
        return;
    }
    return $token;
}

=head2 handle_callback

Handle the callback from the OAuth2 provider and fetch the protected resource

=cut

sub handle_callback {
    my ($self) = @_;

    my $token = $self->get_token();
    return unless($token);

    # request a JSON response
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new('GET', $self->source->{'protected_resource_url'});
    $request->header('Authorization' => "Bearer $token");
    $request->header('Content-Type' => 'application/json');
    my $response = $ua->request($request);

    if ($response->is_success) {
        my $content = $response->decoded_content;
        my $data = decode_json($content);
        
        if ($data->{code} == 0) {
            my $info = $data->{data};
            my $pid = $self->_extract_username_from_response($info);
            
            $self->username($pid);
            if($info->{email}) { 
                $self->app->session->{email} = $info->{email}; 
            }

            get_logger->info("OAuth2 successfull for username ".$self->username);
            $self->source->lookup_from_provider_info($self->username, $info);
            
            pf::auth_log::record_completed_oauth($self->source->id, $self->current_mac, $pid, $pf::auth_log::COMPLETED, $self->app->profile->name);

            $self->update_person_from_fields();

            $self->done();
        } else {
            get_logger->info("OAuth2: failed to validate the token, redireting to login page.");
            get_logger->debug(sub { use Data::Dumper; "OAuth2 failed response : ".Dumper($response) });
            pf::auth_log::change_record_status($self->source->id, $self->current_mac, $pf::auth_log::FAILED, $self->app->profile->name);
            $self->app->flash->{error} = "OAuth2 Error: Failed to validate the token, please retry";
            $self->landing();
            return;
        }
    }
    else {
        get_logger->info("OAuth2: failed to validate the token, redireting to login page.");
        get_logger->debug(sub { use Data::Dumper; "OAuth2 failed response : ".Dumper($response) });
        pf::auth_log::change_record_status($self->source->id, $self->current_mac, $pf::auth_log::FAILED, $self->app->profile->name);
        $self->app->flash->{error} = "OAuth2 Error: Failed to validate the token, please retry";
        $self->landing();
        return;
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2024 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};

1;

