# Git 工作流

本仓库采用 **`main` + `dev` + 短期分支** 模型, 面向可长期维护的大型项目, 人工与 AI 协作下约束一致适用。

## 协作模式

工作流的繁简取决于是否存在多人协作:

- **单人开发(无多人协作)**: 可直接在 `main` 分支开发与提交, 省去 `dev` 与短期分支; 仍需遵循 Conventional Commits、SemVer, 以及不改写已推送历史等通用约束。
- **多人协作**: 必须执行下文的完整分支流程(受保护的 `main`/`dev` + 短期分支 + 评审/CI)。从单人切换到多人时, 先建立 `dev` 并将后续开发迁到短期分支。

下文的分支模型与合并策略针对多人协作场景。

## 分支模型

| 分支 | 角色 | 约束 |
|------|------|------|
| `main` | 发布分支, 始终保持可构建、可发布的稳定状态 | 受保护; 仅接受评审通过的合并; 严禁直接 push 与改写历史 |
| `dev` | 集成分支, 汇聚已完成的功能 | 受保护; 仅通过分支合入; 保持可编译、测试通过 |
| `feat/*`、`fix/*` 等 | 从 `dev` 切出的短生命周期分支 | 单一目的; 尽快合回 `dev` 后删除 |
| `release/*` | (可选)发布准备分支, 从 `dev` 切出, 只做收尾与缺陷修复 | 合入 `main` 并打 tag, 同时回合 `dev` |
| `hotfix/*` | 针对线上紧急缺陷, 从 `main` 切出 | 合入 `main` 并打补丁 tag, 同时回合 `dev` |

核心理念: **`main` 与 `dev` 是受保护的长期分支, 只能通过评审过的合并更新**; 实际开发都在短生命周期分支上进行, 让长期分支始终健康。

## 分支命名

- 格式 `<type>/<简短描述>`, `type` 对齐 Conventional Commits: `feat`、`fix`、`refactor`、`docs`、`test`、`chore` 等
- 描述用 `kebab-case`, 简短达意; 关联 issue 时前置编号
- 例: `feat/async-acceptor`、`refactor/session-pool`、`fix/142-buffer-overflow`

## 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **原子提交**: 一次提交只表达一个逻辑改动, 且可独立编译通过
- **subject**: 祈使句、首字母小写、不加句号, 建议 ≤ 50 字符, 说明"做了什么"
- **body**: 与 subject 空一行, 说明"为什么"与权衡, 每行 ≤ 72 字符
- **footer**: 关联 issue(`Closes #142`)、不兼容变更(`BREAKING CHANGE: ...`)
- 常用 type: `feat` `fix` `refactor` `perf` `docs` `test` `build` `ci` `chore`

示例:

```
feat(net): add async tcp acceptor

Wrap asio's async_accept as a stdexec sender so connection setup
participates in structured concurrency.

Closes #88
```

## 保持历史整洁

- 合并前先把分支 **rebase 到最新的 `dev`**, 解决冲突并保持近似线性的历史:
  ```
  git fetch origin
  git rebase origin/dev
  ```
- 改写历史(rebase、amend、reset)**只允许在自己尚未合并、未共享的分支上**进行; 推送被 rebase 过的分支用 `--force-with-lease`, 不要用 `--force`:
  ```
  git push --force-with-lease
  ```
- **严禁改写已发布历史**(`main`、`dev`, 及任何他人已基于其工作的分支)
- 合入前 squash 掉 "fix typo"、"WIP" 等噪声提交, 让进入长期分支的每个提交都自洽有意义

## 合并与集成

- `main`、`dev` 为受保护分支: **禁止直接 push**, 必须经 Pull/Merge Request
- 合并前置条件: **评审通过 + CI 通过**(编译、测试、`xmake format` 检查、零警告)
- 合并策略:
  - 短期分支 → `dev`: 推荐 squash 或 rebase 合并, 保持线性历史
  - `dev` → `main`: 以一次合并(或快进)完成发布, 并打 tag
- 合并完成后**删除已合并的短期分支**
- PR 保持小而聚焦以便评审; 长期分支频繁合并, 减少漂移与冲突

## 并行开发: git worktree

并行推进多个任务时, 用 `git worktree` 为每个任务挂载独立工作目录, 避免来回切分支:

```
git worktree add ../proj-feat-x -b feat/x dev   # 基于 dev 新建分支并挂载到独立目录
# 在该目录完成开发与提交
git worktree remove ../proj-feat-x              # 合并后清理
```

- 一个并行任务对应一个 worktree
- **处于某个 worktree 中时, 必须在该环境内开发, 严禁切换分支**
- 任务完成、分支合回 `dev` 后, 删除 worktree 与分支

## 发布与版本

- 遵循 [SemVer](https://semver.org/): `MAJOR.MINOR.PATCH`
- 在 `xmake.lua` 中同步版本号:
  ```lua
  set_version("0.1.0", {build = "%Y%m%d"})
  ```
- 发布时在 `main` 上打**附注 tag** `vX.Y.Z`:
  ```
  git tag -a v0.1.0 -m "release 0.1.0"
  git push origin v0.1.0
  ```
- tag 是多版本文档站点(`xmake doc-versions`)与变更日志的依据; 变更日志可由 Conventional Commits 自动生成

## 热修复

线上紧急缺陷从 `main` 切 `hotfix/*` 修复, 合回 `main` 并打 PATCH tag, **同时回合 `dev`**, 避免下次发布回退该修复。

## 提交前检查(红线)

- **必须通过编译与测试**后才提交
- **未经允许严禁提交**, 所有改动须经审核
- **严禁在 `main` 上 force push、reset 等改写历史**
