const fs = require('fs');
const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';

const txt = fs.readFileSync(logPath, 'utf8');
const sampleIdx = txt.indexOf('1x1x1x1');
console.log('Sample text around 1x1x1x1:');
console.log(txt.substring(sampleIdx - 50, sampleIdx + 150));
