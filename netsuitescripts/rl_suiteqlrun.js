/**
 * @NApiVersion 2.1
 * @NScriptType Restlet
 * @NModuleScope SameAccount
 */
define(["N/query"], (query) => {
  const _post = (requestBody) => {
    const { query: q, limit, offset } = requestBody;

    const runSuiteQL = (qu) =>
      query.runSuiteQL({ query: qu }).asMappedResults();

    function runWithLimit(qu, limit, offset) {
      const start = offset + 1;
      const end = offset + limit;
      const qe = `
                 SELECT
                   *
                 FROM
                   (
                     SELECT
                       rownum AS rownumtemp,
                       *
                     FROM
                       (${qu})
                   )
                 WHERE
                   (rownumtemp BETWEEN ${start} AND ${end})
                 `;
      return runSuiteQL(qe);
    }

    try {
      const results = runWithLimit(q, limit, offset);

      //maybe change query so this isn't needed?
      return {
        success: true,
        results: results.map(({ rownumtemp, ...rest }) => rest),
      };
    } catch (e) {
      return {
        success: false,
        errorMessage: e.message,
      };
    }
  };

  return {
    post: _post,
  };
});
