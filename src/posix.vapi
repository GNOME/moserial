/* posix.vapi
 *
 * Copyright (C) 2008  Emmanuele Bassi
 * Copyright (C) 2008  Matias De la Puente
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authors:
 * 	Matias De la Puente <mfpuente.ar@gmail.com>
 *  Emmanuele Bassi
 */

namespace POSIX
{
	[CCode (cname = "assert", cheader_filename = "assert.h")]
	public static void assert (string expresion);
	
	
	[CCode (lower_case_cprefix = "", cheader_filename = "ctype.h")]
	namespace CType
	{
		public static int digittoint (int c);
		public static bool isalnum (int c);
		public static bool isalpha (int c);
		public static bool isascii (int c);
		public static bool iscntrl (int c);
		public static bool isdigit (int c);
		public static bool isgraph (int c);
		public static bool ishexnumber (int c);
		public static bool isideogram (int c);
		public static bool islower (int c);
		public static bool isnumber (int c);
		public static bool isphonogram (int c);
		public static bool isspecial (int c);
		public static bool isprint (int c);
		public static bool ispunct (int c);
		public static bool isrune (int c);
		public static bool isspace (int c);
		public static bool isupper (int c);
		public static bool isxdigit (int c);
		public static int toascii (int c);
		public static int tolower (int c);
		public static int toupper (int c);
	}
	
	
	[CCode (cname = "dirent", cheader_filename = "dirent.h")]
	public struct Dirent
	{
		public ulong d_ino;
		public long d_off;
		public ushort d_reclen;
		public weak string d_name;
	}
		
	[Compact]
	[CCode (cname = "DIR", free_function = "closedir", cheader_filename = "dirent.h")]
	public class Directory
	{
		[CCode (cname = "opendir")]
		public static Directory open (string name);
		[CCode (cname = "readdir")]
		public Dirent read ();
		[CCode (cname = "rewinddir")]
		public Dirent rewind ();
		[CCode (cname = "seekdir")]
		public void seek (long offset);
		[CCode (cname = "telldir")]
		public long tell ();
		[CCode (cname = "dirfd")]
		public int get_fd ();
	}

	
	[CCode (lower_case_cprefix = "", cheader_filename = "errno.h")]
	namespace Error
	{
		// see errno(3)
		public const int E2BIG;
		public const int EACCESS;
		public const int EADDRINUSE;
		public const int EADDRNOTAVAIL;
		public const int EAFNOSUPPORT;
		public const int EAGAIN;
		public const int EALREADY;
		public const int EBADE;
		public const int EBADF;
		public const int EBADFD;
		public const int EBADMSG;
		public const int EBADR;
		public const int EBADRQC;
		public const int EBADSLT;
		public const int EBUSY;
		public const int ECANCELED;
		public const int ECHILD;
		public const int ECHRNG;
		public const int ECOMM;
		public const int ECONNABORTED;
		public const int ECONNREFUSED;
		public const int ECONNRESET;
		public const int EDEADLK;
		public const int EDEADLOCK;
		public const int EDESTADDRREQ;
		public const int EDOM;
		public const int EDQUOT;
		public const int EEXIST;
		public const int EFAULT;
		public const int EFBIG;
		public const int EHOSTDOWN;
		public const int EHOSTUNREACH;
		public const int EIDRM;
		public const int EILSEQ;
		public const int EINPROGRESS;
		public const int EINTR;
		public const int EINVAL;
		public const int EIO;
		public const int EISCONN;
		public const int EISDIR;
		public const int EISNAM;
		public const int EKEYEXPIRED;
		public const int EKEYREJECTED;
		public const int EKEYREVOKED;
		public const int EL2HLT;
		public const int EL2NSYNC;
		public const int EL3HLT;
		public const int EL3RST;
		public const int ELIBACC;
		public const int ELIBBAD;
		public const int ELIBMAX;
		public const int ELIBSCN;
		public const int ELIBEXEC;
		public const int ELOOP;
		public const int EMEDIUMTYPE;
		public const int EMFILE;
		public const int EMLINK;
		public const int EMSGSIZE;
		public const int EMULTIHOP;
		public const int ENAMETOOLONG;
		public const int ENETDOWN;
		public const int ENETRESET;
		public const int ENETUNREACH;
		public const int ENFILE;
		public const int ENOBUFS;
		public const int ENODATA;
		public const int ENODEV;
		public const int ENOENT;
		public const int ENOEXEC;
		public const int ENOKEY;
		public const int ENOLCK;
		public const int ENOLINK;
		public const int ENOMEDIUM;
		public const int ENOMEM;
		public const int ENOMSG;
		public const int ENONET;
		public const int ENOPKG;
		public const int ENOPROTOOPT;
		public const int ENOSPC;
		public const int ENOSR;
		public const int ENOSTR;
		public const int ENOSYS;
		public const int ENOTBLK;
		public const int ENOTCONN;
		public const int ENOTDIR;
		public const int ENOTEMPTY;
		public const int ENOTSOCK;
		public const int ENOTSUP;
		public const int ENOTTY;
		public const int ENOTUNIQ;
		public const int ENXIO;
		public const int EOPNOTSUPP;
		public const int EOVERFLOW;
		public const int EPERM;
		public const int EPFNOSUPPORT;
		public const int EPIPE;
		public const int EPROTO;
		public const int EPROTONOSUPPORT;
		public const int EPROTOTYPE;
		public const int ERANGE;
		public const int EREMCHG;
		public const int EREMOTE;
		public const int EREMOTEIO;
		public const int ERESTART;
		public const int EROFS;
		public const int ESHUTDOWN;
		public const int ESPIPE;
		public const int ESOCKTNOSUPPORT;
		public const int ESRCH;
		public const int ESTALE;
		public const int ESTRPIPE;
		public const int ETIME;
		public const int ETIMEDOUT;
		public const int ETXTBSY;
		public const int EUCLEAN;
		public const int EUNATCH;
		public const int EUSERS;
		public const int EWOULDBLOCK;
		public const int EXDEV;
		public const int EXFULL;

