"""Sphinx configuration for the project documentation."""

import os
import re


def _xmake_config():
    """Read project name and version from the root xmake.lua (single source of truth).

    Parsing the file directly (rather than taking values from the environment)
    means sphinx-multiversion picks up each tag's own xmake.lua, so historical
    builds show the version that was current at that tag.
    """
    name, ver = "project", "0.0.0"
    xmake = os.path.join(os.path.dirname(__file__), "..", "xmake.lua")
    try:
        with open(xmake, encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return name, ver
    m = re.search(r"""set_project\s*\(\s*["']([^"']+)["']""", text)
    if m:
        name = m.group(1)
    m = re.search(r"""set_version\s*\(\s*["']([^"']+)["']""", text)
    if m:
        ver = m.group(1)
    return name, ver


# -- Project information -----------------------------------------------------
project, version = _xmake_config()
release = version
author = "gycherish"
copyright = "2026, gycherish"

# -- General -----------------------------------------------------------------
extensions = [
    "myst_parser",       # write docs in Markdown (MyST)
    "breathe",           # pull Doxygen XML into Sphinx
    "sphinx_design",     # cards / grids / tabs
    "sphinx.ext.todo",
    "sphinx.ext.intersphinx",
]

exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]
language = "zh_CN"  # docs are primarily Chinese; drives UI strings and CJK setup

# -- MyST (Markdown) ---------------------------------------------------------
myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "fieldlist",
    "tasklist",
]
myst_heading_anchors = 3

# -- Breathe (Doxygen bridge) ------------------------------------------------
# Doxygen writes XML here (see Doxyfile.in / the xmake doc-api task). The path
# can be overridden via DOXYGEN_XML_DIR, which sphinx-multiversion needs because
# it builds each version inside an isolated working tree.
_doxygen_xml = os.environ.get(
    "DOXYGEN_XML_DIR",
    os.path.join(os.path.dirname(__file__), "..", "build", "doc", "xml"),
)
breathe_projects = {project: _doxygen_xml}
breathe_default_project = project

# -- HTML output (pydata-sphinx-theme) ---------------------------------------
html_theme = "pydata_sphinx_theme"
html_title = project
html_static_path = ["_static"]

html_theme_options = {
    "navbar_align": "left",
    "show_prev_next": False,
    "navbar_end": ["theme-switcher", "navbar-icon-links"],
    "pygments_light_style": "default",
    "pygments_dark_style": "github-dark",
}

# The native navbar version switcher is enabled only for multi-version builds
# (xmake doc-versions sets DOC_MULTIVERSION=1 and emits versions.json).
if os.environ.get("DOC_MULTIVERSION") == "1":
    html_theme_options["switcher"] = {
        "json_url": "versions.json",
        "version_match": version,
    }
    html_theme_options["navbar_start"] = ["navbar-logo", "version-switcher"]

# -- sphinx-multiversion -----------------------------------------------------
# Build a separate site for every release tag (vX.Y.Z) plus main/dev.
smv_tag_whitelist = r"^v\d+\.\d+\.\d+$"
smv_branch_whitelist = r"^(main|dev)$"
smv_remote_whitelist = None
smv_released_pattern = r"^refs/tags/v.*$"
smv_outputdir_format = "{ref.name}"

# -- LaTeX / PDF -------------------------------------------------------------
# Engine is chosen by the xmake doc-pdf --engine option (default xelatex). Both
# xelatex and lualatex give professional typesetting; the CJK package differs.
# A system TeX distribution and a CJK font (e.g. Noto / Source Han) are required.
_engine = os.environ.get("DOC_LATEX_ENGINE", "xelatex")
latex_engine = _engine

if _engine == "lualatex":
    _cjk_preamble = r"""
\usepackage{luatexja-fontspec}
\setmainjfont{Noto Serif CJK SC}
\setsansjfont{Noto Sans CJK SC}
\setmonojfont{Noto Sans Mono CJK SC}
"""
else:  # xelatex
    _cjk_preamble = r"""
\usepackage{xeCJK}
\setCJKmainfont{Noto Serif CJK SC}
\setCJKsansfont{Noto Sans CJK SC}
\setCJKmonofont{Noto Sans Mono CJK SC}
"""

latex_elements = {
    "papersize": "a4paper",
    "pointsize": "11pt",
    "fncychap": r"\usepackage[Bjarne]{fncychap}",
    "preamble": r"\usepackage{microtype}" + _cjk_preamble,
    "sphinxsetup": ", ".join(
        [
            "verbatimwithframe=true",
            "VerbatimColor={RGB}{248,248,248}",
            "TitleColor={RGB}{30,30,30}",
            "InnerLinkColor={RGB}{60,90,200}",
            "OuterLinkColor={RGB}{60,90,200}",
            "hmargin={2.5cm,2.5cm}",
            "vmargin={2.5cm,2.5cm}",
        ]
    ),
}
latex_documents = [
    (
        "index",
        f"{project}.tex",
        f"{project} Documentation",
        author,
        "manual",
    ),
]
