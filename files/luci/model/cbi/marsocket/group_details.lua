-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local m, s, o
local marsocket = "marsocket"
local uci = luci.model.uci.cursor()
local sid = arg[1]
local groups_alias_set = {}
local port_set = {}
local nodes = {}
local nodelist = {}

uci:foreach(marsocket, "nodes", function(s)
	local count = #nodes --设置下标idx从0开始
	nodes[#nodes+1] = { idx = count, alias = s.alias }
end)
for _, v in ipairs(uci:get_list(marsocket, sid, "nodelist")) do
	local n = nodes[v+1]
	if n then
		local count = #nodelist+1  --设置下标idx从1开始
		nodelist[count] = { idx = count, alias = n.alias }
	end
end


m = Map(marsocket, title, description)
m.template = "marsocket/group_details"
m.redirect = luci.dispatcher.build_url("admin/services/marsocket/groups")
m.sid = sid
if m.uci:get(marsocket, sid) ~= "groups" then
	luci.http.redirect(m.redirect) 
	return
end

function m:check_port_duplicate(port, alias, option, title)
	local ret = true
	local p = port_set[port]
	if p then
		--不是自己，就返回false
		if p.section ~= sid or p.option ~= option then
			return false, p
		else
			return true
		end
	end

	for k, v in pairs(port_set) do
		if v.section == sid and v.option == option and v.port ~= port then
			port_set[k] = nil				
			break
		end
	end
	port_set[port] = { section = sid, alias = alias, port = port, option = option, title = title }
	return true
end



s = m:section(NamedSection, sid, "groups", translate("Group Setting"))
s.anonymous = true

s:tab("redir", translate("Proxy Setting"))
s:tab("dns", translate("DNS Setting"))
s:tab("node", translate("Node Setting"))



-- [[ redir setting ]]--
o_alias = s:taboption("redir", Value, "alias", translate("Name"))
o_alias.rmempty = false
function o_alias.validate(self, value)
	local v = groups_alias_set[value]
	if v ~= nil and v ~= sid then
		return nil, translate("Duplicate name!")
	end
	return Value.validate(self, value)
end

o = s:taboption("redir", Flag, "enable", translate("Enable"))
o.rmempty = false

o_redir_port = s:taboption("redir", Value, "redir_port", translate("Local Port"))
o_redir_port.rmempty 		= false
o_redir_port.datatype 		= "port"
o_redir_port.placeholder 	= "1234"
o_redir_port.default 		= o_redir_port.placeholder
function o_redir_port.validate(self, value)
	local ret, p = m:check_port_duplicate(value, o_alias:cfgvalue(sid), self.option, self.title)
	if ret == false then
		return nil, translate("Duplicate port!") .. "   \"%s\": %s    \"%s - %s: %s\"" % { self.title, value, p.alias, p.title, p.port }
	end
	return Value.validate(self, value)
end

o = s:taboption("redir", Value, "redir_mtu", translate("Override MTU"))
o.rmempty 		= false
o.datatype 		= "range(296,9200)"
o.placeholder 	= "1492"
o.default 		= o.placeholder

o = s:taboption("redir", Flag, "enable_reuse_port", translate("Enable reuse port"), translate("Need to enable sysctl net.ipv4.tcp_tw_reuse=1"))
o.template 		= "marsocket/checkbox"
o.rmempty 		= false

o = s:taboption("redir", Value, "reuse_port_count", translate("Number of processes"), 
	translate("Number of processes that reuse ports. <BR>If you want to maximize the performance as instantiate up to core_count + 1. \
		<BR>For example, you can run set is 3 ... instances while your device has 2 cores. \
		<BR>BUT, it's not necessary except the server side serves hundreds of users."))
o.rmempty 		= false
o.datatype 		= "range(1,48)"
o.placeholder 	= "3"
o.default 		= o.placeholder



-- [[ dns setting ]]--
o_enable_remote_dns = s:taboption("dns", Flag, "enable_remote_dns", translate("Enable remote DNS"))
o_enable_remote_dns.template = "marsocket/checkbox"
o_enable_remote_dns.rmempty 		= false

o = s:taboption("dns", Value, "remote_dns_servers", translate("Remote DNS Server"))
o.rmempty 		= false
o.datatype		= "ipaddr"
o.placeholder 	= "8.8.8.8"
o.default 		= o.placeholder

o = s:taboption("dns", Value, "remote_dns_port", translate("Remote DNS Port"))
o.rmempty 		= false
o.datatype 		= "port"
o.placeholder 	= "53"
o.default 		= o.placeholder

o_tunnel_port = s:taboption("dns", Value, "tunnel_port", translate("Local udp port of DNS"))
o_tunnel_port.rmempty 		= false
o_tunnel_port.datatype 		= "port"
o_tunnel_port.placeholder 	= "2234"
o_tunnel_port.default 		= o_tunnel_port.placeholder
function o_tunnel_port.validate(self, value)
	if o_enable_remote_dns:cfgvalue(sid) == "1" then
		local ret, p = m:check_port_duplicate(value, o_alias:cfgvalue(sid), self.option, self.title)
		if ret == false then
			return nil, translate("Duplicate port!") .. "   \"%s\": %s    \"%s - %s: %s\"" % { self.title, value, p.alias, p.title, p.port }
		end
	end
	return Value.validate(self, value)
end

o = s:taboption("dns", Value, "tunnel_mtu", translate("Override MTU of remote DNS"))
o.rmempty 		= false
o.datatype 		= "range(296,9200)"
o.placeholder 	= "1492"
o.default 		= o.placeholder

o_enable_tcp_dns = s:taboption("dns", Flag, "enable_tcp_dns", translate("Enable tcp remote DNS"))
o_enable_tcp_dns.template = "marsocket/checkbox"
o_enable_tcp_dns.rmempty = false

o_tcp_dns_port = s:taboption("dns", Value, "tcp_dns_port", translate("Local port of tcp remote DNS"))
o_tcp_dns_port.rmempty 		= false
o_tcp_dns_port.datatype 	= "port"
o_tcp_dns_port.placeholder 	= "5353"
o_tcp_dns_port.default 		= o_tcp_dns_port.placeholder
function o_tcp_dns_port.validate(self, value)
	if o_enable_tcp_dns:cfgvalue(sid) == "1" then
		local ret, p = m:check_port_duplicate(value, o_alias:cfgvalue(sid), self.option, self.title)
		if ret == false then
			return nil, translate("Duplicate port!") .. "   \"%s\": %s    \"%s - %s: %s\"" % { self.title, value, p.alias, p.title, p.port }
		end
	end
	return Value.validate(self, value)
end


-- [[ node setting ]]--
o_switch_mode = s:taboption("node", ListValue, "switch_mode", translate("Switch Mode"))
o_switch_mode.template 	= "marsocket/listvalue"
o_switch_mode.rmempty 	= false
o_switch_mode.default 	= "manual"
o_switch_mode:value("manual", translate("Manual"))
o_switch_mode:value("auto", translate("Auto"))
o_switch_mode:value("fallback", translate("Fallback"))
o_switch_mode:value("haproxy", translate("Haproxy"))

o_haproxy_port = s:taboption("node", Value, "haproxy_port", translate("Local port of Haproxy"))
o_haproxy_port.rmempty 		= false
o_haproxy_port.datatype 	= "port"
o_haproxy_port.placeholder 	= "2001"
o_haproxy_port.default 		= o_haproxy_port.placeholder
function o_haproxy_port.validate(self, value)
	if o_switch_mode:cfgvalue(sid) == "haproxy" then
		local ret, p = m:check_port_duplicate(value, o_alias:cfgvalue(sid), self.option, self.title)
		if ret == false then
			return nil, translate("Duplicate port!") .. "   \"%s\": %s    \"%s - %s: %s\"" % { self.title, value, p.alias, p.title, p.port }
		end		
	end
	return Value.validate(self, value)
end

o = s:taboption("node", Value, "test_url", translate("Test url"))
o.rmempty 		= false
o.placeholder 	= "http://www.google.com/ncr"
o.default 		= o.placeholder

o = s:taboption("node", Value, "test_interval", translate("Test Interval (minute)"))
o.rmempty 		= false
o.datatype 		= "uinteger"
o.placeholder 	= "1"
o.default 		= o.placeholder

o = s:taboption("node", Value, "test_tolerance", translate("Test Tolerance (ms)"))
o.rmempty 		= false
o.datatype 		= "uinteger"
o.placeholder 	= "100"
o.default 		= o.placeholder

o = s:taboption("node", ListValue, "cur_node", translate("Node"))
o.rmempty 		= false
o.default	 	= "nil"
o:value("nil", translate("Disable"))
for _, v in ipairs(nodelist) do o:value(v.idx, v.alias) end

o = s:taboption("node", DynamicList, "nodelist", translate("Proxy Node List"))
o.rmempty 		= false
o.default 		= "nil"
for _, v in ipairs(nodes) do o:value(v.idx, v.alias) end
function o.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	if v then
		for i = #v, 1, -1 do
			if nodes[v[i]+1] == nil then
				table.remove(v, i)
			end
		end
	end
	return v
end
-- function o.write(self, section, value)
-- 	local cur_node = o_cur_node:cfgvalue(section)
-- 	if not value then
		
-- 	if value[cur_node]
-- end





uci:foreach(marsocket, "groups", function(s)
	if s.alias then
		groups_alias_set[s.alias] = s[".name"]
	end

	local t = {}
	t[#t+1] = { enabled = true, 
				data = { section = s[".name"], alias = s.alias, port = s.redir_port, option = o_redir_port.option, title = o_redir_port.title } 
			}
	t[#t+1] = { enabled = (s.enable_remote_dns == "1"), 
				data = { section = s[".name"], alias = s.alias, port = s.tunnel_port, option = o_tunnel_port.option, title = o_tunnel_port.title }
			}
	t[#t+1] = { enabled = (s.enable_tcp_dns == "1"), 
				data = { section = s[".name"], alias = s.alias, port = s.tcp_dns_port, option = o_tcp_dns_port.option, title = o_tcp_dns_port.title }
			}
	t[#t+1] = { enabled = (s.switch_mode == "haproxy"), 
				data = { section = s[".name"], alias = s.alias, port = s.haproxy_port, option = o_haproxy_port.option, title = o_haproxy_port.title }
			}
	for _, v in ipairs(t) do
		if v.enabled == true and v.data.port then
			port_set[v.data.port] = v.data
		end
	end
end)


return m
