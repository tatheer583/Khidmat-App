// Structural checks for environments without Dart. This is not a Flutter analyzer.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const problems = [];
let count = 0;
function inspect(file) {
  const text = fs.readFileSync(file, 'utf8');
  count++;
  for (const match of text.matchAll(/(?:import|export|part)\s+['"]([^'"]+)['"]/g)) {
    const target = match[1];
    if (!target.includes(':') && !fs.existsSync(path.resolve(path.dirname(file), target))) {
      problems.push(path.relative(root, file) + ': missing import ' + target);
    }
  }
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let i = 0;
  while (i < text.length) {
    if (text.slice(i, i + 2) === '//') {
      const end = text.indexOf('\n', i); i = end < 0 ? text.length : end + 1; continue;
    }
    if (text.slice(i, i + 2) === '/*') {
      const end = text.indexOf('*/', i + 2);
      if (end < 0) { problems.push(file + ': unclosed comment'); break; }
      i = end + 2; continue;
    }
    if (text[i] === "'" || text[i] === '"') {
      const quote = text[i], triple = text.slice(i, i + 3) === quote.repeat(3);
      const delimiter = triple ? quote.repeat(3) : quote;
      i += delimiter.length;
      let closed = false;
      while (i < text.length) {
        if (text[i] === '\\') { i += 2; continue; }
        if (text.slice(i, i + delimiter.length) === delimiter) {
          i += delimiter.length; closed = true; break;
        }
        i++;
      }
      if (!closed) problems.push(file + ': unclosed string');
      continue;
    }
    const char = text[i++];
    if ('([{'.includes(char)) stack.push(char);
    if (Object.hasOwn(pairs, char) && stack.pop() !== pairs[char]) {
      problems.push(path.relative(root, file) + ': mismatched ' + char + ' at offset ' + i);
    }
  }
  if (stack.length) problems.push(path.relative(root, file) + ': unclosed delimiters');
}
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith('.dart')) inspect(full);
  }
}
walk(path.join(root, 'lib'));
walk(path.join(root, 'test'));
if (problems.length) {
  process.stderr.write(problems.join('\n') + '\n');
  process.exitCode = 1;
} else {
  process.stdout.write('Structural checks passed for ' + count +
    ' Dart files (imports, strings and delimiters). Flutter analysis is still required.\n');
}
