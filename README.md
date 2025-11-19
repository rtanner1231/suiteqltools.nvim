# suiteqltools

### Neovim plugin with suitescript suiteql functions

<img src="https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/def6e5c5-30a5-46d3-8c3d-eb4a65baa94c" width="90%" />

# Main Features

- Syntax highlighting for SuiteQL queries
- Format SuiteQL queries in code
- SQL editor to run queries against a Netsuite instance
- Searchable query history
- Autocomplete tables and fields (Experimental)
- Show picker for tables and fields from your account

# Requirements

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nsconn.nvim](https://github.com/rtanner1231/nsconn.nvim)
- Node.js
- Treesitter with sql installed
- A Netsuite environment with either this project's restlet installed or SuiteTalk Rest Web Services enabled (for Run Query functionality)
- Optional: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Optional: [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) (For autocomplete)

# Installation

Install with your preferred package manager. Optionally call a setup function to override default options.

## [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    'rtanner1231/suiteqltools.nvim',
    dependencies = {
                "nvim-lua/plenary.nvim",
                "MunifTanjim/nui.nvim",
                "rtanner1231/nsconn.nvim"
    },
    opts={
        -- override default options
    },
    --always load plugin on javascript or typescript files
    --needed for sql formatting to work
    ft={"javascript","typescript"}
}
```

# Configuration Options

## Defaults

```lua
{
    sqlFormatter={
        language='plsql',
        tabWidth=2,
        useTabs=false,
        keywordCase='preserve',
        indentStyle='standard',
        logicalOperatorNewline='before',
        expressionWidth=50,
        denseOperators=false,
        newLineBeforeSemicolon=false
    },
    queryRun={
        initialMode='table',
        jsonFormatSpace=4,
        pageSize=10,
        editorKeymap={
            formatQuery="<C-s>s",
            toggleWindow="<C-s>w",
            runQuery="<C-s>r",
            toggleResultZoom="<C-s>f",
            nextPage="<C-s>n",
            previousPage="<C-s>p",
            toggleDisplayMode="<C-s>m"
        },
        history=false,
        historyLimit=2000,
        completion=false
    },
    picker='auto'

}
```

## Sql Formatter options

The SQL formatter function uses the [sql-formatter](https://www.npmjs.com/package/sql-formatter) library. Refer to the documentation there for information about the individual options.

## Query Run options

- **initialMode** (_default: "table"_) - The type of output running a query will initially produce. "table" will show the results in a table. "json" will show the raw JSON structure of the results.
- **jsonFormatSpace** (_default: 4_) - The number of spaces to indent the JSON output of the query
- **pageSize** (_default: 10_) - The number of results to retrieve per page
- **editorKeymap** - Override default query editor keys. These keymaps will only be set in the sql editor.
  - **formatQuery** (_default: "\<C-s\>s"_) - Keymap to format the query in the editor
  - **toggleWindow** (_default: "\<C-s\>w"_) - Keymap to toggle focus between the editor and result panes
  - **runQuery** (_default: "\<C-s\>r"_) - Keymap to run the query. Only available in the editor pane.
  - **toggleResultZoom** (_default: "\<C-s\>f"_) - Keymap to toggle maximizing the results pane.
  - **nextPage** (_default: "\<C-s\>n"_) - Keymap to move to the next result page.
  - **previousPage** (_default: "\<C-s\>p"_) - Keymap to move to the previous result page.
  - **toggleDisplayMode** (_default: "\<C-s\>m_) - Keymap to toggle query results between table and json formats.
- **history** (_default: false_) - Enable or disable the history functionality.
- **historyLimit** (_default: 2000_) - The maximum number of queries to keep in the history.
- **completion** (_default: false_) - Set to true to enable the completion feature in the query editor and the tablepicker feature.

## General Options
- **picker** (_default: 'auto'_) - The picker to use.  Possible values are "auto", "telescope", and "snacks".  If set to auto, the picker will be automatically determined based on which pickers are installed.  If multiple pickers are installed, it will choose in this order: "snacks" > "telescope".

# Commands

This plugin provides the below commands

- `:SuiteQL FormatQuery` - Format the SuiteQL query under the cursor. Does nothing if there is no query under the cursor.
- `:SuiteQL FormatFile` - Formats all SuiteQL queries in the current file.
- `:SuiteQL ToggleEditor` - Toggles the query editor open and closed. Closing the query editor preserves the current state and will be restored when it is reopened.
- `:SuiteQL EditQuery` - Open the query editor with the SuiteQL query under the cursor. Does nothing if there is no query under the cursor.
- `:SuiteQL History` - Opens the a [Telescope](https://github.com/nvim-telescope/telescope.nvim) picker for searching query history. Does nothing is history configuration option is false.
- `:SuiteQL SetCompletionData` - Open a dialog to import completion data for the current active profile. Does nothing if the completion feature is not enabled.
- `:SuiteQL ShowTablePicker` - Display a telescope picker for finding a table id. See Table / Field Picker section.
- `:SuiteQL ShowFieldPicker` - Display a telescope picker for finding a field id. See Table / Field Picker section.
- `:SuiteQL ShowLastTableFieldPicker` - Diplay the field picker for the last table selected through either the ShowTablePicker or ShowFieldPicker commands. See Table / Field Picker section.
- `:SuiteQL UseRestlet` - Set the current profile to use the restlet for queries. You will be prompted for a scriptId and deploymentId.
- `:SuiteQL UseSuiteTalk` - Set the current profile to use SuiteTalk for queries. This is the default.

# Setup

Running SuiteQL queries requires Oauth tokens to be setup and saved. These tokens will be encrypted and stored in a file called sqc in the vim standard data folder.

1. Set an encryption key. Create an environmental variable called NVIMQueryKey (or what you set queryRun.envVars.encryptKey to in the config). For example add `export NVIMQueryKey=ABCDEF12345` to your .bashrc file to set ABCDEF12345 as the encryption key.
2. Generate oauth tokens in your Netsuite environments. These tokens will need to be created with a role that has at least view access to any table you would like to write queries for. **Never use tokens created from a production environment with this plugin**
3. Run `:NSConn AddProfile` in Neovim. Follow the prompts to create a profile for a Netsuite account and assign OAuth tokens to it. For more information about setting up and managing profiles, see - [nsconn.nvim](https://github.com/rtanner1231/nsconn.nvim)

# Usage

## How queries in code are identified

In order for a string to be considered a SuiteQL query by this plugin, it must be the following:

1. In a javascript or typescript file.
2. Enclosed in backticks (a string literal)
3. Have the first word be "select" or "with" (Case insensitive)

### Examples

${\textsf{\color{lightgreen}This would be considered a SuiteQL query}}$

```
const q=`
    select
    id
    from
    location
`
```

The following would not be considered SuiteQL queries

${\textsf{\color{red}Not enclosed in backticks}}$

```
const q="select id from location"
```

${\textsf{\color{red}Does not start with sélect or with}}$

```

