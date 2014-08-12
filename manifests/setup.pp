define webproject::setup (
  $hostname = undef,
  $dir = undef,
  $database = undef,
  $sql_dump = undef,
  $ssl = undef,
  $php_version = undef,
  $php_extensions = undef,
  $db_charset = undef,
  $db_collate = undef
) {
  require 'webproject'

  if ! $vhost_name {
    $vhostname = $title
  } else {
    $vhostname = $hostname
  }

  if ! $dir {
    $project_dir = "/var/www/${title}"
  } else {
    $project_dir = $dir
  }

  #Set vhost settings and install different php version if enabled
  if $php_version == undef or $php_version == 'system' {
    $vhost_options = ['Indexes', 'FollowSymLinks', 'MultiViews']
    $vhost_custom_fragment = undef
  } else {
    if versioncmp($php_version, '5.3') < 0 {
      $build_prameters = '+soap -- --enable-fastcgi --enable-spl --with-mysqli=/usr/bin/mysql_config --with-mysql=/usr/bin/mysql_config'
    } else {
      $build_prameters = '+iconv +mysql +openssl +soap +cgi'
    }

    if ! defined (Phpbrew::Install[$php_version]) {
      #Install php version
      phpbrew::install { $php_version:
        build_prameters => $build_prameters,
        php_inis => [
          '/etc/php5/mods-available/zzzz_custom.ini'
        ]
      }

      #Install php extensions
      each($php_extensions) |$php_extension| {
        case $php_extension {
          'zend', 'ioncube': {
            if ! defined (Phpdecoder::Install["${php_version}-${php_extension}"]) {
              phpdecoder::install { "${php_version}-${php_extension}":
                type        => $php_extension,
                modules_dir => "/opt/phpbrew/php/php-${php_version}/lib/php/share/",
                php_ini_dir => "/opt/phpbrew/php/php-${php_version}/var/db/",
                php_version => $php_version,
                require     => Phpbrew::Install[$php_version]
              }
            }
          }
          default: {
            phpbrew::extension { "${$php_extension}-${php_version}":
              extension => $php_extension,
              php_version => $php_version,
              require => Phpbrew::Install[$php_version]
            }
          }
        }

      }
    }

    $vhost_options = ['Indexes', 'FollowSymLinks', 'MultiViews', '+ExecCGI']
    $vhost_custom_fragment = "  <IfModule mod_fcgid.c>\n    AddHandler fcgid-script .php\n    FCGIWrapper /usr/lib/cgi-bin/fcgiwrapper-${php_version}.sh .php\n  </IfModule>\n\n"
  }

  #Setup vhost
  apache::vhost { $name:
    servername      => $name,
    docroot         => $project_dir,
    port            => 80,
    custom_fragment => $vhost_custom_fragment,
    directories     => [{
      path           => $project_dir,
      options        => $vhost_options,
      allow_override => ['All'],
    }]
  }

  #Add ssl vhost
  if $ssl == true {
    apache::vhost { "${name}_ssl":
      servername      => $name,
      docroot         => $project_dir,
      port            => 443,
      ssl             => true,
      custom_fragment => $vhost_custom_fragment,
      directories     => [{
        path           => $project_dir,
        options        => $vhost_options,
        allow_override => ['All'],
      }]
    }
  }

  #Setup database
  if $database {
    if $db_charset {
      $charset = $db_charset
    } else {
      $charset = 'utf8'
    }

    if $db_collate {
      $collate = $db_collate
    } else {
      $collate = 'utf8_general_ci'
    }

    if $sql_dump {
        $sql_dump_path = "${project_dir}/_project/${sql_dump}"
    } else {
        $sql_dump_path = undef
    }

    mysql::db { $name:
      user     => $name,
      password => $name,
      charset  => $charset,
      collate  => $collate,
      host     => 'localhost',
      grant    => ['ALL'],
      sql      => $sql_dump_path
    }
  }

}