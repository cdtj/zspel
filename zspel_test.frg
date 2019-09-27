//	how to run:
//		bop_cmd -u ServiceDesk -f test.frg "run(<test_id>)"

#include "zspel.frg"

void run(int t) {
	int i;
	for (i = 0; i < argc; i++) {
		logf(SIGNIFICANT, "argv[%d]: %s", i, argv[i]);
	}
	do_test(t);
}

void do_test(int t) {
	int i;

	// vars are global in loop 
	// so this is what we have
	string str1, str2;
	object zobj;

	for (i = 0; i < argc; i++) {
		logf(SIGNIFICANT, "argv[%d]: %s", i, argv[i]);
	}

	switch (t) {
		// z_binpow
		case 0:
			printf(z_binpow(-1, -1));
			break;
			
		// z_format_to_js_line
		case 1:
			str1 = "'hello'" + "\n\t" + "\"world\"";
			printf(str1);
			printf("\n");
			printf(z_format_to_js_line(str1));
			break;
			
		// z_format_to_json
		case 2:
			str1 = "param";
			str2 = "'hello'" + "\n\t" + "\"world\"";
			printf(str1 + ":" + str2);
			printf("\n");
			printf(z_format_to_json(str1, str2));
			break;
			
		// z_format_to_line
		case 3:
			str1 = "'hello'" + "\n\t" + "\"world\"";
			printf(str1);
			printf("\n");
			printf(z_format_to_line(str1));
			break;
			
		// z_get_factory
		case 4:
			str1 = "z_get_factory:12345";
			printf(str1);
			printf("\n");
			printf(z_get_factory(str1));
			break;
			
		// z_get_gl
		case 5:
			printf(printf((string)z_get_gl()));
			printf("\n");
			printf(printf((string)z_get_gl(1)));
			
		// z_get_latest_object
		case 6:
		// z_obj_info
		case 7:
			printf("valid obj:\n");
			zobj = z_get_latest_object("cr", "id > 0 AND active = 1", "MLIST_STATIC");
			printf(z_obj_info(zobj) + "\n");
			printf("invalid obj:\n");
			zobj = z_get_latest_object("cr", "id < 0", "MLIST_STATIC");
			printf(z_obj_info(zobj) + "\n");
			break;
		// z_modulo
		case 8:
			for (i = 0; i < 5; i++) {
				j = i;
				if (i & 2) {
					j = i * -1;
				}
				printf("%2d @%2d\n", j, z_modulo(j));
			}
			break;
		// z_obj_by_persid
		case 10:
			printf("valid obj:\n");
			zobj = z_get_latest_object("chgcat", "id > 0 AND delete_flag = 0", "MLIST_STATIC");
			printf(z_obj_info(zobj) + "\n");
			if (!is_null(zobj)) {
				printf("obj by persid:\n");
				zobj = z_obj_by_persid(format("%s:%d", zobj.producer_id, zobj.id));
				printf(z_obj_info(zobj) + "\n");
			}
			break;
		// z_obj_by_persid
		case 11:
			printf("valid obj:\n");
			zobj = z_get_latest_object("chgcat", "id > 0 AND delete_flag = 0", "MLIST_STATIC");
			printf(z_obj_info(zobj) + "\n");
			if (!is_null(zobj)) {
				printf("obj by persid:\n");
				zobj = z_obj_by_persid(format("%s:%d", zobj.producer_id, zobj.id));
				printf(z_obj_info(zobj) + "\n");
			}
			break;
		// z_upd_val
		case 12:
			printf("cr, ref_num 2776300:\n");
			z_upd_val("cr", "ref_num = '2776300'", 1, 1, 
				"summary", (string)now(), 
				"status", "HOLD", 
				"UPD_FLAG", "SUPPRESS_TRIGGERS", 
				"PLAN_B", "CR2ASGN"
			);
			break;
		// who's there?
		default:
			printf("unknown test\n");
	}
}
