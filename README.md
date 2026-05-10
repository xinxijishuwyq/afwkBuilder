# OpenHarmony AudioFramework 独立构建（Docker）

这个仓库现已切换为 **仅 Docker** 的独立构建方案，不再维护 GitHub Actions 工作流。

## 目录说明

- `Dockerfile`：构建编译环境镜像。
- `scripts/run-standalone-build.sh`：容器内执行的独立编译脚本。

## 快速开始

### 1) 构建镜像

```bash
docker build -t afwk-standalone-builder .
```

### 2) 运行容器进行编译

```bash
docker run --rm -it \
  -e BASE_REF=master \
  -e AUDIO_FRAMEWORK_DIR=/external/audio_framework \
  -v "$PWD/workdir:/work" \
  -v "$PWD/my_audio_framework:/external/audio_framework" \
  afwk-standalone-builder
```

## 参数说明

- `BASE_REF`：同步使用的分支/标签（默认 `master`）。
- `AUDIO_FRAMEWORK_DIR`：容器内外部 `audio_framework` 目录；用于挂载本地修改源码。脚本会在链接后校验软链接是否创建成功且目标路径一致。
- 脚本内固定执行：`repo sync -c build multimedia_audio_framework`（先拉取 audio_framework 基线，再按需覆盖本地代码）。

## 构建流程

容器内脚本会按固定流程执行：

1. `repo init` 拉取 OpenHarmony manifest。
2. `repo sync` 同步所需项目（固定执行 `repo sync -c build multimedia_audio_framework`）。
3. 执行独立构建命令：
   - `bash build/prebuilts_config.sh && hb build audio_framework -i`
4. 执行一次测试编译：
   - `hb build audio_framework -t`

## 说明

- 本仓库不再包含或维护 GitHub Actions CI 配置。
- 如需在 CI 中使用，请直接在自建 CI 平台调用上述 Docker 流程。
