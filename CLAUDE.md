# Agent 开发指南

## 核心原则

- 仅做**最小必要修改**
- 优先保证可读性和正确性而不是炫技
- 测试优先, 尽可能先写测试再实现功能
- 提交前必须通过编译和测试
- 保持最小化提交原则, 一次提交只包含一个功能或 bug 修复
- 除非显式说明, 所有库和二进制都需要满足跨平台要求(Windows 和 POSIX 平台, 其中 POSIX 平台优先以 Linux 为主)
- 尽量减少文件 IO 和内存拷贝, 数据流转优先使用引用/视图传递
- 尽可能消除本项目内产生的所有警告(三方库自身警告除外)
- 临时生成的设计/分析文件统一放到当前项目的 `.claude/` 目录, 不要散落到项目根目录

## 项目结构

### 目录布局

| 目录 | 用途 |
|------|------|
| `include/<project-name>/` | 公共头文件 |
| `examples/` | 示例程序目录 |
| `src/` | 源文件和私有头文件 |
| `tests/` | 测试文件 |
| `tools/` | 工具目录 |
| `.claude/` | Claude Code 工作目录, 存放临时设计/分析文件 |

以上目录可视情况增加子目录用于分类。

### 命名规则

- 名称必须含义精确, 贴合项目定位
- 优先使用缩写, 在缩写基础上使用 `kebab-case` 格式
- 名称小于 10 个字符时可省略 `-`
- 严禁使用 `cli` 等含义宽泛的命名

## 技术栈

### 异步架构

- 所有文件 IO、网络 IO 必须以异步形式实现
- 优先使用协程表达异步操作
- 协程仅用于异步计算/异步 IO 场景, 普通同步逻辑直接走函数, 不要套协程
- 异步操作必须满足结构化并发要求
- 使用 [stdexec](https://github.com/nvidia/stdexec) 作为核心异步任务编排框架
- 使用 [asio](https://think-async.com/Asio/) 作为网络/IO 框架, 必要时通过 `use_sender` 将 asio 异步 IO 纳入 stdexec

### 语言标准

- C++23 及以上
- 严格遵守 [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
- 优先使用 C++ Ranges 库中的算法
- 优先使用 `std::filesystem` 操作文件系统

### 构建系统

使用 [xmake](https://xmake.io/) 构建:

```
xmake f -m debug <other-option> # 配置项目，开发过程中始终编译 Debug 版本
xmake build [target]            # 编译
xmake test                      # 运行测试
```

以上命令均可传递 `-yvD` 获取详细诊断信息。

`compile_commands.json` 不会随 `xmake build` 自动写入 `build/` 目录, 需手动导出:

```
xmake project -k compile_commands build
```

xmake 根配置文件 `xmake.lua` 模板如下:
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

### 三方库

| 库 | 用途 |
|----|------|
| [catch2](https://github.com/catchorg/Catch2) | 测试框架 |
| [spdlog](https://github.com/gabime/spdlog) | 日志 |
| [argparse](https://github.com/p-ranav/argparse) | 命令行解析 |
| [nlohmann_json](https://github.com/nlohmann/json) | JSON 解析 |

其他三方库可自行决定, 所有依赖通过 xmake 管理(`add_requires`)。

## 编码规范

### 编码与格式

- 统一使用 UTF-8 编码
- 使用空格缩进, 每级 4 个空格, 不使用制表符
- 函数签名加上缩进不超过 120 个字符时不换行
- 优先使用左对齐, 不使用额外空格做列对齐(两端对齐)
- 行尾注释(`//` 与 `///<`)与代码之间仅留一个空格, 不为跨行对齐插入额外空格
- 语句过长需要换行时, 续行使用固定缩进(语句缩进基础上 +4), 不与上一行的开括号对齐;
  参数难以拆分时也可将全部参数整体下移一行
- 换行点应使各行内容均衡成组, 不要贪婪填满首行后悬挂少量参数
- 代码注释不得引用仓库外的文档(如 `.claude/` 下的设计文档), 注释必须自包含
- 确保每个文本文件末尾有一个换行

### 命名规范

- 优先使用 `snake_case` 命名法
- 命名应见名知意, 避免晦涩缩写, 尽可能保持在一个单词内
- 不要在变量名称中使用体现其类型的前缀
- 所有命名中不得出现中文
- 可执行程序名使用 `kebab-case` 格式
- 配置文件优先使用 JSON5 格式, 配置项使用 `camelCase`

### 头文件与引用

- 使用 `#pragma once` 保护头文件
- 项目内头文件使用 `""` 引用, 其他使用 `<>` 引用
- 只引入当前翻译单元显式用到的头文件, 不要依赖间接传递引入的符号
- include 顺序与分组规则:
  1. 当前翻译单元对应的头文件, 后跟一个空行
  2. 系统头文件 (`<unistd.h>`, `<windows.h>` 等)
  3. 标准库头文件 (`<string>`, `<filesystem>` 等)
  4. 三方库头文件 (`<catch2/...>`, `<asio.hpp>` 等)
  5. 项目内头文件 (`"<project-name>/types.hpp"` 等)
- 不同类型头文件之间不加空行

### 类型与初始化

- 定义 enum 时, 默认值/无效值应放在首位
- 成员变量定义时优先使用 `{}` 初始化, 具有默认构造函数的类型可以省略 `{}`
- 系统头文件和 C 库中的类型应使用 `::` 引用

### 语言用法

- 函数参数和数据传递优先使用引用(必要时配合 `const`/`std::span`/`std::string_view`), 避免无谓拷贝
- 不要使用 `using` 给命名空间起别名(包括 `using namespace ...;` 和 `namespace x = ...;`), 一律写全限定名

### 注释

- 统一使用 `doxygen` 风格注释，即注释符号为: `///`
- 所有注释使用英文
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

类成员过多时的初始化：

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
- 未经允许, 严禁在 `main` 分支上执行强制推送、重置等篡改历史的操作
- 未经允许，严禁擅自提交，所有改动必须经过审核通过后才能提交

### 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)。

### 版本管理

遵循 [SemVer](https://semver.org/), 在 `xmake.lua` 中修改:

```lua
set_version("0.1.0", {build = "%Y%m%d"})
```
