# SpanishCards 实施计划

> 设计依据：`docs/superpowers/specs/2026-07-13-spanishcards-design.md`

## 文件职责

- `spanishcards.cls`：16:10 页面、字体、背景、页边距和默认文档行为。
- `spanishcards.sty`：词条注册、配置键、主题、卡片、表格与测验渲染。
- `spanishcards-data.lua`：UTF-8 CSV/JSON 解析、字段映射和 TeX 安全文本输出。
- `tests/run-tests.sh`：编译测试、PDF 文本断言、页数断言与日志检查。
- `tests/test-manual.tex`：手工词条和卡片基础行为。
- `tests/test-quiz.tex`：答案隐藏及 PDF 文本层行为。
- `tests/test-csv.tex`：CSV 引号、逗号、多行与 Unicode 导入。
- `tests/test-json.tex`：JSON Unicode、转义、`null` 与多词条导入。
- `tests/test-table.tex`：同一词库重复渲染及跨页表格行为。
- `tests/fixtures/complex.csv`：CSV 边界测试数据。
- `tests/fixtures/complex.json`：JSON 边界测试数据。
- `example.tex`：完整用户示例，展示卡片、测验配置切换与数据导入。
- `data/example.csv`、`data/example.json`：可直接修改的示例词库。
- `README.md`：中文安装、接口、字段、模式和数据格式文档。

## 任务 1：建立基础失败测试

**文件：**

- 新建 `tests/run-tests.sh`
- 新建 `tests/test-manual.tex`

**步骤：**

1. 编写最小文档，使用 `spanishcards` 文档类、`\AddSpanishWord` 和 `\PrintVocabularyCards`。
2. 在测试脚本中加入 `manual` 测试目标，使用：
   ```bash
   ./tests/run-tests.sh manual
   ```
3. 运行测试并确认失败原因为 `spanishcards.cls` 不存在，而不是测试脚本错误。
4. 预期失败输出包含 `File 'spanishcards.cls' not found`。

## 任务 2：实现类、词条注册与学习卡片

**文件：**

- 新建 `spanishcards.cls`
- 新建 `spanishcards.sty`
- 修改 `tests/test-manual.tex`
- 修改 `tests/run-tests.sh`

**步骤：**

1. 扩充手工测试，使 PDF 必须包含西语、英语、中文、词性、阴阳性、IPA 和三语例句。
2. 运行 `./tests/run-tests.sh manual`，确认因未定义接口失败。
3. 在类文件中实现 LuaLaTeX 引擎检查、`ctexart` 基类、`160 mm × 100 mm` 页面和空页眉页脚。
4. 在样式包中定义词条键、全局序列、`\AddSpanishWord`、`\ClearSpanishWords` 和默认主题。
5. 使用 `tcolorbox` 实现一页一词卡片，包含词头、语言信息、翻译、例句和序号。
6. 运行 `./tests/run-tests.sh manual`，预期编译成功、PDF 为一页且文本断言全部通过。
7. 检查日志中无 `Undefined control sequence`、`LaTeX Error` 或 `Overfull`。

## 任务 3：实现测验与隐藏答案

**文件：**

- 新建 `tests/test-quiz.tex`
- 修改 `tests/run-tests.sh`
- 修改 `spanishcards.sty`

**步骤：**

1. 编写 `recall`、`quiz-english`、`quiz-chinese`、`quiz-examples` 和 `custom` 测试文档或测试段落。
2. 使用 `pdftotext` 断言西语提示存在、目标答案不存在，并断言答题横线由非文本规则生成。
3. 运行 `./tests/run-tests.sh quiz`，确认隐藏答案仍出现在 PDF 文本层，测试先失败。
4. 实现 `\SpanishCardsSetup`、模式预设、额外 `hide` 列表和 `answer-style=hidden|lines`。
5. 隐藏区域仅输出固定高度或规则线，不使用包含答案的 `\phantom`。
6. 重新运行 `./tests/run-tests.sh quiz`，预期所有包含/排除断言通过。

## 任务 4：实现 CSV 批量导入

**文件：**

- 新建 `spanishcards-data.lua`
- 新建 `tests/test-csv.tex`
- 新建 `tests/fixtures/complex.csv`
- 修改 `tests/run-tests.sh`
- 修改 `spanishcards.sty`

**步骤：**

