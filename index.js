const express = require('express');
const app = express();

app.get('/classify', (req, res) => {
  const { score } = req.query;
  if (!score) return res.status(400).json({ error: 'Missing score parameter' });
  
  const s = parseFloat(score);
  if (isNaN(s) || s < 0 || s > 100) return res.status(400).json({ error: 'Score must be between 0 and 100' });
  
  let grade, category;
  if (s >= 90) { grade = 'A'; category = 'Excellent'; }
  else if (s >= 80) { grade = 'B'; category = 'Good'; }
  else if (s >= 70) { grade = 'C'; category = 'Average'; }
  else if (s >= 60) { grade = 'D'; category = 'Below Average'; }
  else { grade = 'F'; category = 'Fail'; }
  
  res.json({ score: s, grade, category });
});

app.listen(3023, () => console.log('Grade Classifier API on port 3023'));