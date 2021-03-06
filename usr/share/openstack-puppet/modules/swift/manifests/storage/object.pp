class swift::storage::object(
  $manage_service = true,
  $enabled        = true,
  $package_ensure = 'present'
) {
  swift::storage::generic { 'object':
    manage_service => $manage_service,
    enabled        => $enabled,
    package_ensure => $package_ensure
  }

  include swift::params

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'swift-object-updater':
    ensure    => $service_ensure,
    name      => $::swift::params::object_updater_service_name,
    enable    => $enabled,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-object'],
  }

  service { 'swift-object-auditor':
    ensure    => $service_ensure,
    name      => $::swift::params::object_auditor_service_name,
    enable    => $enabled,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-object'],
  }
}
