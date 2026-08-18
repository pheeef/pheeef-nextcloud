# @summary Installs php for usage with nextcloud
#
# @param version
#   php version to use
# @param extra_packages
#   extra php related packages to install
# @param user
#   user php runs as
# @param group
#   group php runs as
# @param socket
#   php pool unix socket
# @param chdir
#   php chdir
# @param open_basedir
#   open basedir paths
# @param  opcache_interned_strings_buffer 
#   Size of interned strings buffer. 16 by default.
#
# @example
#   include nextcloud::php
class nextcloud::php (
  String $version,
  Array[String] $extra_packages,
  String $user,
  String $group,
  String $socket = "/run/php/php${version}-fpm-${user}.sock",
  Stdlib::AbsolutePath $chdir = '/var/www',
  Array[Stdlib::Absolutepath] $open_basedir = [$chdir, '/tmp'],
  Integer $opcache_interned_strings_buffer = 16,
) {
  case $nextcloud::php_type {
    'fpm': {
      $_php_version = "php${version}"

      class { 'php::globals':
        php_version => $version,
        config_root => "/etc/php/${version}",
      } -> class { 'php':
        manage_repos => false,
        fpm_user     => $user,
        fpm_group    => $group,
        # get rid of the default pool
        fpm_pools    => {},
      } -> class { 'php::global':
        settings     => {
          'memory_limit'   => '512M',
          'apc.enable_cli' => '1',
        },
      }

      php::fpm::pool { $user:
        listen          => $socket,
        listen_owner    => $user,
        listen_group    => 'www-data',
        env             => ['PATH'],
        chdir           => $chdir,
        php_admin_value => {
          'memory_limit'                    => '512M',
          'open_basedir'                    => "${$open_basedir.join(':')}",
          'opcache.interned_strings_buffer' => $opcache_interned_strings_buffer,
        },
      }

      ensure_packages([
          $_php_version,
          "${_php_version}-apcu",
          "${_php_version}-bcmath",
          "${_php_version}-common",
          "${_php_version}-curl",
          "${_php_version}-gd",
          "${_php_version}-gmp",
          "${_php_version}-imagick",
          "${_php_version}-intl",
          "${_php_version}-mbstring",
          "${_php_version}-pgsql",
          "${_php_version}-redis",
          "${_php_version}-xml",
          "${_php_version}-zip",
          'libmagickcore*-extra',
      ] + $extra_packages)
    }
    'self-managed': {}
    default: {
      fail('nextcloud/php.pp: This php_type is not implemented')
    }
  }
}