		// this is a const int because you're only supposed to copy
		// the errno value, not change it
		public const int errno;

		[CCode (cname = "strerror")]
		public static weak string to_string (int err_no);

		[CCode (cname = "perror")]
		public static void print_error (string? prefix = null);
	}
	
	
	[CCode (cheader_filename = "fcntl.h,unistd.h")]
	namespace File
	{
		[CCode (lower_case_cprefix = "F_")]
		namespace FDFlag
		{
			public const int DUPFD;
			public const int DUP2FD;
			public const int GETFD;
			public const int SETFD;
			public const int GETFL;
			public const int SETFL;
			public const int GETOWN;
			public const int SETOWN;
			public const int GETSIG;
			public const int SETSIG;
			public const int FREESP;
			public const int GETLK;
			public const int GETLK64;
			public const int SETLK;
			public const int SETLK64;
			public const int SETLKW;
			public const int SETLKW64;
			public const int SHARE;
			public const int UNSHARE;
			// linux 2.4 onwards
			public const int GETLEASE;
			public const int SETLEASE;
			public const int RDLCK;
			public const int WRLCK;
			public const int UNLCK;
			public const int NOTIFY;
		}
		
		[CCode (lower_case_cprefix = "DN_")]
		namespace NotifyMask
		{
			public const int ACCESS;
			public const int MODIFY;
			public const int CREATE;
			public const int DELETE;
			public const int RENAME;
			public const int ATTRIB;
			public const int MULTISHOT;
		}
		
		[CCode (lower_case_cprefix = "O_")]
		namespace AccessMode
		{
			public const int ACCMODE;
			public const int RDONLY;
			public const int WRONLY;
			public const int RDWR;
		}
		
		[CCode (lower_case_cprefix = "O_")]
		namespace FileCreation
		{
			public const int CREAT;
			public const int EXCL;
			public const int NOCTTY;
			public const int TRUNC;
			public const int XATTR;
		}
		
		[CCode (lower_case_cprefix = "O_")]
		namespace FileStatus
		{
			public const int APPEND;
			public const int ASYNC;
			public const int DIRECT;
			public const int DIRECTORY;
			public const int DSYNC;
			public const int LARGEFILE;
			public const int NOATIME;
			public const int NOFOLLOW;
			public const int NONBLOCK;
			public const int NDELAY;
			public const int RSYNC;
			public const int SYNC;
		}
		
		[CCode (lower_case_cprefix = "S_")]
		namespace FileMode
		{
			public const ulong IRWXU;
			public const ulong IRUSR;
			public const ulong IWUSR;
			public const ulong IXUSR;
			public const ulong IRWXG;
			public const ulong IRGRP;
			public const ulong IWGRP;
			public const ulong IXGRP;
			public const ulong IRWXO;
			public const ulong IROTH;
			public const ulong IWOTH;
			public const ulong IXOTH;
		}
		
