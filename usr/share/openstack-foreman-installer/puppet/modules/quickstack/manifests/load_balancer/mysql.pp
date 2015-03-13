class quickstack::load_balancer::mysql (
  $frontend_pub_host,
  $backend_server_names,
  $backend_server_addrs,
  $public_port = '3306',
  $public_mode = 'tcp',
  $log = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'mysql':
    addr                 => [ $frontend_pub_host ],
    port                 => "$public_port",
    mode                 => "$public_mode",
    listen_options       => { 'option'     => [ "$log" ], },
    member_options       => [ 'check inter 1s' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
