-- Importable helpers for the documentation build tasks. Kept in its own module
-- so xmake runs it in the script sandbox where os.mkdir/os.cp/io.replace and the
-- like are available (file-scope locals in xmake.lua do not get that sandbox).
--
-- All external tools are launched with os.execv so their output streams live to
-- the terminal; the xmake -v/-D/-q flags are forwarded to control verbosity.

import("core.base.option")

-- keep in sync with set_version in the root xmake.lua
local doc_version = "0.1.0"

local function docdir()
    return path.join(os.projectdir(), "doc")
end

local function outdir()
    return path.join(os.projectdir(), "build", "doc")
end

local function is_verbose()
    return option.get("verbose") or option.get("diagnosis")
end

-- Translate the xmake verbosity flags into sphinx-build flags.
local function sphinx_flags()
    if option.get("diagnosis") then
        return {"-v", "-v"}
    elseif option.get("verbose") then
        return {"-v"}
    elseif option.get("quiet") then
        return {"-q"}
    end
    return {}
end

-- Render Doxyfile.in into the build tree and emit API XML for Breathe.
function run_doxygen()
    local out = outdir()
    os.mkdir(out)
    local doxyfile = path.join(out, "Doxyfile")
    os.cp(path.join(docdir(), "Doxyfile.in"), doxyfile)
    io.replace(doxyfile, "@PROJECT_VERSION@", doc_version, {plain = true})
    io.replace(doxyfile, "@PROJECT_ROOT@", os.projectdir(), {plain = true})
    io.replace(doxyfile, "@OUTPUT_DIR@", out, {plain = true})
    io.replace(doxyfile, "@QUIET@", is_verbose() and "NO" or "YES", {plain = true})
    os.execv("pixi", {"run", "doxygen", doxyfile})
    return path.join(out, "xml")
end

function html()
    run_doxygen()
    local site = path.join(outdir(), "html")
    os.execv("pixi", table.join({"run", "sphinx-build", "-b", "html"}, sphinx_flags(), {docdir(), site}))
    return path.join(site, "index.html")
end

function serve()
    run_doxygen()
    os.execv("pixi", {"run", "sphinx-autobuild", docdir(), path.join(outdir(), "html")})
end

function pdf(engine)
    run_doxygen()
    engine = engine or "xelatex"
    local out = path.join(outdir(), "pdf")
    os.execv("pixi", table.join({"run", "sphinx-build", "-M", "latexpdf"}, sphinx_flags(), {docdir(), out}),
        {envs = {DOC_LATEX_ENGINE = engine}})
    return path.join(out, "latex")
end

function versions()
    run_doxygen()
    local out = path.join(outdir(), "versions")
    os.execv("pixi", table.join({"run", "sphinx-multiversion"}, sphinx_flags(), {docdir(), out}),
        {envs = {DOC_MULTIVERSION = "1"}})

    -- Emit versions.json for the theme's navbar version switcher, and drop a
    -- copy into every per-version site so it is reachable from each page.
    local items = {}
    for _, dir in ipairs(os.dirs(path.join(out, "*"))) do
        local name = path.filename(dir)
        table.insert(items, string.format(
            '  {"name": "%s", "version": "%s", "url": "../%s/"}', name, name, name))
    end
    local manifest = path.join(out, "versions.json")
    io.writefile(manifest, "[\n" .. table.concat(items, ",\n") .. "\n]\n")
    for _, dir in ipairs(os.dirs(path.join(out, "*"))) do
        os.cp(manifest, path.join(dir, "versions.json"))
    end
    return out
end
