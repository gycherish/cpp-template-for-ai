# cpp-template-for-ai

面向 AI Agent 协作的现代 C++23 项目模板: 预置异步技术栈、自动化文档与统一工程规范, 让人与 AI 工具在同一套约定下高效开发。

## 特性

- **C++23**, 严格遵循 [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines), 优先 Ranges 与 `std::filesystem`
- **异步架构**: [stdexec](https://github.com/nvidia/stdexec) 任务编排 + [asio](https://think-async.com/Asio/) 异步 IO, 以协程表达并满足结构化并发
- **构建系统**: [xmake](https://xmake.io/), C++ 依赖经 xrepo 自动管理
- **文档工具链**: Sphinx + MyST(Markdown) + Breathe + Doxygen, 由 [pixi](https://pixi.sh/) 管理; 支持多版本站点与精排 PDF
- **工程规范**: `.clang-format`/`.editorconfig` 固化代码风格, Conventional Commits + SemVer
- **AI 协作**: [CLAUDE.md](CLAUDE.md) 为权威开发指令, [AGENTS.md](AGENTS.md) 作为各 AI 工具的中性入口

## 目录结构

| 目录 | 用途 |
|------|------|
| `include/<project-name>/` | 公共头文件 |
| `src/` | 源文件与私有头文件 |
| `tests/` | 测试 |
| `examples/` | 示例程序 |
| `doc/` | 文档源(产品/需求/设计/决策/手册/开发/API) |

## 环境要求

- [xmake](https://xmake.io/) ≥ 3.0 —— 构建并自动拉取 C++ 依赖
- [pixi](https://pixi.sh/) —— 文档工具链(不构建文档可不装)
- 系统 TeX 发行版 —— 仅 `xmake doc-pdf` 生成 PDF 时需要(Linux 用 TeX Live, Windows 用 MiKTeX)

## 快速开始

### 构建与测试

```
xmake f -m debug      # 配置(开发期使用 Debug)
xmake build           # 编译
xmake test            # 运行测试
```

### 文档

```
pixi install          # 首次: 安装文档工具链
xmake doc             # 构建 HTML 站点 -> build/doc/html
xmake doc-serve       # 本地预览(热重载)
xmake doc-pdf         # 生成 PDF(需系统 TeX)
xmake doc-versions    # 逐版本构建 + 版本切换器
```

## 文档导航

| 文档 | 路径 |
|------|------|
| 产品与需求 | [doc/product/index.md](doc/product/index.md) |
| 架构与设计 | [doc/design/index.md](doc/design/index.md) |
| 决策记录 | [doc/adr/index.md](doc/adr/index.md) |
| 开发文档 | [doc/dev/index.md](doc/dev/index.md) |
| 完整站点 | 运行 `xmake doc` 后打开 `build/doc/html/index.html` |

## 面向 AI 工具

本仓库的开发指令统一维护在 [CLAUDE.md](CLAUDE.md); 任何 AI 编码工具(Claude Code、OpenAI Codex、Cursor 等)经 [AGENTS.md](AGENTS.md) 指向它。开始编码前请先完整阅读并遵循。

## 许可证

本项目以 [MIT 许可证](LICENSE)发布。
