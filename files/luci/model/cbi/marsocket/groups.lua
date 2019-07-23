-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local marsocket = "marsocket"
local uci = luci.model.uci.cursor()
local m, s, o
local nodes = {}
uci:foreach(marsocket, "nodes", function(s)
	local count = #nodes+1 --填充下拉列表的假数据, idx下标从1开始, 0留给nil表示disable
	nodes[count] = { idx = count, alias = s.alias }
end)

m = Map(marsocket, title, description)
m.template = "marsocket/groups"

-- [[ Node List ]]--
s = m:section(TypedSection, "groups", translate("Groups Manager"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.sortable = true
s.extedit = luci.dispatcher.build_url("admin/services/marsocket/groups/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "alias", translate("Name"))
function o.cfgvalue(self, section)
	return Value.cfgvalue(self, section) or translate("None")
end

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty = false

o = s:option(ListValue, "switch_mode", translate("Switch Mode"))
o.template 	= "marsocket/listvalue"
o.rmempty 	= false
o:value("manual", translate("Manual"))
o:value("auto", translate("Auto"))
o:value("fallback", translate("Fallback"))
o:value("balance", translate("Balance"))

o = s:option(ListValue, "cur_node", translate("Node"))
o.rmempty = false
o.default = "nil"
o:value("nil", translate("Disable"))
for _, v in ipairs(nodes) do o:value(v.idx, v.alias) end

o_redir_port = s:option(DummyValue, "redir_port", translate("Local Port"))
o_redir_port.rawhtml = true
function o_redir_port.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	local v2 = v and ("<BR><span id=\"_status_%s\"></span>" % v) or ""
	return "%s%s" % { v or translate("Disable"), v2 }
end

o_tunnel_port = s:option(DummyValue, "tunnel_port", translate("DNS"))
o_tunnel_port.rawhtml = true
function o_tunnel_port.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	local v2 = v and ("<BR><span id=\"_status_%s\"></span>" % v) or ""
	return "%s%s" % { v or translate("Disable"), v2 }
end

o_tcpdns_port = s:option(DummyValue, "tcp_dns_port", translate("TCP DNS"))
o_tcpdns_port.rawhtml = true
function o_tcpdns_port.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	local v2 = v and ("<BR><span id=\"_status_%s\"></span>" % v) or ""
	return "%s%s" % { v or translate("Disable"), v2 }
end

return m

