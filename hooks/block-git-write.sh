#!/usr/bin/env bash
# 严格白名单：只放行已知只读 git 查询，其余一律拦截。
# 目标：拦截能识别的 Codex git 写命令；查询类命令尽量完整放行。
# 支持识别 rtk git、shell 嵌套、functions.exec 及 write_stdin 中的 git 调用。
input=$(cat)

HOOK_INPUT="$input" python3 <<'PY'
import ast
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
    "cat-file",
    "check-attr",
    "check-ignore",
    "check-mailmap",
    "check-ref-format",
    "cherry",
    "count-objects",
    "describe",
    "diff",
    "diff-files",
    "diff-index",
    "diff-tree",
    "for-each-ref",
    "fsck",
    "get-tar-commit-id",
    "grep",
    "help",
    "log",
    "ls-files",
    "ls-remote",
    "ls-tree",
    "merge-base",
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
    "var",
    "verify-commit",
    "verify-pack",
    "verify-tag",
    "version",
    "whatchanged",
}

ALWAYS_BLOCKED = {
    "bugreport",
    "diagnose",
    "difftool",
    "format-patch",
    "help",
    "merge-tree",
    "unpack-file",
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
CMD_LITERAL_RE = re.compile(r"(?:\bcmd\b|[\"']cmd[\"'])\s*:\s*([\"'`])")
WRITE_STDIN_CALL_RE = re.compile(r"\btools\.write_stdin\s*\(")
CHARS_PROPERTY_RE = re.compile(r"^(?:chars|[\"']chars[\"'])\s*:\s*")

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
        if (
            token.isdigit()
            and i + 1 < len(tokens)
            and is_redirection(tokens[i + 1])
        ):
            i += 3
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
    if command == "exec":
        return exec_builtin_is_blocked(args)
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


def exec_builtin_is_blocked(args):
    """Inspect the command executed by the shell exec builtin."""
    i = 0
    while i < len(args):
        token = args[i]
        if token == "--":
            i += 1
            break
        if token == "-a" and i + 1 < len(args):
            i += 2
            continue
        if token.startswith("-"):
            i += 1
            continue
        break
    if i >= len(args):
        return False
    return simple_command_is_blocked(args[i:])


def rtk_command_is_blocked(args):
    if not args:
        return False
    wrapped = basename(args[0])
    if wrapped == "git":
        return git_invocation_is_blocked(args[1:])
    if wrapped == "proxy":
        return rtk_command_is_blocked(args[1:])
    if wrapped in SHELLS:
        return shell_command_is_blocked(args[1:])
    return False


def shell_command_is_blocked(args):
    i = 0
    while i < len(args):
        token = args[i]
        if token == "-c" or (token.startswith("-") and not token.startswith("--") and "c" in token):
            command_index = i + 1
            if command_index < len(args) and args[command_index] == "--":
                command_index += 1
            if command_index >= len(args):
                return False
            return command_is_blocked(args[command_index])
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
    if subcommand in ALWAYS_BLOCKED:
        return True
    if query_has_side_effects(subcommand, sub_args):
        return True
    if subcommand in READ_ONLY:
        return False
    if subcommand in MIXED:
        return mixed_git_command_is_blocked(subcommand, sub_args)
    return True


def query_has_side_effects(subcommand, args):
    """Reject output files and external helpers accepted by Git queries."""
    if subcommand == "fsck" and "--lost-found" in args:
        return True
    if any(arg == "--output" or arg.startswith("--output=") for arg in args):
        return True
    if subcommand == "archive" and any(
        arg == "-o" or (arg.startswith("-o") and len(arg) > 2) for arg in args
    ):
        return True
    if subcommand in {"diff", "log", "show", "whatchanged"} and any(
        arg in {"--ext-diff", "--textconv"} or arg.startswith("--extcmd=")
        for arg in args
    ):
        return True
    if subcommand == "grep" and any(
        arg == "--textconv"
        or arg == "--open-files-in-pager"
        or arg.startswith("--open-files-in-pager=")
        for arg in args
    ):
        return True
    if subcommand == "cat-file" and any(
        arg == "--textconv" or arg == "--filters" for arg in args
    ):
        return True
    if subcommand == "stash" and any(
        arg in {"--ext-diff", "--textconv"} for arg in args
    ):
        return True
    return False


def find_git_subcommand_index(args):
    i = 0
    while i < len(args):
        token = args[i]

        if token == "--version":
            return None
        if token == "--help":
            return None if i == len(args) - 1 else -1
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
        return first_action_is_blocked(
            args,
            allow={"list", "show"},
            block={"add", "append", "copy", "edit", "merge", "prune", "remove"},
            options_with_value={"--ref"},
        )
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
        return first_action_is_blocked(
            args,
            allow={"log"},
            block={
                "bad",
                "good",
                "new",
                "old",
                "replay",
                "reset",
                "run",
                "skip",
                "start",
                "terms",
                "view",
                "visualize",
            },
        )
    return True


def first_action_is_blocked(
    args, allow, block, default_blocked=False, options_with_value=frozenset()
):
    action = first_non_option(args, options_with_value)
    if action is None:
        return default_blocked
    if action in block:
        return True
    if action in allow:
        return False
    return True


def first_non_option(args, options_with_value=frozenset()):
    i = 0
    while i < len(args):
        token = args[i]
        if token == "--":
            return args[i + 1] if i + 1 < len(args) else None
        if token in options_with_value:
            i += 2
            continue
        if any(token.startswith(option + "=") for option in options_with_value):
            i += 1
            continue
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
        "-u",
        "--copy",
        "--create-reflog",
        "--delete",
        "--edit-description",
        "--force",
        "--move",
        "--set-upstream",
        "--set-upstream-to",
        "--track",
        "--unset-upstream",
    }
    compact_write_flags = {"-C", "-D", "-M", "-c", "-d", "-m", "-u"}
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
    if any(
        (
            not arg.startswith("--")
            and any(
                arg.startswith(flag) and len(arg) > len(flag)
                for flag in compact_write_flags
            )
        )
        or arg.startswith("--set-upstream-to=")
        for arg in args
    ):
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
    if any(
        arg in {"-d", "--delete", "--convert-graft-file", "--graft"}
        or (arg.startswith("-d") and len(arg) > 2)
        for arg in args
    ):
        return True
    if not args:
        return False
    if any(arg in {"-l", "--list"} for arg in args):
        return False
    return any(not arg.startswith("-") for arg in args)


