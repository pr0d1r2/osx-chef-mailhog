include_recipe "homebrewalt::default"

["homebrew.mxcl.mailhog.plist" ].each do |plist|
  plist_path = File.expand_path(plist, File.join('~', 'Library', 'LaunchAgents'))
  if File.exists?(plist_path)
    log "mailhog plist found at #{plist_path}"
    execute "unload the plist (shuts down the daemon)" do
      command %'launchctl unload -w #{plist_path}'
      user node['current_user']
    end
  else
    log "Did not find plist at #{plist_path} don't try to unload it"
  end
end

[ "/Users/#{node['current_user']}/Library/LaunchAgents" ].each do |dir|
  directory dir do
    owner node['current_user']
    action :create
  end
end

package "homebrew/mailhog" do
  action [:install, :upgrade]
end

execute "copy over the plist" do
  command %'cp /usr/local/opt/mailhog/homebrew.mxcl.mailhog.plist ~/Library/LaunchAgents/'
  user node['current_user']
end

execute "start the daemon" do
  command %'launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mailhog.plist'
  user node['current_user']
end

ruby_block "Checking that mailhog is running" do
  block do
    Timeout::timeout(60) do
      until system('ps -ax | grep /usr/local/opt/mailhog/bin/MailHog | grep -v grep | wc -l | grep -q 1')
        sleep 1
      end
    end
  end
end
