#!/usr/bin/env python3
import re
import sys
from pathlib import Path

VERSION = "v18-safe-waitany-direct-input"

BRANCHES = {
    "bra", "bsr",
    "bcc", "bcs", "beq", "bne", "bge", "bgt", "bhi", "ble", "bls", "blt",
    "bmi", "bpl", "bvc", "bvs",
}

IF_DIRECTIVES = {
    "if", "ifc", "ifnc", "ifd", "ifnd", "ifeq", "ifne", "ifgt", "ifge", "iflt", "ifle",
}


def split_comment(line: str):
    in_single = False
    in_double = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == ";" and not in_single and not in_double:
            return line[:i], line[i:]
    return line, ""


def first_token_lower(code: str):
    stripped = code.strip()
    if not stripped:
        return ""
    m = re.match(r"([A-Za-z][A-Za-z0-9_]*)(?:\.[A-Za-z])?\b", stripped)
    return m.group(1).lower() if m else ""


def is_standalone_elseif(code: str) -> bool:
    stripped = code.strip()
    return bool(re.fullmatch(r"elseif", stripped, flags=re.IGNORECASE))


def relax_opcode_token(token: str):
    m = re.fullmatch(r"([A-Za-z][A-Za-z0-9_]*)(?:\.(s|w|l))?", token, flags=re.IGNORECASE)
    if not m:
        return token, False
    base = m.group(1).lower()
    if base not in BRANCHES:
        return token, False
    return m.group(1) + ".l", (token.lower() != base + ".l")


def relax_branch_line(code: str):
    if not code.strip():
        return code, 0

    if code.lstrip() != code:
        m = re.match(r"^(\s*)(\S+)(.*)$", code)
        if not m:
            return code, 0
        new_token, changed = relax_opcode_token(m.group(2))
        if changed:
            return m.group(1) + new_token + m.group(3), 1
        return code, 0

    m = re.match(r"^(\S+)(.*)$", code)
    if not m:
        return code, 0

    first = m.group(1)
    rest = m.group(2)
    new_first, changed_first = relax_opcode_token(first)
    if changed_first:
        return new_first + rest, 1

    m2 = re.match(r"^(\s+)(\S+)(.*)$", rest)
    if not m2:
        return code, 0

    new_second, changed_second = relax_opcode_token(m2.group(2))
    if changed_second:
        return first + m2.group(1) + new_second + m2.group(3), 1

    return code, 0


def append_ground_stubs_if_needed(src_path: Path, out_lines: list[str]) -> tuple[int, bool]:
    if src_path.name.lower() != "gloom.s":
        return 0, False

    full_text = "".join(out_lines).lower()
    needs_ground = "groundtile" in full_text or "ceilingtile" in full_text
    if not needs_ground:
        return 0, False

    out_lines.append("\n")
    out_lines.append("; vasm-wrapper: compatibility stubs for missing floor/ceiling mapper labels\n")
    out_lines.append("; The public source references these labels but does not provide their implementation.\n")
    out_lines.append("; Keep them as safe no-op routines for a first linkable build.\n")
    out_lines.append("\tcnop\t0,2\n")
    out_lines.append("groundtile\trts\n")
    out_lines.append("ceilingtile\trts\n")
    return 2, False



