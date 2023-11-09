const crypto = require("node:crypto");

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
  const type = getArgValue(["-t", "--type"]);
  const key = getArgValue(["-k", "--key"]);
  const value = getArgValue(["-v", "--value"]);

  return {
    type,
    key,
    value,
  };
}

const parms = getParameters();

if (!parms.type || !parms.key || !parms.value) {
  process.stdout.write(
    JSON.stringify({ success: false, errorMessage: "missing parms" }) + "\n",
  );
}

const algorithm = "aes-256-cbc";
const key = crypto
  .createHash("sha512")
  .update(parms.key)
  .digest("hex")
  .substring(0, 32);
const encryptionIV = crypto
  .createHash("sha512")
  .update(parms.key)
  .digest("hex")
  .substring(0, 16);

let ret = "";
if (parms.type === "encrypt") {
  const cipher = crypto.createCipheriv(algorithm, key, encryptionIV);
  ret = cipher.update(parms.value, "utf8", "hex");
  ret += cipher.final("hex");
} else {
  //const decipher = crypto.createDecipheriv(algorithm, parms.key);
  const decipher = crypto.createDecipheriv(algorithm, key, encryptionIV);
  ret = decipher.update(parms.value, "hex", "utf8");
  ret += decipher.final("utf8");
}

process.stdout.write(JSON.stringify({ success: true, value: ret }) + "\n");
