# Class: moe_common::services::nextcloud
#
# @param url                    url to run nextcloud under
#
# @param wwwroot                wwwroot folder to install nextcloud to
# @param http_port              http port for webserver
# @param https_port             https port for webserver
#
# @param user                   user the webserver and php-fpm runs as
# @param group                  group the webserver and php-fpm runs as
#
# @param db_type                which database to use, or 'self-managed' for no database at all
#                               currently only postgres is implemented
# @param php_type               what php provider to user
# @param webserver_type         what webserver to user
# @param cache_type             what cach to use
# @param cron_type              what cron type to use
#
# @param database_host          host the database should listen on
# @param database_password      password for postgres database user
# @param database_name          name for postgres database
# @param database_user          name for postgres user
# @param database_port          port the database listens on
#
# @param php_version            version to use for php
# @param php_extra_packages     extra php related packages to install
#
# @param cert_basedir           absolute dirctory for certifcate key and cert vars
# @param key                    absolute path to .key file
# @param cert                   absolute path to .crt file
#
# @param default_config         default config for nextcloud instance
# @param extra_config           extra config (will be deep merged)
# @param common_headers         common headers for webserver
# @param extra_headers          custom extra headers (will be merged with common_headers)
#
class nextcloud (
  Stdlib::Fqdn $url = $facts['networking']['fqdn'],
  Stdlib::Absolutepath $wwwroot = "/var/www/${url}",
  Stdlib::Port $http_port = 80,
  Stdlib::Port $https_port = 443,

  String $user = $url.regsubst('\.', '_', 'G'),
  String $group = $user,

  Enum['postgres', 'self-managed']  $db_type        = 'postgres',
  Enum['fpm', 'self-managed']       $php_type       = 'fpm',
  Enum['nginx', 'self-managed']     $webserver_type = 'nginx',
  Enum['redis', 'self-managed']     $cache_type     = 'redis',
  Enum['systemd', 'self-managed']   $cron_type      = 'systemd',

  # Postgres Parameters
  String $database_host = 'localhost',
  String $database_password = undef,
  String $database_name = $url,
  String $database_user = $user,
  Stdlib::Port $database_port = 5432,

  String $php_version = '8.3',
  Array[String] $php_extra_packages = [],

  Stdlib::Absolutepath $cert_basedir = '/etc/dehydrated',
  Stdlib::Absolutepath $key = "${cert_basedir}/private/${url}.key",
  Stdlib::Absolutepath $cert = "${cert_basedir}/certs/${url}.crt",

  Hash $default_config = {
    'default_phone_region'     => 'AT',
    'default_timezone'         => 'Europe/Vienna',
    'maintenance_window_start' => 1,
  },
  Hash $extra_config = {},

  Hash $common_headers = {
    'Referrer-Policy'                   => 'no-referrer',
    'Strict-Transport-Security'         => 'max-age=15768000; includeSubDomains',
    'X-Content-Type-Options'            => 'nosniff',
    'X-Frame-Options'                   => 'SAMEORIGIN',
    'X-Permitted-Cross-Domain-Policies' => 'none',
    'X-Robots-Tag'                      => 'noindex,nofollow',
    'X-XSS-Protection'                  => '1; mode=block',
  },
  Hash $extra_headers = {}
) {
  $config = deep_merge($default_config, $extra_config)

  # Database
  case $db_type {
    'postgres': {
      class { 'nextcloud::postgres':
        wwwroot           => $wwwroot,
        postgres_host     => $database_host,
        postgres_password => $database_password,
        postgres_database => $database_name,
        postgres_user     => $database_user,
        postgres_port     => $database_port,
      }
    }
    default: {}
  }

  case $php_type {
    'fpm': {
      class { 'nextcloud::php':
        version        => $php_version,
        extra_packages => $php_extra_packages,
        user           => $user,
        group          => $group,
      }
    }
    default: {}
  }

  case $webserver_type {
    'nginx': {
      class { 'nextcloud::nginx':
        url            => $url,
        wwwroot        => $wwwroot,
        http_port      => $http_port,
        https_port     => $https_port,
        key            => $key,
        cert           => $cert,
        common_headers => deep_merge($common_headers, $extra_headers),
        php_socket     => $nextcloud::php::socket,
      }
    }
    default: {}
  }

  file { "${wwwroot}/config/misc.config.php":
    content => epp('nextcloud/config.epp', { 'hash' => $config }),
  }

  case $cache_type {
    'redis': {
      class { 'nextcloud::redis': }
    }
    default: {}
  }

  case $cron_type {
    'systemd': {
      class { 'nextcloud::cron':
        url     => $url,
        wwwroot => $wwwroot,
        user    => $user,
        group   => $group,
      }
    }
    default: {}
  }
}
