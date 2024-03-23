//
//	zspel
//
//	cdtj71<at>gmail.com
//
//	Include string:
//		#include "<full_path>/zspel.frg"
//
//	Description:
//		check zspel_test.frg for examples
//		check function descriptions for more details

#define L_ERROR for(msg_i=0;msg_i<msg_length();msg_i++) { logf(ERROR, "msg[%d]: %s", msg_i, msg[msg_i]); }
#define L_SIGN for(msg_i=0;msg_i<msg_length();msg_i++) { logf(SIGNIFICANT, "msg[%d]: %s", msg_i, msg[msg_i]); }
#define L_BOTH if (msg_error()) { L_ERROR } else { L_SIGN }
#define P_ERROR for(msg_i=0;msg_i<msg_length();msg_i++) { printf("\tERROR[%d]: %s\n", msg_i, (string)msg[msg_i]); }
#define P_SIGN for(msg_i=0;msg_i<msg_length();msg_i++) { printf("\tSGNFCNT[%d]: %s\n", msg_i, (string)msg[msg_i]); }
#define P_BOTH if (msg_error()) { P_ERROR } else { P_SIGN }

#define ILIMIT 2147483648


// Function: z_checkin
// -------------------
// checking in previously checked out group leader
//
// gl: group leader
// delay: delay between iterations if object is busy
// timeout: max iterations before terminating attempts
//
// optional args:
//	(string)event: persid or sym as string of event to attach on failure
//
// returns:
//	1 on failure
//	0 on success
int z_checkin(object gl, int delay, int timeout, ...) {
	int err_stat, retry_count, msg_i, i;
	string msg_string;

	err_stat = 1;
	retry_count = 0;
	while (err_stat) {
		send_wait(0, gl, "checkin");
		if (!msg_error()) {
			err_stat = 0;
		} else {
			if (retry_count > timeout) {
				logf(ERROR, "terminated due timeout, [%d] retries: %s", timeout, msg_string);
				for (i = 3; i < argc; i++) {
					if (!is_empty(argv[i])) {
						z_new_evt(argv[i], zobj.persistent_id, delay);
					}
				}
				send_wait(0, gl, "uncheck");
				return 1;
			} else {
				msg_string = "";
				for (msg_i = 0; msg_i < msg_length(); msg_i++) {
					if (strlen(msg_string) > 0) {
						msg_string += format(" '%s'", msg[msg_i]);
					} else {
						msg_string = format("'%s'", msg[msg_i]);
					}
				}
				logf(ERROR, "unable to checkin, retry in [%d] sec: %s", delay, msg_string);
				sleep(delay);
				retry_count++;
			}
		}
	}
	return 0;
}


// Function: z_checkout
// --------------------
// checking out object into group leader
//
// gl: group leader
// zobj: object to check out
// delay: delay between iterations if object is busy
// timeout: max iterations before terminating attempts
//
// optional args:
//	(string)event: persid or sym as string of event to attach on failure
//
// returns:
//	1 on failure
//	0 on success
int z_checkout(object gl, object zobj, int delay, int timeout, ...) {
	int err_stat, retry_count, msg_i, i;
	string msg_string;

	err_stat = 1;
	retry_count = 0;
	while (err_stat) {
		send_wait(0, gl, "checkout", zobj);
		if (!msg_error()) {
			err_stat = 0;
		} else {
			if (retry_count > timeout) {
				logf(ERROR, "object (%s), terminated due timeout, [%d] retries: %s", z_obj_info(zobj), timeout, msg_string);
				for (i = 4; i < argc; i++) {
					if (!is_empty(argv[i])) {
						z_new_evt(argv[i], zobj.persistent_id, delay);
					}
				}
				return 1;
			} else {
				msg_string = "";
				for (msg_i = 0; msg_i < msg_length(); msg_i++) {
					if (strlen(msg_string) > 0) {
						msg_string += format(" '%s'", msg[msg_i]);
					} else {
						msg_string = format("'%s'", msg[msg_i]);
					}
				}
				logf(ERROR, "unable to checkout, retry in [%d] sec: %s", delay, msg_string);
				sleep(delay);
				retry_count++;
			}
		}
	}
	return 0;
}