1. 创建包含带逗号标签、双引号、多行例句、中文和重音字符的 CSV fixture。
2. 编写测试调用 `\LoadSpanishCSV`，并断言所有词条与特殊文本出现在 PDF 中。
3. 运行 `./tests/run-tests.sh csv`，确认因导入命令或 Lua 模块不存在而失败。
4. 实现 RFC 4180 风格 CSV 状态机，支持引号、双引号转义、逗号、LF/CRLF 和引号内换行。
5. 将 CSV 下划线字段映射到 LaTeX 连字符键，对外部值逐字符转义 TeX 特殊字符。
6. 实现文件错误、标题缺失、未知列和缺失 `spanish` 的诊断。
7. 重新运行 `./tests/run-tests.sh csv`，预期多词条页数与文本断言通过。

## 任务 5：实现 JSON 批量导入

**文件：**

- 修改 `spanishcards-data.lua`
- 新建 `tests/test-json.tex`
- 新建 `tests/fixtures/complex.json`
- 修改 `tests/run-tests.sh`

**步骤：**

1. 创建包含 Unicode、转义引号、换行、数字、布尔值和 `null` 的 JSON fixture。
2. 编写测试调用 `\LoadSpanishJSON`，断言有效标量被导入、`null` 成为空字段。
3. 运行 `./tests/run-tests.sh json`，确认因 JSON 功能未实现而失败。
4. 实现自包含递归下降 JSON 解析器，支持对象、数组、字符串、数字、布尔值、`null` 与 Unicode 转义。
5. 检查根节点为对象数组；嵌套字段值被忽略并给出警告。
6. 复用 CSV 的字段映射、TeX 转义和记录输出路径。
7. 重新运行 `./tests/run-tests.sh json`，预期页数与 Unicode 文本断言通过。

## 任务 6：实现三语总览表格

**文件：**

- 新建 `tests/test-table.tex`
- 修改 `tests/run-tests.sh`
- 修改 `spanishcards.sty`

**步骤：**

1. 编写测试：载入两条词条，先打印卡片，再打印表格，证明打印不会消耗词库。
2. 断言 PDF 同时包含卡片与表格标题，并至少包含三页。
3. 运行 `./tests/run-tests.sh table`，确认因 `\PrintVocabularyTable` 未定义而失败。
4. 使用 `longtable` 实现重复表头、三语主行、语言信息列和三语例句跨列行。
5. 复用卡片的隐藏字段判断，使测验模式同样作用于表格。
6. 重新运行 `./tests/run-tests.sh table`，预期重复渲染、页数和文本断言通过。

## 任务 7：完成示例与中文文档

**文件：**

- 新建 `example.tex`
- 新建 `data/example.csv`
- 新建 `data/example.json`
- 新建 `README.md`

**步骤：**

1. 示例 CSV 与 JSON 分别提供日常、旅行主题词条，避免重复主词条。
2. `example.tex` 同时演示手工录入、CSV/JSON 导入、卡片输出和表格输出。
3. README 记录 LuaLaTeX 命令、文件部署、全部字段、主题、模式、CSV 引号规则和 JSON 根结构。
4. README 明确外部数据按纯文本转义，而手工接口允许 LaTeX 格式。
5. 运行：
   ```bash
   latexmk -lualatex -interaction=nonstopmode -halt-on-error example.tex
   ```
6. 预期生成 `example.pdf`，日志无错误、未定义命令和明显溢出。

## 任务 8：完整验证与视觉检查

**文件：**

- 根据验证结果最小修改上述实现文件。
- 生成 `preview/page-1.png` 作为视觉预览。

**步骤：**

1. 运行全部自动测试：
   ```bash
   ./tests/run-tests.sh all
   ```
2. 运行示例编译并使用 `pdfinfo` 检查页面尺寸为约 `453.54 × 283.46 pt`。
3. 使用 `pdffonts example.pdf` 确认所有字体嵌入。
4. 使用以下命令渲染首张卡片：
   ```bash
   mkdir -p preview
   pdftoppm -f 1 -singlefile -png -r 150 example.pdf preview/page-1
   ```
5. 检查 PNG 中无重叠、裁切、乱码、低对比或异常留白。
6. 若视觉检查失败，仅调整主题、间距或字号，并重新执行全部测试。
7. 最终再次运行 `./tests/run-tests.sh all` 与示例编译，保留成功输出作为完成证据。

## 计划自审

- 每项生产代码前都有明确的失败测试与预期失败原因。
- 手工、测验、CSV、JSON、表格和视觉输出均有独立验收路径。
- 文件名、公共命令和字段映射与设计规格一致。
- 计划中没有未定义占位项或依赖网络的步骤。
- 当前目录不是 Git 仓库，因此不执行提交步骤；实现只修改工作区文件。

