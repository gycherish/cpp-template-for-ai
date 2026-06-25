# 开发文档

面向贡献者：构建、测试、编码规范与提交流程。新增章节时在下方 `toctree` 中登记。

```{toctree}
:maxdepth: 1

```

## 构建与测试

```text
xmake f -m debug        # 配置（开发期使用 Debug）
xmake build             # 编译
xmake test              # 运行测试
```

完整的编码规范与 Git 工作流见仓库根目录的 `CLAUDE.md`。
