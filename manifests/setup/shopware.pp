define webproject::setup::shopware (
  $hostname = undef,
  $dir = undef,
  $database = undef,
  $sql_dump = undef,
  $ssl = undef,
  $php_version = undef,
  $php_extensions = undef,
  $db_charset = undef,
  $db_collate = undef,
  $project_config = ''
) {
  if $ssl == undef {
    $ssl_enabled = true
  }

  if $database == undef {
    $create_database = true
  }

  if $php_extensions == undef {
    $in_php_extensions = ['xdebug']
  } else {
    $in_php_extensions = $php_extensions
  }

  if $db_charset {
    $charset = $db_charset
  } else {
    $charset = 'latin1'
  }

  if $db_collate {
    $collate = $db_collate
  } else {
    $collate = 'latin1_swedish_ci'
  }

  webproject::setup { $title:
    hostname => $hostname,
    dir => $dir,
    database => $create_database,
    sql_dump => $sql_dump,
    ssl => $ssl_enabled,
    php_version => $in_php_version,
    php_extensions => $in_php_extensions,
    db_charset => $charset,
    db_collate => $collate,
  }

  if ! $dir {
    $project_dir = "/var/www/${title}"
  } else {
    $project_dir = $dir
  }

  file { "${project_dir}/config.php":
    ensure => present,
    content => template("webproject/shopware-config.erb"),
  }
}