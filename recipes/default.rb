if node['user'] && node['user']['id']
  include_recipe "homebrew::default"
  user_name = node['user']['id']
  home_dir = Etc.getpwnam(user_name).dir
else
  include_recipe "homebrewalt::default"
  user_name = node['current_user']
  home_dir = node['etc']['passwd'][user_name]['dir']
end

["homebrew.mxcl.mailhog.plist" ].each do |plist|
  plist_path = File.expand_path(plist, File.join(home_dir, 'Library', 'LaunchAgents'))
  if File.exists?(plist_path)
    log "mailhog plist found at #{plist_path}"
    execute "unload the plist (shuts down the daemon)" do
      command %'launchctl unload -w #{plist_path}'
      user user_name
    end
  else
    log "Did not find plist at #{plist_path} don't try to unload it"
  end
end

[ "#{home_dir}/Library/LaunchAgents" ].each do |dir|
  directory dir do
    owner user_name
    action :create
  end
end

package 'mailhog' do
  action [:install, :upgrade]
end

execute "copy over the plist" do
  command %'cp /usr/local/opt/mailhog/homebrew.mxcl.mailhog.plist ~/Library/LaunchAgents/'
  user user_name
end

execute "start the daemon" do
  command %'launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mailhog.plist'
  user user_name
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
