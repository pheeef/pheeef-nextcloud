# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include nextcloud::cron
class nextcloud::cron (
  Stdlib::Fqdn $url,
  Stdlib::Absolutepath $wwwroot,
  String $user,
  String $group,
) {
  systemd::manage_unit { "nc_${url}_cron.service":
    unit_entry    => {
      'Description' => "Systemd service to run Nextlcoud cron for: ${url}",
    },
    service_entry => {
      'Type'             => 'oneshot',
      'User'             => $user,
      'Group'            => $group,
      'WorkingDirectory' => $wwwroot,
      'ExecStart'        => "/usr/bin/php8.3 --define apc.enable_cli=1 ${wwwroot}/cron.php",
      'Restart'          => 'on-failure',
      'RestartSec'       => '5',
    },
    active        => true,
  }
}
