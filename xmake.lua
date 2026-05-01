set_xmakever("3.0.0")
set_project("<project>")
set_version("0.1.0", {build = "%Y%m%d"})
set_languages("c++23")
set_encodings("utf-8")
set_warnings("all", "error")

add_repositories("repo https://gitee.com/gycherish/xrepo.git")
add_requires("stdexec")
add_requires("asio")
-- io_uring backend for asio::stream_file. Linux-only; Windows uses
-- its native IOCP path and needs no extra dependency.
if is_plat("linux") then
    add_requires("liburing")
    add_defines("ASIO_HAS_IO_URING")
end
add_requires("blake3")
add_requires("libsodium")
add_requires("zstd")
add_requires("catch2")
add_requires("spdlog")
add_requires("argparse")
add_requires("nlohmann_json")

add_rules("mode.debug", "mode.release")
add_includedirs("include")

includes("src")
includes("tests")

