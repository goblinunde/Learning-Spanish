# SpanishCards 设计规格

## 1. 项目目标

创建一套面向电脑和平板阅读的西班牙语单词记忆 LaTeX 模块。模块以彩色卡片为主要展示形式，并能将同一份词库渲染为三语总览表格。

核心能力：

- 展示西班牙语、英文翻译和中文翻译。
- 展示词性、阴阳性、IPA 或其他发音提示。
- 展示西语例句及英文、中文例句翻译。
- 提供学习模式和多种隐藏答案的测验模式。
- 支持手工录入、CSV 批量导入和 JSON 批量导入。
- 提供适合 16:10 屏幕的独立文档类，同时允许在其他文档类中单独使用样式包。

## 2. 非目标

首个版本不包含以下能力：

- 音频文件嵌入或在线发音服务。
- 间隔重复算法、学习进度数据库或自动评分。
- XLSX、数据库或网络 API 导入。
- CSV/JSON 内容中的原始 LaTeX 命令执行。
- 自动翻译、自动生成例句或词形变化分析。

这些限制让首个版本保持离线、自包含且容易编译。

## 3. 技术架构

项目由三个运行时文件组成：

1. `spanishcards.cls`
   - 基于 `ctexart`。
   - 配置 16:10 横向屏幕页面、页边距、字体层级、背景和页码。
   - 自动加载 `spanishcards.sty`。
   - 默认使用一页一词的卡片布局。

2. `spanishcards.sty`
   - 使用 LaTeX3 数据结构保存词条。
   - 定义用户接口、卡片组件、表格组件、主题和测验模式。
   - 可被 `ctexart`、`article` 或其他兼容文档类独立加载。

3. `spanishcards-data.lua`
   - 负责读取 UTF-8 CSV 和 JSON。
   - 将外部数据转换为与手工词条相同的内部记录。
   - 自带 CSV 和 JSON 解析逻辑，不依赖 Python、Node.js 或第三方 Lua 模块。

由于需要直接解析 JSON，并要稳定处理中文、重音字符和 IPA，编译引擎固定为 LuaLaTeX。使用 XeLaTeX 或 pdfLaTeX 时，模块给出明确的引擎错误信息。

## 4. 页面与视觉设计

### 4.1 屏幕页面

- 默认页面尺寸为 `160 mm × 100 mm`，比例为 16:10。
- 默认页边距为 `7 mm`。
- 每个词条占一页，便于翻页记忆和全屏展示。
- 页面背景使用低饱和暖白，卡片使用轻微阴影、圆角和左侧主题色条。
- 页面底部显示当前卡片序号与词条总数。

### 4.2 卡片层级

卡片从上到下分为四个区域：

1. **词头区**
   - 西班牙语词条使用最大字号。
   - 等级、主题标签和卡片序号以圆角徽章显示。

2. **语言信息区**
   - 词性、阴阳性和发音并排展示。
   - 空字段不占位置，也不显示空标签。

3. **翻译区**
   - 英文和中文采用左右双栏。
   - 两种翻译拥有独立的小标题与浅色背景。

4. **例句区**
   - 西语例句最醒目。
   - 英文和中文翻译使用次级字号。
   - 测验模式可以只隐藏翻译，保留西语例句作为提示。

### 4.3 颜色主题

内置四种高对比、低疲劳主题：

- `mediterranean`：西班牙红、暖黄和海蓝，作为默认主题。
- `ocean`：蓝色与青绿色。
- `mint`：薄荷绿与深青色。
- `sunset`：橙色、珊瑚色与深紫色。

主题只改变强调色和浅色面板，不改变信息层级。正文与背景对比度以屏幕阅读清晰为准，避免使用红绿对立表达状态。

### 4.4 表格视图

- 使用可跨页的 `longtable`。
- 每个词条包含两行：第一行展示西语、英语、中文和语言信息；第二行跨列展示三语例句。
- 表头在新页面自动重复。
- 测验模式同样作用于表格中的翻译字段。

## 5. 数据模型

每个词条支持以下字段：

