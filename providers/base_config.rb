action :create do
  definitions = Sensu::Helpers.select_attributes(
    node["sensu"],
    %w[transport rabbitmq redis api]
  )

  config = JSON.parse(citadel["#{node.sensu.citadel.root}/config.json"])
  unless config.empty?
    definitions = Chef::Mixin::DeepMerge.merge(definitions, config)
  end

  service_config = {}

  %w[
    client
    api
    server
  ].each do |service|
    unless node.recipe?("sensu::#{service}_service") ||
        node.recipe?("sensu::enterprise_service")
      next
    end

    service_config_item = JSON.parse(citadel["#{node.sensu.citadel.root}/#{service}_config.json"])
    unless service_config_item.empty?
      service_config = Chef::Mixin::DeepMerge.merge(service_config, service_config_item.to_hash)
    end
  end

  unless service_config.empty?
    definitions = Chef::Mixin::DeepMerge.merge(definitions, service_config)
  end

  f = sensu_json_file ::File.join(node["sensu"]["directory"], "config.json") do
    content Sensu::Helpers.sanitize(definitions)
  end

  new_resource.updated_by_last_action(f.updated_by_last_action?)
end
