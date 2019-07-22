-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local m, s, o
local marsocket = "marsocket"
local gfw_count=0
local ip_count=0
local gfwmode=0
local IPK_Version = "1.2"


-- [[ General Setting ]]--
-- m = Map(marsocket, title, description)
-- s = m:section(TypedSection, "general", translate("Settings"))
-- s.anonymous = true

-- o = s:option(Value, "startup_delay", translate("Startup Delay"))
-- o:value(0, translate("Not enabled"))
-- for _, v in ipairs({5, 10, 15, 25, 40}) do
-- 	o:value(v, translatef("%u seconds", v))
-- end
-- o.datatype = "uinteger"
-- o.default = 10
-- o.rmempty = false

-- o = s:option(Value, "ipt_ext", translate("Extra arguments"),
-- 	translate("Passes additional arguments to iptables. Use with care!"))
-- o:value("", translate("None"))
-- o:value("--dport 22:1023", translatef("Proxy port numbers %s only", "22~1023"))
-- o:value("-m multiport --dports 53,80,443", translatef("Proxy port numbers %s only", "53,80,443"))



m = SimpleForm("Version", title, description)
m.reset = false
m.submit = false

s=m:field(DummyValue,"google",translate("Google Connectivity"))
s.value = translate("No Check") 
s.template = "marsocket/check"

s=m:field(DummyValue,"baidu",translate("Baidu Connectivity")) 
s.value = translate("No Check") 
s.template = "marsocket/check"

s=m:field(DummyValue, "check_port", translate("Check Node Port"))
s.template = "marsocket/checkport"
s.value =translate("No Check")
	
return m
