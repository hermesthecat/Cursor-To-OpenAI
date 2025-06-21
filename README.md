# Cursor To OpenAI

Convert the Cursor Editor to an OpenAI API interface service.

## Introduction

This project provides a proxy service that converts the AI chat of the Cursor Editor into an OpenAPI API, allowing you to reuse the LLM of the Cursor in other applications.

## Prerequisites

Visit [Cursor](https://www.cursor.com) and register a account.

### Get Cursor client cookie

The cookie from Cursor webpage does not work in Cursor-To-OpenAI server. You need to get the Cursor client cookie following these steps:

#### Method 1: Automatic Login (Recommended)

1. Run `npm install` to initialize the environment.
2. Run `npm run login`. Open the URL shown in the log, and then login your account.
3. **The token will be automatically saved to your `.env` file** - no manual copying needed!
4. If you need the token value for other purposes, it will also be displayed in the console.

The log of this command looks like:

```bash
[Log] Please open the following URL in your browser to login:
https://www.cursor.com/loginDeepControl?challenge=6aDBevuHkK-HLiZ<......>k2lEjbVRMpg&uuid=5147ac09<....>5fe5f3aeb&mode=login      <-- Copy the url and open it in your browser.
[Log] Waiting for login... (1/60)
[Log] Waiting for login... (2/60)
[Log] Waiting for login... (3/60)
[Log] Waiting for login... (4/60)
[Log] Login successfully. Your Cursor cookie:
user_01JJF<.....>K3F4T8%3A%3AeyJhbGciOiJIUzI1NiIsInR5cCI6Ikp<...................>AsCpbPfnlHy022WxmlKIt4Q7Ll0     <-- This is the Cursor cookie
[Log] Added CURSOR_TOKEN to .env file                                                                                                                        <-- Token automatically saved!
```

**Features:**

- ✅ Automatically saves token to `.env` file
- ✅ Updates existing token if already present
- ✅ Preserves other environment variables
- ✅ No manual copy-paste required

#### Method 2: API-based Login

We provide an API to save you from manual login. You need to log in to your Cursor account in browser and get `WorkosCursorSessionToken` from Application-Cookie.

1. Get Cursor client cookie
    - Url：`http://localhost:3010/cursor/loginDeepContorl`
    - Request：`GET`
    - Authentication：`Bearer Token`（The value of `WorkosCursorSessionToken` from Cursor webpage)
    - Response: In JSON, the value of `accessToken` is the `Cursor Cookie` in JWT format. That's what you want.

2. Screenshot

![models](models.png)

Sample request:

```python
import requests

WorkosCursorSessionToken = "{{{Replace by your WorkosCursorSessionToken from cookie in browser}}}}"
response = requests.get("http://localhost:3010/cursor/loginDeepControl", headers={
    "authorization": f"Bearer {WorkosCursorSessionToken}"
})
data = response.json()
cookie = data["accessToken"]
print(cookie)
```

## How to Run

### Environment Setup

After obtaining your Cursor cookie using Method 1 above, your `.env` file will be automatically created/updated with:

```bash
CURSOR_TOKEN=your_cursor_token_here
```

You can also manually create a `.env` file in the project root with this format if needed.

### Run in docker

```bash
docker run -d --name cursor-to-openai -p 3010:3010 ghcr.io/jiuz-chn/cursor-to-openai:latest
```

### Run in npm

```bash
npm install
npm run start
```

## How to use the server

1. Get models
    - Url：`http://localhost:3010/v1/models`
    - Request：`GET`
    - Authentication：`Bearer Token`（The value of `Cursor Cookie`)

2. Chat completion
    - Url：`http://localhost:3010/v1/chat/completions`
    - Request：`POST`
    - Authentication：`Bearer Token`（The value of `Cursor Cookie`，supports comma-separated values）

For the response body, please refer to the OpenAI interface

### Python demo

```python
from openai import OpenAI

client = OpenAI(api_key="{{{Replace by the Cursor cookie of your account. It starts with user_...}}}",
                base_url="http://localhost:3010/v1")

response = client.chat.completions.create(
    model="claude-3-7-sonnet",
    messages=[
        {"role": "user", "content": "Hello."},
    ],
    stream=False
)

print(response.choices)
```

## Notes

- Please keep your Cursor cookie properly and do not disclose it to others
- This project is for study and research only, please abide by the Cursor Terms of Use
- The login tool automatically manages your `.env` file for convenience
- If you need to update your token, simply run `npm run login` again

## Acknowledgements

- This project is based on [cursor-api](https://github.com/zhx47/cursor-api)(by zhx47).
- This project integrates the commits in [cursor-api](https://github.com/lvguanjun/cursor-api)(by lvguanjun).
