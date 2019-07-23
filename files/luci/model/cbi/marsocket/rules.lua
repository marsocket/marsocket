-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
local title = "Marsocket"
local description = translate("Marsocket is a proxy policy program that provides fine-grained control over access routes through all hosts on the LAN.")
local marsocket = "marsocket"
local uci = luci.model.uci.cursor()
local m, s, o

local groups = {}
uci:foreach(marsocket, "groups", function(s)
	local count = #groups
	groups[count+1] = { idx = count, alias = s.alias }
end)
local country_code = {}
country_code[#country_code+1] = { code = "AE", name = "United Arab Emirates" }
country_code[#country_code+1] = { code = "AF", name = "Afghanistan" }
country_code[#country_code+1] = { code = "AS", name = "American Samoa" }
country_code[#country_code+1] = { code = "AU", name = "Australia" }
country_code[#country_code+1] = { code = "BD", name = "Bangladesh" }
country_code[#country_code+1] = { code = "BN", name = "Brunei Darussalam" }
country_code[#country_code+1] = { code = "BT", name = "Bhutan" }
country_code[#country_code+1] = { code = "BZ", name = "Belize" }
country_code[#country_code+1] = { code = "CA", name = "Canada" }
country_code[#country_code+1] = { code = "CH", name = "Switzerland" }
country_code[#country_code+1] = { code = "CK", name = "Cook Islands" }
country_code[#country_code+1] = { code = "CN", name = "China" }
country_code[#country_code+1] = { code = "EE", name = "Estonia" }
country_code[#country_code+1] = { code = "ES", name = "Spain" }
country_code[#country_code+1] = { code = "FJ", name = "Fiji" }
country_code[#country_code+1] = { code = "FM", name = "Micronesia" }
country_code[#country_code+1] = { code = "FR", name = "France" }
country_code[#country_code+1] = { code = "GB", name = "United Kingdom" }
country_code[#country_code+1] = { code = "GI", name = "Gibraltar" }
country_code[#country_code+1] = { code = "GU", name = "Guam" }
country_code[#country_code+1] = { code = "HK", name = "Hong Kong" }
country_code[#country_code+1] = { code = "ID", name = "Indonesia" }
country_code[#country_code+1] = { code = "IN", name = "India" }
country_code[#country_code+1] = { code = "IR", name = "Iran" }
country_code[#country_code+1] = { code = "JP", name = "Japan" }
country_code[#country_code+1] = { code = "KH", name = "Cambodia" }
country_code[#country_code+1] = { code = "KI", name = "Kiribati" }
country_code[#country_code+1] = { code = "KR", name = "Korea" }
country_code[#country_code+1] = { code = "KY", name = "Cayman Islands" }
country_code[#country_code+1] = { code = "LA", name = "Laos" }
country_code[#country_code+1] = { code = "LK", name = "Sri Lanka" }
country_code[#country_code+1] = { code = "MH", name = "Marshall Islands" }
country_code[#country_code+1] = { code = "MM", name = "Myanmar" }
country_code[#country_code+1] = { code = "MN", name = "Mongolia" }
country_code[#country_code+1] = { code = "MO", name = "Macao" }
country_code[#country_code+1] = { code = "MP", name = "Northern Mariana Islands" }
country_code[#country_code+1] = { code = "MU", name = "Mauritius" }
country_code[#country_code+1] = { code = "MV", name = "Maldives" }
country_code[#country_code+1] = { code = "MY", name = "Malaysia" }
country_code[#country_code+1] = { code = "NC", name = "New Caledonia" }
country_code[#country_code+1] = { code = "NF", name = "Norfolk Island" }
country_code[#country_code+1] = { code = "NL", name = "Netherlands" }
country_code[#country_code+1] = { code = "NO", name = "Norway" }
country_code[#country_code+1] = { code = "NP", name = "Nepal" }
country_code[#country_code+1] = { code = "NR", name = "Nauru" }
country_code[#country_code+1] = { code = "NU", name = "Niue" }
country_code[#country_code+1] = { code = "NZ", name = "New Zealand" }
country_code[#country_code+1] = { code = "PA", name = "Panama" }
country_code[#country_code+1] = { code = "PF", name = "French Polynesia" }
country_code[#country_code+1] = { code = "PG", name = "Papua New Guinea" }
country_code[#country_code+1] = { code = "PH", name = "Philippines" }
country_code[#country_code+1] = { code = "PK", name = "Pakistan" }
country_code[#country_code+1] = { code = "PW", name = "Palau" }
country_code[#country_code+1] = { code = "SB", name = "Solomon Islands" }
country_code[#country_code+1] = { code = "SC", name = "Seychelles" }
country_code[#country_code+1] = { code = "SE", name = "Sweden" }
country_code[#country_code+1] = { code = "SG", name = "Singapore" }
country_code[#country_code+1] = { code = "TH", name = "Thailand" }
country_code[#country_code+1] = { code = "TK", name = "Tokelau" }
country_code[#country_code+1] = { code = "TL", name = "Timor-Leste" }
country_code[#country_code+1] = { code = "TO", name = "Tonga" }
country_code[#country_code+1] = { code = "TR", name = "Turkey" }
country_code[#country_code+1] = { code = "TV", name = "Tuvalu" }
country_code[#country_code+1] = { code = "TW", name = "Taiwan (Province of China)" }
country_code[#country_code+1] = { code = "US", name = "United States" }
country_code[#country_code+1] = { code = "VG", name = "Virgin Islands" }
country_code[#country_code+1] = { code = "VN", name = "Viet Nam" }
country_code[#country_code+1] = { code = "VU", name = "Vanuatu" }
country_code[#country_code+1] = { code = "WF", name = "Wallis and Futuna" }
country_code[#country_code+1] = { code = "WS", name = "Samoa" }










m = Map(marsocket, title, description)

s = m:section(TypedSection, "rules_gfwlist", translate("GFW List"))
s.anonymous = true
o = s:option(ListValue, "dns_group_idx", translate("Remote DNS"))
o:value("nil", translate("Disable"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Driect"))
o:value("use_default_proxy", translate("Use default proxy"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end

o = s:option(DummyValue, "count", translate("Number of domains in gfwlist"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local filename = "/etc/%s/dnsmasq.d/gfwlist.conf" % marsocket
	if nixio.fs.access(filename) then
	 	local count = luci.sys.exec("grep 'server=' %s | wc -l" % filename)
	 	return "<input type='text' class='cbi-input-text' readonly='readonly' value='%s' />" % count
	end
	return "<input type='text' class='cbi-input-text' readonly='readonly' value='%s' />" % translate("Not yet counted")
end


s = m:section(TypedSection, "rules_iplist", translate("IP List From APNIC"))
s.template 	= "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable = true

o_country = s:option(ListValue, "country", translate("Country"))
for _, v in ipairs(country_code) do o_country:value(v.code, translate(v.name)) end
o_country.rmempty = false

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Driect"))
o:value("use_default_proxy", translate("Use default proxy"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end

o = s:option(DummyValue, "count", translate("Number of IP segment"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local code = o_country:cfgvalue(section)
	if code then
		local filename = "/etc/%s/apnic.d/%s.list" % { marsocket, code }
		if nixio.fs.access(filename) then
		 	local count = luci.sys.exec("cat %s | wc -l" % filename)
		 	return "<input type='text' class='cbi-input-text' readonly='readonly' value='%s' />" % count
		end
	end
	return "<input type='text' class='cbi-input-text' readonly='readonly' value='%s' />" % translate("Not yet counted")
end


s = m:section(TypedSection, "rules_ip", translate("IP CIDR"))
s.template 	= "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable = true

o = s:option(Value, "net", translate("IP Net"))
o.datatype 	= "ip4addr" --"or(file, '/dev/null')"
o.placeholder = "0.0.0.0/24"
o.rmempty = false

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Driect"))
o:value("use_default_proxy", translate("Use default proxy"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end




s = m:section(TypedSection, "rules_domain")
s.template 	= "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable = true

o = s:option(Value, "domain", translate("Domain"))
o.datatype 		= "host"
o.placeholder	= "example.com"
o.default 		= o.placeholder
o.rmempty 		= false

o = s:option(Flag, "allow_rebind", translate("Rebind"))

o = s:option(ListValue, "dns_group_idx", translate("Remote DNS"))
o:value("nil", translate("Disable"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end

o = s:option(ListValue, "proxy_group_idx", translate("Proxy"))
o:value("nil", translate("Driect"))
o:value("use_default_proxy", translate("Use default proxy"))
for _, v in ipairs(groups) do o:value(v.idx, v.alias) end



return m
