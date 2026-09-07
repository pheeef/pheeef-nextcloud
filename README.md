# pheeef-nextcloud

The module configures the webserver, database, php and redis for a nextcloud installation. 

## Description

Briefly tell users why they might want to use your module. Explain what your
module does and what kind of problems users can solve with it.

This should be a fairly short description helps the user decide if your module
is what they want.

## Setup

### Beginning with nextcloud

The very basic steps needed for a user to get the module up and running. This
can include setup steps, if necessary, or it can be an example of the most basic
use of the module.

## Usage

### Minimal Example

```puppet
nextcloud {
    url => 'cloud.example.com'
}
```

## Limitations

The class is designed to be pluggable, so db_type, php_type, webserver_type, cache_type and cron_type are all configurable to the technology you want to use. 

Currenlty the follow technologies are implemented:

database:      'postgres'
php:           'fpm'
webserver:     'nginx'
cache:         'redis'
cron:          'systemd'


## Development

Issues and Pull Requests are welcome, AI usage is *strongly* discouraged.