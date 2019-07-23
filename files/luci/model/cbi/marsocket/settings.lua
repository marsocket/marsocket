-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local marsocket = "marsocket"
local m, s, o

-- [[ General Setting ]]--
m = Map(marsocket, title, description)
m.template = "marsocket/settings"
s = m:section(TypedSection, "general", translate("Settings"))
s.anonymous = true

o = s:option(DummyValue, "gfwlist", translate("Last updated of gfwlist"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local filename = "/etc/%s/%s-latest" % { marsocket, self.option }
	local id = "cbid.%s.%s.%s.readonly" % { marsocket, section, self.option }
	local button = "<input type='button' class='cbi-button cbi-button-apply' value='%s' onclick='update_data(this, \"%s\", \"%s\")'/>" 
		% { translate("Update now"), id, self.option }
	local input = ""
	if nixio.fs.access(filename) then
	 	local t = luci.sys.exec("ls -la %s | awk '{ print $6\" \"$7\" \"$8 }'" % filename)
	 	input = "<input type='text' class='cbi-input-text' readonly='readonly' id='%s' value='%s'/>" % { id, t }
	else
		input = "<input type='text' class='cbi-input-text' readonly='readonly' id='%s' value='%s'/>" % { id, translate("Not fonud database file") }
	end
	return input .. "&nbsp;&nbsp;" .. button
end

o = s:option(DummyValue, "apnic", translate("Last updated of apnic data"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local filename = "/etc/%s/%s-latest" % { marsocket, self.option }
	local id = "cbid.%s.%s.%s.readonly" % { marsocket, section, self.option }
	local button = "<input type='button' class='cbi-button cbi-button-apply' value='%s' onclick='update_data(this, \"%s\", \"%s\")'/>" 
		% { translate("Update now"), id, self.option }
	local input = ""
	if nixio.fs.access(filename) then
	 	local t = luci.sys.exec("ls -la %s | awk '{ print $6\" \"$7\" \"$8 }'" % filename)
	 	input = "<input type='text' class='cbi-input-text' readonly='readonly' id='%s' value='%s'/>" % { id, t }
	else
		input = "<input type='text' class='cbi-input-text' readonly='readonly' id='%s' value='%s'/>" % { id, translate("Not fonud database file") }
	end
	return input .. "&nbsp;&nbsp;" .. button
end

o = s:option(ListValue, "auto_update_weekday", translate("Auto update"))
o.template = "marsocket/left_listvalue"
o.rmempty 	= false
o.default 	= "nil"
o.style		= "width: 7em;"
o:value("nil", translate("Every day"))
o:value("0", translate("Sun"))
o:value("1", translate("Mon"))
o:value("2", translate("Tue"))
o:value("3", translate("Wed"))
o:value("4", translate("Thu"))
o:value("5", translate("Fri"))
o:value("6", translate("Sat"))

o = s:option(ListValue, "auto_update_hours", "hours")
o.template = "marsocket/mid_listvalue"
o.rmempty 	= false
o.default 	= "4"
o.style		= "width: 5em;"
o.prefixhtml = "&nbsp;&nbsp;"
for i=0,23,1 do o:value(i, string.format("%02d", i)) end

o = s:option(ListValue, "auto_update_minutes", "minutes")
o.template 	= "marsocket/right_listvalue"
o.rmempty	= false
o.default 	= "0"
o.style		= "width: 5em;"
o.prefixhtml = "&nbsp;&nbsp;:&nbsp;"
for i=0,55,5 do o:value(i, string.format("%02d", i)) end

o = s:option(Value, "ipt_ext", translate("Extra arguments"),
	translate("Passes additional arguments to iptables. Use with care!"))
o:value("", translate("None"))
o:value("--dport 22:1023", translatef("Proxy port numbers %s only", "22~1023"))
o:value("-m multiport --dports 53,80,443", translatef("Proxy port numbers %s only", "53,80,443"))

--[[
o = s:option(Value, "startup_delay", translate("Startup Delay"))
o:value(0, translate("Not enabled"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	o:value(v, translatef("%u seconds", v))
end
o.datatype = "uinteger"
o.default = 10
o.rmempty = false
]]


--[[
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
]]
return m
