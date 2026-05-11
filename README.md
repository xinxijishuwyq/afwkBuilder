# OpenHarmony AudioFramework 独立构建（Docker）

这个仓库现已切换为 **仅 Docker** 的独立构建方案，不再维护 GitHub Actions 工作流。

## 目录说明

- `Dockerfile`：构建编译环境镜像。
- `scripts/run-standalone-build.sh`：容器内执行的独立编译脚本。

## 快速开始

### 1) 构建镜像（默认会在镜像构建阶段预热一次 `hb build audio_framework -i`）

```bash
docker build -t afwk-standalone-builder .
```

如需跳过镜像构建阶段预热：

```bash
docker build --build-arg PREBUILD_HB_CACHE=0 -t afwk-standalone-builder .
```

### 2) 运行容器进行编译

```bash
docker run --rm -it \
  -e BASE_REF=master \
  -e AUDIO_FRAMEWORK_DIR=/external/audio_framework \
  -v "$PWD/my_audio_framework:/external/audio_framework" \
  afwk-standalone-builder
```

示例 A（通过环境变量传入编译命令）：

```bash
docker run --rm -it \
  -e BASE_REF=master \
  -e AUDIO_FRAMEWORK_DIR=/external/audio_framework \
  -e HB_BUILD_COMMAND="hb build audio_framework -i" \
  -v "$PWD/my_audio_framework:/external/audio_framework" \
  afwk-standalone-builder
```

示例 B（在镜像名后直接传入完整命令参数）：

```bash
docker run --rm -it \
  -e BASE_REF=master \
  -e AUDIO_FRAMEWORK_DIR=/external/audio_framework \
  -v "$PWD/my_audio_framework:/external/audio_framework" \
  afwk-standalone-builder \
  hb build audio_framework -t
```

## 参数说明

- `BASE_REF`：同步使用的分支/标签（默认 `master`）。
- `AUDIO_FRAMEWORK_DIR`：容器内外部 `audio_framework` 目录；用于挂载本地修改源码。脚本会使用 `rsync` 覆盖 `foundation/multimedia/audio_framework`，避免 `hb` 不遍历软链接目录的问题。
- 默认不再要求挂载主机 `~/.hpm` 或 `~/.ccache`；镜像构建阶段会执行预热来准备基础缓存。
- 脚本默认根据是否预热自动选择 `repo sync -c` 项目（预热开启=`build multimedia_audio_framework`，非预热=`build`）；`audio_framework` 代码仍可由 `AUDIO_FRAMEWORK_DIR` 提供。
- 首次执行 `repo init` 时，脚本会为该命令临时注入 Git 身份环境变量，避免交互式报错，不会修改容器内全局 Git 配置。
- `scripts/run-standalone-build.sh` 的 `hb` 编译命令由外部传入：可通过脚本参数或 `HB_BUILD_COMMAND` 环境变量传入，脚本内部直接执行。
- `WARMUP_BUILD_COMMAND`：运行容器时的缓存预热命令，默认 `hb build audio_framework -i`。如需自定义可通过环境变量覆盖。
- `PREBUILD_HB_CACHE`：镜像构建阶段是否预热缓存（默认 `1`，执行一次 `hb build audio_framework -i`）。
- `SYNC_PROJECTS`：`repo sync -c` 的项目列表。未显式设置时：预热开启默认 `build multimedia_audio_framework`，非预热场景默认仅 `build`。

## 构建流程

容器内脚本会按固定流程执行：

1. `repo init` 拉取 OpenHarmony manifest。
2. `repo sync` 同步所需项目（默认根据是否预热自动选择：预热开启=`build multimedia_audio_framework`，非预热=`build`；也可通过 `SYNC_PROJECTS` 覆盖）。
3. 固定执行预构建环境配置：`bash build/prebuilts_config.sh`。
4. 先执行缓存预热命令：`hb build audio_framework -i`（可通过 `WARMUP_BUILD_COMMAND` 覆盖）。
5. 再执行外部传入的 `hb` 编译命令（参数或 `HB_BUILD_COMMAND`）。
   - 示例：`./scripts/run-standalone-build.sh hb build audio_framework -i`
   - 示例：`./scripts/run-standalone-build.sh hb build audio_framework -t`
   - 示例：`HB_BUILD_COMMAND="hb build audio_framework -i && hb build audio_framework -t" ./scripts/run-standalone-build.sh`

## 说明

- 本仓库不再包含或维护 GitHub Actions CI 配置。
- 如需在 CI 中使用，请直接在自建 CI 平台调用上述 Docker 流程。
