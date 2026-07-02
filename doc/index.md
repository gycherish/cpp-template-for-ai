# cpp-template-for-ai 文档

本站点由构建系统自动生成：叙述性文档（产品、设计、决策、手册、开发）以 Markdown 编写，API 参考由 Doxygen 从源码 `///` 注释抽取，统一经 Sphinx 渲染；并可按 git tag/分支构建多版本，通过版本切换器查看。

```{toctree}
:maxdepth: 2
:caption: 文档目录

product/index
design/index
adr/index
manual/index
dev/index
api/index
```

## 本地构建

```text
pixi install            # 首次：安装文档工具链
xmake doc               # 构建 HTML 站点 -> build/doc/html
xmake doc-serve         # 本地预览（热重载）
xmake doc-pdf           # 生成 PDF（需系统 TeX）
xmake doc-versions      # 逐版本构建并生成版本切换器
```
