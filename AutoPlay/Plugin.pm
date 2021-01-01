package Plugins::AutoPlay::Plugin;

#
# LMS-AutoPlay
#
# Copyright (c) 2019-2021 Craig Drummond <craig.p.drummond@gmail.com>
#
# MIT license.
#


use strict;

use base qw(Slim::Plugin::Base);

use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;
use Slim::Utils::Strings qw(string);

use Plugins::AutoPlay::PlayerSettings;

my $log = Slim::Utils::Log->addLogCategory({
    'category' => 'plugin.autoplay',
    'defaultLevel' => 'ERROR',
    'description' => 'PLUGIN_AUTOPLAY'
});

my $prefs = preferences('plugin.autoplay');
my $sPrefs = preferences('server');
my $initialTime = time();

sub getDisplayName {
    return 'PLUGIN_AUTOPLAY';
}

my @browseMenuChoices = (
    'PLUGIN_AUTOPLAY_ENABLE',
);
my %menuSelection;

my %defaults = (
    'enabled' => 0,
);

sub initPlugin {
    my $class = shift;
    $class->SUPER::initPlugin(@_);
    Plugins::AutoPlay::PlayerSettings->new();
    Slim::Control::Request::subscribe(\&clientPower, [['power']]);
    Slim::Control::Request::subscribe(\&clientNew, [['client'], ['new']]);
    Slim::Control::Request::subscribe(\&clientReconnect, [['client'], ['reconnect']]);
}

sub shutdownPlugin {
    Slim::Control::Request::unsubscribe(\&clientPower);
    Slim::Control::Request::unsubscribe(\&clientNew);
    Slim::Control::Request::unsubscribe(\&clientConnect);
}

sub startPlayback {
    my $request = shift;
    my $client = $request->client();
    return unless defined $client;

    my $cPrefs = $prefs->client($client);
    return unless ($cPrefs->get('enabled'));
    return unless $client->power();

    $log->debug("Starting playback on " . $client->name());
    $client->execute(["play"]);
}

sub clientPower {
    startPlayback(shift);
}

sub clientNew {
    # Only react to connect messages if server was started more than 30seconds ago!  
    if ((time() - $initialTime) > 30) {
        startPlayback(shift);
    }
}

sub clientReconnect {
    startPlayback(shift);
}
   
sub lines {
    my $client = shift;
    my ($line1, $line2, $overlay2);
    my $flag;

    $line1 = $client->string('PLUGIN_AUTOPLAY') . " (" . ($menuSelection{$client}+1) . " " . $client->string('OF') . " " . ($#browseMenuChoices + 1) . ")";
    $line2 = $client->string($browseMenuChoices[$menuSelection{$client}]);

    # Add a checkbox
    if ($browseMenuChoices[$menuSelection{$client}] eq 'PLUGIN_AUTOPLAY_ENABLE') {
        $flag  = $prefs->client($client)->get('enabled');
        $overlay2 = Slim::Buttons::Common::checkBoxOverlay($client, $flag);
    }

    return {
        'line'    => [ $line1, $line2],
        'overlay' => [undef, $overlay2],
    };
}

my %functions = (
    'up' => sub  {
        my $client = shift;
        my $newposition = Slim::Buttons::Common::scroll($client, -1, ($#browseMenuChoices + 1), $menuSelection{$client});
        $menuSelection{$client} =$newposition;
        $client->update();
    },
    'down' => sub  {
        my $client = shift;
        my $newposition = Slim::Buttons::Common::scroll($client, +1, ($#browseMenuChoices + 1), $menuSelection{$client});
        $menuSelection{$client} =$newposition;
        $client->update();
    },
    'right' => sub {
        my $client = shift;
        my $cPrefs = $prefs->client($client);
        my $selection = $menuSelection{$client};

        if ($browseMenuChoices[$selection] eq 'PLUGIN_AUTOPLAY_ENABLE') {
            my $enabled = $cPrefs->get('enabled') || 0;
            $client->showBriefly({ 'line1' => string('PLUGIN_AUTOPLAY'), 
                                   'line2' => string($enabled ? 'PLUGIN_AUTOPLAY_DISABLING' : 'PLUGIN_AUTOPLAY_ENABLING') });
            $cPrefs->set('enabled', ($enabled ? 0 : 1));
        }
    },
    'left' => sub {
        my $client = shift;
        Slim::Buttons::Common::popModeRight($client);
    },
);

sub setDefaults {
    my $client = shift;
    my $force = shift;
    my $clientPrefs = $prefs->client($client);
    $log->debug("Checking defaults for " . $client->name() . " Forcing: " . $force);
    foreach my $key (keys %defaults) {
        if (!defined($clientPrefs->get($key)) || $force) {
            $log->debug("Setting default value for $key: " . $defaults{$key});
            $clientPrefs->set($key, $defaults{$key});
        }
    }
}

sub getFunctions { return \%functions;}
        
1;