		[CCode (cname = "flock")]
		public struct FLock
		{
			public short l_type;
			public short l_whence;
			public long l_start;
			public long l_len;
			public long l_pid;
		}
		
		[CCode (cname = "iovec", cheader_filename = "sys/uio.h")]
		public struct IOVector
		{
			public void* iov_base;
			public size_t iov_len;
		}
		
		[CCode (cname = "fcntl")]
		public static int fcntl (int fd, int cmd);
		[CCode (cname = "fcntl")]
		public static int fcntl_with_arg (int fd, int cmd, ulong arg);
		[CCode (cname = "fcntl")]
		public static int fcntl_with_flock (int fd, int cmd, FLock @lock);
		[CCode (cname = "open")]
		public static int open (string pathname, int flags, ulong mode = 0);
		[CCode (cname = "creat")]
		public static int creat (string pathname, ulong mode);
		[CCode (cname = "openat")]
		public static int open_at (int dirfd, string pathname, int flags, ulong mode = 0);
		[CCode (cname = "read")]
		public static ssize_t read (int fd, void* buf, size_t nbyte);
		[CCode (cname = "pread")]
		public static ssize_t pread (int fd, void* buf, size_t nbyte, long offset);
		[CCode (cname = "readv", cheader_filename = "sys/uio.h")]
		public static int read_vector (int fd, IOVector vector, size_t count);
		[CCode (cname = "write")]
		public static ssize_t write (int fd, void* buf, size_t nbyte);
		[CCode (cname = "pwrite")]
		public static ssize_t pwrite (int fd, void* buf, size_t nbyte, long offset);
		[CCode (cname = "writev", cheader_filename = "sys/uio.h")]
		public static int write_vector (int fd, IOVector vector, size_t count);
		[CCode (cname = "close")]
		public static int close (int fd);
	}

	
	[CCode (lower_case_cprefix = "", cheader_filename = "fenv.h")]
	namespace FloatEnv
	{
		[CCode (cname = "fenv_t")]
		public struct FloatEnv { }
		
		public static int feclearexcept (int excepts);
		public static int fegetexceptflag (out ushort flagp, int excepts);
		public static int feraiseexcept (int excepts);
		public static int fesetexceptflag (ref ushort flagp, int excepts);
		public static int fetestexcept (int excepts);
		public static int fegetround ();
		public static int fesetround (int rounding_mode);
		public static int fegetenv (out FloatEnv envp);
		public static int feholdexcept (out FloatEnv envp);
		public static int fesetenv (ref FloatEnv envp);
		public static int feupdateenv (ref FloatEnv envp);
	}

	
	[CCode (cname = "group", cheader_filename = "grp.h")]
	public struct Group
	{
		public weak string gr_name;
		public weak string gr_passwd;
		public long gr_gid;
		public weak string[] gr_mem;
		
		[CCode (cname = "getgrnam")]
		public static Group get_by_name (string name);
		[CCode (cname = "getgrgid")]
		public static Group get_by_gid (long gid);
		[CCode (cname = "getgrent")]
		public static Group get_entry ();
		[CCode (cname = "setgrent")]
		public static void set_entry ();
		[CCode (cname = "entgrent")]
		public static void end_entry ();
		[CCode (cname = "fgetgrent")]
		public static Group get_entry_by_stream (GLib.FileStream stream);
	}
	
	[CCode (cname = "passwd", cheader_filename = "pwd.h")]
	public struct Password
	{
		public weak string pw_name;
		public weak string pw_passwd;
		public long pw_uid;
		public long pw_gid;
		public weak string pw_gecos;
		public weak string pw_dir;
		public weak string pw_shell;
		
		[CCode (cname = "getpw")]
		public static int reconstruct (long uid, string buf);
		[CCode (cname = "getpwnam")]
		public static Password get_by_name (string name);
		[CCode (cname = "getpwuid")]
		public static Password get_by_uid (long uid);
		[CCode (cname = "getpwent")]
		public static Password get_entry ();
		[CCode (cname = "setpwent")]
		public static void set_entry ();
		[CCode (cname = "entpwent")]
		public static void end_entry ();
		[CCode (cname = "fgetpwent")]
		public static Password get_entry_by_stream (GLib.FileStream stream);
	}
	
