const { format } = require("./sqlformatter");

/**
 * From the list of argument key aliases, return the value if is exists.  Return null otherwise
 * @param {string[]} argKeys
 * @returns {string}
 */
const getArgValue = (argKeys) => {
  for (let i = 0; i < argKeys.length; i++) {
    if (process.argv.indexOf(argKeys[i]) > -1) {
      const index = process.argv.indexOf(argKeys[i]);
      if (process.argv.length > index + 1) {
        return process.argv[process.argv.indexOf(argKeys[i]) + 1];
      }
    }
  }
  return null;
};

function getParameters() {
  const language = getArgValue(["-l", "--language"]);
  const dialect = getArgValue(["-d", "--dialect"]);
  const tabWidth = getArgValue(["-w", "--tabwidth"]);
  const useTabs = getArgValue(["-t", "--usetabs"]);
  const keywordCase = getArgValue(["-k", "--keywordcase"]);
  const indentStyle = getArgValue(["-i", "--indentstyle"]);
  const logicalOperatorNewline = getArgValue([
    "-o",
    "--logicaloperatornewline",
  ]);
  const expressionWidth = getArgValue(["-e", "--expressionwidth"]);
  const denseOperators = getArgValue(["-D", "--denseoperators"]);
  const newLineBeforeSemicolon = getArgValue([
    "-n",
    "--newlinebeforesemicolon",
  ]);

  //return object with only the above variables, filtering out any null values
  const objectRet = {
    language,
    dialect,
    tabWidth,
    useTabs,
    keywordCase,
    indentStyle,
    logicalOperatorNewline,
    expressionWidth,
    denseOperators,
    newLineBeforeSemicolon,
  };

  return Object.keys(objectRet)
    .filter((key) => objectRet[key] !== null)
    .reduce((obj, key) => {
      const val = objectRet[key];
      const valueToUse =
        val.toLowerCase() == "true"
          ? true
          : val.toLowerCase() == "false"
          ? false
          : val;
      obj[key] = valueToUse;
      return obj;
    }, {});
}

const query = getArgValue(["-q", "--query"]);

const sqlParms = getParameters();

const formatted = format(query, sqlParms);

process.stdout.write(formatted + "\n");

//process.stdout.write(formatted.length + "\n");

//process.stdout.write("aaa\r\nbbb\r\nccc\r\n");
