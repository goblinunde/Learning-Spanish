local spanishcards_data = {}

local field_map = {
  spanish = "spanish",
  english = "english",
  chinese = "chinese",
  pos = "pos",
  gender = "gender",
  pronunciation = "pronunciation",
  example_es = "example-es",
  example_en = "example-en",
  example_zh = "example-zh",
  level = "level",
  tags = "tags",
  color = "color",
}

local field_order = {
  "spanish",
  "english",
  "chinese",
  "pos",
  "gender",
  "pronunciation",
  "example_es",
  "example_en",
  "example_zh",
  "level",
  "tags",
  "color",
}

local function warn(message)
  texio.write_nl("term and log", "Package spanishcards Warning: " .. message)
  texio.write_nl("term and log", "")
end

local function report_error(message, help)
  tex.error("SpanishCards: " .. message, {help})
end

local function read_file(path)
  local resolved_path = kpse.find_file(path) or path
  local handle = io.open(resolved_path, "rb")
  if not handle then
    return nil, "cannot read '" .. path .. "'"
  end

  local content = handle:read("*a")
  handle:close()
  return content, nil
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function row_is_empty(row)
  for _, value in ipairs(row) do
    if value ~= "" then
      return false
    end
  end
  return true
end

local function parse_csv(content)
  local rows = {}
  local current_row = {}
  local field_parts = {}
  local inside_quotes = false
  local index = 1
  local content_length = #content

  local function finish_field()
    current_row[#current_row + 1] = table.concat(field_parts)
    field_parts = {}
  end

  local function finish_row()
    finish_field()
    rows[#rows + 1] = current_row
    current_row = {}
  end

  while index <= content_length do
    local character = content:sub(index, index)

    if inside_quotes then
      if character == '"' then
        if content:sub(index + 1, index + 1) == '"' then
          field_parts[#field_parts + 1] = '"'
          index = index + 2
        else
          inside_quotes = false
          index = index + 1
        end
      else
        field_parts[#field_parts + 1] = character
        index = index + 1
      end
    elseif character == '"' and #field_parts == 0 then
      inside_quotes = true
      index = index + 1
    elseif character == "," then
      finish_field()
      index = index + 1
    elseif character == "\n" then
      finish_row()
      index = index + 1
    elseif character == "\r" then
      finish_row()
      if content:sub(index + 1, index + 1) == "\n" then
        index = index + 2
      else
        index = index + 1
      end
    else
      field_parts[#field_parts + 1] = character
      index = index + 1
    end
  end

  if inside_quotes then
    error("unterminated quoted field")
  end

  if #field_parts > 0 or #current_row > 0 or content:sub(-1) == "," then
    finish_row()
  end

  return rows
end

local tex_escape_map = {
  ["\\"] = "\\textbackslash{}",
  ["{"] = "\\{",
  ["}"] = "\\}",
  ["$"] = "\\$",
  ["&"] = "\\&",
  ["#"] = "\\#",
  ["%"] = "\\%",
  ["_"] = "\\_",
  ["^"] = "\\textasciicircum{}",
  ["~"] = "\\textasciitilde{}",
  ["\n"] = " ",
  ["\r"] = " ",
  ["\t"] = " ",
}

local function tex_escape(value)
  local escaped = {}
  for index = 1, #value do
    local character = value:sub(index, index)
    escaped[#escaped + 1] = tex_escape_map[character] or character
  end
  return table.concat(escaped)
end

local function scalar_to_string(value, json_null)
  if value == nil or value == json_null then
    return ""
  end
  if type(value) == "boolean" then
    return value and "true" or "false"
  end
  return tostring(value)
end

local function record_to_latex(record, source, record_number, json_null)
  local key_values = {}

  for _, external_key in ipairs(field_order) do
    local value = record[external_key]
    if type(value) == "table" and value ~= json_null then
      warn(
        string.format(
          "ignored nested value for '%s' in %s record %d",
          external_key,
          source,
          record_number
        )
      )
    else
      local latex_key = field_map[external_key]
      local scalar_value = scalar_to_string(value, json_null)
      key_values[#key_values + 1] =
        latex_key .. "={" .. tex_escape(scalar_value) .. "}"
    end
  end

  key_values[#key_values + 1] = "source={" .. tex_escape(source) .. "}"
  key_values[#key_values + 1] = "record={" .. tostring(record_number) .. "}"
  return "\\AddSpanishWord{" .. table.concat(key_values, ",") .. "}"
end

local function emit_record(record, source, record_number, json_null)
  tex.sprint(record_to_latex(record, source, record_number, json_null))
end

function spanishcards_data.load_csv(path)
  local content, read_error = read_file(path)
  if not content then
    report_error(read_error, "Check the CSV path and file permissions.")
    return
  end

  local parse_ok, rows_or_error = pcall(parse_csv, content)
  if not parse_ok then
    report_error(
      "invalid CSV in '" .. path .. "': " .. rows_or_error,
      "Check quoted fields and delimiters."
    )
    return
  end

  local rows = rows_or_error
  if #rows == 0 or row_is_empty(rows[1]) then
    report_error(
      "CSV header missing in '" .. path .. "'",
      "Add a first row containing field names."
    )
    return
  end

  local headers = rows[1]
  headers[1] = headers[1]:gsub("^\239\187\191", "")
  local known_columns = {}

  for column_index, header in ipairs(headers) do
    local normalized_header = trim(header)
    headers[column_index] = normalized_header
    if field_map[normalized_header] then
      known_columns[column_index] = normalized_header
    elseif normalized_header ~= "" then
      warn("ignored unknown CSV column '" .. normalized_header .. "' in " .. path)
    end
  end

  for row_index = 2, #rows do
    local row = rows[row_index]
    if not row_is_empty(row) then
      local record = {}
      for column_index, external_key in pairs(known_columns) do
        record[external_key] = row[column_index] or ""
      end
      emit_record(record, path, row_index - 1)
    end
  end
end

local json_null = {}
local json_array_marker = {}

local function parse_json(content)
  local index = 1
  local content_length = #content

  local function location()
    local prefix = content:sub(1, math.max(index - 1, 0))
    local _, line_breaks = prefix:gsub("\n", "\n")
    local last_line_start = prefix:match(".*()\n") or 0
    return line_breaks + 1, index - last_line_start
  end

  local function parse_error(message)
    local line, column = location()
    error(string.format("%s at line %d, column %d", message, line, column), 0)
  end

  local function skip_whitespace()
    while index <= content_length do
      local character = content:sub(index, index)
      if character == " " or character == "\t" or
          character == "\n" or character == "\r" then
        index = index + 1
      else
        break
      end
    end
  end

  local function parse_unicode_escape()
    local hexadecimal = content:sub(index, index + 3)
    if #hexadecimal ~= 4 or not hexadecimal:match("^[0-9a-fA-F]+$") then
      parse_error("invalid Unicode escape")
    end
    index = index + 4

    local codepoint = tonumber(hexadecimal, 16)
    if codepoint >= 0xD800 and codepoint <= 0xDBFF then
      if content:sub(index, index + 1) ~= "\\u" then
        parse_error("high surrogate without low surrogate")
      end
      index = index + 2
      local low_hexadecimal = content:sub(index, index + 3)
      if #low_hexadecimal ~= 4 or
          not low_hexadecimal:match("^[0-9a-fA-F]+$") then
        parse_error("invalid low surrogate")
      end
      index = index + 4
      local low_codepoint = tonumber(low_hexadecimal, 16)
      if low_codepoint < 0xDC00 or low_codepoint > 0xDFFF then
        parse_error("invalid low surrogate")
      end
      codepoint = 0x10000 +
        (codepoint - 0xD800) * 0x400 +
        (low_codepoint - 0xDC00)
    elseif codepoint >= 0xDC00 and codepoint <= 0xDFFF then
      parse_error("low surrogate without high surrogate")
    end

    return utf8.char(codepoint)
  end

  local function parse_string()
    if content:sub(index, index) ~= '"' then
      parse_error("expected string")
    end
    index = index + 1
    local parts = {}
    local escape_map = {
      ['"'] = '"',
      ["\\"] = "\\",
      ["/"] = "/",
      ["b"] = "\b",
      ["f"] = "\f",
      ["n"] = "\n",
      ["r"] = "\r",
      ["t"] = "\t",
    }

    while index <= content_length do
      local character = content:sub(index, index)
      if character == '"' then
        index = index + 1
        return table.concat(parts)
      elseif character == "\\" then
        index = index + 1
        local escape_character = content:sub(index, index)
        if escape_character == "u" then
          index = index + 1
          parts[#parts + 1] = parse_unicode_escape()
        elseif escape_map[escape_character] then
          parts[#parts + 1] = escape_map[escape_character]
          index = index + 1
        else
          parse_error("invalid string escape")
        end
      elseif character:byte() < 0x20 then
        parse_error("unescaped control character in string")
      else
        parts[#parts + 1] = character
        index = index + 1
      end
    end

    parse_error("unterminated string")
  end

  local function parse_number()
    local remaining = content:sub(index)
    local number_text =
      remaining:match("^%-?%d+%.%d+[eE][+-]?%d+") or
      remaining:match("^%-?%d+[eE][+-]?%d+") or
      remaining:match("^%-?%d+%.%d+") or
      remaining:match("^%-?%d+")

    if not number_text then
      parse_error("invalid number")
    end
    if number_text:match("^%-?0%d") then
      parse_error("leading zero in number")
    end

    index = index + #number_text
    return tonumber(number_text)
  end

  local parse_value

  local function parse_array()
    index = index + 1
    skip_whitespace()
    local array = setmetatable({}, json_array_marker)

    if content:sub(index, index) == "]" then
      index = index + 1
      return array
    end

    while true do
      array[#array + 1] = parse_value()
      skip_whitespace()
      local character = content:sub(index, index)
      if character == "]" then
        index = index + 1
        return array
      elseif character ~= "," then
        parse_error("expected ',' or ']' in array")
      end
      index = index + 1
      skip_whitespace()
    end
  end

  local function parse_object()
    index = index + 1
    skip_whitespace()
    local object = {}

    if content:sub(index, index) == "}" then
      index = index + 1
      return object
    end

    while true do
      local key = parse_string()
      skip_whitespace()
      if content:sub(index, index) ~= ":" then
        parse_error("expected ':' after object key")
      end
      index = index + 1
      skip_whitespace()
      object[key] = parse_value()
      skip_whitespace()

      local character = content:sub(index, index)
      if character == "}" then
        index = index + 1
        return object
      elseif character ~= "," then
        parse_error("expected ',' or '}' in object")
      end
      index = index + 1
      skip_whitespace()
    end
  end

  parse_value = function()
    skip_whitespace()
    local character = content:sub(index, index)

    if character == '"' then
      return parse_string()
    elseif character == "{" then
      return parse_object()
    elseif character == "[" then
      return parse_array()
    elseif content:sub(index, index + 3) == "true" then
      index = index + 4
      return true
    elseif content:sub(index, index + 4) == "false" then
      index = index + 5
      return false
    elseif content:sub(index, index + 3) == "null" then
      index = index + 4
      return json_null
    elseif character == "-" or character:match("%d") then
      return parse_number()
    end

    parse_error("unexpected value")
  end

  skip_whitespace()
  local result = parse_value()
  skip_whitespace()
  if index <= content_length then
    parse_error("unexpected trailing content")
  end
  return result
end

local function read_json_records(path)
  local content, read_error = read_file(path)
  if not content then
    return nil, read_error, "Check the JSON path and file permissions."
  end

  local parse_ok, result_or_error = pcall(parse_json, content)
  if not parse_ok then
    return nil,
      "invalid JSON in '" .. path .. "': " .. result_or_error,
      "Check the reported line and column."
  end

  local records = result_or_error
  if type(records) ~= "table" or getmetatable(records) ~= json_array_marker then
    return nil,
      "JSON root in '" .. path .. "' is not an array",
      "Use an array of vocabulary objects."
  end

  return records, nil, nil
end

local function records_to_latex(records, source)
  local lines = {}
  local warned_unknown_keys = {}

  for record_index, record in ipairs(records) do
    if type(record) ~= "table" or getmetatable(record) == json_array_marker then
      warn(string.format("ignored non-object JSON record %d in %s", record_index, source))
    else
      for key in pairs(record) do
        if not field_map[key] and not warned_unknown_keys[key] then
          warn("ignored unknown JSON field '" .. key .. "' in " .. source)
          warned_unknown_keys[key] = true
        end
      end

      local spanish = scalar_to_string(record.spanish, json_null)
      if type(record.spanish) == "table" or spanish == "" then
        warn(string.format("skipped record %d in %s without spanish", record_index, source))
      else
        lines[#lines + 1] =
          record_to_latex(record, source, record_index, json_null)
      end
    end
  end

  return table.concat(lines, "\n")
end

function spanishcards_data.load_json(path)
  local records, read_error, help = read_json_records(path)
  if not records then
    report_error(read_error, help)
    return
  end

  local latex = records_to_latex(records, path)
  for line in latex:gmatch("[^\n]+") do
    tex.sprint(line)
  end
end

spanishcards_data.emit_record = emit_record
spanishcards_data.field_map = field_map
spanishcards_data.field_order = field_order
spanishcards_data.parse_json = parse_json
spanishcards_data.read_file = read_file
spanishcards_data.read_json_records = read_json_records
spanishcards_data.record_to_latex = record_to_latex
spanishcards_data.records_to_latex = records_to_latex
spanishcards_data.report_error = report_error
spanishcards_data.scalar_to_string = scalar_to_string
spanishcards_data.warn = warn
spanishcards_data.json_null = json_null

return spanishcards_data
