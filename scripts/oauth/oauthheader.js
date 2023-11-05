const { createHmac } = require("node:crypto");
const OAuth = require("./oauth1");

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

//Get the below parameters
//token (-t,--token),
//token secret (-k,--tokensecret),
//consumer key (-c,--consumerkey),
//consumer secret (-s,--consumersecret),
//realm (-r,--realm)
//url (-u,--url)
//method (-m,--method)
//payload (-p,--payload)
function getParameters() {
  const token = getArgValue(["-t", "--token"]);
  const tokenSecret = getArgValue(["-k", "--tokensecret"]);
  const consumerKey = getArgValue(["-c", "--consumerkey"]);
  const consumerSecret = getArgValue(["-s", "--consumersecret"]);
  const realm = getArgValue(["-r", "--realm"]);
  const url = getArgValue(["-u", "--url"]);
  const method = getArgValue(["-m", "--method"]);
  const payload = getArgValue(["-p", "--payload"]);

  return {
    token,
    tokenSecret,
    consumerKey,
    consumerSecret,
    realm,
    url,
    method,
    payload,
  };
}

const getOauth = (
  url,
  method,
  accountId,
  consumerKey,
  consumerSecret,
  tokenId,
  tokenSecret,
  payload = {},
) => {
  if (method == "GET" || method == "DELETE") {
    pathToCall += "&" + qs.stringify(payload);
  }

  // var url = pathToCall;
  var request = {
    url: url,
    method: method,
    body: payload,
  };
  const oauth = OAuth({
    consumer: { key: consumerKey, secret: consumerSecret },
    signature_method: "HMAC-SHA256",
    hash_function(base_string, key) {
      return createHmac("sha256", key).update(base_string).digest("base64");
    },
  });

  const authorization = oauth.authorize(request, {
    key: tokenId,
    secret: tokenSecret,
  });

  var headers = oauth.toHeader(authorization);
  headers.Authorization += ', realm="' + accountId + '"';
  headers["Content-Type"] = "application/json";

  return headers;
};

const parameters = getParameters();

const headers = getOauth(
  parameters.url,
  parameters.method,
  parameters.realm,
  parameters.consumerKey,
  parameters.consumerSecret,
  parameters.token,
  parameters.tokenSecret,
  parameters.payload,
);

process.stdout.write(JSON.stringify(headers) + "\n");

// if (process.argv[2] && process.argv[2] === "-f") {
//   process.stdout.write("Flag present.\n");
// } else {
//   process.stdout.write("Flag not present.\n");
// }
