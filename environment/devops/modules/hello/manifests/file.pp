define hello::file (
  $ensure  = present,
  $owner   = 'root',
  $group   = 'root',
  $mode    = '0644',
  $content = undef,
  $source  = undef,
) {
 file { '/var/www/www.devops.com/hello.php':
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    source  => $source,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }
}