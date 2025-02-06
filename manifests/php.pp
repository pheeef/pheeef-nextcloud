# @summary Installs php for usage with nextcloud
#
# @param version            php version to user
# @param extra_packages     extra php related packages to install
# @param user               user php runs as
# @param group              group php runs as
#
# @example
#   include nextcloud::php
class nextcloud::php (
  String $version,
  Array[String] $extra_packages,
  String $user,
  String $group,
) {
  $_php_version = "php${version}"
  $_socket = "/run/php/php${version}-fpm-nextcloud.sock"

  class { 'php::globals':
    php_version => $version,
    config_root => "/etc/php/${version}",
  } -> class { 'php':
    manage_repos => false,
    fpm_user     => $user,
    fpm_group    => $group,
  } -> class { 'php::global':
    settings     => {
      'menory_limit'                    => '512M',
      'apc.enable_cli'                  => '1',
      'opcache.interned_strings_buffer' => '16',
    },
  }

  php::fpm::pool { 'nextcloud':
    listen       => $_socket,
    listen_owner => $user,
    listen_group => $group,
    env          => ['PATH'],
  }

  ensure_packages([
      $_php_version,
      "${_php_version}-common",
      "${_php_version}-curl",
      "${_php_version}-gd",
      "${_php_version}-mbstring",
      "${_php_version}-xml",
      "${_php_version}-zip",
      "${_php_version}-pgsql",
      "${_php_version}-redis",
      "${_php_version}-apcu",
      "${_php_version}-bcmath",
      "${_php_version}-gmp",
      "${_php_version}-intl",
      "${_php_version}-imagick",
      'libmagickcore-6.q16-6-extra',
  ] + $extra_packages)
}