const q=`
    --comment
    select
    id
    from
    location
`
```

## Syntax highlighting

Any string which satisfies the above rules to be considered a SuiteQL query will automatically have syntax highlighting applied.

## Formatting

A SuiteQL query may be formatted by using commands `:SuiteQL FormatQuery` to format the query under the cursor or `:SuiteQL FormatFile` to format all SuiteQL queries in the file.

This uses the [sql-formatter](https://www.npmjs.com/package/sql-formatter) library. The formatted preferences may be set in the plugin configuration. The following options are exposed, refer to the sql-formatter documentation for information about what they do

- language
- tabWidth
- useTabs
- keywordCase
- indentStyle
- logicalOperatorNewline
- expressionWidth
- denseOperators
- newLineBeforeSemicolon

## Managing profiles

To run queries against a Netsuite environment, a connection profile must be set up for that environment.

- Use `:NSConn AddProfile` to create a profile. Follow the prompts to enter a profile name, Netsuite account number, and Oauth token information. If the profile name already exists, it will be overwritten. The first profile created will automatically be set as the active profile.
- Change the active profile with the `:NSConn SelectProfile` command. This will show a floating window with all profiles listed. The current active profile will have a star next to its name. Placing the cursor over a line and pressing enter or pressing the number next to a profile will make that profile active. Press escape to cancel.
- Delete a profile with the `:NSConn DeleteProfile` command. This will show a floating window with all profiles lists. The current active profile will have a star next to its name. Placing the cursor over a line and pressing enter or pressing the number next to a profile will delete the profile. The active profile may not be deleted. Press escape to cancel.
- Remove all profiles with the `:NSConn ResetTokens` command. This will delete all saved profiles.
  See: [nsconn.nvim](https://github.com/rtanner1231/nsconn.nvim) for more information

## Edit and Run Query

The query edit may be opened with the following commands

- `:SuiteQL ToggleEditor` - Opens the editor. If the editor had previously been open, opens to the most recent state.
- `:SuiteQL EditQuery` - Open the query under the cursor in the query editor. Does nothing if there is no query under the cursor.

The Query editor may be closed with the `:SuiteQL ToggleEditor` command.

The query editor consists of three sections: the editor pane, the results pane, and the status bar
![SuiteQLEditorPanes](https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/cb10795c-4282-4c6f-81e9-7a9ce0c41f7e)

- Queries should be written in the editor pane. Press the **runQuery** keymap (default \<C-s\>r) to run the query.
- Format the query in the editor pane with the **formatQuery** keymap (default \<C-s\>s).
- Toggle the cursor between the editor and results window with the **toggleWindow** keymap (default \<C-s\>w).
- Navigate between pages with the **nextPage** (default \<C-s\>n) and **previousPage** (default \<C-s\>p) keymaps. The status bar will show the max number of pages and the current page.
- Toggle between maximizing and shrinking the results pane with the **toggleResultZoom** keymap (default \<C-s\>f). Maximizing the result pane will automatically focus the result pane. Shrinking the result pane will automatically focus the editor pane.
- Toggle between showing the results as a table and showing the results as JSON using the **toggleDisplayMode** keymap (default \<C-s\>m).

**Note: Due to a quirk of lua, columns may not appear in the same order in the results as they appear in the query**

## Query service type

SuiteQL queries may either be run using SuiteTalk web services or using a restlet.

Using Suitetalk requires no changes to your Netsuite environment but using the restlet has the following advantages:

- All fields are returned even if they are null. Suitetalk does not return columns where every value is null.
- More complex queries are supported. Suitetalk does not support some queries that are supported in Suitescript, such as queries with CTEs.

### Restlet setup

- Load the restlet located in this repository at netsuitescripts/rl_suiteqlrun.js into your Netsuite file cabinet.
- Deploy the restlet
- Ensure the active connection profile is the same as the environment you deployed the restlet to.
- Run `:SuiteQL UseRestlet` in Neovim to cause queries run in the current profile to use the restlet. You will be promted for the restlet scriptId and deploymentId.
- You can run `:SuiteQL UseSuiteTalk` to make queries for the current profile use Suitetalk instead

## History

Tracking query history can optionally be enabled (See Configuration Options). Requires [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

- Successful queries will be saved in history.
- Query history can be viewed using the `:SuiteQL History` command. Queries may be searched using the search bar. Press enter on a query to open it in the query editor.
- Queries are stored in the neovim data directory in a file called suiteqlhistory.json. This file can be removed to clear the history.

Demo: Search query history, open selected query in editor, run query.
![suiteqlhistory](https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/19b83c42-9e06-42e7-bfc0-0c76904c4da6)

# Autocomplete

_Note: this feature is experimental_
![autocomplete](https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/60916e7d-3922-449d-b200-0ae2aef35435)

This feature enables offline autocomplete for tables and fields in the query editor.

## Setup

- Ensure you have the [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) plugin installed.
- Set the **completion** property to true in the plugin configuration.
- You will need to extract the table and field data from your Netsuite environment. Download the file located at _netsuitescripts/loadcompletion.html_ in this repository. Load this file into your Netsuite filecabinet and open it. Press the Run button to begin the extraction process. Once complete, copy the value in the Results field into to the clipboard. More information about how this works can be found in [this](https://timdietrich.me/blog/netsuite-records-catalog-api/) blog post.
  <img src="https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/c291bd30-d5ad-4ecb-8594-437ee2d19a3f" width="70%" />

- Next load the table and field data into Neovim. Ensure the active profile is the one which corresponds to environment the data was downloaded from (run `:SuiteQL SelectProfile` to change if needed). Run `:SuiteQL SetCompletionData`. In the dialog that appears, paste the results of the SuiteQL Completion Data tool and press enter.
- Repeat for any other profiles.
- Completion should now be active.

## Usage

- Table completion will trigger after the string _"from"_ and _"join"_ followed by whitespace (Case insensitive). _Note: There is currently an issue where the table completion will not trigger at the beginning of a line, even if from or join preceded it line above. In this case, adding a space at the start of the line should make it trigger._
- Field completion will trigger after a . (period). Completion without a table or alias is not currently supported. _Note: The query must be reletively well formed to be able to resolve the tables and aliases. If the tables and aliases are unable to be resolved, the completion will not trigger_

# Table / Field lookup

![tablepicker](https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/d51a39e1-a29e-4ed7-a9bc-838c1b197e1a)

_Note: This feature requires the Autocompelete feature to be enabled and set up_

Lookup tables in fields in telescope's fuzzy finder pickers. Pickers use completion data for the currently active profile.

## Usage

The following commands may be used

- `:SuiteQL ShowTablePicker` - Display a telescope picker for finding a table id. Press enter to insert the table id at the cursor position. Press Ctrl+f to show the field picker for the selected table.
- `:SuiteQL ShowFieldPicker` - Display a telescope picker for finding a field id. The first picker will show the list of tables. Selecting a table will show the list of fields in that table. Press enter to insert the field id at the cursor position.
- `:SuiteQL ShowLastTableFieldPicker` - Diplay the field picker for the last table selected through either the ShowTablePicker or ShowFieldPicker commands. Runs `:SuiteQL ShowFieldPicker` if no table has been selected.
