# OpenHarmony AudioFramework 独立构建验证

这个仓库提供一个 GitHub Actions 工作流，用于验证 OpenHarmony `multimedia_audio_framework` 的独立构建，并支持将 prebuild（`build/prebuilts_config.sh`）与正常构建解耦：

- 正常构建：默认使用已有 prebuild 缓存，加快构建。
- 缓存刷新：可手动触发或每日定时，仅执行 prebuild 并写入当日缓存。

## 工作流

- 文件：`.github/workflows/openharmony-audioframework-standalone-verify.yml`
- 触发方式：
  - `workflow_dispatch`（手动触发）
  - `schedule`（每日定时，默认北京时间 02:20）

## 输入参数（workflow_dispatch）

1. `run_mode`：运行模式
   - `build`：正常构建（恢复缓存 + 执行 `build_command`）
   - `refresh-cache`：仅刷新缓存（不恢复历史缓存，仅执行 prebuild）
2. `source_repo`：AudioFramework 仓库地址（默认 OpenHarmony GitCode 官方仓库）
3. `base_ref`：基础分支/标签/提交
4. `pr_commit`：要验证的 PR 提交 SHA（可选，仅 `build` 模式生效）
5. `build_command`：独立构建命令（默认 `bash build/prebuilts_config.sh && hb build audio_framework -i`）

## 缓存策略说明

- 缓存键：`prebuild-cache-${runner.os}-${base_ref}-${YYYYMMDD}`
- `build` 模式：
  - 恢复同分支最新缓存（通过 `restore-keys` 前缀匹配）
  - 不主动写缓存，避免每次构建都产生新缓存
- `refresh-cache` 模式（含定时任务）：
  - 不恢复任何历史缓存（避免基于旧缓存不断叠加）
  - 仅运行 `bash build/prebuilts_config.sh`
  - 生成并保存当天新缓存

这样可以做到：

- 日常 PR/分支验证速度更快（用缓存）
- 缓存生成与业务构建分离（更可控）
- 刷新时不吃旧缓存，避免“越滚越大”的风险

## 建议用法

### 1) 日常验证（推荐）

- `run_mode`: `build`
- `base_ref`: 目标分支（例如 `master`）
- `pr_commit`: 要验证的 PR commit SHA
- `build_command`: 你的独立构建命令

### 2) 手动刷新 prebuild 缓存

- `run_mode`: `refresh-cache`
- `base_ref`: 要刷缓存的分支
- 其他参数按需保留默认

### 3) 自动每日刷新

- 已内置 `schedule`，默认每天执行一次 `refresh-cache` 逻辑
