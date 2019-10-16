# Prints out field descriptions of all logs generated by Zeek 3.0+.
#
# * Set environment variable ZEEK_ALLOW_INIT_ERRORS=1 before running Zeek
#   with this script.
#
# * Requires a version of Bro/Zeek with the improvements from:
#   https://github.com/bro/bro/commit/1f450c05102be6dd7ebcc2c5901d5a3a231cd675
#   (Was not included in 2.6 release)

@load zeekygen
#@load test-all-policy

module PrintLogs;

export {
	option csv = T;

	option title_map: table[string] of string = {
		["barnyard2.log"] = "Alerts from Barnyard2",
		["broker.log"] = "Events from Broker-enabled peers",
		["capture_loss.log"] = "Packet loss rate",
		["cluster.log"] = "Cluster messages",
		["config.log"] = "Configuration option changes",
		["conn.log"] = "IP, TCP, UDP, ICMP connection details",
		["dce_rpc.log"] = "Details on DCE/RPC messages",
		["dhcp.log"] = "DHCP lease activity",
		["dnp3.log"] = "DNP3 requests and replies",
		["dns.log"] = "DNS query/response details",
		["dpd.log"] = "Dynamic protocol detection failures",
		["files.log"] = "File analysis results",
		["ftp.log"] = "FTP request/reply details",
		["http.log"] = "HTTP request/reply details",
		["intel.log"] = "Intelligence data matches",
		["irc.log"] = "IRC communication details",
		["kerberos.log"] = "Kerberos authentication",
		["known_certs.log"] = "SSL certificates",
		["known_hosts.log"] = "Hosts with complete TCP handshakes",
		["known_modbus.log"] = "Modbus masters and slaves",
		["known_services.log"] = "Services running on hosts",
		["loaded_scripts.log"] = "Show all loaded scripts",
		["modbus.log"] = "Modbus commands and responses",
		["modbus_register_change.log"] = "Modbus holding register changes",
		["mysql.log"] = "MySQL",
		["netcontrol.log"] = "NetControl actions",
		["netcontrol_catch_release.log"] = "NetControl catch and releases",
		["netcontrol_drop.log"] = "NetControl drops",
		["netcontrol_shunt.log"] = "NetControl shunts",
		["notice.log"] = "Interesting events/activity",
		["notice_alarm.log"] = "Alarming events/activity",
		["ntlm.log"] = "NT LAN Manager (NTLM)",
		["ocsp.log"] = "Online Certificate Status Protocol (OCSP)",
		["openflow.log"] = "OpenFlow debug log",
		["packet_filter.log"] = "Applied packet filters",
		["pe.log"] = "Portable Executable (PE)",
		["radius.log"] = "RADIUS authentication attempts",
		["rdp.log"] = "Remote Desktop Protocol (RDP)",
		["reporter.log"] = "Error/warning/info messages",
		["rfb.log"] = "Remote Framebuffer (RFB)",
		["signatures.log"] = "Signature matches",
		["sip.log"] = "SIP analysis",
		["smb_cmd.log"] = "SMB commands",
		["smb_files.log"] = "Details on SMB files",
		["smb_mapping.log"] = "SMB mappings",
		["smtp.log"] = "SMTP transactions",
		["snmp.log"] = "SNMP messages",
		["socks.log"] = "SOCKS proxy requests",
		["software.log"] = "Software used on the network",
		["ssh.log"] = "SSH handshakes",
		["ssl.log"] = "SSL handshakes",
		["stats.log"] = "Memory/event/packet/lag stats",
		["syslog.log"] = "Syslog messages",
		["traceroute.log"] = "Traceroute detection",
		["tunnel.log"] = "Details of encapsulating tunnels",
		["unified2.log"] = "Interprets Snort's unified output",
		["weird.log"] = "Unexpected network/protocol activity",
		["weird_stats.log"] = "Stats related to weird.log",
		["x509.log"] = "X.509 certificate info",
	};
}

global csvs_written: set[string] = set();

event bro_done() &priority = -100
	{
	for ( f in csvs_written )
		print fmt("wrote %s", f);
	}
event bro_init() &priority = -100
	{
	local path_to_id_map: table[string] of Log::ID = table();
	local paths: vector of string = vector();
	local stream: Log::Stream;
	local id: Log::ID;

	for ( id in Log::active_streams )
		{
		stream = Log::active_streams[id];

		if ( ! stream?$path )
			next;

		path_to_id_map[stream$path] = id;
		paths += stream$path;
		}

	sort(paths, strcmp);

	for ( i in paths )
		{
		id = path_to_id_map[paths[i]];
		stream = Log::active_streams[id];

		local log_file = fmt("%s.log", stream$path);
		local fields = record_fields(stream$columns);
		local info_id = cat(stream$columns);
		local field_names = record_type_to_vector(info_id);
		local csv_file: file;
		local csv_filename: string;

		if ( csv )
			{
			csv_filename = fmt("%s.%s.%s-%s.csv", Version::info$major,
			                   Version::info$minor, Version::info$patch,
			                   log_file);
			csv_file = open(csv_filename);

			if ( log_file in title_map )
				print csv_file, fmt("\"%s | %s\"", log_file,
				                    title_map[log_file]);
			else
				print csv_file, fmt("\"%s\"", log_file);

			print csv_file, "\"FIELD\",\"TYPE\",\"DESCRIPTION\"";
			}
		else
			{
			if ( log_file in title_map )
				print fmt("%s | %s", log_file, title_map[log_file]);
			else
				print log_file;
			}

		for ( idx in field_names )
			{
			local field = field_names[idx];
			local field_props = fields[field];

			if ( ! field_props$log )
				next;

			local fq_field = fmt("%s$%s", info_id, field);
			local field_desc = get_record_field_comments(fq_field);
			field_desc = gsub(field_desc, /\x0a/, " ");
			# note: period_idx is 1-based
			local period_idx = strstr(field_desc, ".");

			if ( period_idx < |field_desc| )
				{
				if ( field_desc[period_idx] !in set(" ", "\n") )
					# Likely the period doesn't indicate the end of a sentence
					# TODO: could look for the next period
					period_idx = 0;
				}

			if ( period_idx != 0 )
				field_desc = field_desc[0:period_idx];

			if ( |field_desc| > 0 && /[[:alnum:]]/ !in field_desc[0] )
				field_desc = "";

			if ( csv )
				{
				if ( |field_desc| > 0 && field_desc[|field_desc| - 1] == "." )
					field_desc = field_desc[0:|field_desc| - 1];

				field_desc = gsub(field_desc, /\"/, "'");
				print csv_file, fmt("\"%s\",\"%s\",\"%s\"", field,
				                    field_props$type_name, field_desc);
				}
			else
				print fmt("  %s: %s - %s", field, field_props$type_name,
				          field_desc);
			}

		if ( csv )
			{
			add csvs_written[csv_filename];
			close(csv_file);
			}
		else
			print "";

		}
	}