// Function: z_format_to_json
// --------------------------
// formating key and value pair to json styled format
//
// key: string passed as key
// value: string passed as value, also will be formated to line
// 		  with `z_format_to_line`
//
// returns: formatted in json style key/value pair
string z_format_to_json(string key, string val) {
	return format("\t\"%s\" : \"%s\"", key, z_format_to_line(val));
}


// Function: z_format_to_line
// --------------------------
// replacing linebreaks to prevent js crashing
//
// inputline: string to convert
//
// returns: formatted string that safe to pass to js interpreter
string z_format_to_line(string inputline) {
	logf(TRACE, "<< %s", inputline);
	string templine;
	templine = inputline;
	templine = gsub(templine, "[\r]", "\\\r");
	templine = gsub(templine, "[\n]", "\\\n");
	logf(TRACE, ">> %s", templine);
	return templine;
}


// Function: z_get_factory
// --------------------------
// getting factory (producer_id) form persid (persistent_id)
//
// persid: persistent_id
//
// returns: factory (producer_id)
string z_get_factory(string persid) {
	if (sindex(persid, ":")) {
		return substr(persid, 0, (sindex(persid, ":")));
	}
	return (string)NULL;
}


// Function: z_get_gl
// --------------------------
// getting group leader
//
// optional args:
//	(int)this_gl {1}: get current session's group leader,
//			   will work if you're already have something checked out,
//			   like you in func on method caused by POST_VAL/PRE_VAL trigger
//			   or attached event macro
//
// returns: factory (producer_id)
object z_get_gl(...) {
	int msg_i;

	if ((argc > 0) && (argv[0] == 1)) {
		send_wait(0, this, "get_gl");
	} else {
		send_wait(0, top_object(), "get_co_group");
	}

	if (msg_error()) {
		L_ERROR
	} else {
		if (msg_length() > 0) {
			return (object)msg[0];
		} else {
			logf(ERROR, "get_gl empty response");
		}
	}
	return (object)NULL;
}


// Function: z_get_latest_object
// --------------------------
// fetching latest in list row and returning it as an object
//
// factory: factory to search on
// wc: whereclause, searching criteria
// domset: factory domset, run `bop_sinfo -l <factory>` to get domsets and their details
//
// returns: object
object z_get_latest_object(string factory, string wc, string domset) {
	int zcount, msg_i;
	object zobj, zfound;
	send_wait(0, top_object(), "call_attr", factory, "sync_fetch", domset, wc, -1, 0);
	if (msg_error()) {
		logf(ERROR, "sync_fetch failed: %s", wc);
		L_ERROR
	} else {
		zcount = msg[1];
		if (zcount > 0) {
			zfound = msg[0];
			send_wait(0, zfound, "dob_by_index", "DEFAULT", zcount - 1, zcount - 1);
			if (msg_error()) {
				logf(ERROR, "dob_by_index failed: %s", wc);
				L_ERROR
			} else {
				zobj = msg[0];
				return zobj;
			}
		}
	}
	return (object)NULL;
}


// Function: z_binpow
// ------------------
// computes power of int
//
// a: int to power
// n: power
//
// returns: powered int
int z_binpow(int a, int n) {
	if (n == 0) {
		return 1;
	}
	if (n % 2 == 1) {
		return z_binpow(a, n - 1);
	} else {
		int b;
		b = z_binpow(a, n / 2);
		return b;
	}
}


// Function: z_modulo
// --------------------------
// returning digit's modulo
//
// num: digit
//
// returns: digit's modulo
int z_modulo(int num) {
	if (num < 0) {
		num = -1;
	}
	return num;
}


