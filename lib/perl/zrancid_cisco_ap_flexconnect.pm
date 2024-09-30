package zrancid_cisco_ap_flexconnect;

sub import { return 0; }
sub init { return 0; }

$C = '!';

$zrancid::options{comment} = $C;
$zrancid::options{config_end_on_prompt} = 1;
$zrancid::options{commands}{'show version'}{prefix} = "${C}Version: ";
$zrancid::options{commands}{'show version'}{skip_until} = 'Cisco AP Software';
$zrancid::options{commands}{'show version'}{subs} = [
    [ '(?i:(uptime is\s+))[0-9].*', '$1<removed>' ],
];
$zrancid::options{commands}{'show flexconnect status'}{prefix} = "${C}FlexConnect: ";
$zrancid::options{commands}{'show flexconnect wlan'}{prefix} = "${C}FlexConnect: ";
$zrancid::options{commands}{'show flexconnect wlan vlan'}{prefix} = "${C}FlexConnect: ";

return 1;
