# JSON-to-TeX 转换器实施计划

> 设计依据：`docs/superpowers/specs/2026-07-13-json-to-tex-design.md`

## 任务 1：建立转换器失败测试

**文件：**

- 修改 `tests/run-tests.sh`
- 新建 `tests/test-generated-fragment.tex`

**步骤：**

1. 增加 `converter` 测试目标。
2. 测试调用 `texlua scripts/json-to-tex.lua` 生成片段、卡片文档和表格文档。
3. 断言片段包含 `\AddSpanishWord` 且不包含 `\documentclass`。
4. 用 `tests/test-generated-fragment.tex` 输入生成片段并编译。
5. 运行 `./tests/run-tests.sh converter`，确认因转换器不存在而失败。

## 任务 2：提取纯 JSON 与 TeX 序列化接口

**文件：**

- 修改 `spanishcards-data.lua`

**步骤：**

1. 保持失败测试不变。
2. 导出 `parse_json`、`read_json_records`、`record_to_latex` 和 `records_to_latex`。
3. 让 `load_json` 复用纯函数，不改变现有运行时行为。
4. 运行 `./tests/run-tests.sh json`，确认既有 JSON 测试保持通过。
5. 转换器测试仍应因脚本不存在而失败。

## 任务 3：实现转换器 CLI

**文件：**

- 新建 `scripts/json-to-tex.lua`

**步骤：**

1. 解析 `--input`、`--output`、`--format`、`--view` 和 `--help`。
2. 使用 Kpathsea 定位 `spanishcards-data.lua` 并调用共享纯函数。
3. 实现片段和完整文档两个渲染器。
4. 实现递归创建目录、同目录临时写入与原子重命名。
5. 对非法参数、读写错误和 JSON 错误返回非零状态。
6. 运行 `./tests/run-tests.sh converter`，确认三种输出均可编译。
7. 连续转换两次并比较 SHA-256，确认输出稳定。

## 任务 4：实现 Makefile 工作流

**文件：**

- 新建 `Makefile`
- 修改 `tests/run-tests.sh`

**步骤：**

1. 编写 `help`、`test`、`pdf`、`convert-json`、`json-fragments`、`json-documents`、`clean` 和 `distclean`。
2. 使用模式规则将 `data/*.json` 映射到两个生成目录。
3. 为 `convert-json` 提供可覆盖变量与默认值。
4. 在转换器测试中验证 Make 单文件和批量目标。
5. 运行 `make json-fragments` 与 `make json-documents`，检查目标文件。
6. 运行 `make test`，确认全部测试通过。

## 任务 5：重写详细 README

**文件：**

- 修改 `README.md`

**步骤：**

1. 加入目录、功能矩阵和依赖说明。
2. 记录四种数据工作流及各自适用场景。
3. 完整记录 Make 目标、变量和命令示例。
4. 加入片段与完整文档生成示例。
5. 加入字段、主题、测验模式、项目结构和故障排除。
6. 检查 README 中所有命令与实际 Makefile 一致。

## 任务 6：最终验证与清理

**步骤：**

1. 运行 `bash -n tests/run-tests.sh`。
2. 运行 `texlua spanishcards-data.lua` 与转换器 `--help`。
3. 运行 `./tests/run-tests.sh all`。
4. 运行 `make json-fragments json-documents`。
5. 运行 `make pdf` 并检查 PDF 页数、尺寸、日志和字体嵌入。
6. 删除调试遗留的根目录辅助文件，保留源文件、示例 PDF 和预览图。
7. 再次运行全部测试，记录完成证据。

## 计划自审

- 每项转换功能均先有失败测试。
- 运行时 JSON 导入与预生成 TeX 共用解析和转义实现。
- 单文件、批量、片段、卡片文档和表格文档均有验收路径。
- README 命令由实际目标驱动，不包含未实现选项。
- 当前目录不是 Git 仓库，因此不执行提交步骤。