def decode_js_string(source, quote_index):
    """Decode one non-interpolated JavaScript string literal."""
    quote = source[quote_index]
    escaped = False
    for index in range(quote_index + 1, len(source)):
        char = source[index]
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if quote == "`" and source.startswith("${", index):
            return None, index + 2
        if char != quote:
            continue

        literal = source[quote_index : index + 1]
        if quote == "`":
            literal = repr(literal[1:-1])
        try:
            return ast.literal_eval(literal), index + 1
        except (SyntaxError, ValueError):
            return None, index + 1
    return None, len(source)


def find_js_string_end(source, quote_index):
    """Return the index after one JavaScript string literal."""
    quote = source[quote_index]
    escaped = False
    for index in range(quote_index + 1, len(source)):
        char = source[index]
        if escaped:
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == quote:
            return index + 1
    return None


def skip_js_comment(source, index):
    """Return the index after a JavaScript comment, or the same index."""
    if source.startswith("//", index):
        newline = source.find("\n", index + 2)
        return len(source) if newline < 0 else newline + 1
    if source.startswith("/*", index):
        end = source.find("*/", index + 2)
        return None if end < 0 else end + 2
    return index


def find_matching_delimiter(source, opening_index):
    """Return the matching delimiter index while skipping strings and comments."""
    pairs = {"(": ")", "{": "}", "[": "]"}
    opening = source[opening_index]
    if opening not in pairs:
        return None
    stack = [opening]
    index = opening_index + 1
    while index < len(source):
        char = source[index]
        if char in "\"'`":
            index = find_js_string_end(source, index)
            if index is None:
                return None
            continue
        comment_end = skip_js_comment(source, index)
        if comment_end is None:
            return None
        if comment_end != index:
            index = comment_end
            continue
        if char in pairs:
            stack.append(char)
        elif char in pairs.values():
            if char != pairs[stack[-1]]:
                return None
            stack.pop()
            if not stack:
                return index
        index += 1
    return None


def split_top_level_properties(source):
    """Split a JavaScript object body at top-level commas."""
    properties = []
    start = 0
    index = 0
    while index < len(source):
        char = source[index]
        if char in "\"'`":
            index = find_js_string_end(source, index)
            if index is None:
                return None
            continue
        comment_end = skip_js_comment(source, index)
        if comment_end is None:
            return None
        if comment_end != index:
            index = comment_end
            continue
        if char in "({[":
            closing = find_matching_delimiter(source, index)
            if closing is None:
                return None
            index = closing + 1
            continue
        if char in ")}]":
            return None
        if char == ",":
            properties.append(source[start:index])
            start = index + 1
        index += 1
    properties.append(source[start:])
    return properties


