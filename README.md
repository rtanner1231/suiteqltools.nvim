# suiteqltoo# suiteqltools
### Neovim plugin with suitescript suiteql functions

<img src="https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/def6e5c5-30a5-46d3-8c3d-eb4a65baa94c" width="90%" />

## Main Features
- Syntax highlighting for SuiteQL queries
- Format SuiteQL queries in code
- SQL editor to run queries against a Netsuite instance

## Requirements
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Node.js
- Treesitter with sql installed
- A Netsuite environment with SuiteTalk Rest Web Services enabled (for Run Query functionality)

## Installation
Install with your preferred package manager.  Optionally call a setup function to override default options.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    'rtanner1231/suiteqltools.nvim',
    dependencies = {
                "nvim-lua/plenary.nvim",
                "MunifTanjim/nui.nvim"
    },
    opts={
        -- override default options
    }
}
```

## Configuration Options

### Defaults

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
        envVars={
            encryptKey='NVIMQueryKey',
        },
        editorKeymap={
            formatQuery="<C-s>s",
            toggleWindow="<C-s>w",
            runQuery="<C-s>r",
            toggleResultZoom="<C-s>f",
            nextPage="<C-s>n",
            previousPage="<C-s>p",
            toggleDisplayMode="<C-s>m"
        }
    }
}
```

### Sql Formatter options

The SQL formatter function uses the [sql-formatter](https://www.npmjs.com/package/sql-formatter) library.  Refer to the documentation there for information about the individual options.

### Query Run options

- **initialMode** (*default: "table"*) - The type of output running a query will initially produce.  "table" will show the results in a table.  "json" will show the raw JSON structure of the results.
- **jsonFormatSpace** (*default: 4*) - The number of spaces to indent the JSON output of the query
- **pageSize** (*default: 10*) - The number of results to retrieve per page
- **envVars**
  - **encryptKey** (*default: "NVIMQueryKey"*) - The environmental variable which will hold the encryption key for the Oauth tokens storage.  See setup for more information.
- **editorKeymap** - Override default query editor keys.  These keymaps will only be set in the sql editor.
  - **formatQuery** (*default: "\<C-s\>s"*) - Keymap to format the query in the editor
  - **toggleWindow** (*default: "\<C-s\>w"*) - Keymap to toggle focus between the editor and result panes
  - **runQuery** (*default: "\<C-s\>r"*) - Keymap to run the query.  Only available in the editor pane.
  - **toggleResultZoom** (*default: "\<C-s\>f"*) - Keymap to toggle maximizing the results pane.
  - **nextPage** (*default: "\<C-s\>n"*) - Keymap to move to the next result page.
  - **previousPage** (*default: "\<C-s\>p"*) - Keymap to move to the previous result page.
  - **toggleDisplayMode** (*default: "\<C-s\>m*) - Keymap to toggle query results between table and json formats.

## Commands
This plugin provides the below commands
-*:SuiteQL FormatQuery* - Format the SuiteQL query under the cursor.  Does nothing if there is no query under the cursor.
-*:SuiteQL FormatFile* - Formats all SuiteQL queries in the current file.
-*:SuiteQL SetDefaultTokens* - Set the default account OAUTH tokens.  These credentials will be used if no project specific tokens are found.
-*:SuiteQL SetProjectTokens* - Set project specific OAUTH tokens.  These tokens will be keyed to the current working directory of the project.
-*:SuiteQL ResetTokens* - Remove all saved OAUTH tokens.
-*:SuiteQL ToggleEditor* - Toggles the query editor open and closed.  Closing the query editor preserves the current state and will be restored when it is reopened.
-*:SuiteQL EditQuery* - Open the query editor with the SuiteQL query under the cursor.  Does nothing if there is no query under the cursor.

## Setup
Running SuiteQL queries requires Oauth tokens to be setup and saved.  These tokens will be encrypted and stored in a file called sqc in the vim standard data folder.

1. Set an encryption key.  Create an environmental variable called NVIMQueryKey (or what you set queryRun.envVars.encryptKey to in the config).  For example add ```export NVIMQueryKey=ABCDEF12345``` to your .bashrc file to set ABCDEF12345 as the encryption key.
2. Generate oauth tokens in your Netsuite environments.  These tokens will need to be created with a role that has at least view access to any table you would like to write queries for.  **Never use tokens created from a production environment with this plugin**
3. Run ```:SuiteQL SetDefaultTokens``` in Neovim.  Follow the prompts to enter token information.

## Usage

### How queries in code are identified

In order for a string to be considered a SuiteQL query by this plugin, it must be the following:
1. In a javascript or typescript file.
2. Enclosed in backticks (a string literal)
3. Have the first word be "select" or "with" (Case insensitive)

#### Examples
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

### Syntax highlighting

Any string which satisfies the above rules to be considered a SuiteQL query will automatically have syntax highlighting applied.

### Formatting

A SuiteQL query may be formatted by using commands ```:SuiteQL FormatQuery``` to format the query under the cursor or ```:SuiteQL FormatFile``` to format all SuiteQL queries in the file.

This uses the [sql-formatter](https://www.npmjs.com/package/sql-formatter) library.  The formatted preferences may be set in the plugin configuration.  The following options are exposed, refer to the sql-formatter documentation for information about what they do
-language
-tabWidth
-useTabs
-keywordCase
-indentStyle
-logicalOperatorNewline
-expressionWidth
-denseOperators
-newLineBeforeSemicolon

### Edit and Run Query

The query edit may be opened with the following commands
- ```:SuiteQL ToggleEditor``` - Opens the editor.  If the editor had previously been open, opens to the most recent state.
- ```:SuiteQL EditQuery``` - Open the query under the cursor in the query editor.  Does nothing if there is no query under the cursor.

The Query editor may be closed with the ```:SuiteQL ToggleEditor``` command.

The query editor consists of three sections: the editor pane, the results pane, and the status bar
![SuiteQLEditorPanes](https://github.com/rtanner1231/suiteqltools.nvim/assets/142627958/cb10795c-4282-4c6f-81e9-7a9ce0c41f7e)
