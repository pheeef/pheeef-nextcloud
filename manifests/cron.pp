# @summary manages the nextcloud-cron task with a systemd-timer
#
# @param wwwroot
#   the webroot of the instance
#
# @param url
#   nextcloud url used as an identifier
#
# @param user
#   unix user to exceute the cron-task / commonly also the user that runs the php-pool
#
# @param group
#   unix group to execute the cron-task / see above
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
