-- Documentation build tasks. The Python/Doxygen toolchain is provided by pixi,
-- so every external tool is invoked through `pixi run ...`. Shared logic lives
-- in docbuild.lua and is imported inside each on_run.

task("doc-api")
    set_category("plugin")
    on_run(function ()
        import("docbuild", {rootdir = os.scriptdir()})
        print("API XML: " .. docbuild.run_doxygen())
    end)
    set_menu({
        usage = "xmake doc-api",
        description = "Extract API docs from /// comments into Doxygen XML",
        options = {},
    })

task("doc")
    set_category("plugin")
    on_run(function ()
        import("docbuild", {rootdir = os.scriptdir()})
        print("HTML site: " .. docbuild.html())
    end)
    set_menu({
        usage = "xmake doc",
        description = "Build the HTML documentation site (current version)",
        options = {},
    })

task("doc-serve")
    set_category("plugin")
    on_run(function ()
        import("docbuild", {rootdir = os.scriptdir()})
        docbuild.serve()
    end)
    set_menu({
        usage = "xmake doc-serve",
        description = "Serve docs locally with live reload",
        options = {},
    })

task("doc-pdf")
    set_category("plugin")
    on_run(function ()
        import("core.base.option")
        import("docbuild", {rootdir = os.scriptdir()})
        print("PDF: " .. docbuild.pdf(option.get("engine")))
    end)
    set_menu({
        usage = "xmake doc-pdf [options]",
        description = "Build a professionally typeset PDF (requires system TeX)",
        options = {
            {"e", "engine", "kv", "xelatex", "LaTeX engine: xelatex (default) or lualatex"},
        },
    })

task("doc-versions")
    set_category("plugin")
    on_run(function ()
        import("docbuild", {rootdir = os.scriptdir()})
        print("Versioned sites: " .. docbuild.versions())
    end)
    set_menu({
        usage = "xmake doc-versions",
        description = "Build one HTML site per git tag/branch with a version switcher",
        options = {},
    })
