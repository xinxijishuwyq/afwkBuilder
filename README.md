# OpenHarmony AudioFramework 独立构建验证

这个仓库提供一个可手动触发的 GitHub Actions 工作流，用于验证 OpenHarmony `multimedia_audio_framework` 的独立构建。

## 工作流

- 文件：`.github/workflows/openharmony-audioframework-standalone-verify.yml`
- 触发方式：`workflow_dispatch`（手动触发）

## 输入参数

1. `source_repo`：AudioFramework 仓库地址（默认是 OpenHarmony GitCode 官方仓库地址）
2. `base_ref`：基础分支/标签/提交
3. `pr_commit`：要验证的 PR 提交 SHA（可选）
4. `build_command`：独立构建命令（默认 `./build.sh`，可按你的环境替换）

## 建议用法

1. `base_ref` 填目标分支（例如 `master`）
2. `pr_commit` 填你要验证的 PR commit SHA
3. `build_command` 填你当前可在 CI 环境执行的独立构建命令

这样会从 `base_ref` 拉代码，再 `cherry-pick` 指定 `pr_commit`，最后执行独立构建命令。
