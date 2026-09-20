const http = require('http');

const payload = JSON.stringify({
    clientId: 'b734604a-ec49-485a-951b-7c05348c530f',
    code: 'return "hello"'
});

const req = http.request({
    hostname: '127.0.0.1',
    port: 16384,
    path: '/execute',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
    }
}, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => console.log('RESPONSE:', data));
});

req.write(payload);
req.end();
