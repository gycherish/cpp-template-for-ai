# 项目开发指南

本文件是面向在本仓库工作的 AI Agent 的权威指令, 优先级高于默认行为, 必须严格遵守。

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
| `.claude/` | Claude Code 工作目录, 存放临时设计/分析文件 |

以上目录可视情况增加子目录用于分类。临时生成的设计/分析文件一律放 `.claude/`, 不要散落到项目根目录。

### 命名

**文件、目录与程序**

- 名称含义精确, 贴合项目定位; 严禁 `cli` 等含义宽泛的命名
- 优先使用缩写, 在缩写基础上用 `kebab-case`; 名称小于 10 个字符时可省略 `-`
- 可执行程序名用 `kebab-case`; 程序仅由单个源文件构成时, 该源文件与程序同名

**代码标识符**

- 优先 `snake_case`, 见名知意, 尽可能保持在一个单词内
- 不在变量名中使用体现其类型的前缀; 所有命名不得出现中文

**配置文件**

- 优先 JSON5 格式, 配置项使用 `camelCase`

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

### 格式

> 缩进、行尾、文件末换行等机械规则已由根目录 `.clang-format` 与 `.editorconfig` 固化, 手工编辑后可用 `xmake format` 校正。
> 但你(AI)产出的代码必须本来就符合以下规则, 不能依赖事后格式化。

- 统一使用 UTF-8 编码; 每级 4 个空格缩进, 不使用制表符; 每个文本文件末尾保留一个换行
- 函数签名加上缩进不超过 120 个字符时不换行
- 优先左对齐, 不使用额外空格做列对齐(两端对齐); 行尾注释(`//` 与 `///<`)与代码之间仅留一个空格
- 语句过长需要换行时, 续行使用固定缩进(语句缩进基础上 +4), 不与上一行的开括号对齐;
  参数难以拆分时也可将全部参数整体下移一行
- 换行点应使各行内容均衡成组, 不要贪婪填满首行后悬挂少量参数

### 头文件与引用

- 使用 `#pragma once` 保护头文件
- 项目内头文件使用 `""` 引用, 其他使用 `<>` 引用
- 只引入当前翻译单元显式用到的头文件, 不要依赖间接传递引入的符号
- include 顺序与分组规则(不同类型之间不加空行):
  1. 当前翻译单元对应的头文件, 后跟一个空行
  2. 系统头文件 (`<unistd.h>`, `<windows.h>` 等)
  3. 标准库头文件 (`<string>`, `<filesystem>` 等)
  4. 三方库头文件 (`<catch2/...>`, `<asio.hpp>` 等)
  5. 项目内头文件 (`"<project-name>/types.hpp"` 等)

### 类型与初始化

- 定义 enum 时, 默认值/无效值应放在首位
- 成员变量定义时优先使用 `{}` 初始化, 具有默认构造函数的类型可以省略 `{}`
- 系统头文件和 C 库中的类型应使用 `::` 引用

### 语言用法

- 函数参数和数据传递优先使用引用(必要时配合 `const`/`std::span`/`std::string_view`), 避免无谓拷贝
- 不要使用 `using` 给命名空间起别名(包括 `using namespace ...;` 和 `namespace x = ...;`), 一律写全限定名

### 注释

- 统一使用 `doxygen` 风格注释, 即注释符号为 `///`, 所有注释使用英文
- 注释必须自包含, 不得引用仓库外的文档(如 `.claude/` 下的设计文档)
- 当函数签名自解释时不要添加太多无意义的注释

### 示例

#### 基本形态

```cpp
// class
class server;
class session {
public:
    explicit session(const server& srv) {
        // code...
    }

private:
    server& m_srv;
};

// struct
struct config {
    int timeout{5};
};

// namespace
namespace myproj {
namespace detail {
} // namespace detail
} // namespace myproj

// function
void async_accept() {
    // code ...
}

// operator
int a = b + c;
int a = b > c ? b : c;

// if
if (condition) {
    // code ...
}
else {
    // code ...
}

// while
while (condition) {
    // code ...
}

// switch...case with multiple lines
switch (label) {
case label1: {
    break;
}
default: {
    break;
}
}
// switch...case with only return
switch (label) {
case label1: return "label1";
default: return "default";
}

// for
for (int i = 0; i < cnt; ++i) {
    // code ...
}

// global variable
config g_cfg;

// global variable via accessor
const std::error_category& my_category() noexcept {
    static my_error_category category;
    return category;
}

// constant
inline constexpr int max_buffer_size = 65536;
```

#### 好坏对照

行尾注释只留单空格, 不为跨行对齐做填充:

```cpp
// good
std::uint32_t id{}; ///< unique object id
std::uint32_t parent_id{}; ///< zero when root

// bad: extra spaces inserted for column alignment
std::uint32_t id{};        ///< unique object id
std::uint32_t parent_id{}; ///< zero when root
```

换行续行使用固定缩进(+4), 不与开括号对齐:

```cpp
// good
std::unique_ptr<server> make_server(const executor& exec,
    std::string_view address, std::uint16_t port, const options& opts);

// good: wrapping a call expression works the same way
return std::make_unique<session>(std::move(socket),
    endpoint{address, port}, opts, pool);

// bad: aligned to the open parenthesis
std::unique_ptr<server> make_server(const executor& exec,
                                    std::string_view address, std::uint16_t port,
                                    const options& opts);
// bad: first line exceeds the column limit before wrapping
std::unique_ptr<server> make_server(const executor& exec, std::string_view address, std::uint16_t port,
    const options& opts);
```

命名空间一律全限定, 不起别名:

```cpp
// good
auto entries = myproj::detail::parse(data);
auto path = std::filesystem::current_path();

// bad
using namespace myproj::detail;
namespace fs = std::filesystem;
```

enum 默认/无效值放首位; 例外: 线格式枚举按协议取值, 不强加无效值:

```cpp
// good
enum class state {
    idle, // default state comes first
    running,
    stopped,
};

// exception: values are wire format (fixed by the protocol), keep them pure
enum class opcode : std::uint8_t {
    request = 0x00,
    response = 0x01,
};
```

类成员过多时的初始化:

```cpp
// good
session(std::unique_ptr<channel> ch, const registry& reg, buffer_pool& pool,
    config cfg, std::uint16_t id)
    : m_channel{std::move(ch)}, m_registry{reg}, m_pool{pool}
    , m_config{std::move(cfg)}, m_id{id} {}

// bad
session(std::unique_ptr<channel> ch, const registry& reg, buffer_pool& pool,
    config cfg, std::uint16_t id)
    : m_channel{std::move(ch)}, m_registry{reg}, m_pool{pool},
      m_config{std::move(cfg)}, m_id{id} {}
```

## 开发流程

### Git 工作流

- 在 `dev` 分支进行功能开发, 完成并测试通过后合入 `main`
- 并行开发时基于 `dev` 创建新分支并使用 `git worktree`, 完成后合入 `dev` 并删除分支
- 如果当前已经处于 `git worktree` 环境, 则必须在该环境中进行开发, 且严禁切换分支
- 提交与历史相关的红线见文首"核心原则"

### 版本管理

遵循 [SemVer](https://semver.org/), 在 `xmake.lua` 中修改:

```lua
set_version("0.1.0", {build = "%Y%m%d"})
```
