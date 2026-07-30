import express from 'express';
import cors from 'cors';

const app = express();
const port = process.env.PORT || 5001;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Quest API is running' });
});

app.listen(port, () => {
  console.log(`🚀 Quest API listening on port ${port}`);
});