// Function: z_new_evt
// --------------------------
// attaches new attached event by event's name or persid to any object with any delay
//
// evtkey: event name or persid
//
// optional args:
//	(string)obj_id: object to attach event to
//	(int)timeout: delay until event trigger
//	(string)group_name: event group name to separate events functionality
//	(int)delayed_start {0/1}: pass 1 to create delayed event which can start manually
//							  or depending on some object related logic
//
// returns: attached event's persid
string z_new_evt(string evtkey, ...) {
	string obj_id, group_name;
	duration timeout;
	int i, msg_i, delayed_start, violate_on_true;
	object gl, new_atev;

	delayed_start = 0;
	timeout = 15;

	for (i=0;i<argc;i++) {
		logf(INFORMATION, "argv[%d]: %s", i, argv[i]);
	}

	if (sindex(evtkey, 'evt:') == 0) {
		send_wait(0, top_object(), "call_attr", "evt", "val_by_key", "persistent_id", evtkey, 2, "sym", "violate_on_true");
		if (msg_error()) {
			logf(ERROR, "%s > val_by_key failed", evtkey);
			L_ERROR
			return;
		} else {
			evtkey = msg[1];
			violate_on_true = msg[2];
		}
	} else {
		send_wait(0, top_object(), "call_attr", "evt", "val_by_key", "sym", evtkey, 1, "violate_on_true");
		if (msg_error()) {
			logf(ERROR, "%s > val_by_key failed", evtkey);
			L_ERROR
			return;
		} else {
			violate_on_true = msg[1];
		}
	}
	if (argc > 1) {
		obj_id = argv[1];
	} else {
		logf(ERROR, "%s > obj_id is required", evtkey);
	}
	if (argc > 2) {
		timeout = argv[2];
	}
	if (argc > 3) {
		if (!is_empty(argv[3])) {
			group_name = argv[3];
		} else {
			group_name = (string)NULL;
		}
	} else if (violate_on_true == 1) {
		group_name = "SLA";
	}
	if (argc > 4) {
		delayed_start = (int)argv[4];
	}

	gl = z_get_gl(0);

	send_wait(0, top_object(), "call_attr", "evt", "new_attached_event", gl, obj_id, (string)evtkey, (duration)timeout, now(), group_name, 0, delayed_start, (string)NULL);
	if (msg_error()) {
		logf(ERROR, "%s > new_attached_event failed", obj_id);
		L_ERROR
	} else {
		new_atev = msg[0];
		if (z_checkin(gl, 1, 0)) {
			logf(ERROR, "%s > not attached to [%s] with [%d] delay", evtkey, obj_id, timeout);
			L_ERROR
		} else {
			logf(SIGNIFICANT, "%s > attached to [%s] with [%d] delay", evtkey, obj_id, timeout);
			return new_atev.persistent_id;
		}
	}
}


// Function: z_obj_by_persid
// --------------------------
// getting object by it's persid
//
// persid: persistent_id
//
// returns: object
object z_obj_by_persid(string persid) {
	object zobj;
	int msg_i;

	send_wait(0, top_object(), "call_attr", z_get_factory(persid), "dob_by_persid", 0, persid);
	if (msg_error()) {
		logf(ERROR, "%s > dob_by_persid failed", persid);
		L_ERROR
		return (object)NULL;
	}
	return (object)msg[0];
}


// Function: z_obj_info
// --------------------------
// getting common object attributes as string
//
// persid: persistent_id
//
// returns: object
string z_obj_info(object zobj) {
	string factory, rel_attr, common_name, result;
	int msg_i;

	if (is_null(zobj)) {
		return "object is null";
	}
	send_wait(0, zobj, "get_attr_vals", 3, "producer_id", "REL_ATTR", "COMMON_NAME");
	if (msg_error()) {
		result = "not a bpobject! : [";
		for (msg_i = 0; msg_i < msg_length(); msg_i++) {
			result += format("'%s'", (string)msg[msg_i]);
		}
		result += "]";
	} else {
		result = format("factory:[%s]. %s:[%s]. %s:[%s]", msg[3], msg[4], msg[6], msg[7], msg[9]);
	}
	return result;
}


