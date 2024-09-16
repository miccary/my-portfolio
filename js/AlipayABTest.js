import React from 'react';
import './AlipayABTest.css';
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, PointElement, LineElement, Title, Tooltip, Legend, ArcElement } from 'chart.js';
import { Bar, Pie } from 'react-chartjs-2';
import { Link } from 'react-router-dom';

// 注册必要的组件
ChartJS.register(CategoryScale, LinearScale, BarElement, PointElement, LineElement, Title, Tooltip, Legend, ArcElement);

function AlipayABTest() {
  // 示例数据，可以根据实际情况从你的数据源或分析结果中提取
  const barData = {
    labels: ['Control Group', 'Marketing Strategy 1', 'Marketing Strategy 2'],
    datasets: [
      {
        label: 'Click-Through Rate',
        data: [0.0125, 0.0153, 0.0261], // 替换为实际数据
        backgroundColor: ['#ff6384', '#36a2eb', '#cc65fe'],
      },
    ],
  };

  const pieData = {
    labels: ['Control Group', 'Marketing Strategy 1', 'Marketing Strategy 2'],
    datasets: [
      {
        label: 'User Distribution',
        data: [1905662, 411107, 316205], // 替换为实际数据
        backgroundColor: ['#ff6384', '#36a2eb', '#cc65fe'],
      },
    ],
  };

  return (
    <div className="project-container">
      <h2>Analysis of Alipay's Marketing Strategy (A/B Test)</h2>
      <p>This project analyzes the effectiveness of different marketing strategies using A/B testing.</p>
      
      <section>
        <h3>Project Background</h3>
        <p>Alipay's marketing team aimed to determine which of their two marketing strategies was more effective in increasing user engagement and conversion rates.</p>
        <p>Baseline conversion rate: 1.26%, Minimum Detectable Effect: 1%, Sample size: 2167 per variation.</p>
      </section>

      <section>
        <h3>Data Processing and Analysis</h3>
        <p>Data was divided into different groups, cleaned, and analyzed using Python. The click-through rates were calculated and compared between groups:</p>
        <ul>
          <li>Control Group Click-Through Rate: 1.26%</li>
          <li>Marketing Strategy 1 Click-Through Rate: 1.53%</li>
          <li>Marketing Strategy 2 Click-Through Rate: 2.62%</li>
        </ul>
      </section>

      <section>
        <h3>Results</h3>
        <div className="chart">
          <h4>Click-Through Rate Comparison</h4>
          <Bar data={barData} />
        </div>

        <div className="chart">
          <h4>User Distribution Across Strategies</h4>
          <Pie data={pieData} />
        </div>
      </section>

      <section>
        <h3>Statistical Analysis</h3>
        <p>Z-score for Marketing Strategy 1: 14.17, pValue: 7.45e-46</p>
        <p>Z-score for Marketing Strategy 2: 59.44, pValue: 0.0</p>
        <p>Both marketing strategies showed a statistically significant improvement in click-through rates compared to the control group, with Marketing Strategy 2 performing the best.</p>
      </section>

      <section>
        <h3>Conclusion and Recommendations</h3>
        <p>Based on the results, it's recommended that Alipay continues to optimize and implement Marketing Strategy 2 across a broader user base while monitoring its performance.</p>
      </section>

      <section className="back-project">
        <Link to="/projects" className="back-project-button">Return to Project</Link>
      </section>
    </div>
  );
}

export default AlipayABTest;
