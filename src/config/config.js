module.exports = {
    port: process.env.PORT || 3010,
    proxy: {
        enabled: false,
        url: 'http://127.0.0.1:7890',
    },
    cursor_token: process.env.CURSOR_TOKEN || '',
    cursor_accept_encoding: process.env.CURSOR_ACCEPT_ENCODING || 'gzip',
    cursor_connect_protocol_version: process.env.CURSOR_CONNECT_PROTOCOL_VERSION || '1',
    cursor_content_type: process.env.CURSOR_CONTENT_TYPE || 'application/proto',
    cursor_user_agent: process.env.CURSOR_USER_AGENT || 'connect-es/1.6.1',
    cursor_x_cursor_client_version: process.env.CURSOR_X_CURSOR_CLIENT_VERSION || "1.1.5",
    cursor_x_cursor_timezone: process.env.CURSOR_X_CURSOR_TIMEZONE || 'Europe/Istanbul',
    cursor_x_ghost_mode: process.env.CURSOR_X_GHOST_MODE || 'true',
    cursor_host: process.env.CURSOR_HOST || 'api2.cursor.sh',
    //chat_mode: process.env.CHAT_MODE || 1 // 1 for ask, 2 for agent, 3 for edit
    cursor_api_path: process.env.CURSOR_API_PATH || 'aiserver.v1.AiService',
    cursor_chat_path: process.env.CURSOR_CHAT_PATH || 'aiserver.v1.ChatService',
};