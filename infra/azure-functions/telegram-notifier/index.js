const https = require('https');

module.exports = async function (context, req) {
  context.log('Azure Monitor alert received');

  const telegramBotToken = process.env.TELEGRAM_BOT_TOKEN;
  const telegramChatId = process.env.TELEGRAM_CHAT_ID;

  if (!telegramBotToken || !telegramChatId) {
    context.log.error('TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set');
    context.res = { status: 500, body: 'Telegram configuration missing' };
    return;
  }

  // Parse Azure Monitor alert
  const alertData = req.body;
  const status = alertData.status || 'Unknown';
  const contextData = alertData.data?.context || {};
  const resourceName = contextData.resourceName || 'Unknown';
  const resourceType = contextData.resourceType || 'Unknown';
  const resourceGroup = contextData.resourceGroupName || 'Unknown';
  const timestamp = contextData.timestamp || new Date().toISOString();
  const conditionType = contextData.conditionType || 'Unknown';
  const condition = contextData.condition || {};

  // Create beautiful message with emojis and markdown
  const message = `
🚨 *ALERT TRIGGERED* 🚨

📊 **Alert Details:**
━━━━━━━━━━━━━━━━━━━━
🔔 *Status:* \`${status}\`
⏰ *Time:* \`${timestamp}\`
🏷️ *Resource:* \`${resourceName}\`
📦 *Resource Type:* \`${resourceType}\`
👥 *Resource Group:* \`${resourceGroup}\`
📝 *Condition:* \`${conditionType}\`
━━━━━━━━━━━━━━━━━━━━

🔍 **Condition Details:**
\`\`\`json
${JSON.stringify(condition, null, 2)}
\`\`\`
━━━━━━━━━━━━━━━━━━━━

🤖 *Powered by Azure Monitor & Azure Function*
  `.trim();

  // Send to Telegram
  const telegramUrl = `https://api.telegram.org/bot${telegramBotToken}/sendMessage`;
  const payload = JSON.stringify({
    chat_id: telegramChatId,
    text: message,
    parse_mode: 'Markdown'
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

    const reqTelegram = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        context.log('Telegram response:', data);
        context.res = { 
          status: 200, 
          body: 'Alert forwarded to Telegram',
          headers: { 'Content-Type': 'application/json' }
        };
        resolve();
      });
    });

    reqTelegram.on('error', (error) => {
      context.log.error('Telegram error:', error);
      context.res = { status: 500, body: 'Failed to send to Telegram' };
      reject(error);
    });

    reqTelegram.write(payload);
    reqTelegram.end();
  });
};