| 字段 | 必填 | 含义 |
|---|---:|---|
| `spanish` | 是 | 西班牙语词条 |
| `english` | 否 | 英文翻译 |
| `chinese` | 否 | 中文翻译 |
| `pos` | 否 | 词性，例如 `sustantivo`、`verbo` |
| `gender` | 否 | 阴阳性，例如 `m.`、`f.`、`m./f.` |
| `pronunciation` | 否 | IPA 或自定义发音提示 |
| `example_es` | 否 | 西语例句 |
| `example_en` | 否 | 英文例句翻译 |
| `example_zh` | 否 | 中文例句翻译 |
| `level` | 否 | 学习等级，例如 `A1`、`B2` |
| `tags` | 否 | 逗号分隔的主题标签 |
| `color` | 否 | 单词卡主题覆盖值 |

只有 `spanish` 是结构性必填字段。缺失该字段时跳过词条并输出包含来源位置的警告。其他字段缺失时正常渲染剩余内容。

## 6. 公共 LaTeX 接口

### 6.1 全局配置

```latex
\SpanishCardsSetup{
  theme = mediterranean,
  mode = study,
  answer-style = lines,
  show-card-number = true
}
```

支持的主要配置键：

- `theme = mediterranean | ocean | mint | sunset`
- `mode = study | recall | quiz-english | quiz-chinese | quiz-examples | custom`
- `answer-style = hidden | lines`
- `hide = {english,chinese,example-en,example-zh}`，用于 `custom` 模式或补充预设模式。
- `show-card-number = true | false`

### 6.2 手工添加词条

```latex
\AddSpanishWord{
  spanish = {la estación},
  english = {station},
  chinese = {车站},
  pos = {sustantivo},
  gender = {f.},
  pronunciation = {/la es.taˈsjon/},
  example-es = {La estación está cerca.},
  example-en = {The station is nearby.},
  example-zh = {车站就在附近。},
  level = {A1},
  tags = {viajes, ciudad},
  color = {ocean}
}
```

手工录入允许在字段值中使用受控的 LaTeX 格式命令。键值中的逗号必须放在额外的一组花括号中。
LaTeX 接口使用 `example-es`、`example-en`、`example-zh` 形式的连字符键；CSV 与 JSON 继续使用 `example_es`、`example_en`、`example_zh`，导入器负责映射。

### 6.3 数据导入

```latex
\LoadSpanishCSV{data/example.csv}
\LoadSpanishJSON{data/example.json}
```

- 文件路径相对于主 `.tex` 文件或可由 Kpathsea 找到的位置解析。
- 文件必须使用 UTF-8 编码。
- 多次调用会按调用顺序追加词条。
- 外部文件中的文本按纯文本处理，并转义 TeX 特殊字符，防止意外执行命令。

### 6.4 输出与清理

```latex
\PrintVocabularyCards
\PrintVocabularyTable
\ClearSpanishWords
```

- 两个打印命令只读取数据，不消耗数据，因此可以对同一词库先后输出卡片和表格。
- `\ClearSpanishWords` 清空当前词库，方便在同一文档中开始新的章节。
- 空词库调用打印命令时显示友好的空状态提示，并写入警告。

## 7. 测验模式规则

| 模式 | 隐藏字段 |
|---|---|
| `study` | 无 |
| `recall` | `english`、`chinese`、`example_en`、`example_zh` |
| `quiz-english` | `english`、`example_en` |
| `quiz-chinese` | `chinese`、`example_zh` |
| `quiz-examples` | `example_en`、`example_zh` |
| `custom` | `hide` 键指定的字段 |

`answer-style=hidden` 时完全省略答案文本，但保留该区域的标题和基本高度，避免答案长度通过布局泄露。`answer-style=lines` 时使用统一长度的答题横线代替文本。PDF 的文本层中不得包含被隐藏的答案。

## 8. CSV 格式

CSV 第一行必须是字段名，字段名使用数据模型中的英文键。列顺序不受限制，未知列被忽略并输出一次警告。

