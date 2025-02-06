# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @param wwwroot                   wwwroot directory of nextcloud
# @param postgres_host          the address the database is going to bind to 
# @param postgres_password      password for postgres database user
# @param postgres_database      name for postgres database
# @param postgres_user          name for postgres user 
# @param postgres_port          port for postgres
#
# @example
#   include nextcloud::postgres
class nextcloud::postgres (
  Stdlib::Absolutepath $wwwroot,
  String $postgres_password,
  String $postgres_host,
  String $postgres_database,
  String $postgres_user,
  Integer $postgres_port,

) {
  # Setup Database 
  class { 'postgresql::globals':
  } -> class { 'postgresql::server':
  } -> postgresql::server::db { $postgres_database:
    user     => $postgres_user,
    owner    => $postgres_user,
    password => postgresql::postgresql_password($postgres_user, $postgres_password),
  } -> postgresql::server::database_grant { 'nextcloud':
    privilege => 'ALL',
    db        => $postgres_database,
    role      => $postgres_user,
  } -> postgresql::server::database_grant { 'nextcloud_public':
    privilege => 'ALL',
    db        => $postgres_database,
    role      => $postgres_user,
  }

  # Write the config file for Nextcloud

  file { "${wwwroot}/config/db.config.php":
    content => epp('nextcloud/config.epp', { 'hash' => {
          'dbtype'        => 'pgsql',
          'dbname'        => $postgres_database,
          'dbhost'        => "${postgres_host}:${postgres_port}",
          'dbuser'        => $postgres_user,
          'dbpassword'    => $postgres_password,
          'dbtableprefix' => 'oc_',
    } }),
  }
}
