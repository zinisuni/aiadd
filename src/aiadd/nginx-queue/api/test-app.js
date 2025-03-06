const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.send('Hello from test app!');
});

app.listen(8080, () => {
    console.log('Test app listening on port 8080');
});