local Line = require("nui.line")
local Split = require("nui.split")
local Table = require("nui.table")
local Text = require("nui.text")

local split = Split({
  relative="editor",
  position = "bottom",
  size = '20%',
})

local function cell_id(cell)
  return cell.column.id
end

local function capitalize(value)
  return (string.gsub(value, "^%l", string.upper))
end

local columns={
    {
        accessor_key ="firstName",
        header="firstName"
    },
    {
        accessor_key ="lastName",
        header="lastName"
    },

}

local grouped_columns = {
  {
    align = "center",
    header = "Name",
    footer = cell_id,
    columns = {
      {
        accessor_key = "firstName",
        cell = function(cell)
          return Text(capitalize(cell.get_value()), "DiagnosticInfo")
        end,
        header = "First",
        footer = cell_id,
      },
      {
        id = "lastName",
        accessor_fn = function(row)
          return capitalize(row.lastName)
        end,
        header = "Last",
        footer = cell_id,
      },
    },
  },
  {
    align = "center",
    header = "Info",
    footer = cell_id,
    columns = {
      {
        align = "center",
        accessor_key = "age",
        cell = function(cell)
          return Line({ Text(tostring(cell.get_value()), "DiagnosticHint"), Text(" y/o") })
        end,
        header = "Age",
        footer = "age",
      },
      {
        align = "center",
        header = "More Info",
        footer = cell_id,
        columns = {
          {
            align = "right",
            accessor_key = "visits",
            header = "Visits",
            footer = cell_id,
          },
          {
            accessor_key = "status",
            header = "Status",
            footer = cell_id,
            max_width = 6,
          },
        },
      },
    },
  },
  {
    align = "right",
    header = "Progress",
    accessor_key = "progress",
    footer = cell_id,
  },
}

local table = Table({
  bufnr = split.bufnr,
  columns = columns,
  data = {
    {
      firstName = "tanner",
      lastName = "linsley",
      age = 24,
      visits = 100,
      status = "In Relationship",
      progress = 50,
    },
    {
      firstName = "tandy",
      lastName = "miller",
      age = 40,
      visits = 40,
      status = "Single",
      progress = 80,
    },
    {
      firstName = "joe",
      lastName = "dirte",
      age = 45,
      visits = 20,
      status = "Complicated",
      progress = 10,
    },
  },
})

split:mount()
table:render()


split:map("n", "q", function()
  split:unmount()
end, {})

split:map("n", "x", function()
  local cell = table:get_cell()
  if cell then
    local column = cell.column
    if column.accessor_key then
      cell.row.original[column.accessor_key] = "Poof!"
    end
    table:refresh_cell(cell)
  end
end, {})
