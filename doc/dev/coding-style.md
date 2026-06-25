# C++ 编码风格指南

本指南规定本仓库所有 C++ 代码的风格约定。格式类机械规则由根目录 `.clang-format` 与 `.editorconfig` 固化, 手工编辑后可用 `xmake format` 校正; 但应直接写出符合规则的代码, 不要依赖事后格式化。

## 命名

### 代码标识符

- 优先 `snake_case`, 见名知意, 尽可能保持在一个单词内
- 不使用体现**类型**的前缀(匈牙利命名), 但使用作用域前缀: 类私有成员变量加 `m_`, 全局变量加 `g_`
- 所有命名不得出现中文

### 文件、目录与程序

- 名称含义精确, 贴合项目定位; 严禁 `cli` 等含义宽泛的命名
- 优先使用缩写, 在缩写基础上用 `kebab-case`; 名称小于 10 个字符时可省略 `-`
- 可执行程序名用 `kebab-case`; 程序仅由单个源文件构成时, 该源文件与程序同名

### 配置文件

- 优先 JSON5 格式, 配置项使用 `camelCase`

## 格式

- 统一使用 UTF-8 编码; 每级 4 个空格缩进, 不使用制表符; 每个文本文件末尾保留一个换行
- 函数签名加上缩进不超过 120 个字符时不换行
- 优先左对齐, 不使用额外空格做列对齐(两端对齐); 行尾注释(`//` 与 `///<`)与代码之间仅留一个空格
- 语句过长需要换行时, 续行使用固定缩进(语句缩进基础上 +4), 不与上一行的开括号对齐; 参数难以拆分时也可将全部参数整体下移一行
- 换行点应使各行内容均衡成组, 不要贪婪填满首行后悬挂少量参数

## 头文件与引用

- 使用 `#pragma once` 保护头文件
- 项目内头文件使用 `""` 引用, 其他使用 `<>` 引用
- 只引入当前翻译单元显式用到的头文件, 不要依赖间接传递引入的符号
- include 顺序与分组规则(不同类型之间不加空行):
  1. 当前翻译单元对应的头文件, 后跟一个空行
  2. 系统头文件 (`<unistd.h>`, `<windows.h>` 等)
  3. 标准库头文件 (`<string>`, `<filesystem>` 等)
  4. 三方库头文件 (`<catch2/...>`, `<asio.hpp>` 等)
  5. 项目内头文件 (`"<project-name>/types.hpp"` 等)

## 类型与初始化

- 定义 enum 时, 默认值/无效值应放在首位
- 成员变量定义时优先使用 `{}` 初始化, 具有默认构造函数的类型可以省略 `{}`
- 系统头文件和 C 库中的类型应使用 `::` 引用

## 语言用法

- 函数参数和数据传递优先使用引用(必要时配合 `const`/`std::span`/`std::string_view`), 避免无谓拷贝
- 单参数构造函数加 `explicit`, 避免隐式转换
- 不要使用 `using` 给命名空间起别名(包括 `using namespace ...;` 和 `namespace x = ...;`), 一律写全限定名

## 注释

- 统一使用 `doxygen` 风格注释, 即注释符号为 `///`, 所有注释使用英文
- 注释必须自包含, 不得引用仓库外的文档(如 AI 工具工作目录下的设计文档)
- 当函数签名自解释时不要添加太多无意义的注释

## 示例

### 基本形态

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

### 好坏对照

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