// Function: z_upd_val
// --------------------------
// updates attributes with provided data for all matching objects
//
// factory: factory to search on
// wc: whereclause, searching criteria
// delay: delay between iterations if object is busy
// timeout: max iterations before terminating attempts
//
// optional args:
//	-- please notice that at least 1 pair of key/value should be provided --
//	[
//		(string){
//			attribute_name: attribute name to update
//			flag: flag to perform activity on fail, currentnly
//				only `PLAN_B` flag available, which attaches an
//				event on fail. Pass event name or persid as value
//				this flag.
//			update_modifier: set_val method's argument, known modifiers:
//				SURE_SET - forcing the update,
//				SUPPRESS_TRIGGERS - don't trigger attribute related triggers
//		}
//		value: attribute_name/flag/update_modifier value
//	]
//
// returns: object
int z_upd_val(string factory, string wc, int delay, int timeout, ...) {
	set_ilimit(ILIMIT);
	object zfound, gl, zobj;
	int zcount, i, j, msg_i;
	string upd_flag, plan_b;

	send_wait(0, top_object(), "call_attr", factory, "sync_fetch", "STATIC", wc, -1, 0);
	if (msg_error()) {
		logf(SIGNIFICANT, "%s > sync_fetch failed: %s", factory, wc);
		L_ERROR
		return 1;
	}
	zcount = msg[1];
	zfound = msg[0];
	if (zcount == 0) {
		logf(SIGNIFICANT, "%s > nothing found: %s", factory, wc);
		return 1;
	}

	if (argc < 5) {
		logf(SIGNIFICANT, "%s > nothing to update (not enough args): %d", factory, argc);
		return 1;
	}

	gl = z_get_gl();

	for (j=4;j<(argc-1);j=j+2) {
		if (argv[j] == "PLAN_B") {
			plan_b = argv[j+1];
			break;
		}
	}

	for (i = 0; i < zcount; i++) {
		send_wait(0, zfound, "dob_by_index", "DEFAULT", i, i);
		if (msg_error()) {
			logf(ERROR, "%s > dob_by_index [%d] failed: %s", factory, i, wc);
			L_ERROR
		} else {
			zobj = msg[0];
			if (z_checkout(gl, zobj, delay, timeout, plan_b)) {
				return 1;
			}
			for (j = 4; j < (argc - 1); j = j + 2) {
				if (argv[j] == "UPD_FLAG") {
					upd_flag = argv[j+1];
					continue;
				} else if (argv[j] == "PLAN_B") {
					continue;
				}
				if (!is_empty(upd_flag)) {
					send_wait(0, zobj, "call_attr", argv[j], "set_val", argv[j + 1], upd_flag);
				} else {
					send_wait(0, zobj, "call_attr", argv[j], "set_val", argv[j + 1]);
				}
				if (msg_error()) {
					logf(ERROR, "%s > can't set val: %s", factory, wc);
					L_ERROR
					continue;
				}
				logf(INFORMATION, "updating [%s]: '%s' = [%s]", zobj.persistent_id, argv[j], argv[j + 1]);
			}
			if (z_checkin(gl, delay, timeout, plan_b)) {
				return 1;
			}
		}
	}
	logf(SIGNIFICANT, "%s > updated: %s", factory, wc);

	return 0;
}

string z_get_attr_type(string factory, string attr) {
	int msg_i;

	send_wait(0, top_object(), "call_attr", factory, "dob_attr_type_info", attr);
	if (msg_error()) {
		L_ERROR
		return;
	}
	if (msg[1] == "VALUE") {
		switch ((int)msg[2]) {
			case 0:
				return "INTEGER";
			case 1:
				return "DOUBLE";
			case 2:
				return "STRING";
			case 6:
				return "LOCAL_TIME";
			case 7:
				return "DATE";
			case 8:
				return "DURATION";
			case 9:
				return "UUID";
			default:
				return "UNKNOWN";
		}
	} else if (msg[1] == "SREL") {
		return z_get_attr_type(msg[2], msg[3]);
	} else {
		return format("%s to %s", msg[1], msg[2]);
	}
}

// z_nextmonth
//	returns first day of next month
//	@args:
//		0: date
//		1: time ("12:34:56" duration format) (optional)
date z_nextmonth(date dt, ...) {
	int mm, dd, yyyy, splen;
	string splitter[3], str, tm;
	
	tm = "00:00:00";
	if (argc == 2) {
		tm = argv[1];
	}
	splen = split(splitter, substr((string)dt, 0, 12), "/");

	if (splen == 3) {
		mm = (int)splitter[0];
		dd = (int)splitter[1];
		yyyy = (int)splitter[2];
		str = format("%s/%s/%s %s", (mm + 1), "01", yyyy, tm);
		dt = (date)(string)str;
	} else {
		dt = (date)NULL;
	}
	return dt;
}

// z_get_who
//	returns current user
//	uuid who;
//	who = z_get_who();
uuid z_get_who() {
	send_wait(0,top_object(), "call_attr", "cnt", "current_user_id");
	if (msg_error()) {
		return (uuid)NULL;
	}
	return (uuid)msg[0];
}