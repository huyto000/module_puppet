require 'puppet'
require 'net/https'
require 'uri'
require 'json'

Puppet::Reports.register_report(:webhook) do
  def process
    configdir = File.dirname(Puppet.settings[:config])
    configfile = File.join(configdir, 'webhook.yaml')
    raise(Puppet::ParseError, "AlertNow report config file #{configfile} not readable") unless File.file?(configfile)

    @config = YAML.load_file(configfile)

    @config["statuses"] ||= "changed,failed"
    statuses = @config["statuses"].split(",")

    # Kernel#` should always run on puppetserver host
    puppetmaster_hostname = `hostname`.chomp
    pretxt = self.status
    provisioned_host = self.host
    environment = self.environment
    time = Time.now

    if statuses.include?(self.status)
	pretxt = "#{pretxt}"
	
      payload = make_payload(pretxt, puppetmaster_hostname, provisioned_host, environment)
	_payload = payload.merge("time_triggered" => time.inspect)
        post_to_webhook(URI.parse(@config["webhook"]), _payload, @config['http_proxy'])
        Puppet.notice("Notification sent to AlertNow Producer")
     
    end
  end

  private
  def make_payload(pretxt, puppetmaster_hostname, provisioned_host, environment)
    {
      "attachments" => [{
	  "status"	=> pretxt,
          "puppet_master_host" => puppetmaster_hostname,
          "provisioned_host"    => provisioned_host,
	  "environment"		=> environment
        }],
    }
  end

  def post_to_webhook(uri, payload, proxy_address)
    if proxy_address
      proxy_uri = URI(proxy_address)
      https = Net::HTTP.new(uri.host, 443, proxy_uri.hostname, proxy_uri.port)
    else
      https = Net::HTTP.new(uri.host, 443)
    end
    https.use_ssl = true
    r = https.start do |https|
      https.post(uri.path, payload.to_json)
    end
    case r
    when Net::HTTPSuccess
      return
    else
      Puppet.err("Notification from Puppetmaster to AlertNow failed with #{r}")
    end
  end
end
