-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local marsocket = "marsocket"
local uci = luci.model.uci.cursor()
local m, s, o
local sid = arg[1]
local nodes_alias_set = {}
uci:foreach(marsocket, "nodes", function(s)
	if s.alias then
		nodes_alias_set[s.alias] = s[".name"]
	end
end)
local encrypt_methods = {
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",
	"aes-128-gcm",
	"aes-192-gcm",
	"aes-256-gcm",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"bf-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf",
	"chacha20-ietf-poly1305",
	"xchacha20-ietf-poly1305",
}





m = Map(marsocket, title, description)
m.redirect = luci.dispatcher.build_url("admin/services/marsocket/nodes")
m.sid = sid
m.template = "marsocket/node_details"

if m.uci:get(marsocket, sid) ~= "nodes" then
	luci.http.redirect(m.redirect) 
	return
end

-- [[ Node Setting ]]--
s = m:section(NamedSection, sid, "nodes", translate("Node Setting"))
s.anonymous = true
s.addremove   = false

o = s:option(Value, "alias", translate("Name"))
o.rmempty = false
function o.validate(self, value)
	local v = nodes_alias_set[value]
	if v ~= nil and v ~= sid then
		return nil, translate("Duplicate name!")
	end
	return Value.validate(self, value)
end

o = s:option(Value, "server", translate("Server"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Flag, "fast_open", translate("TCP Fast Open"))
o.rmempty = false

o = s:option(Flag, "no_delay", translate("TCP no-delay"))
o.rmempty = false

o = s:option(Value, "timeout", translate("Connection Timeout"))
o.datatype = "uinteger"
o.default = 60
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.password = true
o.rmempty = false

o = s:option(Value, "key", translate("Directly Key"))

o = s:option(ListValue, "encrypt_method", translate("Encrypt Method"))
for _, v in ipairs(encrypt_methods) do o:value(v, v:upper()) end
o.rmempty = false

o = s:option(Value, "plugin", translate("Plugin"))
o.placeholder = "eg: obfs-local"

o = s:option(Value, "plugin_opts", translate("Plugin Arguments"))
o.placeholder = "eg: obfs=http;obfs-host=www.bing.com"

return m
