module.exports = (markdown, options) => {
  return new Promise((resolve, reject) => {
    let in_code = false;
    return resolve(
      markdown
        .split('\n')
        .map((line, index) => {
          if (!/^```/.test(line) || index === 0) {
            if (in_code) {
              return line.replace(new RegExp('<', 'g'), "&lt").replace(new RegExp('>', 'g'), '&gt');
            }
            return line;
          }
          in_code = !in_code;
          return line;
        })
        .join('\n')
    );
  });
};
