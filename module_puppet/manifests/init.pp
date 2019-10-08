class webhook_alertnow (
  $webhook    = undef,
) {

  $webhook_puppet_confdir = "/etc/puppetlabs/puppet"

  $webhook_var = {
    webhook     => $webhook
  }

  file { "${webhook_puppet_confdir}/webhook.yaml":
    content     => inline_template('<%= YAML.dump(@webhook_var) %>')
  }

  ini_subsetting { 'puppet.conf/report/true':
    ensure               => present,
    path                 => "${webhook_puppet_confdir}/puppet.conf",
    section              => 'master',
    setting              => 'report',
    subsetting           => 'true',
    subsetting_separator => ',',
  }->

  ini_subsetting { 'puppet.conf/reports/webhook':
    ensure               => present,
    path                 => "${webhook_puppet_confdir}/puppet.conf",
    section              => 'master',
    setting              => 'reports',
    subsetting           => 'webhook_var',
    subsetting_separator => ',',
    require              => File[ "${webhook_puppet_confdir}/webhook.yaml" ],
  }
}
