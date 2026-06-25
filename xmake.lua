set_xmakever("3.0.0")
set_project("cpp-template-for-ai")
set_version("0.1.0", {build = "%Y%m%d"})
set_languages("c++23")
set_encodings("utf-8")
set_warnings("all", "error")

add_rules("mode.debug", "mode.release")
add_includedirs("include")

includes("src")
includes("tests")
includes("doc")
