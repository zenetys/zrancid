package zrancid_fscom;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{config_end_on_prompt} = 1;
$zrancid::options{commands}{'show version'}{prefix} = '!Version: ';
$zrancid::options{commands}{'show version'}{subs} = [
    [ '( uptime is )[^,]+(, The current time: ).*', '$1<removed>$2<removed>' ],
    [ '(System start time\s+: ).*', '$1<removed>' ],
    [ '(System uptime\s+: ).*', '$1<removed>' ],
];
$zrancid::options{commands}{'show running-config'}{subs} = [
    [ '^(username [^ ]+ [^ ]+ [^ ]+ ).*', '!$1<removed>', ],
];

return 1;