	[CCode (cheader_filename = "signal.h")]
	namespace Signal
	{
		// signals defined in signal(7)
		[CCode (cname = "SIGHUP")]
		public const int HUP;
		[CCode (cname = "SIGINT")]
		public const int INT;
		[CCode (cname = "SIGQUIT")]
		public const int QUIT;
		[CCode (cname = "SIGILL")]
		public const int ILL;
		[CCode (cname = "SIGABRT")]
		public const int ABRT;
		[CCode (cname = "SIGFPE")]
		public const int FPE;
		[CCode (cname = "SIGKILL")]
		public const int KILL;
		[CCode (cname = "SIGSEGV")]
		public const int SEGV;
		[CCode (cname = "SIGPIPE")]
		public const int PIPE;
		[CCode (cname = "SIGALRM")]
		public const int ALRM;
		[CCode (cname = "SIGTERM")]
		public const int TERM;
		
		// dispositions defined in signal(2)
		[CCode (cname = "SIG_DFL")]
		public const int DFL;
		[CCode (cname = "SIG_IGN")]
		public const int IGN;
		
		public static delegate void Handler (int sig_num);
		
		// vala does not have overloading, so we simply create
		// to functions, one taking the handler and one taking
		// the value
		[CCode (cname = "signal")]
		public static void set_handler (int sig_num, Handler hnd);
		[CCode (cname = "signal")]
		public static void set_value (int sig_num, int disposition = DFL);
		
		[CCode (cname = "siginfo_t")]
		public struct Info
		{
			int si_signo;
			int si_errno;
			int si_code;
			// pid_t si_pid;
			long si_pid;
			// uid_t si_uid;
			long si_uid;
			int si_status;
			// clock_t si_utime;
			long si_utime;
			// clock_t si_stime;
			long si_stime;
			// sigval_t si_value;
			int si_value;
			int si_int;
			void* si_ptr;
			void* si_addr;
			int si_band;
			int si_fd;
		}

		public static delegate void ActionHandler (int sig_num, Info info, void* context);
		
		[CCode (cname = "struct sigaction")]
		public struct Action
		{
			public Handler sa_handler;
			public ActionHandler sa_sigaction;
			public int sa_mask;
			public int sa_flags;
		}
		
		[CCode (cname = "SA_NOCLDSTOP")]
		public const int NO_CLDSTOP;
		[CCode (cname = "SA_NOCLDWAIT")]
		public const int NO_CLDWAIT;
		[CCode (cname = "SA_RESETHAND")]
		public const int RESETHAND;
		[CCode (cname = "SA_ONSTACK")]
		public const int ONSTACK;
		[CCode (cname = "SA_RESTART")]
		public const int RESTART;
		[CCode (cname = "SA_NODEFER")]
		public const int NODEFER;
		[CCode (cname = "SA_SIGINFO")]
		public const int SIGINFO;
		
		[CCode (cname = "sigaction")]
		public static int set_action (int sig_num, Action act, out Action? old_act = null);
		[CCode (cname = "kill")]
		public static int kill (long pid, int sig);
		[CCode (cname = "killpg")]
		public static int kill_process_group (long pgrp, int sig);
		[CCode (cname = "raise")]
		public static int raise (int sig);
		[CCode (cname = "sigpause")]
		public static int pause (int sig);
		[CCode (cname = "sighold")]
		public static int hold (int sig);
		[CCode (cname = "sigignore")]
		public static int ignore (int sig);
		[CCode (cname = "sigrelse")]
		public static int relse (int sig);	
	}


	[CCode (cname="struct termios", cheader_filename = "termios.h")]
	public struct Termios
	{
		public uint c_iflag;
		public uint c_oflag;
		public uint c_cflag;
		public uint c_lflag;
		public uchar c_line;
		public weak uchar[] c_cc;
		public uint c_ispeed;
		public uint c_ospeed;
			
		[CCode (cname = "cfgetispeed")]
		public uint get_input_speed ();
		[CCode (cname = "cfgetospeed")]
		public uint get_output_speed ();
		[CCode (cname = "cfsetispeed")]
		public int set_input_speed (uint speed);
		[CCode (cname = "cfsetospeed")]
		public int set_output_speed (uint speed);
		[CCode (cname = "tcdrain")]
		public static int drain (int fd);
		[CCode (cname = "tcflow")]
		public static int flow (int fd, int action);
		[CCode (cname = "tcflush")]
		public static int flush (int fd, int queue_selector);
		[CCode (cname = "tcgetattr", instance_pos = -1)]
		public int get_attributes (int fd);
		[CCode (cname = "tcgetsid")]
		public static long get_session_id (int fd);
		[CCode (cname = "tcsendbreak")]
		public static int send_break (int fd, int duration);
		[CCode (cname = "tcsetattr", instance_pos = -1)]
		public int set_attribute (int fd, int optional_actions);
	}
			
