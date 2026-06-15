#!/usr/bin/env python3
"""Namespace an OpenSCAD component file so it can coexist with others in one
dispatcher via `include`. Prefixes every identifier the file *defines*
(modules, functions, top-level variables) with PREFIX_, except a small set of
shared inputs driven by the dispatcher. Wraps top-level geometry into
PREFIX_main(). Built-ins are never touched (they are not in the defined set)."""
import re, sys

def strip_comment(line):
    # remove // comment (no // inside strings in these files)
    in_str = False
    out = []
    i = 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_str = not in_str
        if not in_str and c == '/' and i + 1 < len(line) and line[i+1] == '/':
            break
        out.append(c)
        i += 1
    return ''.join(out)

def depth_delta(code):
    # net brace depth change on a comment/string-stripped line
    in_str = False
    d = 0
    for c in code:
        if c == '"':
            in_str = not in_str
        elif not in_str:
            if c == '{':
                d += 1
            elif c == '}':
                d -= 1
    return d

def namespace(path, prefix, shared_inputs, drop_defs):
    text = open(path).read()
    # Strip /* ... */ block comments (can span lines). They are non-functional
    # here (OpenSCAD customizer markers like /* [Hidden] */ are unused by the
    # platform) and otherwise confuse the //-only statement classifier.
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    lines = text.split('\n')

    # --- 1. collect defined identifiers ---
    modules = set(re.findall(r'^\s*module\s+([A-Za-z_]\w*)', text, re.M))
    functions = set(re.findall(r'^\s*function\s+([A-Za-z_]\w*)', text, re.M))
    # top-level variable assignments (brace depth 0)
    topvars = set()
    depth = 0
    for line in lines:
        code = strip_comment(line)
        if depth == 0:
            m = re.match(r'\s*([A-Za-z_]\w*)\s*=(?!=)', code)
            if m and not code.lstrip().startswith(('module', 'function')):
                topvars.add(m.group(1))
        depth += depth_delta(code)

    defined = (modules | functions | topvars) - set(shared_inputs)
    defined -= {'true', 'false', 'undef', 'PI'}

    # --- 2. split top-level statements: defs/assignments/use/include vs geometry ---
    head = []      # var defs, module/function defs, use/include
    geom = []      # top-level executable geometry statements
    depth = 0
    buf = []
    buf_is_geom = False
    def classify(stmt_code):
        s = stmt_code.lstrip()
        if s.startswith(('module ', 'function ', 'use ', 'include ', 'use<', 'include<')):
            return 'head'
        if re.match(r'[A-Za-z_]\w*\s*=(?!=)', s):
            return 'head'
        if s == '' :
            return 'head'
        return 'geom'

    # walk line by line, grouping by brace depth so multi-line module defs/calls stay intact
    cur = []
    for line in lines:
        code = strip_comment(line)
        cur.append(line)
        depth += depth_delta(code)
        # A depth-0 statement is complete only when the line's code ends with
        # ';' or '}'. This keeps `module foo()\n{ ... }` (brace on next line)
        # as a single statement instead of splitting the body out.
        stripped = code.rstrip()
        if depth == 0 and (stripped.endswith(';') or stripped.endswith('}')):
            joined = '\n'.join(cur)
            first = strip_comment(joined).strip()
            (geom if classify(first) == 'geom' else head).append(joined)
            cur = []
    if cur:
        head.append('\n'.join(cur))

    body = '\n'.join(head + geom)

    # --- 3. drop top-level definitions of shared inputs + explicit drop_defs ---
    for name in list(shared_inputs) + list(drop_defs):
        # remove a top-level "name = .... ;" possibly spanning to first semicolon
        body = re.sub(r'^\s*' + re.escape(name) + r'\s*=(?!=)[^;]*;[ \t]*(//[^\n]*)?$',
                      '// [dispatcher-driven] ' + name, body, flags=re.M)

    # --- 4. prefix every defined identifier (word-boundary) ---
    if defined:
        pat = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, defined), key=len, reverse=True)) + r')\b')
        body = pat.sub(lambda m: prefix + m.group(1), body)

    # --- 5. rebuild: head first, then geometry wrapped in PREFIX_main() ---
    # re-split: after prefixing, re-separate head vs geom by re-walking
    # (simpler: we already separated; re-apply prefix to head/geom separately)
    head_txt = '\n'.join(head)
    geom_txt = '\n'.join(geom)
    for name in list(shared_inputs) + list(drop_defs):
        head_txt = re.sub(r'^\s*' + re.escape(name) + r'\s*=(?!=)[^;]*;[ \t]*(//[^\n]*)?$',
                          '// [dispatcher-driven] ' + name, head_txt, flags=re.M)
    if defined:
        # string-aware prefixing: never rewrite inside "..." string literals
        # or // comments. Tokenise into strings / line-comments / code, and only
        # apply the identifier prefix to code segments.
        seg = re.compile(r'("(?:[^"\\]|\\.)*"|//[^\n]*)')
        def prefix_code(s):
            out = []
            for j, part_s in enumerate(seg.split(s)):
                if j % 2 == 1:        # the captured string/comment segment
                    out.append(part_s)
                else:
                    out.append(pat.sub(lambda m: prefix + m.group(1), part_s))
            return ''.join(out)
        head_txt = prefix_code(head_txt)
        geom_txt = prefix_code(geom_txt)

    out = (f"// ===== namespaced bundle: {path} (prefix {prefix}) =====\n"
           + head_txt
           + f"\nmodule {prefix}main() {{\n" + geom_txt + "\n}\n")
    return out, sorted(defined)

def libonly(path, drop_defs):
    """Return the file's top-level definitions/variables WITHOUT prefixing and
    WITHOUT its top-level geometry, dropping the named defs. Used to inline one
    component's module library into another (e.g. box -> gauntlet)."""
    out, _ = namespace(path, '', [], drop_defs)
    # namespace() with empty prefix leaves names unchanged; strip the _main wrapper
    out = re.sub(r'\nmodule main\(\) \{.*$', '\n', out, flags=re.S)
    out = out.replace('// =====', '// (library) =====', 1)
    return out

if __name__ == '__main__':
    if sys.argv[1] == '--lib':
        drop = sys.argv[3].split(',') if len(sys.argv) > 3 and sys.argv[3] else []
        sys.stdout.write(libonly(sys.argv[2], drop))
    else:
        path, prefix = sys.argv[1], sys.argv[2]
        shared = sys.argv[3].split(',') if len(sys.argv) > 3 and sys.argv[3] else []
        drop = sys.argv[4].split(',') if len(sys.argv) > 4 and sys.argv[4] else []
        out, defined = namespace(path, prefix, shared, drop)
        sys.stdout.write(out)
        sys.stderr.write(f"prefixed {len(defined)} idents: {defined}\n")
