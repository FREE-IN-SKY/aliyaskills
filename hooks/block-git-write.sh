#!/usr/bin/env bash
# 严格白名单：只放行已知只读 git 查询，其余一律拦截。
# 目标：修改类 git 命令绝不通过；查询类命令尽量完整放行。
# 支持识别 rtk git、git 全局参数、以及 bash/sh/zsh -c 中的嵌套 git 调用。
input=$(cat)

HOOK_INPUT="$input" python3 <<'PY'
import json
import os
import posixpath
import re
import shlex
import sys

BLOCK_MESSAGE = "BLOCKED: 仅允许只读 git 查询命令。可写或未知 git 命令已拦截。"

READ_ONLY = {
    "annotate",
    "archive",
    "blame",
    "bugreport",
    "cat-file",
    "check-attr",
    "check-ignore",
    "check-mailmap",
    "check-ref-format",
    "cherry",
    "count-objects",
    "describe",
    "diagnose",
    "diff",
    "diff-files",
    "diff-index",
    "diff-tree",
    "difftool",
    "for-each-ref",
    "format-patch",
    "fsck",
    "get-tar-commit-id",
    "grep",
    "help",
    "log",
    "ls-files",
    "ls-remote",
    "ls-tree",
    "merge-base",
    "merge-tree",
    "name-rev",
    "pack-redundant",
    "patch-id",
    "range-diff",
    "request-pull",
    "rev-list",
    "rev-parse",
    "shortlog",
    "show",
    "show-branch",
    "show-index",
    "show-ref",
    "status",
    "stripspace",
    "unpack-file",
    "var",
    "verify-commit",
    "verify-pack",
    "verify-tag",
    "version",
    "whatchanged",
}

MIXED = {
    "bisect",
    "branch",
    "config",
    "notes",
    "reflog",
    "remote",
    "replace",
    "stash",
    "submodule",
    "tag",
    "worktree",
}

CONTROL_TOKENS = {";", "&&", "||", "|", "&", "(", ")"}
SHELLS = {"bash", "sh", "zsh"}
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*$")

GLOBAL_OPTIONS_WITH_VALUE = {
    "-C",
    "-c",
    "--config-env",
    "--exec-path",
    "--git-dir",
    "--namespace",
    "--super-prefix",
    "--work-tree",
}

GLOBAL_OPTIONS_NO_VALUE = {
    "-p",
    "-P",
    "--bare",
    "--glob-pathspecs",
    "--help",
    "--html-path",
    "--icase-pathspecs",
    "--info-path",
    "--literal-pathspecs",
    "--man-path",
    "--no-pager",
    "--no-replace-objects",
    "--noglob-pathspecs",
    "--paginate",
    "--version",
}


def basename(token):
    return posixpath.basename(token)


