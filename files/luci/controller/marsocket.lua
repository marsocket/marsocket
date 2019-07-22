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
		_("General Settings"), 10).leaf = true

 	 entry({"admin", "services", "marsocket", "rules"},
		cbi("marsocket/rules"),
		_("Rules"), 20).leaf = true

	entry({"admin", "services", "marsocket", "groups"}, 
		arcombine(cbi("marsocket/groups"), cbi("marsocket/group_details")),
		_("Groups Manage"), 30).leaf = true

	entry({"admin", "services", "marsocket", "nodes"}, 
		arcombine(cbi("marsocket/nodes"), cbi("marsocket/node_details")),
		_("Node Manage"), 40).leaf = true

	entry({"admin", "services", "marsocket", "settings"},
		cbi("marsocket/settings"),
		_("Settings"), 50).leaf = true


	entry({"admin", "services", "marsocket", "check_groups_status"}, call("check_groups_status")).leaf = true
	entry({"admin", "services", "marsocket", "get_groups_nodelist"}, call("get_groups_nodelist")).leaf = true
	entry({"admin", "services", "marsocket", "switch_groups_nodelist"}, call("switch_groups_nodelist")).leaf = true
	entry({"admin", "services", "marsocket", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "marsocket", "check"}, call("check_status")).leaf = true
	entry({"admin", "services", "marsocket", "checkport"}, call("check_port"))

end

function check_status()
	local ret = luci.sys.call("/usr/bin/marsocket-check http://www.%s.com" % luci.http.formvalue("set"))
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = ret })
end

function check_port()
	local sk = require("socket")
	local retstring="<br/><br/>"
	local marsocket = "marsocket"
	local uci = luci.model.uci.cursor()
	uci:foreach(marsocket, "nodes", function(s)
		local server_name = s.alias
		if not server_name and s.server and s.server_port then
			server_name = "%s:%s" % {s.server, s.server_port}
		end
		socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		local t = sk.gettime()
		ret = socket:connect(s.server, s.server_port)
		if  tostring(ret) == "true" then
			socket:close()
			t = (sk.gettime() - t) * 1000
			retstring = retstring .. "<font color='green'>[" .. server_name .. "] OK (" .. string.format("%.2fms", t) .. ").</font><br/>"
		else
			retstring = retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br/>"
		end	
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = retstring })
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

function action_status()
	local marsocket = "marsocket"
	local proxy_list = {}
	local uci = luci.model.uci.cursor()
	uci:foreach(marsocket, "groups", function(s)
		proxy_list[s.redir_port] = server_is_running("ss-redir", s.redir_port)
	end)
	luci.http.prepare_content("application/json")
	luci.http.write_json(proxy_list)
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
		if s.switch_mode == "haproxy" then
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

		ret[s[".name"]] = { disabled = (s.switch_mode == "haproxy"), list = list }
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
		if mode == "haproxy" then
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

	local ret = { disabled = (mode == "haproxy"), list = list }
	luci.http.prepare_content("application/json")
	luci.http.write_json(ret)
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



