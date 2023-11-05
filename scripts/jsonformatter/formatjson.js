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
  const json = getArgValue(["-j", "--json"]);
  const space = getArgValue(["-s", "--space"]);
  return {
    json,
    space,
  };
}

const params = getParameters();

if (!params.json) {
  return "{}";
}

const space = params.space ? params.space : 2;

const obj = JSON.parse(params.json);

process.stdout.write(JSON.stringify(obj, null, parseInt(space)));