```csv
spanish,english,chinese,pos,gender,pronunciation,example_es,example_en,example_zh,level,tags,color
la estación,station,车站,sustantivo,f.,/la es.taˈsjon/,La estación está cerca.,The station is nearby.,车站就在附近。,A1,"viajes, ciudad",ocean
```

解析器支持：

- 逗号分隔字段。
- 双引号字段。
- 双引号内的逗号与换行。
- 使用两个连续双引号表示一个字面双引号。
- LF 与 CRLF 换行。

## 9. JSON 格式

JSON 根节点必须是对象数组，每个对象代表一个词条：

```json
[
  {
    "spanish": "la estación",
    "english": "station",
    "chinese": "车站",
    "pos": "sustantivo",
    "gender": "f.",
    "pronunciation": "/la es.taˈsjon/",
    "example_es": "La estación está cerca.",
    "example_en": "The station is nearby.",
    "example_zh": "车站就在附近。",
    "level": "A1",
    "tags": "viajes, ciudad",
    "color": "ocean"
  }
]
```

字符串、数字、布尔值和 `null` 均可被解析；非字符串标量会转换为文本，`null` 转为空字段。嵌套对象和数组不是合法字段值，遇到时跳过该字段并输出警告。

## 10. 错误处理

- 非 LuaLaTeX 引擎：终止编译并说明正确命令。
- 文件不存在或不可读：终止当前导入，保留此前已载入的词条。
- CSV 标题行缺失：终止当前文件导入。
- JSON 语法错误或根节点类型错误：终止当前文件导入并报告行列位置。
- 词条缺少 `spanish`：跳过该词条并报告文件名与记录序号。
- 未知全局选项或非法主题：使用默认值并输出 LaTeX 警告。
- 单张卡片内容超出屏幕页：输出 overfull 警告；首个版本不静默缩小正文，以避免不同卡片字号不一致。

## 11. 文件规划

```text
spanishcards.cls
spanishcards.sty
spanishcards-data.lua
example.tex
data/example.csv
data/example.json
README.md
tests/run-tests.sh
tests/test-manual.tex
tests/test-csv.tex
tests/test-json.tex
tests/test-quiz.tex
```

## 12. 测试与验收

### 12.1 自动测试

- 使用 LuaLaTeX 编译手工录入、CSV 导入和 JSON 导入示例。
- 验证每个测试无 LaTeX error、未定义命令和缺失文件错误。
- 使用 `pdftotext` 验证学习模式包含西、英、中三种文本。
- 使用 `pdftotext` 验证测验模式的 PDF 文本层不包含被隐藏答案。
- 验证 CSV 中带逗号、引号和多行例句的记录。
- 验证 JSON 中的重音字符、中文、转义字符和 `null`。
- 验证同一数据集可以连续打印卡片和表格。

### 12.2 视觉验收

- 将示例 PDF 页面渲染为 PNG 并逐页检查。
- 卡片无文本重叠、裁切和明显溢出。
- 西语词条、翻译和例句具有清晰的视觉层级。
- 中文、重音字符和 IPA 正确显示。
- 学习模式与测验模式布局稳定，不因隐藏答案明显跳动。
- 表格表头、分页和例句跨列显示正确。

### 12.3 交付结果

- 可直接运行的 `.cls`、`.sty` 和 Lua 数据模块。
- CSV、JSON 与手工录入示例。
- 中文 README，包含安装、编译、字段和模式说明。
- 编译成功的示例 PDF 与至少一张页面预览图。

## 13. 自审结论

- **引擎边界明确**：直接 JSON 导入与 Unicode 需求统一落在 LuaLaTeX，不承诺其他引擎。
- **模块职责明确**：类负责页面，样式包负责表现，Lua 负责外部数据。
- **数据安全明确**：外部数据作为纯文本；需要 LaTeX 格式时使用手工接口。
- **测验行为明确**：隐藏字段不会残留在 PDF 文本层，且布局不泄露答案长度。
- **显示范围明确**：默认一页一词，同时提供可跨页总览表格，不实现高密度双栏卡片墙。
- **首版范围受控**：不加入音频、自动翻译、学习算法或外部预处理器。
