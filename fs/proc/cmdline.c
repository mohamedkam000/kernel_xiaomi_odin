#include <linux/fs.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/random.h>
#include <linux/string.h>

enum {
	FLAG_DELETE = 0,
	FLAG_REPLACE,
};

#define COMMAND_LINE_SIZE 4096
static char new_command_line[COMMAND_LINE_SIZE];

static int cmdline_proc_show(struct seq_file *m, void *v)
{
	seq_puts(m, new_command_line);
	seq_putc(m, '\n');
	return 0;
}

static int process_flag(int replace, const char *flag, const char *new_var)
{
	char *start_flag, *end_flag, *next_flag;
	char *last_char = new_command_line + COMMAND_LINE_SIZE;
	size_t rest_len, flag_len, cmd_len, var_len, nvar_len;
	int ret = 0;

	while ((start_flag = strnstr(new_command_line, flag, COMMAND_LINE_SIZE))) {
		end_flag = strnchr(start_flag, last_char - start_flag, ' ');

		if (end_flag > last_char)
			end_flag = last_char;

		cmd_len = strlen(new_command_line);
		if (unlikely(cmd_len > COMMAND_LINE_SIZE))
			break;

		next_flag = end_flag + 1;
		rest_len = (size_t)(last_char - end_flag);
		flag_len = (size_t)(end_flag - start_flag);

		if (replace) {
			if (!new_var)
				break;

			nvar_len = strlen(new_var);
			var_len = flag_len - strlen(flag);

			if (nvar_len > var_len &&
			    (cmd_len + (nvar_len - var_len)) > COMMAND_LINE_SIZE)
				break;
		}

		if (rest_len)
			memmove(start_flag, next_flag, rest_len);

		memset(last_char - flag_len, '\0', flag_len);
		ret++;

		if (replace) {
			cmd_len = strlen(new_command_line);
			if (unlikely(cmd_len > COMMAND_LINE_SIZE))
				break;

			sprintf(new_command_line + cmd_len, " %s%s", flag, new_var);

			break;
		}
	}

	return ret;
}

void apply_random(void)
{
	u32 rnd;
	char rand_str[11];

	get_random_bytes(&rnd, sizeof (rnd));
	snprintf(rand_str, sizeof(rand_str), "%08x", rnd);
	return rand_str;
}

static int __init proc_cmdline_init(void)
{
	memcpy(new_command_line, saved_command_line,
		min((size_t)COMMAND_LINE_SIZE, strlen(saved_command_line)));

	process_flag(FLAG_REPLACE, "androidboot.verifiedbootstate=", "green");
	process_flag(FLAG_REPLACE, "androidboot.warranty_bit=", "0");
	process_flag(FLAG_REPLACE, "androidboot.fmp_config=", "1");
	process_flag(FLAG_REPLACE, "androidboot.veritymode=", "enforcing");
	process_flag(FLAG_REPLACE, "androidboot.vbmeta.device_state=", "locked");
	process_flag(FLAG_REPLACE, "androidboot.selinux=", "enforcing");
	process_flag(FLAG_REPLACE, "androidboot.serialno=", apply_random());
	process_flag(FLAG_REPLACE, "androidboot.secureboot=", "1");
	process_flag(FLAG_REPLACE, "androidboot.ramdump=", "disable");
	process_flag(FLAG_REPLACE, "androidboot.secureboot=", "1");
	process_flag(FLAG_REPLACE, "androidboot.bootreason=", "unknown");
	process_flag(FLAG_REPLACE, "androidboot.flash.locked=", "1");
	process_flag(FLAG_REPLACE, "androidboot.force_normal_boot=", "1");

	//~ process_flag(FLAG_REPLACE, "androidboot.ap_serial=", "0x000000000000");
	//~ process_flag(FLAG_REPLACE, "androidboot.boot_devices=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.bootloader=", "S906BOXMDEXK5");
	//~ process_flag(FLAG_REPLACE, "androidboot.carrierid=", "EUX");
	//~ process_flag(FLAG_REPLACE, "androidboot.debug_level=", "0x0");
	//~ process_flag(FLAG_REPLACE, "androidboot.dram_info=", "01,07,00,12G");
	//~ process_flag(FLAG_REPLACE, "androidboot.em.did=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.em.model=", "SM-S906B");
	//~ process_flag(FLAG_REPLACE, "androidboot.hardware=", "gs201");
	//~ process_flag(FLAG_REPLACE, "androidboot.hardware.revision=", "27");
	//~ process_flag(FLAG_REPLACE, "androidboot.revision=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.hardware.sku=", "GE2AE");
	//~ process_flag(FLAG_REPLACE, "androidboot.hmac_mismatch=", "0");
	//~ process_flag(FLAG_REPLACE, "androidboot.wb.snapQB=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.ddr_size=", "12");
	//~ process_flag(FLAG_REPLACE, "androidboot.=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.=", "");
	//~ process_flag(FLAG_REPLACE, "androidboot.=", "");

	proc_create_single("cmdline", 0, NULL, cmdline_proc_show);
	return 0;
}

fs_initcall(proc_cmdline_init);