	[CCode (lower_case_cprefix = "V", cheader_filename = "termios.h")]
	namespace CCIndex
	{
		public const int INTR;
		public const int QUIT;
		public const int ERASE;
		public const int KILL;
		public const int EOF;
		public const int MIN;
		public const int EOL;
		public const int TIME;
		public const int START;
		public const int STOP;
		public const int SUSP;
	}
		
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace InputMode
	{
		public const uint BRKINT;
		public const uint ICRNL;
		public const uint IGNBRK;
		public const uint IGNCR;
		public const uint IGNPAR;
		public const uint INLCR;
		public const uint INPCK;
		public const uint ISTRIP;
		public const uint IXANY;
		public const uint IXOFF;
		public const uint IXON;
		public const uint PARMRK;
		
		public const uint CRTSCTS;
	}
	
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace OutputMode
	{
		public const uint OPOST;
		public const uint ONLCR;
		public const uint OCRNL;
		public const uint ONOCR;
		public const uint ONLRET;
		public const uint OFILL;
		public const uint NLDLY;
		public const uint NL0;
		public const uint NL1;
		public const uint CRDLY;
		public const uint CR0;
		public const uint CR1;
		public const uint CR2;
		public const uint CR3;
		public const uint TABDLY;
		public const uint TAB0;
		public const uint TAB1;
		public const uint TAB2;
		public const uint TAB3;
		public const uint BSDLY;
		public const uint BS0;
		public const uint BS1;
		public const uint VTDLY;
		public const uint VT0;
		public const uint VT1;
		public const uint FFDLY;
		public const uint FF0;
		public const uint FF1;
	}
	
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace Misc
	{
		public const int VTIME;
		public const int VMIN;
	}
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace BaudRate
	{
		public const uint B0;
		public const uint B50;
		public const uint B75;
		public const uint B110;
		public const uint B134;
		public const uint B150;
		public const uint B200;
		public const uint B300;
		public const uint B600;
		public const uint B1200;
		public const uint B1800;
		public const uint B2400;
		public const uint B4800;
		public const uint B9600;
		public const uint B19200;
		public const uint B38400;
	
		public const uint B57600;	
		public const uint B115200;
		public const uint B230400;
		public const uint B460800;
		public const uint B576000;
		public const uint B921600;
	}
	
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace ControlMode
	{
		public const uint CSIZE;
		public const uint CS5;
		public const uint CS6;
		public const uint CS7;
		public const uint CS8;
		public const uint CSTOPB;
		public const uint CREAD;
		public const uint PARENB;
		public const uint PARODD;
		public const uint HUPCL;
		public const uint CLOCAL;
	}
	
	[CCode (lower_case_cprefix = "", cheader_filename = "termios.h")]
	namespace LocalMode
	{
		public const uint ECHO;
		public const uint ECHOE;
		public const uint ECHOK;
		public const uint ECHONL;
		public const uint ICANON;
		public const uint IEXTEN;
		public const uint ISIG;
		public const uint NOFLSH;
		public const uint TOSTOP;
	}
	
	[CCode (lower_case_cprefix = "TCSA", cheader_filename = "termios.h")]
	namespace AttributeSelection
	{
		public const int NOW;
		public const int DRAIN;
		public const int FLUSH;
	}
	
	[CCode (lower_case_cprefix = "TC", cheader_filename = "termios.h")]
	namespace LineControl
	{
		public const int IFLUSH;
		public const int IOFLUSH;
		public const int OFLUSH;
		public const int IOFF;
		public const int ION;
		public const int OOFF;
		public const int OON;
	}
	[CCode (lower_case_cprefix = "", cheader_filename = "sys/ioctl.h")]
	namespace ioctl
	{
		public const int TIOCMGET;
		public const int TIOCMSET;
		public const int TIOCM_RTS;
		[CCode (cname = "ioctl")]
		public static int ioctl (int fd, int a, out int b);
	}
}
