package zrancid_aruba_ap;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{comment} = '#';
$zrancid::options{config_end_on_prompt} = 1;
$zrancid::options{commands}{'show version'}{prefix} = '#Version: ';
$zrancid::options{commands}{'show version'}{subs} = [
    [ '(?i:(uptime is\s+))[0-9].*', '$1<removed>' ],
];
$zrancid::options{commands}{'show running-config'}{subs} = [
    [ '^(\s*)(facebook [0-9]+ )[a-f0-9]+', '$1#$2<removed>' ],
    [ '^(\s*)(user guest )[a-f0-9]+ portal', '$1#$2<removed>' ],
    [ '^(\s*)(wpa-passphrase )[a-f0-9]+', '$1#$2<removed>' ],
    [ '^(\s*)(key )[a-f0-9]+', '$1#$2<removed>' ],
    [ '^(\s*)(snmp-server community )[a-f0-9]+', '$1#$2<removed>' ],
];

return 1;
