# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include nextcloud::nginx
class nextcloud::nginx (
  Stdlib::Fqdn $url,
  Stdlib::Absolutepath $wwwroot,
  Stdlib::Port $http_port,
  Stdlib::Port $https_port,
  Stdlib::Absolutepath $cert_basedir,
  Stdlib::Absolutepath $key,
  Stdlib::Absolutepath $cert,
  Hash $common_headers,
  String::Absolutepath $php_socket,
) {
  class { 'nginx':
    manage_repo                  => false,
    server_tokens                => off,
    server_purge                 => true,
    mime_types                   => {
      'text/javascript'  => 'mjs',
      'application/wasm' => 'wasm',
    },
    mime_types_preserve_defaults => true,
  }

  file { [$wwwroot]:
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
  }
  # HTTP ENDPOINT
  -> nginx::resource::server { "${url}_http":
    listen_port  => $http_port,
    www_root     => $wwwroot,
    server_name  => [$url],
    ssl_redirect => true,
  }

  nginx::resource::server { "${url}_https":
    listen_port        => $https_port,
    www_root           => $wwwroot,
    server_name        => [$url],
    ssl                => true,
    ssl_cert           => $cert,
    ssl_key            => $key,
    add_header         => $common_headers,
    try_files          => ['$uri', '$uri/', '/index.php$request_uri'],
    http2              => on,
    index_files        => ['index.php', 'index.html', '/index.php$request_uri'],
    server_cfg_prepend => {
      client_max_body_size    => '512M',
      client_body_timeout     => '300s',
      client_body_buffer_size => '512k',
      fastcgi_buffers         => '64 4K',
      fastcgi_hide_header     => 'X-Powered-By',
      gzip                    => 'on',
      gzip_vary               => 'on',
      gzip_comp_level         => '4',
      gzip_min_length         => '256',
      gzip_proxied            => 'expired no-cache no-store private no_last_modified no_etag auth',
      gzip_types              => 'application/atom+xml text/javascript application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/wasm application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy',
      include                 => 'mime.types',
      root                    => $wwwroot,
    },
  }

  nginx::resource::location { 'nextcloud_php':
    ssl                 => true,
    ssl_only            => true,
    server              => "${url}_https",
    location            => '~ \.php(?:$|/)',
    rewrite_rules       => ['^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|ocs-provider\/.+|.+\/richdocumentscode(_arm64)?\/proxy) /index.php$request_uri'],
    fastcgi_split_path  => '^(.+?\.php)(/.*)$',
    index_files         => ['index.php', 'index.html', '/index.php$request_uri'],
    proxy               => undef,
    fastcgi             => "unix:${$php_socket}",
    include             => ['fastcgi_params'],
    try_files           => ['$fastcgi_script_name =404'],
    fastcgi_script      => undef,
    fastcgi_param       => {
      'SCRIPT_FILENAME'         => '$document_root$fastcgi_script_name',
      'PATH_INFO'               => '$path_info',
      'HTTPS'                   => 'on',
      'modHeadersAvailable'     => true,
      'front_controller_active' => true,
    },
    location_cfg_append => {
      fastcgi_intercept_errors   => 'on',
      fastcgi_request_buffering  => 'off',
      fastcgi_max_temp_file_size => '0',
      set                        => '$path_info $fastcgi_path_info',
    },
  }

  nginx::resource::location { 'nextcloud_static':
    ssl        => true,
    ssl_only   => true,
    location   => '~ \.(?:css|js|mjs|svg|gif|ico|jpg|png|webp|wasm|tflite|map|ogg|flac)$',
    server     => "${url}_https",
    try_files  => ['$uri', '/index.php$request_uri'],
    add_header => {
      'Cache-Control'                     => 'public, max-age=15778463',
    } + $common_headers,
  }

  # Hide some paths from the client
  [
    '~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)',
    '~ ^/(?:\.|autotest|occ|issue|indie|db_|console)',
  ].each | $loc | {
    nginx::resource::location { $loc:
      ssl         => true,
      ssl_only    => true,
      server      => "${url}_https",
      raw_prepend => 'return 404;',
    }
  }

  nginx::resource::location { '^~ /.well-known':
    ssl         => true,
    ssl_only    => true,
    server      => "${url}_https",
    raw_prepend => [
      'location = /.well-known/carddav { return 301 /remote.php/dav/; }',
      'location = /.well-known/caldav { return 301 /remote.php/dav/; }',
      'location /.well-known/acme-challenge { try_files $uri $uri/ =404; }',
      'location /.well-known/pki-validation { try_files $uri $uri/ =404; }',
      'return 301 /index.php$request_uri;',
    ],
  }

  nginx::resource::location { '/remote':
    ssl         => true,
    ssl_only    => true,
    server      => "${url}_https",
    raw_prepend => [
      'return 301 /remote.php$request_uri;',
    ],
  }

  moe_common::services::balancemember { 'nextcloud':
    options => 'ssl verify none',
  }
}
