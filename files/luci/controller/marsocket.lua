-- Copyright (C) 2019 marsocket <marsocket@gmail.com>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.marsocket", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/marsocket") then
		return
	end

	entry({"admin", "services", "marsocket"}, 
		alias("admin", "services", "marsocket", "general"), 
		_("Marsocket"), 10).dependent = true

	entry({"admin", "services", "marsocket", "general"}, 
		cbi("marsocket/general"), 
		_("General"), 10).leaf = true

 	 entry({"admin", "services", "marsocket", "rules"},
		cbi("marsocket/rules"),
		_("Rules"), 20).leaf = true

	entry({"admin", "services", "marsocket", "groups"}, 
		arcombine(cbi("marsocket/groups"), cbi("marsocket/group_details")),
		_("Groups"), 30).leaf = true

	entry({"admin", "services", "marsocket", "nodes"}, 
		arcombine(cbi("marsocket/nodes"), cbi("marsocket/node_details")),
		_("Nodes"), 40).leaf = true

	entry({"admin", "services", "marsocket", "settings"},
		cbi("marsocket/settings"),
		_("Settings"), 50).leaf = true


	entry({"admin", "services", "marsocket", "check_groups_status"}, call("check_groups_status")).leaf = true
	entry({"admin", "services", "marsocket", "get_groups_nodelist"}, call("get_groups_nodelist")).leaf = true
	entry({"admin", "services", "marsocket", "switch_groups_nodelist"}, call("switch_groups_nodelist")).leaf = true
	entry({"admin", "services", "marsocket", "update_data"}, call("update_data")).leaf = true
	entry({"admin", "services", "marsocket", "check"}, call("check_status")).leaf = true

end

function check_status()
	-- HTTP_CODE=`curl -L -o /dev/null --connect-timeout 10 -s --head -w "%{http_code}" "$1"`
	local ret = luci.sys.call("/usr/bin/marsocket-check http://www.%s.com" % luci.http.formvalue("set"))
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = ret })
end

local function server_is_running(server, port)
	local ret = luci.sys.exec("ps -w | grep %s | grep -v grep | grep '%s' | wc -l" % { server, port })	
	return tonumber(ret)
end

function check_groups_status()
	local marsocket = "marsocket"
	local status_list = {}
	local uci = luci.model.uci.cursor()
	uci:foreach(marsocket, "groups", function(s)
		if s.redir_port then
			status_list[s.redir_port] = server_is_running("ss-redir", "\\-l " .. s.redir_port)
		end
		if s.tunnel_port then
			status_list[s.tunnel_port] = server_is_running("ss-tunnel", "\\-l " .. s.tunnel_port)
		end
		if s.tcp_dns_port then
			status_list[s.tcp_dns_port] = server_is_running("dns-forwarder", "\\-p " .. s.tcp_dns_port)
		end
	end)
	luci.http.prepare_content("application/json")
	luci.http.write_json(status_list)
end

function get_groups_nodelist()
	local marsocket = "marsocket"
	local uci = luci.model.uci.cursor()
	local nodes = {}
	uci:foreach(marsocket, "nodes", function(s)
		local count = #nodes
		nodes[#nodes+1] = { idx = count, alias = s.alias }
	end)	

	local ret = {}
	uci:foreach(marsocket, "groups", function(s)		
		local list = {}
		if s.switch_mode == "balance" then
			list[#list+1] = { value = "nil", alias = "Not changeable", selected = (s.cur_node == "nil"), idx = #list+1 }			
		else
			list[#list+1] = { value = "nil", alias = "Disable", selected = (s.cur_node == "nil"), idx = #list+1 }
			if s.nodelist then
				for _, v in ipairs(s.nodelist) do
					local n = nodes[v+1]
					if n then
						local count = tostring(#list) --这里不+1
						list[#list+1] = { value = count, alias = n.alias, selected = (s.cur_node == count), idx = #list+1 }
					end
				end
			end
		end

		ret[s[".name"]] = list
	end)


	luci.http.prepare_content("application/json")
	luci.http.write_json(ret)
end

function switch_groups_nodelist()
	local marsocket = "marsocket"
	local uci = luci.model.uci.cursor()
	local section = luci.http.formvalue("section")
	local mode = luci.http.formvalue("mode")
	local list = {}

	if uci:get(marsocket, section) == "groups" then
		local nodes = {}
		uci:foreach(marsocket, "nodes", function(s)
			local count = #nodes
			nodes[#nodes+1] = { idx = count, alias = s.alias }
		end)

		local cur_node = uci:get(marsocket, section, "cur_node")
		if mode == "balance" then
			list[#list+1] = { value = "nil", alias = "Not changeable", selected = (cur_node == "nil"), idx = #list+1 }
		else
			list[#list+1] = { value = "nil", alias = "Disable", selected = (cur_node == "nil"), idx = #list + 1 }
			for _, v in ipairs(uci:get_list(marsocket, section, "nodelist")) do
				local n = nodes[v+1]
				if n then
					local count = tostring(#list) --这里不+1
					list[#list+1] = { value = count, alias = n.alias, selected = (cur_node == count), idx = #list+1 }
				end
			end
		end
	end

	local ret = list
	luci.http.prepare_content("application/json")
	luci.http.write_json(ret)
end

function update_data()
	local marsocket = "marsocket"
	local set = luci.http.formvalue("set")
	local ret = 0
	local filename = "/etc/%s/%s-latest" % { marsocket, set }
	ret = luci.sys.call("/usr/bin/%s-%s --download --output-file \"/etc/%s/%s-latest\" >> /var/log/update_%s.log 2>&1" % { marsocket, set, marsocket, set, set })
	if ret == 0 then
		ret = luci.sys.exec("ls -la %s | awk 'NR==1 { print $6\" \"$7\" \"$8 }'" % filename)
	else
		ret = "-1"
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = ret })
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end



