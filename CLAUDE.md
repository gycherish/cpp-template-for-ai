# 项目开发指南

本文件是面向在本仓库工作的 AI 编码工具的权威指令, 优先级高于默认行为, 必须严格遵守。

## 核心原则

- **最小必要修改**: 只改达成目标所必需的部分, 正确性与可读性优先于炫技
- **测试优先**: 尽可能先写测试再实现功能
- **跨平台**: 除非显式说明, 所有库与二进制都要同时满足 Windows 和 POSIX(POSIX 以 Linux 为主)
- **最小提交**: 一次提交只包含一个功能或一个 bug 修复, 遵循 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- **性能默认**: 数据流转优先用引用/视图传递, 尽量减少文件 IO 与内存拷贝
- **零警告**: 消除本项目产生的所有编译警告(三方库自身警告除外)

> **红线(未经允许严禁)**:
> 1. 擅自提交 —— 所有改动须经审核通过后才能 commit
> 2. 在 `main` 上执行 force push、reset 等改写历史的操作
> 3. 跳过编译或测试就提交 —— 提交前必须通过编译和测试

## 项目结构

### 目录布局

| 目录 | 用途 |
|------|------|
| `include/<project-name>/` | 公共头文件 |
| `src/` | 源文件和私有头文件 |
| `examples/` | 示例程序 |
| `tests/` | 测试文件 |
| `tools/` | 工具 |
| `doc/` | 文档源(设计/手册/开发/API) |
| `.claude/`、`.codex/` 等 | 各 AI 工具的工作目录, 存放临时设计/分析文件(已被 .gitignore 忽略) |

以上目录可视情况增加子目录用于分类。临时生成的设计/分析文件放当前 AI 工具自己的工作目录(如 `.claude/`、`.codex/`), 不要散落到项目根目录。

## 技术栈

### 语言标准

- C++23 及以上, 严格遵守 [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
- 优先使用 C++ Ranges 库中的算法
- 优先使用 `std::filesystem` 操作文件系统

### 异步架构

- 所有文件 IO、网络 IO 必须以异步形式实现, 优先使用协程表达
- 协程仅用于异步计算/异步 IO 场景, 普通同步逻辑直接走函数, 不要套协程
- 异步操作必须满足结构化并发要求
- 编排框架使用 [stdexec](https://github.com/nvidia/stdexec)
- 网络/IO 框架使用 [asio](https://think-async.com/Asio/), 必要时通过 stdexec 中提供的 `use_sender` 将 asio 异步 IO 纳入 stdexec

### 依赖管理

- C++ 依赖全部通过 xmake 管理(`add_requires`)
- **非 C++ 的外部工具(如 Python)优先用 [pixi](https://pixi.sh/) 管理**, 保持环境可复现、不污染系统
- 常用三方库:

| 库 | 用途 |
|----|------|
| [catch2](https://github.com/catchorg/Catch2) | 测试框架 |
| [spdlog](https://github.com/gabime/spdlog) | 日志 |
| [argparse](https://github.com/p-ranav/argparse) | 命令行解析 |
| [nlohmann_json](https://github.com/nlohmann/json) | JSON 解析 |

其他三方库可自行决定。

## 构建与命令

使用 [xmake](https://xmake.io/) 构建, 开发过程中始终编译 Debug 版本。命令均可追加 `-yvD` 获取详细诊断信息。

```
xmake f -m debug <other-option>   # 配置项目
xmake build [target]              # 编译
xmake test                        # 运行测试
xmake format                      # 按 .clang-format 格式化(手工编辑后校正用)
```

`compile_commands.json` 不会随 `xmake build` 自动写入 `build/`, 需手动导出:

```
xmake project -k compile_commands build
```

根配置文件 `xmake.lua` 模板:

```lua
set_xmakever("3.0.0")
set_project("<project-name>")
set_version("0.1.0", {build = "%Y%m%d"})
set_languages("c++23")
set_encodings("utf-8")
set_warnings("all", "error")

add_repositories("repo https://gitee.com/gycherish/xrepo.git")
add_requires("stdexec")

add_rules("mode.debug", "mode.release")
add_includedirs("include")

includes("src")
includes("tests")
includes("doc")
```

### 文档

文档工具链(Doxygen/Sphinx 等)由 pixi 管理, 详见 `doc/`。

```
pixi install            # 首次安装文档工具链
xmake doc               # 构建 HTML 站点
xmake doc-serve         # 本地预览(热重载)
xmake doc-pdf [--engine=xelatex|lualatex]   # 生成 PDF(需系统 TeX)
xmake doc-versions      # 逐版本构建并生成版本切换器
```

## 编码规范

C++ 的命名、格式、头文件与引用、类型与初始化、语言用法、注释及完整示例, 统一收录在 [编码风格指南](doc/dev/coding-style.md)。

**编写/修改 C++ 代码, 或新建源文件、构建目标前, 必须先阅读该指南并严格遵循。** 其中的格式类机械规则另由根目录 `.clang-format` 与 `.editorconfig` 固化, 手工编辑后可用 `xmake format` 校正。

## 开发流程

分支模型、分支/提交命名、合并与发布、版本(SemVer)、git worktree 用法详见 [Git 工作流](doc/dev/git-workflow.md)。核心约束:

- **协作模式**: 单人开发(无多人协作)可直接在 `main` 上开发提交; 一旦多人协作, 必须改走下列标准分支流程
- 多人协作: `main`、`dev` 为受保护长期分支, 只接受评审通过的合并; 开发在从 `dev` 切出的短期分支(`feat/*`、`fix/*` 等)上进行, 完成后合回 `dev` 并删除
- 并行任务用 `git worktree` 挂独立目录; 处于 worktree 中必须在该环境开发, 严禁切换分支
- 提交遵循 Conventional Commits; 版本遵循 SemVer; 提交/历史红线见文首
