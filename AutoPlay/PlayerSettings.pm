package Plugins::AutoPlay::PlayerSettings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Strings qw (string);
use Slim::Display::NoDisplay;
use Slim::Display::Display;


my $prefs = preferences('plugin.autoplay');
my $log   = logger('plugin.autoplay');

sub name {
    return Slim::Web::HTTP::CSRF->protectName('PLUGIN_AUTOPLAY');
}

sub needsClient {
    return 1;
}

sub validFor {
    return 1;
}

sub page {
    return Slim::Web::HTTP::CSRF->protectURI('plugins/AutoPlay/settings/player.html');
}

sub prefs {
    my $class = shift;
    my $client = shift;
    return ($prefs->client($client), qw(enabled));
}

sub handler {
    my ($class, $client, $params) = @_;
    $log->debug("AutoPlay::PlayerSettings->handler() called. " . $client->name());
    Plugins::AutoPlay::Plugin->extSetDefaults($client, 0);
    if ($params->{'saveSettings'}) {
        $params->{'pref_enabled'} = 0 unless defined $params->{'pref_enabled'};
    }

    return $class->SUPER::handler( $client, $params );
}

1;
