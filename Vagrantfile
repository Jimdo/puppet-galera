Vagrant::Config.run do |config|

  config.vm.provision :puppet, :module_path => "modules" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"
  end

  config.vm.define :db01 do |config|
    config.vm.box = "squeeze64"
    config.vm.network "33.33.33.11"
    config.vm.host_name = "db01.domain.test"
  end

  config.vm.define :db02 do |config|
    config.vm.box = "squeeze64"
    config.vm.network "33.33.33.12"
    config.vm.host_name = "db02.domain.test"
  end

  config.vm.define :db03 do |config|
    config.vm.box = "squeeze64"
    config.vm.network "33.33.33.13"
    config.vm.host_name = "db03.domain.test"
  end
end
