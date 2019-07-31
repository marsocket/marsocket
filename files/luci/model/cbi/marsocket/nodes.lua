-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local marsocket = "marsocket"
local m, s, o

m = Map(marsocket, title, description)

-- [[ Nodes Manage ]]--
s = m:section(TypedSection, "nodes", translate("Nodes Manage"))
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/marsocket/nodes/%s")
	
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end 

o = s:option(DummyValue, "alias", translate("Name"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "encrypt_method", translate("Encrypt Method"))
function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	return v and v:upper() or "?"
end

o = s:option(DummyValue, "plugin", translate("Plugin"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

return m