def patch_waitany_direct_input(out_lines: list[str], src_path: Path) -> int:
    if src_path.name.lower() != "gloom.s":
        return 0

    text = "".join(out_lines)
    pattern = re.compile(
        r"(?m)^waitany\s+movem\.l\s+d0-d7/a0-a6,-\(a7\)\n"
        r"\.wait\s+bsr(?:\.l)?\s+checkany\n"
        r"\s*beq(?:\.s)?\s+\.wait\n"
        r"\.wait2\s+bsr(?:\.l)?\s+checkany\n"
        r"\s*bne(?:\.s)?\s+\.wait2\n"
        r"\s*movem\.l\s+\(a7\)\+,d0-d7/a0-a6\n"
        r"\s*rts\n"
    )
    replacement = (
        "waitany\tmovem.l\td0-d7/a0-a6,-(a7)\n"
        "; v18: direct wait input path, avoids relying only on readmenusel.\n"
        "; Accepts normal menu fire, SPACE, RETURN, ESC and left mouse button.\n"
        ".gwi_wait\tbsr.l\tvwait\n"
        "\tbsr.l\treadmenusel\n"
        "\tand\t#$10,d0\t; menu fire bit\n"
        "\tbne.s\t.gwi_seen\n"
        "\tmove.l\trawtable(pc),a0\n"
        "\tbtst\t#0,8(a0)\t; SPACE rawkey $40\n"
        "\tbne.s\t.gwi_seen\n"
        "\tbtst\t#4,8(a0)\t; RETURN rawkey $44\n"
        "\tbne.s\t.gwi_seen\n"
        "\tbtst\t#5,8(a0)\t; ESC rawkey $45\n"
        "\tbne.s\t.gwi_seen\n"
        "\tmove.b\t$bfe001,d1\n"
        "\tbtst\t#6,d1\t; left mouse button, active low\n"
        "\tbeq.s\t.gwi_seen\n"
        "\tbra.s\t.gwi_wait\n"
        ".gwi_seen\tbsr.l\tvwait\n"
        "\tbsr.l\treadmenusel\n"
        "\tand\t#$10,d0\n"
        "\tbne.s\t.gwi_seen\n"
        "\tmove.l\trawtable(pc),a0\n"
        "\tbtst\t#0,8(a0)\n"
        "\tbne.s\t.gwi_seen\n"
        "\tbtst\t#4,8(a0)\n"
        "\tbne.s\t.gwi_seen\n"
        "\tbtst\t#5,8(a0)\n"
        "\tbne.s\t.gwi_seen\n"
        "\tmove.b\t$bfe001,d1\n"
        "\tbtst\t#6,d1\n"
        "\tbeq.s\t.gwi_seen\n"
        "\tmovem.l\t(a7)+,d0-d7/a0-a6\n"
        "\trts\n"
    )
    text2, count = pattern.subn(replacement, text, count=1)
    if count:
        out_lines[:] = text2.splitlines(keepends=True)
    return count

def normalize(src_path: Path, dst_path: Path) -> None:
    lines = src_path.read_text(encoding="latin-1").splitlines(keepends=True)
    out = []
    if_depth = 0
    orphan_elseif = 0
    conditional_elseif = 0
    branch_relaxed = 0

    for line in lines:
        newline = "\n" if line.endswith("\n") else ""
        body = line[:-1] if newline else line
        code, comment = split_comment(body)
        token = first_token_lower(code)

        if token in IF_DIRECTIVES:
            if_depth += 1

        if is_standalone_elseif(code):
            if if_depth > 0:
                conditional_elseif += 1
                out.append(body + newline)
            else:
                orphan_elseif += 1
                out.append("; vasm-wrapper: orphan Devpac elseif marker disabled: " + body + newline)
            continue

        if token == "endc":
            if if_depth > 0:
                if_depth -= 1

        new_code, changed = relax_branch_line(code)
        branch_relaxed += changed
        out.append(new_code + comment + newline)

    waitany_direct_patch = patch_waitany_direct_input(out, src_path)
    stub_count, ground_included = append_ground_stubs_if_needed(src_path, out)

    dst_path.parent.mkdir(parents=True, exist_ok=True)
    dst_path.write_text("".join(out), encoding="latin-1")
    print(
        f"Normalized {src_path} -> {dst_path} [{VERSION}] "
        f"({orphan_elseif} orphan elseif marker(s) commented, "
        f"{conditional_elseif} conditional elseif marker(s) kept, "
        f"{branch_relaxed} branch(es) forced to .l with label-aware parsing, "
        f"{stub_count} ground mapper stub label(s) added, "
        f"ground.s included={str(ground_included).lower()}, "
        f"waitany direct input patch(es)={waitany_direct_patch})"
    )


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0]} <input.s> <output.s>", file=sys.stderr)
        return 2
    normalize(Path(argv[1]), Path(argv[2]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
