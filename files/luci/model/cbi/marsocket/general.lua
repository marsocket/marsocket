-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local m, s, o
local marsocket = "marsocket"
local uci = luci.model.uci.cursor()
local nwm = require("luci.model.network").init()
local lan_ifaces = {}
local groups = {}

for _, net in ipairs(nwm:get_networks()) do
	if net:name() ~= "loopback" and string.find(net:name(), "wan") ~= 1 then
		net = nwm:get_network(net:name())
		local device = net and net:get_interface()
		if device then
			lan_ifaces[device:name()] = device:get_i18n()
		end
	end
end

uci:foreach(marsocket, "groups", function(s)
	local count = #groups
	groups[count+1] = { idx = count, alias = s.alias }
end)



local function has_bin(name)
	return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end

local has_redir = has_bin("ss-redir")
local has_dnsforwarder = has_bin("dns-forwarder")

if not has_redir then
	return Map(marsocket, title, "<b style='color:red'>ss-redir %s.</b>" % translate("binary file not found"))
end

m = Map(marsocket, title, description)
--m.template = "marsocket/general"




-- [[ Zone LAN ]]--
s = m:section(TypedSection, "lan", translate("Zone LAN"))
s.anonymous = true

o = s:option(MultiValue, "ifaces", translate("Interface"))
function o.cfgvalue(...)
	local v = MultiValue.cfgvalue(...)
	if v then
		return v
	else
		local names = {}
		for name, _ in pairs(lan_ifaces) do
			names[#names+1] = name
		end
		return table.concat(names, " ")
	end
end
for name, i18n in pairs(lan_ifaces) do o:value(name, i18n) end

o = s:option(ListValue, "type", translate("Outbound mode"))
o:value("b", translate("Direct"))
o:value("g", translate("Global"))
o:value("p", translate("Proxy by default"))
o:value("d", translate("Direct by default"))
o.rmempty = false

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
if #groups == 0 then
	o:value("nil", translate("Disable"))
else
	for _, v in ipairs(groups) do o:value(v.idx, v.alias) end
end



-- [[ Local Host ]]--
s = m:section(TypedSection, "local_host", translate("Local Host"))
s.anonymous = true
o = s:option(ListValue, "type", translate("Outbound mode"))
o:value("b", translate("Direct"))
o:value("g", translate("Global"))
o:value("p", translate("Proxy by default"))
o:value("d", translate("Direct by default"))
o.rmempty = false

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Use Zone LAN"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end




-- [[ LAN Hosts ]]--
s = m:section(TypedSection, "lan_hosts", translate("LAN Hosts"))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable = true

o = s:option(Flag, "enable", translate("Enable"))

o = s:option(Value, "macaddr", translate("MAC-Address"))
luci.sys.net.mac_hints(function(mac, name)
	o:value(mac, "%s (%s)" % { mac, name })
end)
o.datatype = "macaddr"
o.rmempty = false

o = s:option(ListValue, "type", translate("Mode"))
o:value("b", translate("Direct"))
o:value("g", translate("Global"))
o:value("p", translate("Proxy by default"))
o:value("d", translate("Direct by default"))
o.rmempty = false

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Use Zone LAN"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end
















--[[

if has_dnsforwarder then
	s = m:section(TypedSection, "dns-forwarder", translate("DNS Forwarder"))
	s.anonymous   = true

	o = s:option(Flag, "enable", translate("Enable"))
	o.rmempty     = false

	o = s:option(Value, "dns_servers", translate("DNS Server"))
	o.datatype		= "ipaddr"
	o.placeholder 	= "8.8.8.8"
	o.default     	= "8.8.8.8"
	o.rmempty     	= false	
end


if has_redir then

	
	s = m:section(TypedSection, "transparent_proxy_list", 
			translate("Proxy List"), translate("The first record is the default proxy"))
	s.template 	= "cbi/tblsection"
	s.addremove = true
	s.anonymous = true

	o = s:option(Value, "alias", translate("Name"))
	o.rmempty = false

	o = s:option(ListValue, "tpl_server", translate("Server"))
	o:value("nil", translate("Disable"))
	for _, v in ipairs(nodes) do o:value(v.name, v.alias) end
	o.default = "nil"
	o.rmempty = false

	o_port = s:option(Value, "tpl_local_port", translate("Local Port"))
	o_port.datatype = "port"
	o_port.default 	= 1234
	o_port.rmempty 	= false

	o_port = s:option(Value, "tpl_dns_port", translate("DNS Port"))
	o_port.datatype = "port"
	o_port.default 	= 0
	o_port.rmempty 	= false

	o = s:option(Value, "tpl_mtu", translate("Override MTU"))
	o.datatype 	= "range(296,9200)"
	o.default 	= 1492
	o.rmempty 	= false

	o = s:option(DummyValue, "tpl_server_status", translate("Status"))
	function o.cfgvalue(self, section)
		local v = o_port:cfgvalue(section)
	    return "<span id=\"_redir_status_%s\"></span>" % (v or '?')
	end
    o.rawhtml = true

end

--]]



return m
