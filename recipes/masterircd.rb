#####################
#
# IRCD Install
#
#
#
#####################

user "ircd" do
  home "/home/ircd"
end

%w{nmap gcc make}.each do |pkg|
  package pkg do
    action :install
  end
end

bash "group_install" do
  user "root"
  command "yum groupinstall -y 'development tools'"
end

cookbook_file "/home/ircd/Unreal.tar.gz" do
  source "Unreal3.2.10.2.tar.gz"
  owner "root"
  group "root"
  mode  "0644"
end

bash "install_program" do
  user "ircd"
  cwd  "/home/ircd"
  code <<-EOH
  tar -xvf Unreal.tar.gz
  /bin/mv /home/ircd/#{node[:unrealircd][:version]}/* .
  /bin/bash ./configure --with-showlistmodes --with-listen=5 --with-dpath=/home/ircd --with-spath=/home/ircd/src/ircd --with-nick-history=2000 --with-sendq=3000000 --with-bufferpool=18 --with-permissions=0600 --with-fd-setsize=1024 --enable-dynamic-linking
  /usr/bin/make
  /bin//touch ircd.rules
  /bin/touch ircd.motd
  /bin/touch ircd.log
  EOH
end

cookbook_file "/home/ircd/services.conf" do
  source "services.conf.erb"
  owner "root"
  group "root"
  mode  "0644"
end

template "/home/ircd/me.conf" do
  source "masterme.conf.erb"
  owner "root"
  group "root"
  mode  "0644"
end

template "/home/ircd/links.conf" do
  source "masterlinks.conf.erb"
  owner "root"
  group "root"
  mode  "0644"
end

cookbook_file "/home/ircd/unrealircd.conf" do
  source "unrealircd.conf.erb"
  owner "root"
  group "root"
  mode  "0644"
end

execute "wget_confs" do
	command "/bin/mv #{node[:unrealircd][:ip]}/ircd/* ."
	command "/bin/rm -rf #{node[:unrealircd][:ip]}/"
	command "/bin/chown ircd:ircd *"
end

bash "set_iptables" do
  user "root"
  code <<-EOF
    /sbin/iptables -F
    /sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    /sbin/iptables -iptables -A INPUT -p tcp --dport 6667 -j ACCEPT
    /sbin/iptables -iptables -A INPUT -p tcp --dport 8067 -j ACCEPT
    /sbin/iptables -iptables -A INPUT -p tcp --dport 7029 -j ACCEPT
    /sbin/iptables -iptables -P INPUT DROP
    /sbin/iptables -iptables -P FORWARD DROP
    /sbin/iptables -iptables -P OUTPUT ACCEPT
    /sbin/iptables -iptables -A INPUT -i lo -j ACCEPT
    /sbin/iptables -iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    /sbin/service iptables save
    /sbin/service iptables restart
    EOF
end

#execute "unrealircd_start" do
#  command "/bin/bash /home/ircd/unreal start"
#end