def write_stdin_call_is_blocked(argument):
    """Reject a write_stdin argument unless its chars value is provably safe."""
    argument = argument.strip()
    if not argument.startswith("{"):
        return True
    object_end = find_matching_delimiter(argument, 0)
    if object_end is None or argument[object_end + 1 :].strip():
        return True

    properties = split_top_level_properties(argument[1:object_end])
    if properties is None:
        return True
    for property_source in properties:
        property_source = property_source.strip()
        if not property_source:
            continue
        if property_source.startswith("...") or property_source.startswith("["):
            return True
        if property_source == "chars":
            return True

        match = CHARS_PROPERTY_RE.match(property_source)
        if match is None:
            if re.search(r"\bchars\b", property_source):
                return True
            continue
        value = property_source[match.end() :].strip()
        if not value or value[0] not in "\"'`":
            return True
        decoded, end = decode_js_string(value, 0)
        if not isinstance(decoded, str) or value[end:].strip():
            return True
        if command_is_blocked(decoded):
            return True
    return False


def write_stdin_is_blocked(source):
    """Reject unsafe write_stdin calls in one functions.exec source string."""
    position = 0
    while True:
        match = WRITE_STDIN_CALL_RE.search(source, position)
        if match is None:
            return False
        opening = match.end() - 1
        closing = find_matching_delimiter(source, opening)
        if closing is None:
            return True
        if write_stdin_call_is_blocked(source[opening + 1 : closing]):
            return True
        position = closing + 1


def exec_commands(source):
    """Return literal shell inputs inside a functions.exec program."""
    commands = []
    position = 0
    while True:
        match = CMD_LITERAL_RE.search(source, position)
        if match is None:
            return commands
        command, position = decode_js_string(source, match.start(1))
        if isinstance(command, str):
            commands.append(command)


def exec_source(tool_input):
    """Return a functions.exec source string or reject an invalid payload."""
    if isinstance(tool_input, str):
        return tool_input
    if isinstance(tool_input, dict):
        for key in ("code", "source"):
            if isinstance(tool_input.get(key), str):
                return tool_input[key]
    raise ValueError("functions.exec payload has no source string")


def commands_from_payload(payload):
    """Return shell commands visible in a Bash or functions.exec hook payload."""
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input")
    if tool_name == "exec" or tool_name.endswith(".exec"):
        return exec_commands(exec_source(tool_input))

    if tool_name != "Bash" or not isinstance(tool_input, dict):
        raise ValueError("unsupported hook tool payload")
    command = tool_input.get("command")
    if not isinstance(command, str):
        raise ValueError("Bash payload has no command string")
    return [command]


def payload_is_blocked(payload):
    """Return whether a validated hook payload requests a Git write."""
    if not isinstance(payload, dict):
        raise ValueError("hook payload is not an object")
    if payload.get("hook_event_name") not in {"PreToolUse", "PermissionRequest"}:
        raise ValueError("unsupported hook event")
    tool_name = payload.get("tool_name")
    if not isinstance(tool_name, str):
        raise ValueError("hook payload has no tool name")
    if tool_name == "exec" or tool_name.endswith(".exec"):
        source = exec_source(payload.get("tool_input"))
        if write_stdin_is_blocked(source):
            return True
    return any(
        command_is_blocked(command) for command in commands_from_payload(payload)
    )


def deny_permission_request():
    """Print the supported PermissionRequest denial response."""
    response = {
        "hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": {
                "behavior": "deny",
                "message": "Git 写操作已被 Codex 策略拦截. 请在你的终端手动执行.",
            },
        }
    }
    print(json.dumps(response, ensure_ascii=False))


payload = None
try:
    payload = json.loads(os.environ.get("HOOK_INPUT", ""))
    blocked = payload_is_blocked(payload)
except Exception:
    if isinstance(payload, dict) and payload.get("hook_event_name") == "PermissionRequest":
        deny_permission_request()
        sys.exit(0)
    print(BLOCK_MESSAGE, file=sys.stderr)
    sys.exit(2)

if blocked:
    if payload.get("hook_event_name") == "PermissionRequest":
        deny_permission_request()
    else:
        print(BLOCK_MESSAGE, file=sys.stderr)
        sys.exit(2)

sys.exit(0)
PY
exit $?
