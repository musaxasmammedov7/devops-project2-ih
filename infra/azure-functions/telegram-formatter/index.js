const https = require('https');

module.exports = async function (context, req) {
  context.log('Azure Monitor alert received');

  const telegramBotToken = process.env.TELEGRAM_BOT_TOKEN;
  const telegramChatId = process.env.TELEGRAM_CHAT_ID;

  if (!telegramBotToken || !telegramChatId) {
    context.log.error('TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set');
    context.res = { status: 500, body: 'Configuration missing' };
    return;
  }

  // Parse Azure Monitor Common Alert Schema
  const alertData = req.body;
  
  // Extract data from Azure Monitor payload
  const data = alertData.data || {};
  const alertContext = data.alertContext || {};
  const condition = data.condition || {};
  
  // Get resource info
  const resourceName = data.resourceName || 'Unknown';
  const resourceType = data.resourceType || 'Unknown';
  const resourceGroup = data.resourceGroupName || 'Unknown';
  const severity = data.severity || 'Unknown';
  const status = data.monitorCondition || 'Unknown';
  const firedTime = data.firedDateTime || new Date().toISOString();
  const alertRule = data.alertRule || {};
  const alertName = alertRule.displayName || 'Azure Alert';
  
  // Get metric value if available
  const allOf = condition.allOf || [];
  const firstCondition = allOf[0] || {};
  const metricName = firstCondition.metricName || 'Unknown';
  const metricValue = firstCondition.metricValue || 'Unknown';
  const threshold = firstCondition.threshold || 'Unknown';
  const operator = firstCondition.operator || 'Unknown';

  // Create beautiful message with emojis
  const message = `🚨 *${alertName}* 🚨

📊 *Alert Status:* ${status}
⚡ *Severity:* ${severity}
⏰ *Fired Time:* ${firedTime}

📋 *Resource Details:*
├─ 🏷️ *Name:* ${resourceName}
├─ 📦 *Type:* ${resourceType}
└─ 👥 *Resource Group:* ${resourceGroup}

📈 *Metric:*
├─ 📊 *Metric:* ${metricName}
├─ 📉 *Value:* ${metricValue}
├─ 🎯 *Threshold:* ${threshold}
└─ 🔍 *Operator:* ${operator}

🔗 *View in Portal:*
https://portal.azure.com/#@/resource${data.resourceId || ''}

🤖 _Powered by Azure Monitor & Terraform_`;

  // Send to Telegram
  const payload = JSON.stringify({
    chat_id: telegramChatId,
    text: message,
    parse_mode: 'Markdown',
    disable_web_page_preview: true
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.telegram.org',
      path: `/bot${telegramBotToken}/sendMessage`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const telegramReq = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        context.log('Telegram response:', data);
        context.res = { 
          status: 200, 
          body: { 
            message: 'Alert forwarded to Telegram',
            telegram_response: JSON.parse(data)
          }
        };
        resolve();
      });
    });

    telegramReq.on('error', (error) => {
      context.log.error('Telegram error:', error);
      context.res = { status: 500, body: { error: 'Failed to send to Telegram', details: error.message } };
      reject(error);
    });

    telegramReq.write(payload);
    telegramReq.end();
  });
};
