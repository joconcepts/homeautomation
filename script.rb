#!/usr/bin/env ruby

require 'socket'

group = ARGV[0]
who = ARGV[1]

def send_udp server: "192.168.2.190", command: nil
  udp = UDPSocket.new
  udp.send("#{command}\n", 0, server, 8888)
end

def rc_cmd type: nil, group: nil, id: nil
  send_udp command: "#{type} #{group} #{id}"
end

def wol mac: nil
  addr = ['<broadcast>', 9]
  udp = UDPSocket.new
  udp.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
  data = "\xFF\xFF\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
  arr = mac.split(':')
  16.times do |i|
    data<< arr[0].hex.chr+arr[1].hex.chr+arr[2].hex.chr+arr[3].hex.chr+arr[4].hex.chr+arr[5].hex.chr
  end
  udp.send(data, 0, addr[0], addr[1])
end

def reachable ip: nil
  system "ping -c1 -w1 #{ip} > /dev/null"
end

begin
  if group == "rc"
    cmd = ARGV[2]
    raise "command #{cmd} not found!" unless ["on", "off"].include? cmd
    targets = [ 
      {name: "backup", group: "10000", id: "10000"},
      {name: "lampe", group: "10000", id: "01000"},
    ]
    target = targets.find{|x| x[:name] == who}
    raise "target '#{who}' not found" if target.nil?

    rc_cmd type: "#{cmd}", group: target[:group], id: target[:id]
    puts "rc cmd '#{cmd}' for '#{who}' done"
  elsif group == "wol"
    targets = [ {name: "nas", mac: "08:60:6e:87:ab:13"} ]
    target = targets.find{|x| x[:name] == who}
    raise "target '#{who}' not found" if target.nil?

    wol mac: target[:mac]
    puts "wakeup on '#{who}' done"
  elsif group == "ping"
    targets = [ {name: "nas", ip: "192.168.2.60"} ]
    target = targets.find{|x| x[:name] == who}
    raise "target '#{who}' not found" if target.nil?

    if reachable ip: target[:ip]
      puts "#{who} is reachable"
    else
      puts "#{who} is not reachable"
    end
  elsif group == "system"
    cmd = ARGV[2]
    commands = [
      { name: "reboot", command: "reboot" },
      { name: "shutdown", command: "halt -p" },
      { name: "load", command: "cat /proc/loadavg" },
      { name: "smb", command: "smbstatus" },
      { name: "mem", command: "free -m" },
      { name: "pacman_refresh", command: "pacman -Syy" },
      { name: "pacman_count", command: "pacman -Qu | wc -l" },
      { name: "disk_rip", command: "nohup /root/scripts/disk_rip.sh > /dev/null 2>/dev/null < /dev/null &" }
    ]
    command = commands.find{|x| x[:name] == cmd}
    raise "command '#{cmd}' not found!" if command.nil?

    targets = [ {name: "nas", ip: "192.168.2.60"} ]
    target = targets.find{|x| x[:name] == who}
    raise "target '#{who}' not found" if target.nil?

    ssh = `ssh root@#{target[:ip]} '#{command[:command]}'`
    puts "system command '#{cmd}' on '#{who}':\n#{ssh}"
  else
    raise "command '#{cmd}' not found"
  end
rescue => e
  puts "error: #{e}"
end
