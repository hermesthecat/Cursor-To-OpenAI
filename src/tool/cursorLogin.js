const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4, v5: uuidv5 } = require('uuid');

function generatePkcePair() {
  const verifier = crypto.randomBytes(43).toString('base64url');
  const challenge = crypto.createHash('sha256').update(verifier).digest('base64url');
  return { verifier, challenge };
}

function getLoginUrl(uuid, challenge) {
  const loginUrl = `https://www.cursor.com/loginDeepControl?challenge=${challenge}&uuid=${uuid}&mode=login`
  return loginUrl
}

async function queryAuthPoll(uuid, verifier) {
  const authPolllUrl = `https://api2.cursor.sh/auth/poll?uuid=${uuid}&verifier=${verifier}`;
  const response = await fetch(authPolllUrl, {
    method: 'GET',
    headers: {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/0.48.6 Chrome/132.0.6834.210 Electron/34.3.4 Safari/537.36",
      "Accept": "*/*"
    },
    timeout: 5000
  });

  if (response.status === 200) {
    const data = await response.json();
    return data
  }

  return undefined;
}

function updateEnvFile(token) {
  const envPath = path.join(process.cwd(), '.env');
  let envContent = '';

  // Read existing .env file if it exists
  if (fs.existsSync(envPath)) {
    envContent = fs.readFileSync(envPath, 'utf8');
  }

  // Check if CURSOR_TOKEN already exists
  const tokenRegex = /^CURSOR_TOKEN=.*$/m;
  const newTokenLine = `CURSOR_TOKEN=${token}`;

  if (tokenRegex.test(envContent)) {
    // Replace existing CURSOR_TOKEN
    envContent = envContent.replace(tokenRegex, newTokenLine);
    console.log("[Log] Updated existing CURSOR_TOKEN in .env file");
  } else {
    // Add new CURSOR_TOKEN
    if (envContent && !envContent.endsWith('\n')) {
      envContent += '\n';
    }
    envContent += newTokenLine + '\n';
    console.log("[Log] Added CURSOR_TOKEN to .env file");
  }

  // Write back to .env file
  fs.writeFileSync(envPath, envContent);
}

if (require.main === module) {

  async function main() {
    const { verifier, challenge } = generatePkcePair();
    const uuid = uuidv4();
    const loginUrl = getLoginUrl(uuid, challenge);
    console.log("[Log] Please open the following URL in your browser to login:");
    console.log(loginUrl);

    const retryAttempts = 60;

    for (let i = 0; i < retryAttempts; i++) {
      console.log(`[Log] Waiting for login... (${i + 1}/${retryAttempts})`);
      const data = await queryAuthPoll(uuid, verifier);
      if (data) {
        const accessToken = data.accessToken || undefined;
        const authId = data.authId || "";
        let token = undefined
        if (authId.split("|").length > 1) {
          const userId = authId.split("|")[1];
          token = `${userId}%3A%3A${accessToken}`;
        } else {
          token = accessToken;
        }
        console.log("[Log] Login successfully. Your Cursor cookie:");
        console.log(token)
        // replace the token in .env file
        updateEnvFile(token);
        break;
      }
      await new Promise(resolve => setTimeout(resolve, 5000));

      if (i === retryAttempts - 1) {
        console.log("Login timeout, please try again.");
      }
    }
  }

  main().catch((error) => {
    console.error("Error:", error);
  });

}

module.exports = {
  generatePkcePair,
  queryAuthPoll
}