def shell_tokens(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def is_assignment(token):
    return bool(ASSIGNMENT_RE.match(token))


def is_redirection(token):
    return token in {"<", ">", ">>", "2>", "2>>", "&>", ">&", "<<<"}


def split_simple_commands(tokens):
    current = []
    for token in tokens:
        if token in CONTROL_TOKENS:
            if current:
                yield current
                current = []
        else:
            current.append(token)
    if current:
        yield current


def command_is_blocked(command):
    if not command:
        return False
    try:
        tokens = shell_tokens(command)
    except ValueError:
        return "git" in command

    for simple in split_simple_commands(tokens):
        if simple_command_is_blocked(simple):
            return True
    return False


def simple_command_is_blocked(tokens):
    i = 0
    while i < len(tokens):
        token = tokens[i]
        if is_assignment(token):
            i += 1
            continue
        if is_redirection(token):
            i += 2
            continue
        return command_at_is_blocked(tokens, i)
    return False


def command_at_is_blocked(tokens, index):
    command = basename(tokens[index])
    args = tokens[index + 1 :]

    if command == "env":
        return env_command_is_blocked(args)
    if command in {"sudo", "doas"}:
        return sudo_command_is_blocked(args)
    if command == "command":
        return command_builtin_is_blocked(args)
    if command == "rtk":
        return rtk_command_is_blocked(args)
    if command in SHELLS:
        return shell_command_is_blocked(args)
    if command == "git":
        return git_invocation_is_blocked(args)
    return False


def env_command_is_blocked(args):
    i = 0
    while i < len(args):
        token = args[i]
        if is_assignment(token):
            i += 1
            continue
        if token == "-u" and i + 1 < len(args):
            i += 2
            continue
        if token.startswith("-"):
            i += 1
            continue
        return simple_command_is_blocked(args[i:])
    return False


def sudo_command_is_blocked(args):
    # sudo/doas [-选项] [--] 命令 ... —— 透传给实际命令判断
    i = 0
    while i < len(args):
        token = args[i]
        # 选项吃一个参数的情况
        if token in {"-u", "-g", "-U", "-C", "-D", "-R", "-T", "-A", "-a", "-r", "-t", "-p"} and i + 1 < len(args):
            i += 2
            continue
        if token.startswith("-") and token not in {"-"}:
            # 形如 -u=root 的合并写法
            i += 1
            continue
        if token == "--":
            i += 1
            break
        break
    if i >= len(args):
        return False
    return simple_command_is_blocked(args[i:])


def command_builtin_is_blocked(args):
    i = 0
    while i < len(args) and args[i].startswith("-"):
        # command -v/-V/type 查询命令本身，不执行 git。
        if args[i] in {"-v", "-V"}:
            return False
        i += 1
    if i >= len(args):
        return False
    return simple_command_is_blocked(args[i:])


def rtk_command_is_blocked(args):
    if not args:
        return False
    wrapped = basename(args[0])
    if wrapped == "git":
        return git_invocation_is_blocked(args[1:])
    if wrapped in SHELLS:
        return shell_command_is_blocked(args[1:])
    return False


def shell_command_is_blocked(args):
    i = 0
    while i < len(args):
        token = args[i]
        if token == "-c" or (token.startswith("-") and not token.startswith("--") and "c" in token):
            if i + 1 >= len(args):
                return False
            return command_is_blocked(args[i + 1])
        i += 1
    return False


def git_invocation_is_blocked(args):
    subcommand_index = find_git_subcommand_index(args)
    if subcommand_index is None:
        return False
    if subcommand_index < 0:
        return True

    subcommand = args[subcommand_index]
    sub_args = args[subcommand_index + 1 :]
    if subcommand in READ_ONLY:
        return False
    if subcommand in MIXED:
        return mixed_git_command_is_blocked(subcommand, sub_args)
    return True


def find_git_subcommand_index(args):
    i = 0
    while i < len(args):
        token = args[i]

        if token in {"--help", "--version"}:
            return None
        if token in GLOBAL_OPTIONS_NO_VALUE:
            i += 1
            continue
        if token in GLOBAL_OPTIONS_WITH_VALUE:
            i += 2
            continue
        if any(token.startswith(opt + "=") for opt in GLOBAL_OPTIONS_WITH_VALUE):
            i += 1
            continue
        if token.startswith("-C") and token != "-C":
            i += 1
            continue
        if token.startswith("-c") and token != "-c":
            i += 1
            continue
        if token.startswith("-"):
            return -1
        return i
    return None


def mixed_git_command_is_blocked(subcommand, args):
    if subcommand == "branch":
        return branch_is_blocked(args)
    if subcommand == "remote":
        return remote_is_blocked(args)
    if subcommand == "reflog":
        return first_action_is_blocked(args, allow={"show", "exists"}, block={"delete", "drop", "expire"})
    if subcommand == "tag":
        return tag_is_blocked(args)
    if subcommand == "config":
        return config_is_blocked(args)
    if subcommand == "notes":
        return first_action_is_blocked(args, allow={"list", "show"}, block={"add", "append", "copy", "edit", "merge", "prune", "remove"})
    if subcommand == "replace":
        return replace_is_blocked(args)
    if subcommand == "stash":
        # 裸 git stash 等同 git stash push，是写操作；显式 push/pop 等也走这里
        return first_action_is_blocked(args, allow={"list", "show"}, block={"apply", "branch", "clear", "create", "drop", "pop", "push", "save", "store"}, default_blocked=True)
    if subcommand == "worktree":
        return first_action_is_blocked(args, allow={"list"}, block={"add", "lock", "move", "prune", "remove", "repair", "unlock"})
    if subcommand == "submodule":
        return first_action_is_blocked(args, allow={"status"}, block={"absorbgitdirs", "add", "deinit", "init", "set-branch", "set-url", "sync", "update"})
    if subcommand == "bisect":
        return first_action_is_blocked(args, allow={"log", "view", "visualize"}, block={"bad", "good", "new", "old", "replay", "reset", "run", "skip", "start", "terms"})
    return True


def first_action_is_blocked(args, allow, block, default_blocked=False):
    action = first_non_option(args)
    if action is None:
        return default_blocked
    if action in block:
        return True
    if action in allow:
        return False
    return True


def first_non_option(args):
    i = 0
    while i < len(args):
        token = args[i]
        if token == "--":
            return args[i + 1] if i + 1 < len(args) else None
        if token.startswith("-"):
            i += 1
            continue
        return token
    return None


def branch_is_blocked(args):
    write_flags = {
        "-C",
        "-D",
        "-M",
        "-c",
        "-d",
        "-f",
        "-m",
        "--copy",
        "--create-reflog",
        "--delete",
        "--edit-description",
        "--force",
        "--move",
        "--set-upstream",
        "--track",
        "--unset-upstream",
    }
    list_flags = {
        "-a",
        "-l",
        "-r",
        "-v",
        "-vv",
        "--all",
        "--contains",
        "--list",
        "--merged",
        "--no-contains",
        "--no-merged",
        "--points-at",
        "--remotes",
    }
    if any(arg in write_flags for arg in args):
        return True
    has_list_flag = any(arg in list_flags for arg in args)
    positionals = [arg for arg in args if not arg.startswith("-")]
    return bool(positionals and not has_list_flag)


def remote_is_blocked(args):
    if not args:
        return False
    if all(arg in {"-v", "--verbose"} for arg in args):
        return False
    action = first_non_option(args)
    if action in {"get-url", "show"}:
        return False
    return True


def tag_is_blocked(args):
    write_flags = {
        "-F",
        "-a",
        "-d",
        "-f",
        "-m",
        "-s",
        "-u",
        "--annotate",
        "--delete",
        "--edit",
        "--file",
        "--force",
        "--local-user",
        "--sign",
    }
    list_flags = {
        "-l",
        "--contains",
        "--list",
        "--merged",
        "--no-contains",
        "--no-merged",
        "--points-at",
    }
    if any(arg in write_flags for arg in args):
        return True
    has_list_flag = any(arg in list_flags or arg.startswith("-n") for arg in args)
    positionals = [arg for arg in args if not arg.startswith("-")]
    return bool(positionals and not has_list_flag)


def config_is_blocked(args):
    write_flags = {
        "-e",
        "--add",
        "--edit",
        "--remove-section",
        "--rename-section",
        "--replace-all",
        "--unset",
        "--unset-all",
    }
    read_flags = {
        "-l",
        "--get",
        "--get-all",
        "--get-color",
        "--get-colorbool",
        "--get-regexp",
        "--get-urlmatch",
        "--list",
        "--name-only",
        "--show-origin",
        "--show-scope",
    }
    option_args = {"--file", "-f", "--blob", "--type"}
    if any(arg in write_flags for arg in args):
        return True
    if any(arg in read_flags for arg in args):
        return False

    positionals = []
    i = 0
    while i < len(args):
        token = args[i]
        if token in option_args:
            i += 2
            continue
        if token.startswith("--type="):
            i += 1
            continue
        if token.startswith("-"):
            i += 1
            continue
        positionals.append(token)
        i += 1
    return len(positionals) >= 2


def replace_is_blocked(args):
    if any(arg in {"-d", "--delete"} for arg in args):
        return True
    if not args:
        return False
    if any(arg in {"-l", "--list"} for arg in args):
        return False
    return any(not arg.startswith("-") for arg in args)


try:
    payload = json.loads(os.environ.get("HOOK_INPUT", ""))
    command = payload.get("tool_input", {}).get("command", "")
except Exception:
    command = ""

if command_is_blocked(command):
    print(BLOCK_MESSAGE, file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PY
exit $?
