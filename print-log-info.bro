# Prints out field descriptions of all logs generated by Bro/Zeek.
# This requires a version of Bro/Zeek with the improvements from:
# https://github.com/bro/bro/commit/1f450c05102be6dd7ebcc2c5901d5a3a231cd675

@load test-all-policy

function log_record_ids(): id_table
	{
	local globals = global_ids();
	local rval = id_table();

	 for ( id in globals )
	 	{
	 	if ( /.*::.*Info$/ !in id )
	 		next;

	 	rval[id] = globals[id];
		}

	return rval;
	}

event bro_init() &priority = -100
	{
	for ( id in Log::active_streams )
		{
		local stream = Log::active_streams[id];

		if ( ! stream?$path )
			next;

		local log_file = fmt("%s.log", stream$path);
		local fields = record_fields(stream$columns);
		local info_id = cat(stream$columns);
		local field_names = record_type_to_vector(info_id);

		print log_file;

		for ( idx in field_names )
			{
			local field = field_names[idx];
			local field_props = fields[field];

			if ( ! field_props$log )
				next;

			local fq_field = fmt("%s$%s", info_id, field);
			local field_desc = get_record_field_comments(fq_field);
			field_desc = gsub(field_desc, /\x0a/, " ");
			local period_idx = strstr(field_desc, ".");

			if ( period_idx != 0 )
				field_desc = field_desc[0:period_idx];

			if ( |field_desc| > 0 && /[[:alnum:]]/ !in field_desc[0] )
				field_desc = "";

			print fmt("  %s: %s - %s", field, field_props$type_name, field_desc);
			}

		print "";
		}
	}