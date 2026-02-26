const fetch = require('node-fetch');
const fs = require('fs');
const path = require('path');

const testCases = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../frontend/test/fixtures/server_test_cases.json'), 'utf-8'));

describe('Server Parity Tests', () => {
  const baseUrl = 'http://localhost:8788'; // Assuming wrangler dev runs on this port

  testCases.forEach(testCase => {
    it(testCase.name, async () => {
      if (testCase.request.method === 'POST') {
        const response = await fetch(`${baseUrl}${testCase.request.path}`, {
          method: 'POST',
          headers: testCase.request.headers,
          body: JSON.stringify(testCase.request.body),
        });

        if (testCase.expected_response) {
          expect(response.status).toBe(testCase.expected_response.status);
          const body = await response.json();
          expect(body).toEqual(testCase.expected_response.body);
        }

        if (testCase.expected_stream_chunks) {
          const chunks = [];
          for await (const chunk of response.body) {
            chunks.push(chunk);
          }
          const body = Buffer.concat(chunks).toString('utf8');
          const lines = body.split('\n').filter(line => line.startsWith('data: '));
          let chunkIndex = 0;
          for (const line of lines) {
            const data = line.substring(6);
            if (data === '[DONE]') {
              continue;
            }
            const json = JSON.parse(data);
            if (json.done) {
              expect(json.done).toBe(testCase.expected_final_chunk.done);
              expect(json.speechUrl).toBeDefined();
            } else {
              expect(json).toEqual(testCase.expected_stream_chunks[chunkIndex]);
              chunkIndex++;
            }
          }
        }
      }
    });
  });
});
