# OpenHarmony AudioFramework 独立构建验证

这个仓库提供一个 GitHub Actions 工作流，用于验证 OpenHarmony `multimedia_audio_framework` 的独立构建，并支持将 prebuild（`build/prebuilts_config.sh`）与正常构建解耦：

- 正常构建：默认使用已有 prebuild 缓存，加快构建。
- 缓存刷新：可手动触发或每日定时，执行完整构建以刷新 prebuild 与 ccache，并写入当日缓存。

## 工作流

- 文件：`.github/workflows/openharmony-audioframework-standalone-verify.yml`
- 触发方式：
  - `workflow_dispatch`（手动触发）
  - `schedule`（每日定时，默认北京时间 02:20）

## 输入参数（workflow_dispatch）

1. `run_mode`：运行模式
   - `build`：正常构建（恢复缓存 + 执行 `build_command`）
   - `refresh-cache`：刷新缓存（不恢复历史缓存，执行完整构建以生成 prebuild + ccache）
2. `manifest_repo`：manifest 仓库地址（用于 `repo init`，默认 OpenHarmony GitCode 官方 manifest）
3. `base_ref`：基础分支/标签/提交
4. `pr_patch_content`：PR patch 内容（可选，仅 `build` 模式生效）
   - 支持直接粘贴 patch/mailbox 内容
   - 支持 URL 编码内容（会自动解码）
   - 支持 `base64:<payload>` 格式（会自动 Base64 解码）
   - 配置后优先级最高：会优先于 `pr_patch_url` / `pr_fetch_spec` / `pr_commit` 执行
   - 通过 `git am --3way` 优先应用，失败时回退 `git apply`
5. `pr_patch_url`：PR patch 链接（可选，仅 `build` 模式生效），例如：
   - `https://gitcode.com/openharmony/multimedia_audio_framework/pull/14808.patch`
   - 支持 URL 编码输入（会自动解码）
   - 当 `pr_patch_content` 为空时，配置后会优先于 `pr_fetch_spec` / `pr_commit` 执行（通过下载 patch 后优先 `git am --3way`，失败时回退 `git apply`）
   - 支持包含多笔 commit 的 mailbox patch（常见于 PR/MR `.patch` 链接）
6. `pr_fetch_spec`：PR 拉取规格（可选，仅 `build` 模式生效），格式：
   - `<repo_url> <refspec>`
   - 示例：`https://gitcode.com/openharmony/multimedia_audio_framework.git +refs/merge-requests/14808/head:pr_14808`
   - 兼容 URL 编码输入（如把空格写成 `%20`）：`https://gitcode.com/openharmony/multimedia_audio_framework.git%20+refs/merge-requests/14808/head:pr_14808`
   - 当 `pr_patch_content` 与 `pr_patch_url` 都为空时，配置后会优先于 `pr_commit` 执行（即先 `git fetch <repo_url> <refspec>`，再检出目标引用）
7. `pr_commit`：要验证的 PR 提交 SHA（可选，仅 `build` 模式生效；当 `pr_patch_content`、`pr_patch_url` 和 `pr_fetch_spec` 都为空时生效）
8. `build_command`：独立构建命令（默认 `bash build/prebuilts_config.sh && hb build audio_framework -i`）
9. `ut_build_command`：UT 独立编译命令（默认 `hb build audio_framework -t`，仅在 `build` 模式独立执行一次）

## 缓存策略说明

- 缓存键：`prebuild-cache-${runner.os}-${base_ref}-${YYYYMMDD}`
- ccache 缓存键：`ccache-${runner.os}-${base_ref}-${YYYYMMDD}`
- `build` 模式：
  - 恢复同分支最新缓存（通过 `restore-keys` 前缀匹配）
  - 不主动写缓存，避免每次构建都产生新缓存
  - 缓存目录为工作区根目录下的 `prebuilts`、`out/prebuilts` 与 `.cache/prebuilts`
  - 主构建完成后，额外独立执行一次 UT 编译（默认 `hb build audio_framework -t`）
  - 构建完成后自动上传编译产物（`out/**`），默认保留 7 天
- `refresh-cache` 模式（含定时任务）：
  - 不恢复任何历史缓存（避免基于旧缓存不断叠加）
  - 执行 `build_command` 完整构建（默认 `bash build/prebuilts_config.sh && hb build audio_framework -i`）
  - 生成并保存当天新缓存（`prebuilts` + `ccache`）

这样可以做到：

- 日常 PR/分支验证速度更快（用缓存）
- 缓存生成与业务构建分离（更可控）
- CI 会扫描 `build/indep_configs/config/*.json`，将其中所有符合格式的 `raw.gitcode.com/openharmony/<repo>/raw/<branch>/<path>` 链接统一规范化到 `raw.githubusercontent.com/openharmony/<repo>/<branch>/<path>`。
- 刷新时不吃旧缓存，避免“越滚越大”的风险
- 构建流程启用 `ccache`，并在刷新模式中落盘缓存，供后续 `build` 模式恢复
- CI 运行时通过 `repo init + repo sync` 拉取 `build` 与 `multimedia_audio_framework`，符合部件独立编译指导中的推荐方式。

## 建议用法



### 1) 日常验证（推荐）

- `run_mode`: `build`
- `base_ref`: 目标分支（例如 `master`）
- `pr_patch_content`: 可直接粘贴 patch 内容（推荐）
- `pr_patch_url`: 推荐直接填 PR patch 链接（如 `https://gitcode.com/openharmony/multimedia_audio_framework/pull/14808.patch`）
- 或 `pr_fetch_spec`: PR 拉取规格（如 `https://gitcode.com/openharmony/multimedia_audio_framework.git +refs/merge-requests/14808/head:pr_14808`）
- 或 `pr_commit`: 要验证的 PR commit SHA
- `build_command`: 你的独立构建命令

如需从本地 patch 文件触发，可通过 GitHub CLI 把文件内容传给 `pr_patch_content`：

```bash
gh workflow run openharmony-audioframework-standalone-verify.yml \
  -f run_mode=build \
  -f base_ref=master \
  -F pr_patch_content=@./pr_14808.patch
```

### 2) 手动刷新 prebuild 缓存

- `run_mode`: `refresh-cache`
- `base_ref`: 要刷缓存的分支
- 其他参数按需保留默认

### 3) 自动每日刷新

- 已内置 `schedule`，默认每天执行一次 `refresh-cache` 逻辑
